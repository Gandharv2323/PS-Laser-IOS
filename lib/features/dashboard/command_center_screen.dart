/// Phase 3 — Dashboard Command Center
/// Real-time iOS-first manufacturing operations hub.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import '../../core/models/models.dart';
import '../../core/services/order_engine.dart';
import '../../core/services/firestore_service.dart';
import '../../core/theme/ios_design_system.dart';
import '../../core/providers/session_provider.dart';
import '../../core/utils/date_utils.dart';

class CommandCenterScreen extends StatefulWidget {
  const CommandCenterScreen({super.key});

  @override
  State<CommandCenterScreen> createState() => _CommandCenterScreenState();
}

class _CommandCenterScreenState extends State<CommandCenterScreen> {
  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionProvider>().session;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? PSColors.darkBg : PSColors.lightBg,
      body: RefreshIndicator(
        color: PSColors.brand,
        backgroundColor: isDark ? PSColors.darkCard : PSColors.lightCard,
        onRefresh: () async => setState(() {}),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            _buildHeader(session, isDark),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 16),
                  _MetricsSection(),
                  const SizedBox(height: 20),
                  _TodayOrdersSection(),
                  const SizedBox(height: 20),
                  _OverdueSection(),
                  const SizedBox(height: 20),
                  _QuickActionsSection(),
                  const SizedBox(height: 20),
                  _OperationsSection(),
                  const SizedBox(height: 20),
                  _AlertsFeedSection(),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  SliverAppBar _buildHeader(UserSession session, bool isDark) {
    final now = DateTime.now();
    final hour = now.hour;
    final greeting = hour < 12 ? 'Good Morning' : hour < 17 ? 'Good Afternoon' : 'Good Evening';
    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final days = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
    final dayName = days[(now.weekday - 1) % 7];
    final dateStr = '$dayName, ${now.day} ${months[now.month - 1]}';

    return SliverAppBar(
      pinned: true,
      expandedHeight: 130,
      backgroundColor: isDark ? PSColors.darkBg : PSColors.lightBg,
      surfaceTintColor: Colors.transparent,
      actions: [
        IconButton(
          icon: const Icon(Icons.psychology_rounded, color: PSColors.neonPurple),
          tooltip: 'AI Assistant',
          onPressed: () => context.go('/ai-chat'),
        ),
        IconButton(
          icon: const Icon(Icons.settings_outlined),
          onPressed: () => context.go('/settings'),
        ),
        const SizedBox(width: 4),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                PSColors.brand.withAlpha(15),
                Colors.transparent,
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 60, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Row(
                  children: [
                    PSLiveIndicator(color: PSColors.neonGreen, label: 'LIVE', size: 7),
                    const SizedBox(width: 8),
                    Text(
                      'PS LASER · Command Center',
                      style: PSText.caption(color: PSColors.textDark3)
                          .copyWith(fontWeight: FontWeight.w700, letterSpacing: 1.0),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '$greeting, ${session.userName.split(' ').first}',
                        style: PSText.title(),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: PSColors.darkCard,
                        borderRadius: BorderRadius.circular(PSRadius.full),
                        border: Border.all(color: PSColors.darkBorder, width: 0.5),
                      ),
                      child: Text(
                        dateStr,
                        style: PSText.caption(color: PSColors.textDark2)
                            .copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Metrics Row ──────────────────────────────────────────────────────────────

class _MetricsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<OrderMetrics>(
      stream: OrderEngine.streamMetrics(),
      builder: (context, snap) {
        final m = snap.data ?? OrderMetrics.empty;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PSSectionHeader(title: 'Operations Pulse'),
            Row(
              children: [
                Expanded(child: _MetricTile(
                  label: 'Active', value: '${m.active}',
                  color: PSColors.neonCyan, icon: Icons.play_circle_outline_rounded,
                  onTap: () => GoRouter.of(context).go('/orders'),
                )),
                const SizedBox(width: 10),
                Expanded(child: _MetricTile(
                  label: 'Overdue', value: '${m.overdue}',
                  color: m.overdue > 0 ? PSColors.neonRed : PSColors.statusNeutral,
                  icon: Icons.warning_amber_rounded,
                )),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _MetricTile(
                  label: 'Due Today', value: '${m.dueToday}',
                  color: PSColors.neonYellow, icon: Icons.today_rounded,
                )),
                const SizedBox(width: 10),
                Expanded(child: _MetricTile(
                  label: 'Done %', value: '${m.completionRate}%',
                  color: PSColors.neonGreen, icon: Icons.check_circle_outline_rounded,
                )),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  final VoidCallback? onTap;

  const _MetricTile({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? PSColors.darkCard : PSColors.lightCard,
          borderRadius: BorderRadius.circular(PSRadius.md),
          border: Border.all(color: color.withAlpha(60), width: 0.5),
        ),
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: color.withAlpha(25),
                borderRadius: BorderRadius.circular(PSRadius.sm),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: PSText.metricSmall(color: color)),
                Text(label, style: PSText.caption(color: PSColors.textDark3)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Today's Orders ───────────────────────────────────────────────────────────

class _TodayOrdersSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Order>>(
      stream: OrderEngine.streamToday(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const _ShimmerSection(label: "TODAY'S ORDERS");
        }
        final orders = snap.data ?? [];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PSSectionHeader(
              title: "Today's Orders",
              action: orders.isEmpty ? null : 'See All',
              onAction: () => GoRouter.of(context).go('/orders'),
            ),
            if (orders.isEmpty)
              _EmptyCard(
                icon: Icons.check_circle_outline_rounded,
                message: 'No orders due today',
                color: PSColors.neonGreen,
              )
            else
              SizedBox(
                height: 140,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: orders.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (_, i) => _TodayOrderCard(order: orders[i]),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _TodayOrderCard extends StatelessWidget {
  final Order order;
  const _TodayOrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final color = PSColors.forPriority(order.priority);
    final statusColor = PSColors.forStatus(order.status);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        GoRouter.of(context).go('/orders/detail/${order.id}');
      },
      child: Container(
        width: 200,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? PSColors.darkCard : PSColors.lightCard,
          borderRadius: BorderRadius.circular(PSRadius.md),
          border: Border.all(color: color.withAlpha(50), width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    order.clientName,
                    style: PSText.bodySmall(weight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              order.description,
              style: PSText.caption(color: PSColors.textDark2),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(25),
                    borderRadius: BorderRadius.circular(PSRadius.full),
                  ),
                  child: Text(
                    order.status.replaceAll('_', ' '),
                    style: PSText.caption(color: statusColor)
                        .copyWith(fontWeight: FontWeight.w700, fontSize: 9),
                  ),
                ),
                const Spacer(),
                if (order.dueDate != null)
                  Text(
                    PSDateUtils.smartDateLabel(order.dueDate!),
                    style: PSText.caption(
                      color: order.isOverdue ? PSColors.neonRed : PSColors.textDark3,
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

// ── Overdue Strip ────────────────────────────────────────────────────────────

class _OverdueSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Order>>(
      stream: OrderEngine.streamOverdue(),
      builder: (context, snap) {
        final orders = snap.data ?? [];
        if (orders.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PSSectionHeader(title: 'Overdue Orders'),
            Container(
              decoration: BoxDecoration(
                color: PSColors.neonRed.withAlpha(12),
                borderRadius: BorderRadius.circular(PSRadius.md),
                border: Border.all(color: PSColors.neonRed.withAlpha(80), width: 0.5),
              ),
              child: Column(
                children: orders.take(3).map((o) => ListTile(
                  dense: true,
                  leading: const Icon(Icons.warning_amber_rounded,
                      color: PSColors.neonRed, size: 18),
                  title: Text(
                    o.clientName,
                    style: PSText.bodySmall(color: PSColors.textDark1,
                        weight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    o.description,
                    style: PSText.caption(color: PSColors.textDark3),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Text(
                    o.dueDate != null ? PSDateUtils.smartDateLabel(o.dueDate!) : '',
                    style: PSText.caption(color: PSColors.neonRed)
                        .copyWith(fontWeight: FontWeight.w700),
                  ),
                  onTap: () => GoRouter.of(context).go('/orders/detail/${o.id}'),
                )).toList(),
              ),
            ),
            if (orders.length > 3)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: GestureDetector(
                  onTap: () => GoRouter.of(context).go('/orders'),
                  child: Text(
                    '+ ${orders.length - 3} more overdue orders',
                    style: PSText.bodySmall(color: PSColors.neonRed)
                        .copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

// ── Quick Actions ────────────────────────────────────────────────────────────

class _QuickActionsSection extends StatelessWidget {
  static const _actions = [
    _QuickAction(
      label: 'New Order',
      icon: Icons.add_circle_rounded,
      color: PSColors.brand,
      route: '/orders/add',
    ),
    _QuickAction(
      label: 'AI Chat',
      icon: Icons.psychology_rounded,
      color: PSColors.neonPurple,
      route: '/ai-chat',
    ),
    _QuickAction(
      label: 'Inventory',
      icon: Icons.inventory_2_rounded,
      color: PSColors.neonCyan,
      route: '/inventory',
    ),
    _QuickAction(
      label: 'Reports',
      icon: Icons.bar_chart_rounded,
      color: PSColors.neonOrange,
      route: '/reports',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PSSectionHeader(title: 'Quick Actions'),
        GridView.count(
          crossAxisCount: 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 0.85,
          children: _actions
              .map((a) => _QuickActionTile(action: a))
              .toList(),
        ),
      ],
    );
  }
}

class _QuickAction {
  final String label;
  final IconData icon;
  final Color color;
  final String route;
  const _QuickAction({
    required this.label,
    required this.icon,
    required this.color,
    required this.route,
  });
}

class _QuickActionTile extends StatelessWidget {
  final _QuickAction action;
  const _QuickActionTile({required this.action});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        GoRouter.of(context).go(action.route);
      },
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? PSColors.darkCard : PSColors.lightCard,
          borderRadius: BorderRadius.circular(PSRadius.md),
          border: Border.all(
            color: action.color.withAlpha(50),
            width: 0.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: action.color.withAlpha(25),
                borderRadius: BorderRadius.circular(PSRadius.sm),
              ),
              child: Icon(action.icon, color: action.color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              action.label,
              style: PSText.caption(
                color: isDark ? PSColors.textDark2 : PSColors.textLight2,
              ).copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Operations Section (Machines + Attendance) ───────────────────────────────

class _OperationsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PSSectionHeader(title: 'Floor Status'),
        Row(
          children: [
            Expanded(child: _MachinesPulse(isDark: isDark)),
            const SizedBox(width: 10),
            Expanded(child: _AttendanceSnapshot(isDark: isDark)),
          ],
        ),
      ],
    );
  }
}

class _MachinesPulse extends StatelessWidget {
  final bool isDark;
  const _MachinesPulse({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirestoreService.machines.snapshots(),
      builder: (context, snap) {
        int running = 0, idle = 0, maintenance = 0;
        for (final doc in snap.data?.docs ?? []) {
          final data = doc.data() as Map<String, dynamic>;
          final status = data['status'] as String? ?? '';
          if (status == 'RUNNING') running++;
          else if (status == 'IDLE') idle++;
          else if (status == 'MAINTENANCE') maintenance++;
        }
        final total = running + idle + maintenance;

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? PSColors.darkCard : PSColors.lightCard,
            borderRadius: BorderRadius.circular(PSRadius.md),
            border: Border.all(
              color: isDark ? PSColors.darkBorder : PSColors.lightBorder,
              width: 0.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.precision_manufacturing_rounded,
                      size: 14, color: PSColors.neonCyan),
                  const SizedBox(width: 6),
                  Text('Machines',
                      style: PSText.caption(color: PSColors.textDark3)
                          .copyWith(fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 10),
              Text('$running / $total',
                  style: PSText.metricSmall(color: PSColors.neonGreen)),
              Text('Running', style: PSText.caption(color: PSColors.textDark3)),
              const SizedBox(height: 8),
              Row(
                children: [
                  _MiniChip(label: '$idle Idle', color: PSColors.neonYellow),
                  const SizedBox(width: 6),
                  if (maintenance > 0)
                    _MiniChip(label: '$maintenance Maint.', color: PSColors.neonOrange),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AttendanceSnapshot extends StatelessWidget {
  final bool isDark;
  const _AttendanceSnapshot({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now().toString().substring(0, 10);
    return StreamBuilder<QuerySnapshot>(
      stream: FirestoreService.attendance
          .where('date', isEqualTo: today)
          .snapshots(),
      builder: (context, snap) {
        int present = 0, absent = 0;
        for (final doc in snap.data?.docs ?? []) {
          final data = doc.data() as Map<String, dynamic>;
          final status = data['status'] as String? ?? '';
          if (status == 'PRESENT') present++;
          else if (status == 'ABSENT') absent++;
        }
        final total = present + absent;

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? PSColors.darkCard : PSColors.lightCard,
            borderRadius: BorderRadius.circular(PSRadius.md),
            border: Border.all(
              color: isDark ? PSColors.darkBorder : PSColors.lightBorder,
              width: 0.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.people_alt_rounded,
                      size: 14, color: PSColors.neonGreen),
                  const SizedBox(width: 6),
                  Text('Attendance',
                      style: PSText.caption(color: PSColors.textDark3)
                          .copyWith(fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 10),
              Text('$present / $total',
                  style: PSText.metricSmall(color: PSColors.neonGreen)),
              Text('Present', style: PSText.caption(color: PSColors.textDark3)),
              const SizedBox(height: 8),
              if (absent > 0)
                _MiniChip(label: '$absent Absent', color: PSColors.neonRed)
              else
                _MiniChip(label: 'Full house', color: PSColors.neonGreen),
            ],
          ),
        );
      },
    );
  }
}

class _MiniChip extends StatelessWidget {
  final String label;
  final Color color;
  const _MiniChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(PSRadius.full),
      ),
      child: Text(label,
          style: PSText.caption(color: color).copyWith(fontWeight: FontWeight.w600)),
    );
  }
}

// ── Alerts Feed ──────────────────────────────────────────────────────────────

class _AlertsFeedSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return StreamBuilder<QuerySnapshot>(
      stream: FirestoreService.notifications
          .where('is_read', isEqualTo: false)
          .orderBy('created_at', descending: true)
          .limit(3)
          .snapshots(),
      builder: (context, snap) {
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PSSectionHeader(
              title: 'Recent Alerts',
              action: 'See All',
              onAction: () => GoRouter.of(context).go('/alerts'),
            ),
            Container(
              decoration: BoxDecoration(
                color: isDark ? PSColors.darkCard : PSColors.lightCard,
                borderRadius: BorderRadius.circular(PSRadius.md),
                border: Border.all(
                  color: isDark ? PSColors.darkBorder : PSColors.lightBorder,
                  width: 0.5,
                ),
              ),
              child: Column(
                children: docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final title = data['title'] as String? ?? '';
                  final body = data['body'] as String? ?? '';
                  final priority = data['priority'] as String? ?? 'MEDIUM';
                  final color = PSColors.forPriority(priority);
                  return ListTile(
                    dense: true,
                    leading: Container(
                      width: 8, height: 8,
                      margin: const EdgeInsets.only(top: 4),
                      decoration: BoxDecoration(
                        color: color, shape: BoxShape.circle,
                      ),
                    ),
                    title: Text(title,
                        style: PSText.bodySmall(weight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    subtitle: Text(body,
                        style: PSText.caption(color: PSColors.textDark3),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    onTap: () => GoRouter.of(context).go('/alerts'),
                  );
                }).toList(),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ── Shared Helpers ───────────────────────────────────────────────────────────

class _ShimmerSection extends StatelessWidget {
  final String label;
  const _ShimmerSection({required this.label});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: PSText.sectionHeader()),
        const SizedBox(height: 10),
        Container(
          height: 80,
          decoration: BoxDecoration(
            color: isDark ? PSColors.darkCard : PSColors.lightCard,
            borderRadius: BorderRadius.circular(PSRadius.md),
          ),
        ),
      ],
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final IconData icon;
  final String message;
  final Color color;
  const _EmptyCard({required this.icon, required this.message, required this.color});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? PSColors.darkCard : PSColors.lightCard,
        borderRadius: BorderRadius.circular(PSRadius.md),
        border: Border.all(
          color: isDark ? PSColors.darkBorder : PSColors.lightBorder,
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Text(message, style: PSText.body(color: PSColors.textDark3)),
        ],
      ),
    );
  }
}
