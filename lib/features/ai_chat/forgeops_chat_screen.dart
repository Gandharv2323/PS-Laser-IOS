import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../../core/services/secure_storage_service.dart';
import '../../core/services/firestore_service.dart';
import '../../core/theme/app_theme.dart';

// ─── OpenRouter config ─────────────────────────────────────────────────────
const _kOpenRouterUrl = 'https://openrouter.ai/api/v1/chat/completions';
const _kModel = 'openai/gpt-oss-120b:free';

class ForgeOpsChatScreen extends StatefulWidget {
  const ForgeOpsChatScreen({super.key});
  @override
  State<ForgeOpsChatScreen> createState() => _ForgeOpsChatScreenState();
}

class _ForgeOpsChatScreenState extends State<ForgeOpsChatScreen> {
  final _scrollCtrl = ScrollController();
  final _textCtrl = TextEditingController();
  final List<_ChatMessage> _messages = [
    _ChatMessage(
      isAI: true,
      text:
          'ForgeOps AI online.\n\nI have live access to your floor data: attendance, inventory, machines, work orders, alerts, and payroll.\n\nWhat do you need?',
      time: DateTime.now().subtract(const Duration(seconds: 5)),
    ),
  ];
  bool _thinking = false;

  final List<String> _quickPrompts = [
    'Floor status right now?',
    'Low stock items?',
    'Machines needing maintenance?',
    'Open work orders?',
    'Attendance today?',
    'Active alerts?',
    'Payroll this month?',
  ];

