import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/services/firestore_service.dart';
import '../../core/providers/session_provider.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/stat_card.dart';
import '../widgets/empty_state_widget.dart';

class WorkOrderListScreen extends StatefulWidget {
  const WorkOrderListScreen({super.key});
  @override
  State<WorkOrderListScreen> createState() => _WorkOrderListScreenState();
}

class _WorkOrderListScreenState extends State<WorkOrderListScreen> {
  List<Map<String, dynamic>> _orders = [];
  String _statusFilter = 'ALL';
  bool _loading = true;
  static const int _pageSize = 20;
  int _currentPage = 1;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);
    final snap = await FirestoreService.workOrders
        .orderBy('created_at', descending: true)
        .get();
    if (!mounted) return;
    setState(() {
      _orders = snap.docs.map(FirestoreService.docToMap).toList();
      _loading = false;
    });
  }

  List<Map<String, dynamic>> get _filtered => _statusFilter == 'ALL'
      ? _orders
      : _orders.where((o) => o['status'] == _statusFilter).toList();

  List<Map<String, dynamic>> get _paginated =>
      _filtered.take(_currentPage * _pageSize).toList();

  bool get _hasMore => _paginated.length < _filtered.length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Work Orders'),
        actions: [
          IconButton(
            icon: const Icon(Icons.view_kanban_outlined),
            onPressed: () => context.go('/work-orders/kanban'),
            tooltip: 'Kanban View',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.go('/work-orders/create'),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                SizedBox(
                  height: 44,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    children:
                        [
                              'ALL',
                              'PENDING',
                              'IN_PROGRESS',
                              'COMPLETED',
                              'CANCELLED',
                            ]
                            .map(
                              (s) => Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: FilterChip(
                                  label: Text(s.replaceAll('_', ' ')),
                                  selected: _statusFilter == s,
                                  onSelected: (_) =>
                                      setState(() => _statusFilter = s),
                                  selectedColor: AppTheme.primaryBlue
                                      .withValues(alpha: 0.15),
                                  checkmarkColor: AppTheme.primaryBlue,
                                ),
                              ),
                            )
                            .toList(),
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _load,
                    child: _filtered.isEmpty
                        ? EmptyStateWidget.orders(
                            key: const Key('orders_empty'),
                            onAdd: () => context.go('/work-orders/create'),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _paginated.length + (_hasMore ? 1 : 0),
                            itemBuilder: (_, i) {
                              if (i == _paginated.length) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  child: Center(
                                    child: OutlinedButton.icon(
                                      onPressed: () =>
                                          setState(() => _currentPage++),
                                      icon: const Icon(Icons.expand_more, size: 16),
                                      label: Text(
                                        'Load More (${_filtered.length - _paginated.length} remaining)',
                                      ),
                                    ),
                                  ),
                                );
                              }
                              return _WOCard(order: _paginated[i]);
                            },
                          ),
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/work-orders/create'),
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _WOCard extends StatelessWidget {
  final Map<String, dynamic> order;
  const _WOCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () => context.go('/work-orders/detail/${order['id']}'),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? AppTheme.darkBorder : const Color(0xFFE5E7EB),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    order['wo_number'] as String,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                  const Spacer(),
                  PriorityBadge(priority: order['priority'] as String),
                  const SizedBox(width: 8),
                  StatusBadge(status: order['status'] as String),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                order['subject'] as String,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today_outlined,
                    size: 12,
                    color: Color(0xFF6B7280),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Due: ${order['deadline'] ?? 'N/A'}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.chevron_right,
                    color: Color(0xFF6B7280),
                    size: 16,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class WorkOrderKanbanScreen extends StatefulWidget {
  const WorkOrderKanbanScreen({super.key});
  @override
  State<WorkOrderKanbanScreen> createState() => _WorkOrderKanbanScreenState();
}

class _WorkOrderKanbanScreenState extends State<WorkOrderKanbanScreen> {
  Map<String, List<Map<String, dynamic>>> _columns = {
    'PENDING': [],
    'IN_PROGRESS': [],
    'COMPLETED': [],
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    final snap = await FirestoreService.workOrders.get();
    final orders = snap.docs.map(FirestoreService.docToMap).toList();
    if (!mounted) return;
    setState(() {
      _columns = {'PENDING': [], 'IN_PROGRESS': [], 'COMPLETED': []};
      for (final o in orders) {
        final s = o['status'] as String? ?? '';
        if (_columns.containsKey(s)) _columns[s]!.add(o);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kanban Board'),
        leading: BackButton(onPressed: () => context.go('/work-orders')),
        actions: [
          IconButton(
            icon: const Icon(Icons.list_outlined),
            onPressed: () => context.go('/work-orders'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: _columns.entries
              .map((e) => _KanbanColumn(status: e.key, orders: e.value))
              .toList(),
        ),
      ),
    );
  }
}

class _KanbanColumn extends StatelessWidget {
  final String status;
  final List<Map<String, dynamic>> orders;
  const _KanbanColumn({required this.status, required this.orders});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = AppTheme.statusColor(status);
    return Container(
      width: 260,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  status.replaceAll('_', ' '),
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                const Spacer(),
                Text(
                  '${orders.length}',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          ...orders.map(
            (o) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark ? AppTheme.darkBorder : const Color(0xFFE5E7EB),
                ),
              ),
              child: InkWell(
                onTap: () => context.go('/work-orders/detail/${o['id']}'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      o['wo_number'] as String,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppTheme.primaryBlue,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      o['subject'] as String,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 8),
                    PriorityBadge(priority: o['priority'] as String),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class WorkOrderDetailScreen extends StatefulWidget {
  final String workOrderId;
  const WorkOrderDetailScreen({super.key, required this.workOrderId});
  @override
  State<WorkOrderDetailScreen> createState() => _WorkOrderDetailScreenState();
}

class _WorkOrderDetailScreenState extends State<WorkOrderDetailScreen> {
  Map<String, dynamic>? _order;
  Timer? _ticker;
  Duration _elapsed = Duration.zero;
  bool _timerRunning = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted) return;
    final doc = await FirestoreService.workOrders.doc(widget.workOrderId).get();
    if (doc.exists && mounted) {
      final order = FirestoreService.docToMap(doc);
      final timerStart = order['timer_start'] as String?;
      Duration elapsed = Duration.zero;
      bool running = false;
      if (timerStart != null) {
        elapsed = DateTime.now().difference(DateTime.parse(timerStart));
        running = true;
      }
      setState(() {
        _order = order;
        _elapsed = elapsed;
        _timerRunning = running;
      });
      if (running && _ticker == null) _startTick();
    }
  }

  void _startTick() {
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsed += const Duration(seconds: 1));
    });
  }

  Future<void> _toggleTimer() async {
    if (_timerRunning) {
      _ticker?.cancel();
      _ticker = null;
      await FirestoreService.workOrders.doc(widget.workOrderId).update({'timer_start': null});
      if (mounted) setState(() => _timerRunning = false);
    } else {
      final startAt = DateTime.now().subtract(_elapsed).toIso8601String();
      await FirestoreService.workOrders.doc(widget.workOrderId).update({'timer_start': startAt});
      if (mounted) {
        setState(() => _timerRunning = true);
        _startTick();
      }
    }
  }

  Future<void> _resetTimer() async {
    _ticker?.cancel();
    _ticker = null;
    await FirestoreService.workOrders.doc(widget.workOrderId).update({'timer_start': null});
    if (mounted) {
      setState(() {
        _elapsed = Duration.zero;
        _timerRunning = false;
      });
    }
  }

  String _formatElapsed() {
    final h = _elapsed.inHours.toString().padLeft(2, '0');
    final m = (_elapsed.inMinutes % 60).toString().padLeft(2, '0');
    final s = (_elapsed.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  Future<void> _updateStatus(String status) async {
    await FirestoreService.workOrders.doc(widget.workOrderId).update({'status': status});
    await _load();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Status updated to $status')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (_order == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(_order!['wo_number'] as String),
        leading: BackButton(onPressed: () => context.go('/work-orders')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Details card ──────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppTheme.darkBorder : const Color(0xFFE5E7EB),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      PriorityBadge(priority: _order!['priority'] as String),
                      const SizedBox(width: 8),
                      StatusBadge(status: _order!['status'] as String),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _order!['subject'] as String,
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF111827),
                    ),
                  ),
                  if (_order!['description'] != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _order!['description'] as String,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    'Deadline',
                    _order!['deadline'] ?? 'N/A',
                    isDark,
                  ),
                  _buildInfoRow(
                    'Created',
                    _order!['created_at']?.toString().substring(0, 10) ?? '',
                    isDark,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Persistent Timer card ─────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppTheme.darkBorder : const Color(0xFFE5E7EB),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'WORK TIMER',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF6B7280),
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      _formatElapsed(),
                      style: GoogleFonts.inter(
                        fontSize: 48,
                        fontWeight: FontWeight.w700,
                        color: _timerRunning
                            ? AppTheme.primaryBlue
                            : (isDark ? Colors.white : const Color(0xFF111827)),
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _toggleTimer,
                          icon: Icon(
                            _timerRunning ? Icons.stop : Icons.play_arrow,
                          ),
                          label: Text(_timerRunning ? 'Stop' : 'Start'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _timerRunning
                                ? AppTheme.accentRed
                                : AppTheme.primaryBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: _resetTimer,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text('Reset'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Status update ─────────────────────────────────────────────
            Text(
              'UPDATE STATUS',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF6B7280),
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ['PENDING', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED']
                  .map((s) {
                    final isCurrent = _order!['status'] == s;
                    return ActionChip(
                      label: Text(s.replaceAll('_', ' ')),
                      backgroundColor: isCurrent ? AppTheme.statusBg(s) : null,
                      labelStyle: TextStyle(
                        color: isCurrent ? AppTheme.statusColor(s) : null,
                        fontWeight: isCurrent
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                      onPressed: () => _updateStatus(s),
                    );
                  })
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, bool isDark) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : const Color(0xFF111827),
          ),
        ),
      ],
    ),
  );
}

class CreateWorkOrderScreen extends StatefulWidget {
  const CreateWorkOrderScreen({super.key});
  @override
  State<CreateWorkOrderScreen> createState() => _CreateWorkOrderScreenState();
}

class _CreateWorkOrderScreenState extends State<CreateWorkOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _priority = 'MEDIUM';
  String? _deadline;
  bool _saving = false;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final session = context.read<SessionProvider>().session;
    final snap = await FirestoreService.workOrders.get();
    final count = snap.size;
    await FirestoreService.workOrders.add({
      'wo_number': 'WO-${1100 + count}',
      'subject': _subjectCtrl.text.trim(),
      'description': _descCtrl.text.trim(),
      'priority': _priority,
      'deadline': _deadline,
      'status': 'PENDING',
      'created_by': session.userId,
      'created_at': DateTime.now().toIso8601String(),
    });
    if (mounted) context.go('/work-orders');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Work Order'),
        leading: BackButton(onPressed: () => context.go('/work-orders')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLabelField(
                'Subject',
                hint: 'e.g. Cut 50 SS Plates',
                controller: _subjectCtrl,
                isDark: isDark,
                validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              _buildLabelField(
                'Description',
                hint: 'Optional details...',
                controller: _descCtrl,
                isDark: isDark,
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              _buildDropdownLabel(
                'Priority',
                _priority,
                ['LOW', 'MEDIUM', 'HIGH'],
                isDark,
                (v) => setState(() => _priority = v!),
              ),
              const SizedBox(height: 16),
              _buildLabelField(
                'Deadline',
                hint: 'YYYY-MM-DD',
                isDark: isDark,
                onTap: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (d != null) {
                    setState(() => _deadline = d.toString().substring(0, 10));
                  }
                },
                readOnly: true,
                controller: TextEditingController(text: _deadline ?? ''),
              ),
              const SizedBox(height: 28),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Confirmation Required',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'I\'ll create this work order. Confirm to proceed.',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Create Work Order'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabelField(
    String label, {
    String? hint,
    TextEditingController? controller,
    required bool isDark,
    String? Function(String?)? validator,
    bool readOnly = false,
    VoidCallback? onTap,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? const Color(0xFFD1D5DB) : const Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          readOnly: readOnly,
          onTap: onTap,
          validator: validator,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: isDark
                ? const Color(0xFF0A0E1A)
                : const Color(0xFFF9FAFB),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: isDark ? AppTheme.darkBorder : const Color(0xFFE5E7EB),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: isDark ? AppTheme.darkBorder : const Color(0xFFE5E7EB),
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownLabel(
    String label,
    String value,
    List<String> items,
    bool isDark,
    void Function(String?)? onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? const Color(0xFFD1D5DB) : const Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: value,
          onChanged: onChanged,
          decoration: InputDecoration(
            filled: true,
            fillColor: isDark
                ? const Color(0xFF0A0E1A)
                : const Color(0xFFF9FAFB),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: isDark ? AppTheme.darkBorder : const Color(0xFFE5E7EB),
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
          ),
          items: items
              .map((i) => DropdownMenuItem(value: i, child: Text(i)))
              .toList(),
        ),
      ],
    );
  }
}
