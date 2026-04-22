import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/services/firestore_service.dart';
import '../../core/providers/session_provider.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/stat_card.dart';

// ─── Re-exports ──────────────────────────────────────────────────────────────
export 'qr_checkin_screen.dart' show QrCheckinScreen;

// ─── Attendance Screen ────────────────────────────────────────────────────────

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});
  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  List<Map<String, dynamic>> _records = [];
  List<Map<String, dynamic>> _allEmployees = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);
    final today = DateTime.now().toString().substring(0, 10);

    // Load today's attendance records
    final attendanceSnap = await FirestoreService.attendance
        .where('date', isEqualTo: today)
        .orderBy('check_in')
        .get();

    // Load all active employees
    final empSnap = await FirestoreService.employees
        .where('is_active', isEqualTo: 1)
        .orderBy('name')
        .get();

    final emps = empSnap.docs.map(FirestoreService.docToMap).toList();
    final empMap = {for (final e in emps) e['id'] as String: e};

    // Merge attendance with employee fields
    final records = attendanceSnap.docs.map((doc) {
      final rec = FirestoreService.docToMap(doc);
      final emp = empMap[rec['employee_id'] as String? ?? ''] ?? {};
      return {...rec, 'name': emp['name'] ?? '', 'designation': emp['designation'] ?? '', 'department': emp['department'] ?? ''};
    }).toList();

    if (!mounted) return;
    setState(() {
      _records = records;
      _allEmployees = emps;
      _loading = false;
    });
  }

  Future<void> _showMarkDialog(BuildContext context) async {
    final today = DateTime.now().toString().substring(0, 10);
    final now = DateTime.now().toString().substring(11, 16);

    // Find employees NOT yet marked today (use local list)
    final markedIds = _records.map((r) => r['employee_id'] as String? ?? '').toSet();
    final unmarked = _allEmployees
        .where((e) => !markedIds.contains(e['id'] as String? ?? ''))
        .toList();

    if (!context.mounted) return;

    if (unmarked.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All employees already marked for today.'),
        ),
      );
      return;
    }

    String? selectedEmpId = unmarked.isNotEmpty ? unmarked.first['id'] as String? : null;
    String selectedStatus = 'PRESENT';

    if (!context.mounted) return;
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Mark Attendance'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: selectedEmpId,
                decoration: const InputDecoration(
                  labelText: 'Employee',
                  border: OutlineInputBorder(),
                ),
                items: unmarked
                    .map(
                      (e) => DropdownMenuItem<String>(
                        value: e['id'] as String?,
                        child: Text(e['name'] as String),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setDialogState(() => selectedEmpId = v),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: selectedStatus,
                decoration: const InputDecoration(
                  labelText: 'Status',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'PRESENT', child: Text('✅ Present')),
                  DropdownMenuItem(value: 'ABSENT', child: Text('❌ Absent')),
                  DropdownMenuItem(
                    value: 'HALF_DAY',
                    child: Text('🌓 Half Day'),
                  ),
                  DropdownMenuItem(value: 'LATE', child: Text('⏰ Late')),
                ],
                onChanged: (v) => setDialogState(() => selectedStatus = v!),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (selectedEmpId == null) return;
                await FirestoreService.attendance.add({
                  'employee_id': selectedEmpId,
                  'date': today,
                  'check_in': selectedStatus == 'PRESENT' || selectedStatus == 'LATE' ? now : null,
                  'check_out': null,
                  'status': selectedStatus,
                });
                if (ctx.mounted) Navigator.pop(ctx);
                await _load();
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  /// Mark ALL unmarked employees as PRESENT
  Future<void> _markAllPresent() async {
    final today = DateTime.now().toString().substring(0, 10);
    final now = DateTime.now().toString().substring(11, 16);
    final markedIds = _records.map((r) => r['employee_id'] as String? ?? '').toSet();
    final unmarked = _allEmployees
        .where((e) => !markedIds.contains(e['id'] as String? ?? ''))
        .toList();
    for (final emp in unmarked) {
      await FirestoreService.attendance.add({
        'employee_id': emp['id'],
        'date': today,
        'check_in': now,
        'check_out': null,
        'status': 'PRESENT',
      });
    }
    await _load();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Marked ${unmarked.length} employees as PRESENT.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionProvider>().session;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final present = _records.where((r) => r['status'] == 'PRESENT').length;
    final absent = _records.where((r) => r['status'] == 'ABSENT').length;
    final today = DateTime.now();
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            tooltip: 'QR Check-in',
            onPressed: () => context.go('/attendance/qr-checkin'),
          ),
          if (session.canViewPayroll) // Supervisors+
            IconButton(
              icon: const Icon(Icons.supervisor_account_outlined),
              tooltip: 'Supervisor Approval',
              onPressed: () => context.go('/attendance/supervisor-approval'),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showMarkDialog(context),
        icon: const Icon(Icons.how_to_reg),
        label: const Text('Mark Attendance'),
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: StatCard(
                    title: 'Present',
                    value: '$present',
                    icon: Icons.check_circle_outline,
                    color: AppTheme.statusRunning,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: StatCard(
                    title: 'Absent',
                    value: '$absent',
                    icon: Icons.cancel_outlined,
                    color: AppTheme.accentRed,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: StatCard(
                    title: 'Total',
                    value: '${_records.length}',
                    icon: Icons.people_outline,
                    color: AppTheme.primaryBlue,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'TODAY — ${months[today.month - 1]} ${today.day}',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF6B7280),
                    letterSpacing: 1.0,
                  ),
                ),
                if (session.canViewPayroll)
                  TextButton.icon(
                    onPressed: _markAllPresent,
                    icon: const Icon(Icons.done_all, size: 16),
                    label: const Text(
                      'Mark All Present',
                      style: TextStyle(fontSize: 12),
                    ),
                  )
                else
                  TextButton(onPressed: _load, child: const Text('Refresh')),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _records.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 64,
                            color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No attendance marked yet today',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              color: const Color(0xFF6B7280),
                            ),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: () => _showMarkDialog(context),
                            icon: const Icon(Icons.how_to_reg),
                            label: const Text('Mark Now'),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                      itemCount: _records.length,
                      itemBuilder: (_, i) {
                        final r = _records[i];
                        final status = r['status'] as String;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark ? AppTheme.darkCard : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isDark
                                  ? AppTheme.darkBorder
                                  : const Color(0xFFE5E7EB),
                            ),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundColor: AppTheme.statusColor(
                                  status,
                                ).withValues(alpha: 0.15),
                                child: Text(
                                  (r['name'] as String)[0],
                                  style: TextStyle(
                                    color: AppTheme.statusColor(status),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      r['name'] as String,
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: isDark
                                            ? Colors.white
                                            : const Color(0xFF111827),
                                      ),
                                    ),
                                    Text(
                                      '${r['designation']} • ${r['department']}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF6B7280),
                                      ),
                                    ),
                                    if (r['check_in'] != null)
                                      Text(
                                        'In: ${r['check_in']}${r['check_out'] != null ? '  • Out: ${r['check_out']}' : ''}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF6B7280),
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
          ),
        ],
      ),
    );
  }
}

