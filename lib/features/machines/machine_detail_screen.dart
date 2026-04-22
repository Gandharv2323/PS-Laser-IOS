import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/services/firestore_service.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/stat_card.dart';

class MachineDetailScreen extends StatefulWidget {
  final String machineId;
  const MachineDetailScreen({super.key, required this.machineId});
  @override
  State<MachineDetailScreen> createState() => _MachineDetailScreenState();
}

class _MachineDetailScreenState extends State<MachineDetailScreen> {
  Map<String, dynamic>? _machine;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    final doc = await FirestoreService.machines.doc(widget.machineId).get();
    if (doc.exists && mounted) setState(() => _machine = FirestoreService.docToMap(doc));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (_machine == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    final status = _machine!['status'] as String;
    final statusColor = AppTheme.statusColor(status);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _machine!['name'] as String,
          style: const TextStyle(fontSize: 16),
        ),
        leading: BackButton(onPressed: () => context.go('/machines')),
        actions: [
          TextButton.icon(
            onPressed: () =>
                context.go('/machines/analytics/${_machine!['id']}'),
            icon: const Icon(Icons.analytics_outlined, size: 18),
            label: const Text('Analytics'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: statusColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.memory_outlined,
                      color: statusColor,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _machine!['name'] as String,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF111827),
                          ),
                        ),
                        Text(
                          _machine!['code'] as String,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                        Text(
                          _machine!['location'] as String? ?? '',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                  StatusBadge(status: status),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    title: 'Runtime Today',
                    value: '${_machine!['runtime_today']}h',
                    icon: Icons.schedule_outlined,
                    color: AppTheme.primaryBlue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatCard(
                    title: 'Runtime Month',
                    value: '${_machine!['runtime_month']}h',
                    icon: Icons.calendar_month_outlined,
                    color: AppTheme.accentOrange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _InfoSection('Maintenance', [
              {
                'label': 'Last Serviced',
                'value': _machine!['last_serviced_date'] ?? 'N/A',
              },
              {
                'label': 'Next Service Due',
                'value': _machine!['next_service_due'] ?? 'N/A',
              },
              {
                'label': 'Capacity',
                'value': '${_machine!['capacity']} units/hr',
              },
            ], isDark: isDark),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.build_outlined, size: 16),
                    label: const Text('Log Maintenance'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => context.go('/work-orders/create'),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Create Work Order'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  final String title;
  final List<Map<String, String>> rows;
  final bool isDark;
  const _InfoSection(this.title, this.rows, {required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
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
          Text(
            title.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF6B7280),
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 12),
          ...rows.map(
            (r) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    r['label']!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  Text(
                    r['value']!,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF111827),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MachineAnalyticsScreen extends StatefulWidget {
  final String machineId;
  const MachineAnalyticsScreen({super.key, required this.machineId});
  @override
  State<MachineAnalyticsScreen> createState() => _MachineAnalyticsScreenState();
}

class _MachineAnalyticsScreenState extends State<MachineAnalyticsScreen> {
  Map<String, dynamic>? _machine;
  @override
  void initState() {
    super.initState();
    FirestoreService.machines.doc(widget.machineId).get().then((doc) {
      if (doc.exists && mounted) setState(() => _machine = FirestoreService.docToMap(doc));
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (_machine == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text('${_machine!['name']} — Analytics'),
        leading: BackButton(
          onPressed: () => context.go('/machines/detail/${widget.machineId}'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'WEEKLY RUNTIME (HRS)',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF6B7280),
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              height: 200,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? AppTheme.darkBorder : const Color(0xFFE5E7EB),
                ),
              ),
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 10,
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 2,
                    getDrawingHorizontalLine: (v) => FlLine(
                      color: isDark
                          ? AppTheme.darkBorder
                          : const Color(0xFFE5E7EB),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (v, _) => Text(
                          ['M', 'T', 'W', 'T', 'F', 'S', 'S'][v.toInt()],
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 24,
                        getTitlesWidget: (v, _) => Text(
                          '${v.toInt()}h',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  barGroups: [7, 8, 9, 6, 8, 3, 3.5]
                      .asMap()
                      .entries
                      .map(
                        (e) => BarChartGroupData(
                          x: e.key,
                          barRods: [
                            BarChartRodData(
                              toY: e.value.toDouble(),
                              color: AppTheme.primaryBlue,
                              width: 20,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(6),
                              ),
                            ),
                          ],
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    title: 'Total Runtime',
                    value: '${_machine!['runtime_month']}h',
                    icon: Icons.timer_outlined,
                    color: AppTheme.primaryBlue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatCard(
                    title: 'Efficiency',
                    value: '78%',
                    icon: Icons.speed_outlined,
                    color: AppTheme.statusRunning,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
