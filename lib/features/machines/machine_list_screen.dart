import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/services/firestore_service.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/stat_card.dart';

class MachineListScreen extends StatefulWidget {
  const MachineListScreen({super.key});
  @override
  State<MachineListScreen> createState() => _MachineListScreenState();
}

class _MachineListScreenState extends State<MachineListScreen> {
  List<Map<String, dynamic>> _machines = [];
  String _statusFilter = 'ALL';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);
    final snap = await FirestoreService.machines.orderBy('name').get();
    if (!mounted) return;
    setState(() {
      _machines = snap.docs.map(FirestoreService.docToMap).toList();
      _loading = false;
    });
  }

  List<Map<String, dynamic>> get _filtered => _statusFilter == 'ALL'
      ? _machines
      : _machines.where((m) => m['status'] == _statusFilter).toList();

  @override
  Widget build(BuildContext context) {
    final running = _machines.where((m) => m['status'] == 'RUNNING').length;
    final maintenance = _machines
        .where((m) => m['status'] == 'MAINTENANCE')
        .length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Machines'),
        actions: [
          IconButton(icon: const Icon(Icons.filter_list), onPressed: () {}),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: StatCard(
                          title: 'Running',
                          value: '$running',
                          icon: Icons.play_circle_outline,
                          color: AppTheme.statusRunning,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: StatCard(
                          title: 'Maintenance',
                          value: '$maintenance',
                          icon: Icons.build_outlined,
                          color: AppTheme.statusMaintenance,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: StatCard(
                          title: 'Idle',
                          value: '${_machines.length - running - maintenance}',
                          icon: Icons.pause_circle_outline,
                          color: AppTheme.statusIdle,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 44,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    children: ['ALL', 'RUNNING', 'IDLE', 'MAINTENANCE']
                        .map(
                          (s) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(s),
                              selected: _statusFilter == s,
                              onSelected: (_) =>
                                  setState(() => _statusFilter = s),
                              selectedColor: AppTheme.primaryBlue.withValues(
                                alpha: 0.15,
                              ),
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
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filtered.length,
                      itemBuilder: (_, i) =>
                          _MachineCard(machine: _filtered[i]),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _MachineCard extends StatelessWidget {
  final Map<String, dynamic> machine;
  const _MachineCard({required this.machine});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final status = machine['status'] as String;
    final isMaintenanceDue =
        machine['next_service_due'] != null &&
        DateTime.tryParse(
              machine['next_service_due'],
            )?.isBefore(DateTime.now()) ==
            true;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () => context.go('/machines/detail/${machine['id']}'),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isMaintenanceDue
                  ? AppTheme.accentOrange.withValues(alpha: 0.5)
                  : (isDark ? AppTheme.darkBorder : const Color(0xFFE5E7EB)),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.statusColor(status).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.memory_outlined,
                  color: AppTheme.statusColor(status),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            machine['name'] as String,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF111827),
                            ),
                          ),
                        ),
                        StatusBadge(status: status),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${machine['code']} • ${machine['location']}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    if (isMaintenanceDue) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.warning_amber_rounded,
                            size: 12,
                            color: AppTheme.accentOrange,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Maintenance Overdue',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: AppTheme.accentOrange,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      'Runtime today: ${machine['runtime_today']}h',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Color(0xFF6B7280)),
            ],
          ),
        ),
      ),
    );
  }
}
