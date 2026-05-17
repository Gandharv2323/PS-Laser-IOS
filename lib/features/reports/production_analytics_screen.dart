/// Production Analytics Screen — Phase 6
///
/// Three fl_chart visualizations built from real-time Order data:
///   1. Orders by Status — Donut PieChart
///   2. Order Volume (last 7 days) — BarChart
///   3. Priority Distribution — Horizontal progress bars
library;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/models/models.dart';
import '../../core/services/order_engine.dart';
import '../../core/theme/ios_design_system.dart';

class ProductionAnalyticsScreen extends StatefulWidget {
  const ProductionAnalyticsScreen({super.key});

  @override
  State<ProductionAnalyticsScreen> createState() =>
      _ProductionAnalyticsScreenState();
}

class _ProductionAnalyticsScreenState
    extends State<ProductionAnalyticsScreen> {
  int _touchedStatusIndex = -1;

  // ── Status chart data ──────────────────────────────────────────────────────
  static const List<_StatusSeries> _statusDefs = [
    _StatusSeries('RECEIVED',      'Received',      PSColors.neonCyan),
    _StatusSeries('SCHEDULED',     'Scheduled',     PSColors.brand),
    _StatusSeries('IN_PROGRESS',   'In Progress',   PSColors.neonOrange),
    _StatusSeries('QUALITY_CHECK', 'Quality Check', PSColors.neonPurple),
    _StatusSeries('COMPLETED',     'Completed',     PSColors.neonGreen),
    _StatusSeries('DELIVERED',     'Delivered',     PSColors.statusOnline),
    _StatusSeries('CANCELLED',     'Cancelled',     PSColors.statusNeutral),
  ];

  Map<String, int> _countByStatus(List<Order> orders) {
    final m = <String, int>{for (final s in _statusDefs) s.key: 0};
    for (final o in orders) {
      if (m.containsKey(o.status)) m[o.status] = m[o.status]! + 1;
    }
    return m;
  }

  Map<String, int> _countByPriority(List<Order> orders) {
    final keys = ['LOW', 'MEDIUM', 'HIGH', 'URGENT'];
    final m = <String, int>{for (final k in keys) k: 0};
    for (final o in orders) {
      if (m.containsKey(o.priority)) m[o.priority] = m[o.priority]! + 1;
    }
    return m;
  }

  // Returns count for each of the last 7 calendar days (oldest first)
  List<_DayCount> _last7Days(List<Order> orders) {
    final now = DateTime.now();
    return List.generate(7, (i) {
      final day = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: 6 - i));
      final count = orders.where((o) {
        return o.createdAt.year == day.year &&
            o.createdAt.month == day.month &&
            o.createdAt.day == day.day;
      }).length;
      return _DayCount(day, count);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? PSColors.darkBg : PSColors.lightBg,
      body: StreamBuilder<List<Order>>(
        stream: OrderEngine.streamAll(),
        builder: (context, snap) {
          final orders = snap.data ?? [];
          final byStatus = _countByStatus(orders);
          final byPriority = _countByPriority(orders);
          final days = _last7Days(orders);

          return CustomScrollView(
            slivers: [
              // ── App Bar ──────────────────────────────────────────
              SliverAppBar(
                pinned: true,
                backgroundColor:
                    isDark ? PSColors.darkBg : PSColors.lightBg,
                surfaceTintColor: Colors.transparent,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      size: 18),
                  onPressed: () => context.go('/reports'),
                ),
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Production Analytics',
                        style: PSText.title()),
                    Text(
                      '${orders.length} total orders',
                      style:
                          PSText.caption(color: PSColors.textDark3),
                    ),
                  ],
                ),
              ),

              // ── Section 1: Status Donut ───────────────────────────
              _sectionHeader('Order Status Breakdown'),
              SliverToBoxAdapter(
                child: _StatusDonut(
                  byStatus: byStatus,
                  statusDefs: _statusDefs,
                  touchedIndex: _touchedStatusIndex,
                  onTouch: (i) =>
                      setState(() => _touchedStatusIndex = i),
                  isDark: isDark,
                ),
              ),

              // ── Section 2: Daily Volume Bar Chart ─────────────────
              _sectionHeader('Order Volume — Last 7 Days'),
              SliverToBoxAdapter(
                child: _DailyVolumeChart(days: days, isDark: isDark),
              ),

              // ── Section 3: Priority Distribution ─────────────────
              _sectionHeader('Priority Distribution'),
              SliverToBoxAdapter(
                child: _PriorityBars(
                  byPriority: byPriority,
                  total: orders.isEmpty ? 1 : orders.length,
                  isDark: isDark,
                ),
              ),

              // ── Section 4: Top Clients ────────────────────────────
              _sectionHeader('Top Clients by Order Count'),
              SliverToBoxAdapter(
                child: _TopClients(orders: orders, isDark: isDark),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          );
        },
      ),
    );
  }

  Widget _sectionHeader(String title) => SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
          child: Text(
            title.toUpperCase(),
            style: PSText.sectionHeader(color: PSColors.textDark3),
          ),
        ),
      );
}