  // ─── Live Firestore context builder ──────────────────────────────────────
  Future<String> _queryLiveData(String userText) async {
    final lower = userText.toLowerCase();
    final today = DateTime.now().toString().substring(0, 10);
    final month = DateTime.now().toString().substring(0, 7);

    // FLOOR STATUS
    if (lower.contains('floor') || lower.contains('status') || lower.contains('overview')) {
      final attSnap = await FirestoreService.attendance
          .where('date', isEqualTo: today)
          .where('status', isEqualTo: 'PRESENT').get();
      final empSnap = await FirestoreService.employees.where('is_active', isEqualTo: 1).get();
      final machSnap = await FirestoreService.machines.get();
      final woSnap = await FirestoreService.workOrders
          .where('status', whereIn: ['PENDING', 'IN_PROGRESS']).get();
      final alertSnap = await FirestoreService.alerts.where('is_resolved', isEqualTo: 0).get();
      final machines = machSnap.docs.map(FirestoreService.docToMap).toList();
      return 'Floor Status — $today:\n• Workers present: ${attSnap.size} / ${empSnap.size}\n• Machines running: ${machines.where((m) => m['status'] == 'RUNNING').length} / ${machines.length}\n• Open work orders: ${woSnap.size}\n• Unresolved alerts: ${alertSnap.size}';
    }

    // INVENTORY / LOW STOCK
    if (lower.contains('stock') || lower.contains('inventory') || lower.contains('item')) {
      final snap = await FirestoreService.inventory.get();
      final lowStock = snap.docs.map(FirestoreService.docToMap)
          .where((i) => (i['current_qty'] as num) <= (i['reorder_level'] as num)).toList();
      if (lowStock.isEmpty) return 'Inventory: No items below reorder level. All stock levels are adequate.';
      final lines = lowStock.map((r) => '• ${r['name']} — ${r['current_qty']} left (reorder at ${r['reorder_level']})').join('\n');
      return 'Low Stock Alert (${lowStock.length} items):\n$lines\n\nRaise purchase orders immediately.';
    }

    // MACHINES / MAINTENANCE
    if (lower.contains('machine') || lower.contains('maintenance') || lower.contains('service')) {
      final snap = await FirestoreService.machines.get();
      final all = snap.docs.map(FirestoreService.docToMap).toList();
      final overdue = all.where((m) {
        final due = m['next_service_due'] as String?;
        return m['status'] == 'MAINTENANCE' || (due != null && due.compareTo(today) < 0);
      }).toList();
      final running = all.where((m) => m['status'] == 'RUNNING').length;
      final idle = all.where((m) => m['status'] == 'IDLE').length;
      final offline = all.where((m) => m['status'] == 'OFFLINE').length;
      String resp = 'Machines (${all.length} total):\n• Running: $running  Idle: $idle  Offline: $offline\n';
      if (overdue.isNotEmpty) {
        resp += '\nMaintenance Due / Overdue:\n';
        resp += overdue.map((m) => '• ${m['name']} — due ${m['next_service_due']}').join('\n');
        resp += '\n\nSchedule maintenance now to avoid production halt.';
      } else {
        resp += '\nAll machines are within service schedule.';
      }
      return resp;
    }

    // WORK ORDERS
    if (lower.contains('work order') || lower.contains('wo') || lower.contains('jobs')) {
      final snap = await FirestoreService.workOrders
          .where('status', whereIn: ['PENDING', 'IN_PROGRESS']).get();
      if (snap.size == 0) return 'Work Orders: No open work orders. All caught up.';
      final open = snap.docs.map(FirestoreService.docToMap).toList();
      final priorityOrder = {'CRITICAL': 1, 'HIGH': 2, 'MEDIUM': 3, 'LOW': 4};
      open.sort((a, b) => (priorityOrder[a['priority']] ?? 5).compareTo(priorityOrder[b['priority']] ?? 5));
      final lines = open.map((w) => '• ${w['wo_number']} [${w['priority']}] — ${w['subject']} (${w['status']})').join('\n');
      return 'Open Work Orders (${open.length}):\n$lines';
    }

    // ATTENDANCE
    if (lower.contains('attendance') || lower.contains('present') || lower.contains('absent')) {
      final snap = await FirestoreService.attendance.where('date', isEqualTo: today).get();
      if (snap.size == 0) return 'Attendance: No records marked yet for today ($today).';
      final records = snap.docs.map(FirestoreService.docToMap).toList();
      // Enrich with employee names
      for (final r in records) {
        final empId = r['employee_id'] as String? ?? '';
        if (empId.isNotEmpty) {
          final empDoc = await FirestoreService.employees.doc(empId).get();
          if (empDoc.exists) r['name'] = FirestoreService.docToMap(empDoc)['name'];
        }
      }
      final present = records.where((r) => r['status'] == 'PRESENT').length;
      final absent = records.where((r) => r['status'] == 'ABSENT').length;
      final absentNames = records.where((r) => r['status'] == 'ABSENT').map((r) => r['name'] as String? ?? '').where((n) => n.isNotEmpty).join(', ');
      return 'Attendance — $today:\n• Present: $present\n• Absent: $absent${absentNames.isNotEmpty ? " ($absentNames)" : ''}\n• Total tracked: ${records.length}';
    }

    // ALERTS
    if (lower.contains('alert') || lower.contains('critical') || lower.contains('warning')) {
      final snap = await FirestoreService.alerts
          .where('is_resolved', isEqualTo: 0)
          .orderBy('triggered_at', descending: true).get();
      if (snap.size == 0) return 'Alerts: No active alerts. Floor is running clean.';
      final alerts = snap.docs.map(FirestoreService.docToMap).toList();
      final lines = alerts.map((a) => '• [${a['severity']}] ${a['message']}').join('\n');
      return 'Active Alerts (${alerts.length}):\n$lines\n\nResolve CRITICAL alerts first.';
    }

    // PAYROLL
    if (lower.contains('payroll') || lower.contains('salary') || lower.contains('pay')) {
      final snap = await FirestoreService.payroll.where('month', isEqualTo: month).get();
      if (snap.size == 0) return 'Payroll: No payslips generated for $month yet. Use Generate All in Payroll screen.';
      final records = snap.docs.map(FirestoreService.docToMap).toList();
      // Enrich with names
      for (final r in records) {
        final empId = r['employee_id'] as String? ?? '';
        if (empId.isNotEmpty) {
          final empDoc = await FirestoreService.employees.doc(empId).get();
          if (empDoc.exists) r['name'] = FirestoreService.docToMap(empDoc)['name'];
        }
      }
      final total = records.fold<double>(0, (sum, r) => sum + ((r['net_pay'] as num?)?.toDouble() ?? 0));
      return 'Payroll — $month (${records.length} employees):\nTotal payout: ₹${total.toStringAsFixed(0)}\n\n${records.map((r) => '• ${r['name']}: ₹${r['net_pay']} (${r['paid_days']} days)').join('\n')}';
    }

    // EMPLOYEES
    if (lower.contains('employee') || lower.contains('staff') || lower.contains('worker')) {
      final snap = await FirestoreService.employees.where('is_active', isEqualTo: 1).orderBy('name').get();
      final emps = snap.docs.map(FirestoreService.docToMap).toList();
      return 'Active Employees (${emps.length}):\n${emps.map((e) => '• ${e['name']} — ${e['designation']} (${e['department']})').join('\n')}';
    }

    // CYLINDERS
    if (lower.contains('cylinder') || lower.contains('gas')) {
      final snap = await FirestoreService.cylinders.get();
      final cyls = snap.docs.map(FirestoreService.docToMap).toList();
      final empty = cyls.where((c) => c['status'] == 'EMPTY').length;
      final full = cyls.where((c) => c['status'] == 'FULL').length;
      final partial = cyls.where((c) => c['status'] == 'PARTIAL').length;
      return 'Gas Cylinders (${cyls.length} total):\n• Full: $full\n• Partial: $partial\n• Empty: $empty${empty > 0 ? '\n\n$empty cylinders need refilling.' : ''}';
    }

    return 'No specific data found for that query. User asked: "$userText"';
  }

