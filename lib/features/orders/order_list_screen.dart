/// Order List Screen — PS LASER Order Control System
/// Premium iOS-first realtime order management interface.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../core/models/models.dart';
import '../../core/services/order_engine.dart';
import '../../core/theme/ios_design_system.dart';
import '../../core/utils/date_utils.dart';

class OrderListScreen extends StatefulWidget {
  const OrderListScreen({super.key});

  @override
  State<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<OrderListScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _searchController = TextEditingController();
  bool _isSearching = false;
  String _searchQuery = '';

  static const _filters = [
    ('ALL', 'All'),
    ('RECEIVED', 'Received'),
    ('SCHEDULED', 'Scheduled'),
    ('IN_PROGRESS', 'In Progress'),
    ('QUALITY_CHECK', 'QC'),
    ('COMPLETED', 'Completed'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _filters.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // ── Stream selection based on active tab ──────────────────────────────────

  Stream<List<Order>> _buildStream(int tabIndex) {
    final filter = _filters[tabIndex].$1;
    if (filter == 'ALL') return OrderEngine.streamActive();
    return OrderEngine.streamByStatus(filter).cast<List<Order>>();
  }

  List<Order> _applySearch(List<Order> orders) {
    if (_searchQuery.isEmpty) return orders;
    final q = _searchQuery.toLowerCase();
    return orders.where((o) {
      return o.clientName.toLowerCase().contains(q) ||
          o.description.toLowerCase().contains(q) ||
          o.material.toLowerCase().contains(q) ||
          o.id.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? PSColors.darkBg : PSColors.lightBg,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [_buildSliverHeader(isDark)],
        body: _buildBody(isDark),
      ),
    );
  }

  // ── Sliver Header ─────────────────────────────────────────────────────────

  Widget _buildSliverHeader(bool isDark) {
    return SliverAppBar(
      pinned: true,
      floating: false,
      expandedHeight: 140,
      backgroundColor: isDark ? PSColors.darkBg : PSColors.lightBg,
      surfaceTintColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 20, bottom: 56),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Orders', style: PSText.headline()),
            Text(
              'Order Control System',
              style: PSText.caption(color: PSColors.textDark3),
            ),
          ],
        ),
      ),
      actions: [
        // Search toggle
        IconButton(
          icon: Icon(_isSearching ? Icons.close_rounded : Icons.search_rounded),
          onPressed: () {
            HapticFeedback.selectionClick();
            setState(() {
              _isSearching = !_isSearching;
              if (!_isSearching) {
                _searchQuery = '';
                _searchController.clear();
              }
            });
          },
        ),
        // Voice order
        IconButton(
          icon: const Icon(Icons.mic_none_rounded),
          tooltip: 'Voice Order',
          onPressed: () => context.go('/orders/voice'),
        ),
        const SizedBox(width: 4),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(48),
        child: Column(
          children: [
            if (_isSearching) _buildSearchBar(isDark),
            _buildFilterTabs(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: TextField(
        controller: _searchController,
        autofocus: true,
        style: PSText.body(color: isDark ? PSColors.textDark1 : PSColors.textLight1),
        decoration: InputDecoration(
          hintText: 'Search client, description, material…',
          prefixIcon: Icon(Icons.search_rounded,
              size: 18,
              color: isDark ? PSColors.textDark3 : PSColors.textLight3),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          filled: true,
          fillColor: isDark ? PSColors.darkCard : PSColors.lightCard,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(PSRadius.sm),
            borderSide: BorderSide(
              color: isDark ? PSColors.darkBorder : PSColors.lightBorder,
              width: 0.5,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(PSRadius.sm),
            borderSide: BorderSide(
              color: isDark ? PSColors.darkBorder : PSColors.lightBorder,
              width: 0.5,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(PSRadius.sm),
            borderSide: const BorderSide(color: PSColors.brand, width: 1),
          ),
        ),
        onChanged: (v) => setState(() => _searchQuery = v.trim()),
      ),
    );
  }

  Widget _buildFilterTabs(bool isDark) {
    return TabBar(
      controller: _tabController,
      isScrollable: true,
      tabAlignment: TabAlignment.start,
      indicatorColor: PSColors.brand,
      indicatorWeight: 2,
      labelColor: PSColors.brand,
      unselectedLabelColor: isDark ? PSColors.textDark3 : PSColors.textLight3,
      labelStyle: PSText.label().copyWith(fontSize: 12),
      unselectedLabelStyle: PSText.label().copyWith(fontSize: 12),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      tabs: _filters.map((f) => Tab(text: f.$2)).toList(),
      onTap: (_) => HapticFeedback.selectionClick(),
    );
  }

  // ── Body ──────────────────────────────────────────────────────────────────

  Widget _buildBody(bool isDark) {
    return TabBarView(
      controller: _tabController,
      children: List.generate(_filters.length, (i) {
        return StreamBuilder<List<Order>>(
          stream: _buildStream(i),
          builder: (ctx, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return _buildShimmer(isDark);
            }
            if (snap.hasError) {
              return _buildError(snap.error.toString());
            }

            final orders = _applySearch(snap.data ?? []);

            if (orders.isEmpty) return _buildEmpty(i);

            return RefreshIndicator(
              color: PSColors.brand,
              backgroundColor: isDark ? PSColors.darkCard : PSColors.lightCard,
              onRefresh: () async {
                // Firestore stream auto-refreshes — show delay for UX
                await Future.delayed(const Duration(milliseconds: 500));
              },
              child: CustomScrollView(
                slivers: [
                  // Metrics row at top of list
                  SliverToBoxAdapter(child: _buildMetricsRow(isDark)),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    sliver: SliverList.separated(
                      itemCount: orders.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, idx) =>
                          _OrderCard(order: orders[idx], isDark: isDark),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      }),
    );
  }

  // ── Metrics row ───────────────────────────────────────────────────────────

  Widget _buildMetricsRow(bool isDark) {
    return StreamBuilder<OrderMetrics>(
      stream: OrderEngine.streamMetrics(),
      builder: (_, snap) {
        final m = snap.data ?? OrderMetrics.empty;
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Row(
            children: [
              Expanded(child: _MiniMetric(label: 'Active', value: '${m.active}', color: PSColors.brand)),
              const SizedBox(width: 8),
              Expanded(child: _MiniMetric(label: 'Today', value: '${m.dueToday}', color: PSColors.neonCyan)),
              const SizedBox(width: 8),
              Expanded(child: _MiniMetric(label: 'Overdue', value: '${m.overdue}', color: PSColors.neonRed)),
              const SizedBox(width: 8),
              Expanded(child: _MiniMetric(label: 'Done %', value: '${m.completionRate}%', color: PSColors.neonGreen)),
            ],
          ),
        );
      },
    );
  }

  // ── Loading / Error / Empty ───────────────────────────────────────────────

  Widget _buildShimmer(bool isDark) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, __) => _ShimmerCard(isDark: isDark),
    );
  }

  Widget _buildError(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_off_rounded, color: PSColors.neonRed, size: 48),
          const SizedBox(height: 16),
          Text('Failed to load orders', style: PSText.title()),
          const SizedBox(height: 4),
          Text(error, style: PSText.caption(color: PSColors.textDark3)),
        ],
      ),
    );
  }

  Widget _buildEmpty(int tabIndex) {
    final filter = _filters[tabIndex].$2;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: PSColors.brand.withAlpha(30),
              borderRadius: BorderRadius.circular(PSRadius.lg),
            ),
            child: const Icon(Icons.receipt_long_rounded,
                color: PSColors.brand, size: 34),
          ),
          const SizedBox(height: 20),
          Text(
            _searchQuery.isNotEmpty
                ? 'No results for "$_searchQuery"'
                : 'No $filter orders',
            style: PSText.title(),
          ),
          const SizedBox(height: 6),
          Text(
            _searchQuery.isEmpty && tabIndex == 0
                ? 'Tap + to create your first order'
                : 'Try a different filter',
            style: PSText.body(color: PSColors.textDark2),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Order Card Widget
// ══════════════════════════════════════════════════════════════════════════════

class _OrderCard extends StatelessWidget {
  final Order order;
  final bool isDark;
  const _OrderCard({required this.order, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final priorityColor = PSColors.forPriority(order.priority);
    final statusColor   = PSColors.forStatus(order.status);
    final isOverdue     = order.isOverdue;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        context.go('/orders/detail/${order.id}');
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isDark ? PSColors.darkCard : PSColors.lightCard,
          borderRadius: BorderRadius.circular(PSRadius.md),
          border: Border.all(
            color: isOverdue
                ? PSColors.neonRed.withAlpha(100)
                : isDark ? PSColors.darkBorder : PSColors.lightBorder,
            width: isOverdue ? 1 : 0.5,
          ),
          boxShadow: isOverdue
              ? [BoxShadow(color: PSColors.neonRed.withAlpha(30), blurRadius: 8)]
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header row ─────────────────────────────────────────
              Row(
                children: [
                  // Priority stripe
                  Container(
                    width: 3,
                    height: 40,
                    decoration: BoxDecoration(
                      color: priorityColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Client + description
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                order.clientName,
                                style: PSText.bodySmall(
                                  color: isDark ? PSColors.textDark1 : PSColors.textLight1,
                                  weight: FontWeight.w700,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            PSStatusBadge(status: order.status, compact: true),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          order.description,
                          style: PSText.caption(
                            color: isDark ? PSColors.textDark2 : PSColors.textLight2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // ── Info chips ─────────────────────────────────────────
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  _Chip(
                    icon: Icons.category_outlined,
                    label: order.material,
                    isDark: isDark,
                  ),
                  _Chip(
                    icon: Icons.straighten_rounded,
                    label: '${order.quantity} ${order.unit}',
                    isDark: isDark,
                  ),
                  _Chip(
                    icon: Icons.timer_outlined,
                    label: '${order.estimatedDurationMins}m',
                    isDark: isDark,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // ── Footer row ─────────────────────────────────────────
              Row(
                children: [
                  PSPriorityBadge(priority: order.priority, compact: true),
                  const Spacer(),
                  if (order.dueDate != null) ...[
                    Icon(
                      isOverdue ? Icons.warning_amber_rounded : Icons.schedule_rounded,
                      size: 13,
                      color: isOverdue ? PSColors.neonRed : statusColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isOverdue
                          ? PSDateUtils.timeUntil(order.dueDate)
                          : PSDateUtils.timeUntil(order.dueDate),
                      style: PSText.caption(
                        color: isOverdue ? PSColors.neonRed : statusColor,
                      ).copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      PSDateUtils.smartDateLabel(order.dueDate!),
                      style: PSText.caption(
                        color: isDark ? PSColors.textDark3 : PSColors.textLight3,
                      ),
                    ),
                  ],
                  const SizedBox(width: 6),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 11,
                    color: isDark ? PSColors.textDark3 : PSColors.textLight3,
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

// ── Small info chip ───────────────────────────────────────────────────────────

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  const _Chip({required this.icon, required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: isDark ? PSColors.darkElevated : const Color(0xFFF2F2F7),
        borderRadius: BorderRadius.circular(PSRadius.xs),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10,
              color: isDark ? PSColors.textDark3 : PSColors.textLight3),
          const SizedBox(width: 4),
          Text(
            label,
            style: PSText.caption(
              color: isDark ? PSColors.textDark2 : PSColors.textLight2,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Mini metric ───────────────────────────────────────────────────────────────

class _MiniMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _MiniMetric({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(PSRadius.sm),
        border: Border.all(color: color.withAlpha(50), width: 0.5),
      ),
      child: Column(
        children: [
          Text(value, style: PSText.metricSmall(color: color).copyWith(fontSize: 20)),
          const SizedBox(height: 2),
          Text(label,
              style: PSText.caption(
                color: isDark ? PSColors.textDark3 : PSColors.textLight3,
              )),
        ],
      ),
    );
  }
}

// ── Shimmer loading card ──────────────────────────────────────────────────────

class _ShimmerCard extends StatefulWidget {
  final bool isDark;
  const _ShimmerCard({required this.isDark});
  @override
  State<_ShimmerCard> createState() => _ShimmerCardState();
}

class _ShimmerCardState extends State<_ShimmerCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _anim = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final base = widget.isDark ? PSColors.darkCard : PSColors.lightCard;
    final highlight = widget.isDark ? PSColors.darkElevated : const Color(0xFFE5E5EA);

    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        return Container(
          height: 110,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(_anim.value - 1, 0),
              end: Alignment(_anim.value + 1, 0),
              colors: [base, highlight, base],
            ),
            borderRadius: BorderRadius.circular(PSRadius.md),
          ),
        );
      },
    );
  }
}

// (end of file)