// ═══════════════════════════════════════════════════════════════════════════════
// STATUS DONUT
// ═══════════════════════════════════════════════════════════════════════════════

class _StatusDonut extends StatelessWidget {
  final Map<String, int> byStatus;
  final List<_StatusSeries> statusDefs;
  final int touchedIndex;
  final ValueChanged<int> onTouch;
  final bool isDark;

  const _StatusDonut({
    required this.byStatus,
    required this.statusDefs,
    required this.touchedIndex,
    required this.onTouch,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final sections = <PieChartSectionData>[];
    int idx = 0;
    for (final s in statusDefs) {
      final count = byStatus[s.key] ?? 0;
      if (count == 0) {
        idx++;
        continue;
      }
      final isTouched = idx == touchedIndex;
      sections.add(PieChartSectionData(
        value: count.toDouble(),
        color: s.color,
        radius: isTouched ? 60 : 52,
        title: isTouched ? '$count' : '',
        titleStyle: PSText.body(color: Colors.white)
            .copyWith(fontWeight: FontWeight.w800, fontSize: 13),
        borderSide: isTouched
            ? const BorderSide(color: Colors.white, width: 2)
            : BorderSide.none,
      ));
      idx++;
    }

    // If all zero show a placeholder
    if (sections.isEmpty) {
      sections.add(PieChartSectionData(
        value: 1,
        color: PSColors.darkBorder,
        radius: 52,
        title: '',
      ));
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? PSColors.darkCard : PSColors.lightCard,
        borderRadius: BorderRadius.circular(PSRadius.lg),
        border: Border.all(
          color: isDark ? PSColors.darkBorder : PSColors.lightBorder,
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          // Donut
          SizedBox(
            width: 140,
            height: 140,
            child: PieChart(
              PieChartData(
                pieTouchData: PieTouchData(
                  touchCallback: (event, response) {
                    if (!event.isInterestedForInteractions ||
                        response?.touchedSection == null) {
                      onTouch(-1);
                    } else {
                      HapticFeedback.selectionClick();
                      onTouch(response!
                          .touchedSection!.touchedSectionIndex);
                    }
                  },
                ),
                sections: sections,
                centerSpaceRadius: 40,
                sectionsSpace: 2,
                startDegreeOffset: -90,
              ),
            ),
          ),
          const SizedBox(width: 20),
          // Legend
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: statusDefs.map((s) {
                final count = byStatus[s.key] ?? 0;
                if (count == 0) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                            color: s.color, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          s.label,
                          style: PSText.caption(
                            color: isDark
                                ? PSColors.textDark2
                                : PSColors.textLight2,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '$count',
                        style: PSText.caption(color: s.color)
                            .copyWith(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// DAILY VOLUME BAR CHART
// ═══════════════════════════════════════════════════════════════════════════════

class _DailyVolumeChart extends StatelessWidget {
  final List<_DayCount> days;
  final bool isDark;

  const _DailyVolumeChart({required this.days, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final maxY = days.isEmpty
        ? 1.0
        : days
            .map((d) => d.count.toDouble())
            .reduce((a, b) => a > b ? a : b)
            .clamp(1.0, double.infinity);

    final bars = days.asMap().entries.map((e) {
      final i = e.key;
      final d = e.value;
      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: d.count.toDouble(),
            width: 22,
            borderRadius: const BorderRadius.vertical(
                top: Radius.circular(6)),
            gradient: LinearGradient(
              colors: [PSColors.brand, PSColors.neonCyan],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: maxY + 1,
              color: isDark
                  ? PSColors.darkBorder.withAlpha(60)
                  : PSColors.lightBorder,
            ),
          ),
        ],
      );
    }).toList();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      decoration: BoxDecoration(
        color: isDark ? PSColors.darkCard : PSColors.lightCard,
        borderRadius: BorderRadius.circular(PSRadius.lg),
        border: Border.all(
          color: isDark ? PSColors.darkBorder : PSColors.lightBorder,
          width: 0.5,
        ),
      ),
      child: SizedBox(
        height: 180,
        child: BarChart(
          BarChartData(
            maxY: maxY + 1,
            barGroups: bars,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (_) => FlLine(
                color: isDark
                    ? PSColors.darkBorder
                    : PSColors.lightBorder,
                strokeWidth: 0.5,
              ),
            ),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  interval: maxY > 5 ? (maxY / 5).ceilToDouble() : 1,
                  getTitlesWidget: (val, meta) => Text(
                    val.toInt().toString(),
                    style: PSText.caption(color: PSColors.textDark3)
                        .copyWith(fontSize: 9),
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 22,
                  getTitlesWidget: (val, meta) {
                    final day = days[val.toInt()].day;
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        DateFormat('E').format(day),
                        style:
                            PSText.caption(color: PSColors.textDark3)
                                .copyWith(fontSize: 9),
                      ),
                    );
                  },
                ),
              ),
            ),
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (_) => PSColors.darkElevated,
                getTooltipItem: (group, groupIndex, rod, rodIndex) =>
                    BarTooltipItem(
                  '${rod.toY.toInt()} orders\n${DateFormat('MMM d').format(days[group.x].day)}',
                  PSText.caption(color: Colors.white)
                      .copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// PRIORITY DISTRIBUTION
// ═══════════════════════════════════════════════════════════════════════════════

class _PriorityBars extends StatelessWidget {
  final Map<String, int> byPriority;
  final int total;
  final bool isDark;

  const _PriorityBars({
    required this.byPriority,
    required this.total,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final priorities = [
      ('URGENT', 'Urgent', PSColors.priorityUrgent),
      ('HIGH', 'High', PSColors.priorityHigh),
      ('MEDIUM', 'Medium', PSColors.priorityMedium),
      ('LOW', 'Low', PSColors.priorityLow),
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? PSColors.darkCard : PSColors.lightCard,
        borderRadius: BorderRadius.circular(PSRadius.lg),
        border: Border.all(
          color: isDark ? PSColors.darkBorder : PSColors.lightBorder,
          width: 0.5,
        ),
      ),
      child: Column(
        children: priorities.map((p) {
          final count = byPriority[p.$1] ?? 0;
          final frac = count / total;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                          color: p.$3, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      p.$2,
                      style: PSText.caption(
                        color: isDark
                            ? PSColors.textDark2
                            : PSColors.textLight2,
                      ).copyWith(fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    Text(
                      '$count  (${(frac * 100).round()}%)',
                      style: PSText.caption(color: p.$3)
                          .copyWith(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: frac,
                    minHeight: 6,
                    backgroundColor: isDark
                        ? PSColors.darkBorder
                        : PSColors.lightBorder,
                    valueColor: AlwaysStoppedAnimation(p.$3),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// TOP CLIENTS
// ═══════════════════════════════════════════════════════════════════════════════

class _TopClients extends StatelessWidget {
  final List<Order> orders;
  final bool isDark;

  const _TopClients({required this.orders, required this.isDark});

  @override
  Widget build(BuildContext context) {
    // Aggregate by client
    final m = <String, int>{};
    for (final o in orders) {
      m[o.clientName] = (m[o.clientName] ?? 0) + 1;
    }
    final sorted = m.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.take(5).toList();
    final maxCount = top.isEmpty ? 1 : top.first.value;

    if (top.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? PSColors.darkCard : PSColors.lightCard,
          borderRadius: BorderRadius.circular(PSRadius.lg),
          border: Border.all(
            color: isDark ? PSColors.darkBorder : PSColors.lightBorder,
            width: 0.5,
          ),
        ),
        child: Center(
          child: Text('No order data yet',
              style: PSText.body(color: PSColors.textDark3)),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? PSColors.darkCard : PSColors.lightCard,
        borderRadius: BorderRadius.circular(PSRadius.lg),
        border: Border.all(
          color: isDark ? PSColors.darkBorder : PSColors.lightBorder,
          width: 0.5,
        ),
      ),
      child: Column(
        children: top.asMap().entries.map((e) {
          final rank = e.key + 1;
          final client = e.value.key;
          final count = e.value.value;
          final frac = count / maxCount;
          final rankColor = rank == 1
              ? PSColors.neonYellow
              : rank == 2
                  ? PSColors.textDark2
                  : PSColors.textDark3;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                SizedBox(
                  width: 24,
                  child: Text(
                    '#$rank',
                    style: PSText.caption(color: rankColor)
                        .copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        client,
                        style: PSText.body(
                          color: isDark
                              ? PSColors.textDark1
                              : PSColors.textLight1,
                        ).copyWith(
                            fontWeight: FontWeight.w600, fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: frac,
                          minHeight: 5,
                          backgroundColor: isDark
                              ? PSColors.darkBorder
                              : PSColors.lightBorder,
                          valueColor: AlwaysStoppedAnimation(
                              PSColors.brand),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '$count',
                  style: PSText.body(color: PSColors.brand)
                      .copyWith(fontWeight: FontWeight.w800),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Data models
// ═══════════════════════════════════════════════════════════════════════════════

class _StatusSeries {
  final String key;
  final String label;
  final Color color;
  const _StatusSeries(this.key, this.label, this.color);
}

class _DayCount {
  final DateTime day;
  final int count;
  const _DayCount(this.day, this.count);
}