  // ─── OpenRouter API call ──────────────────────────────────────────────────
  Future<String> _callOpenRouter({
    required String apiKey,
    required String userMessage,
    required String localContext,
  }) async {
    final systemPrompt = '''You are ForgeOps AI, an intelligent assistant embedded inside a manufacturing ERP system for PS Laser Industries.

Your role: Analyse the local database context provided and give a clear, professional, and concise response to the user's question. 
- Always use the local context as the primary source of truth.
- If data is missing or insufficient, say so honestly.
- Use bullet points for lists. Be direct — no unnecessary filler.
- Respond in the same language the user writes in.

Current Local Database Context:
$localContext''';

    final body = jsonEncode({
      'model': _kModel,
      'messages': [
        {'role': 'system', 'content': systemPrompt},
        {'role': 'user', 'content': userMessage},
      ],
      'max_tokens': 512,
      'temperature': 0.4,
    });

    final response = await http
        .post(
          Uri.parse(_kOpenRouterUrl),
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
            'HTTP-Referer': 'https://pslaser.com',
            'X-Title': 'ForgeOps AI',
          },
          body: body,
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final content =
          data['choices']?[0]?['message']?['content'] as String? ?? '';
      return content.trim().isNotEmpty ? content.trim() : localContext;
    } else if (response.statusCode == 401) {
      return '❌ Invalid API key. Go to Settings → AI Integration and update your OpenRouter key.';
    } else if (response.statusCode == 429) {
      return '⏳ Rate limit reached on the free tier. Wait a moment and try again.\n\nLocal data:\n$localContext';
    } else {
      debugPrint('OpenRouter error ${response.statusCode}: ${response.body}');
      return '⚠️ AI service error (${response.statusCode}). Showing local data:\n\n$localContext';
    }
  }

  // ─── Main query processor ─────────────────────────────────────────────────
  Future<String> _processFullQuery(String message) async {
    final localContext = await _queryLiveData(message);

    // Read API key from encrypted secure storage
    final apiKey = await SecureStorageService.getOpenRouterKey() ?? '';

    if (apiKey.trim().isEmpty) {
      return '$localContext\n\n⚙️ Tip: Add your OpenRouter API key in Settings → AI Integration for enhanced AI responses.';
    }

    try {
      return await _callOpenRouter(
        apiKey: apiKey.trim(),
        userMessage: message,
        localContext: localContext,
      );
    } catch (e) {
      debugPrint('OpenRouter call failed: $e');
      return '⚠️ Network error. Showing local data:\n\n$localContext';
    }
  }

  // ─── Send handler ─────────────────────────────────────────────────────────
  void _handleSend([String? quick]) {
    final text = quick ?? _textCtrl.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(_ChatMessage(isAI: false, text: text, time: DateTime.now()));
      _thinking = true;
      _textCtrl.clear();
    });
    _scrollToBottom();

    _processFullQuery(text).then((response) {
      if (!mounted) return;
      setState(() {
        _messages.add(
          _ChatMessage(isAI: true, text: response, time: DateTime.now()),
        );
        _thinking = false;
      });
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _textCtrl.dispose();
    super.dispose();
  }

  // ─── UI ───────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: isDark
            ? const Color(0xFF0A0E1A)
            : const Color(0xFF0D1B2A),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.smart_toy_outlined,
                color: AppTheme.primaryBlue,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ForgeOps AI',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: AppTheme.statusRunning,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'OpenRouter · GPT-OSS 120B',
                      style: TextStyle(fontSize: 10, color: Color(0xFF6EE7B7)),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        leading: BackButton(
          color: Colors.white,
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              context.go('/dashboard');
            }
          },
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: isDark
          ? const Color(0xFF060A14)
          : const Color(0xFFF0F4F8),
      body: Column(
        children: [
          // ── Message list ─────────────────────────────────────────────────
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_thinking ? 1 : 0),
              itemBuilder: (_, i) {
                if (i == _messages.length) return const _ThinkingBubble();
                return _MessageBubble(message: _messages[i], isDark: isDark);
              },
            ),
          ),
          // ── Quick prompts ────────────────────────────────────────────────
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              itemCount: _quickPrompts.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, i) => InkWell(
                onTap: () => _handleSend(_quickPrompts[i]),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withValues(
                      alpha: isDark ? 0.2 : 0.1,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    _quickPrompts[i],
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                ),
              ),
            ),
          ),
          // ── Input bar ────────────────────────────────────────────────────
          Container(
            color: isDark ? const Color(0xFF0A0E1A) : Colors.white,
            padding: EdgeInsets.fromLTRB(
              12,
              8,
              12,
              MediaQuery.of(context).viewInsets.bottom + 8,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textCtrl,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: isDark ? Colors.white : const Color(0xFF111827),
                    ),
                    decoration: InputDecoration(
                      hintText: 'Ask about floor, inventory, machines...',
                      hintStyle: const TextStyle(color: Color(0xFF6B7280)),
                      filled: true,
                      fillColor: isDark
                          ? const Color(0xFF0D1B2A)
                          : const Color(0xFFF9FAFB),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                    onSubmitted: (_) => _handleSend(),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _handleSend,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryBlue,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Message bubble ────────────────────────────────────────────────────────
class _MessageBubble extends StatelessWidget {
  final _ChatMessage message;
  final bool isDark;
  const _MessageBubble({required this.message, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final isAI = message.isAI;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment:
            isAI ? MainAxisAlignment.start : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isAI) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.smart_toy_outlined,
                color: AppTheme.primaryBlue,
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isAI
                    ? (isDark ? const Color(0xFF0D1B2A) : Colors.white)
                    : AppTheme.primaryBlue,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(isAI ? 0 : 16),
                  topRight: Radius.circular(isAI ? 16 : 0),
                  bottomLeft: const Radius.circular(16),
                  bottomRight: const Radius.circular(16),
                ),
                border: isAI
                    ? Border.all(
                        color: isDark
                            ? AppTheme.darkBorder
                            : const Color(0xFFE5E7EB),
                      )
                    : null,
              ),
              child: Text(
                message.text,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: isAI
                      ? (isDark ? Colors.white : const Color(0xFF111827))
                      : Colors.white,
                  height: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Thinking bubble ───────────────────────────────────────────────────────
class _ThinkingBubble extends StatelessWidget {
  const _ThinkingBubble();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.smart_toy_outlined,
              color: AppTheme.primaryBlue,
              size: 16,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0D1B2A) : Colors.white,
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              border: Border.all(
                color: isDark ? AppTheme.darkBorder : const Color(0xFFE5E7EB),
              ),
            ),
            child: const Text(
              '● ● ●',
              style: TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 14,
                letterSpacing: 4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Data model ────────────────────────────────────────────────────────────
class _ChatMessage {
  final bool isAI;
  final String text;
  final DateTime time;
  _ChatMessage({required this.isAI, required this.text, required this.time});
}
