import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/services/firestore_service.dart';
import '../../core/services/notification_service.dart';
import '../../core/providers/session_provider.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/stat_card.dart';


class LeaveApplicationScreen extends StatefulWidget {
  const LeaveApplicationScreen({super.key});
  @override
  State<LeaveApplicationScreen> createState() => _LeaveApplicationScreenState();
}

class _LeaveApplicationScreenState extends State<LeaveApplicationScreen> {
  List<Map<String, dynamic>> _leaves = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final session = context.read<SessionProvider>().session;
    if (!mounted) return;
    setState(() => _loading = true);
    final snap = await FirestoreService.leaves
        .where('employee_id', isEqualTo: session.userId.toString())
        .orderBy('created_at', descending: true)
        .get();
    if (!mounted) return;
    setState(() {
      _leaves = snap.docs.map(FirestoreService.docToMap).toList();
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Leave'),
        leading: BackButton(onPressed: () => context.go('/dashboard')),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showApplyDialog(context),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      _buildBalanceChip(
                        'Annual',
                        '18',
                        AppTheme.primaryBlue,
                        isDark,
                      ),
                      const SizedBox(width: 8),
                      _buildBalanceChip(
                        'Sick',
                        '12',
                        AppTheme.accentOrange,
                        isDark,
                      ),
                      const SizedBox(width: 8),
                      _buildBalanceChip(
                        'Casual',
                        '6',
                        AppTheme.statusRunning,
                        isDark,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'HISTORY',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF6B7280),
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: _leaves.isEmpty
                      ? const Center(
                          child: Text(
                            'No leave applications yet',
                            style: TextStyle(color: Color(0xFF6B7280)),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _leaves.length,
                          itemBuilder: (_, i) {
                            final l = _leaves[i];
                            final status = l['status'] as String;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppTheme.darkCard
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isDark
                                      ? AppTheme.darkBorder
                                      : const Color(0xFFE5E7EB),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 4,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: AppTheme.statusColor(status),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          l['leave_type'] as String,
                                          style: GoogleFonts.inter(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: isDark
                                                ? Colors.white
                                                : const Color(0xFF111827),
                                          ),
                                        ),
                                        Text(
                                          '${l['from_date']} → ${l['to_date']}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF6B7280),
                                          ),
                                        ),
                                        if (l['reason'] != null)
                                          Text(
                                            l['reason'] as String,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: Color(0xFF9CA3AF),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  StatusBadge(status: status),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showApplyDialog(context),
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showApplyDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String selectedType = 'Annual Leave';
    final reasonCtrl = TextEditingController();
    String? fromDate;
    String? toDate;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSt) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Apply for Leave',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                initialValue: selectedType,
                onChanged: (v) => setSt(() => selectedType = v!),
                decoration: InputDecoration(
                  labelText: 'Leave Type',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                ),
                items:
                    [
                          'Annual Leave',
                          'Sick Leave',
                          'Casual Leave',
                          'Emergency Leave',
                        ]
                        .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                        .toList(),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'From',
                        hintText: fromDate ?? 'Select date',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                      ),
                      onTap: () async {
                        final d = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(
                            const Duration(days: 365),
                          ),
                        );
                        if (d != null) {
                          setSt(() => fromDate = d.toString().substring(0, 10));
                        }
                      },
                      controller: TextEditingController(text: fromDate ?? ''),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'To',
                        hintText: toDate ?? 'Select date',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                      ),
                      onTap: () async {
                        final d = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(
                            const Duration(days: 365),
                          ),
                        );
                        if (d != null) {
                          setSt(() => toDate = d.toString().substring(0, 10));
                        }
                      },
                      controller: TextEditingController(text: toDate ?? ''),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: reasonCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Reason',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () async {
                    if (fromDate == null || toDate == null) return;
                    final session = context.read<SessionProvider>().session;
                    final nav = Navigator.of(context);
                    await FirestoreService.leaves.add({
                      'employee_id': session.userId.toString(),
                      'leave_type': selectedType,
                      'from_date': fromDate,
                      'to_date': toDate,
                      'start_date': fromDate,
                      'end_date': toDate,
                      'duration': 1,
                      'reason': reasonCtrl.text,
                      'status': 'PENDING',
                      'created_at': DateTime.now().toIso8601String(),
                    });
                    // 🔔 Notify supervisors of new leave request
                    await NotificationService.triggerAlert(
                      title: '📋 New Leave Request',
                      body: '${session.userName} has applied for $selectedType leave '
                          'from $fromDate to $toDate. Pending your approval.',
                      type: 'LEAVE_REQUEST',
                      route: '/leave/approval-queue',
                    );
                    nav.pop();
                    _load();
                  },
                  child: const Text('Submit Application'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceChip(
    String label,
    String value,
    Color color,
    bool isDark,
  ) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: const Color(0xFF6B7280),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    ),
  );
}

class LeaveApprovalQueueScreen extends StatefulWidget {
  const LeaveApprovalQueueScreen({super.key});
  @override
  State<LeaveApprovalQueueScreen> createState() =>
      _LeaveApprovalQueueScreenState();
}

class _LeaveApprovalQueueScreenState extends State<LeaveApprovalQueueScreen> {
  List<Map<String, dynamic>> _pending = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    final pendingSnap = await FirestoreService.leaves
        .where('status', isEqualTo: 'PENDING')
        .orderBy('start_date')
        .get();
    final leaves = await Future.wait(
      pendingSnap.docs.map((doc) async {
        final leave = FirestoreService.docToMap(doc);
        final empId = leave['employee_id'] as String? ?? '';
        if (empId.isNotEmpty) {
          final empDoc = await FirestoreService.employees.doc(empId).get();
          if (empDoc.exists) {
            final emp = FirestoreService.docToMap(empDoc);
            leave['name'] = emp['name'];
            leave['designation'] = emp['designation'];
          }
        }
        return leave;
      }),
    );
    if (mounted) setState(() => _pending = leaves);
  }

  Future<void> _respond(String id, String status) async {
    await FirestoreService.leaves.doc(id).update({'status': status});
    await _load();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Leave $status')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leave Approvals'),
        leading: BackButton(onPressed: () => context.go('/dashboard')),
      ),
      body: _pending.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 64,
                    color: Color(0xFF4B5563),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No pending approvals',
                    style: TextStyle(color: Color(0xFF6B7280), fontSize: 16),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _pending.length,
              itemBuilder: (_, i) {
                final l = _pending[i];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkCard : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark
                          ? AppTheme.darkBorder
                          : const Color(0xFFE5E7EB),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: AppTheme.primaryBlue.withValues(
                              alpha: 0.15,
                            ),
                            child: Text(
                              (l['name'] as String)[0],
                              style: const TextStyle(
                                color: AppTheme.primaryBlue,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l['name'] as String,
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF111827),
                                  ),
                                ),
                                Text(
                                  l['designation'] as String,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF6B7280),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.accentYellow.withValues(
                                alpha: 0.15,
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'PENDING',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.accentYellow,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '${l['leave_type']} • ${l['from_date']} → ${l['to_date']}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      if (l['reason'] != null &&
                          (l['reason'] as String).isNotEmpty)
                        Text(
                          l['reason'] as String,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF9CA3AF),
                          ),
                        ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () =>
                                  _respond(l['id'] as String, 'APPROVED'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.statusRunning,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                              ),
                              child: const Text('Approve'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () =>
                                  _respond(l['id'] as String, 'REJECTED'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.accentRed,
                                side: const BorderSide(
                                  color: AppTheme.accentRed,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                              ),
                              child: const Text('Reject'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