// ─── Supervisor Approval Screen ───────────────────────────────────────────────

class SupervisorApprovalScreen extends StatefulWidget {
  const SupervisorApprovalScreen({super.key});
  @override
  State<SupervisorApprovalScreen> createState() =>
      _SupervisorApprovalScreenState();
}

class _SupervisorApprovalScreenState extends State<SupervisorApprovalScreen> {
  List<Map<String, dynamic>> _pendingLeaves = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);
    final pendingSnap = await FirestoreService.leaves
        .where('status', isEqualTo: 'PENDING')
        .orderBy('start_date')
        .get();

    // Enrich with employee names
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

    if (mounted) {
      setState(() {
        _pendingLeaves = leaves;
        _loading = false;
      });
    }
  }

  Future<void> _approve(String leaveId, String employeeName) async {
    await FirestoreService.leaves.doc(leaveId).update({'status': 'APPROVED'});
    await _load();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Leave approved for $employeeName')));
  }

  Future<void> _reject(String leaveId, String employeeName) async {
    await FirestoreService.leaves.doc(leaveId).update({'status': 'REJECTED', 'rejection_reason': 'Rejected by supervisor'});
    await _load();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Leave rejected for $employeeName')));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Supervisor Approval'),
        leading: BackButton(onPressed: () => context.go('/attendance')),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _pendingLeaves.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 64,
                    color: AppTheme.accentGreen.withValues(alpha: 0.4),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No pending approvals',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _pendingLeaves.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (_, i) {
                final l = _pendingLeaves[i];
                final id = l['id'] as String;
                final name = l['name'] as String? ?? '';
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkCard : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.accentYellow.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.pending_outlined,
                            color: AppTheme.accentYellow,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF111827),
                                  ),
                                ),
                                Text(
                                  '${l['designation']} • ${l['leave_type']} leave',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF6B7280),
                                  ),
                                ),
                                Text(
                                  '${l['start_date']} → ${l['end_date']} (${l['duration']} day(s))',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF6B7280),
                                  ),
                                ),
                                if (l['reason'] != null)
                                  Text(
                                    'Reason: ${l['reason']}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF6B7280),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => _approve(id, name),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.statusRunning,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Approve'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _reject(id, name),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.accentRed,
                                side: BorderSide(color: AppTheme.accentRed),
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
