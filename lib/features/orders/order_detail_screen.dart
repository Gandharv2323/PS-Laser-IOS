/// Order Detail Screen — Premium iOS-first order management with status timeline.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/models/models.dart';
import '../../core/services/order_engine.dart';
import '../../core/theme/ios_design_system.dart';
import '../../core/utils/date_utils.dart';
import '../../core/providers/session_provider.dart';


class OrderDetailScreen extends StatelessWidget {
  final String orderId;
  const OrderDetailScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Order?>(
      stream: OrderEngine.streamAll().map((orders) {
        try {
          return orders.firstWhere((o) => o.id == orderId);
        } catch (_) {
          return null;
        }
      }),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const _LoadingScreen();
        }
        final order = snap.data;
        if (order == null) return const _NotFoundScreen();
        return _OrderDetailView(order: order);
      },
    );
  }

}

// ══════════════════════════════════════════════════════════════════════════════
// Main Detail View
// ══════════════════════════════════════════════════════════════════════════════

class _OrderDetailView extends StatefulWidget {
  final Order order;
  const _OrderDetailView({required this.order});

  @override
  State<_OrderDetailView> createState() => _OrderDetailViewState();
}

class _OrderDetailViewState extends State<_OrderDetailView> {
  bool _isUpdating = false;

  static const _statusFlow = [
    ('RECEIVED',      Icons.inbox_rounded,           'Received'),
    ('SCHEDULED',     Icons.calendar_today_rounded,  'Scheduled'),
    ('IN_PROGRESS',   Icons.engineering_rounded,     'In Progress'),
    ('QUALITY_CHECK', Icons.fact_check_rounded,      'QC'),
    ('COMPLETED',     Icons.check_circle_rounded,    'Completed'),
    ('DELIVERED',     Icons.local_shipping_rounded,  'Delivered'),
  ];

  // ── Status Transition ──────────────────────────────────────────────────────

  Future<void> _advanceStatus() async {
    final order = widget.order;
    final currentIdx = _statusFlow.indexWhere((s) => s.$1 == order.status);
    if (currentIdx < 0 || currentIdx >= _statusFlow.length - 1) return;

    final nextStatus = _statusFlow[currentIdx + 1].$1;
    await _updateStatus(nextStatus);
  }

  Future<void> _updateStatus(String newStatus) async {
    setState(() => _isUpdating = true);
    HapticFeedback.mediumImpact();

    try {
      final session = context.read<SessionProvider>().session;
      await OrderEngine.updateStatus(
        orderId: widget.order.id,
        newStatus: newStatus,
        changedByEmployeeId: session.userId,
        notes: 'Status updated from detail screen',
      );
      if (mounted) {
        HapticFeedback.heavyImpact();
        _showSnack('Status → $newStatus');
      }
    } catch (e) {
      if (mounted) _showSnack('Failed: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  Future<void> _cancelOrder() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor:
            Theme.of(context).brightness == Brightness.dark ? PSColors.darkCard : PSColors.lightCard,
        title: Text('Cancel Order?', style: PSText.title()),
        content: Text(
          'This will mark the order as CANCELLED. This action cannot be undone.',
          style: PSText.body(color: PSColors.textDark2),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Keep', style: PSText.body(color: PSColors.textDark3)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Cancel Order',
                style: PSText.body(color: PSColors.neonRed)
                    .copyWith(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _updateStatus('CANCELLED');
      if (mounted) context.pop();
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? PSColors.neonRed : PSColors.neonGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(PSRadius.sm)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final order = widget.order;
    final priorityColor = PSColors.forPriority(order.priority);
    final isActive = order.isActive;

    final currentIdx = _statusFlow.indexWhere((s) => s.$1 == order.status);
    final hasNext = isActive && currentIdx >= 0 && currentIdx < _statusFlow.length - 1;
    final nextStatus = hasNext ? _statusFlow[currentIdx + 1] : null;

    return Scaffold(
      backgroundColor: isDark ? PSColors.darkBg : PSColors.lightBg,
      body: CustomScrollView(
        slivers: [
          // ── Hero header ──────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            expandedHeight: 200,
            backgroundColor: isDark ? PSColors.darkBg : PSColors.lightBg,
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              onPressed: () => context.pop(),
            ),
            actions: [
              if (isActive)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded),
                  color: isDark ? PSColors.darkCard : PSColors.lightCard,
                  onSelected: (v) {
                    if (v == 'cancel') _cancelOrder();
                    if (v == 'edit') {
                      context.go('/orders/add?clientId=${order.clientId}&clientName=${order.clientName}');
                    }
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(children: [
                        const Icon(Icons.edit_rounded, size: 16),
                        const SizedBox(width: 8),
                        Text('Edit Order', style: PSText.bodySmall()),
                      ]),
                    ),
                    PopupMenuItem(
                      value: 'cancel',
                      child: Row(children: [
                        const Icon(Icons.cancel_rounded, size: 16, color: PSColors.neonRed),
                        const SizedBox(width: 8),
                        Text('Cancel Order',
                            style: PSText.bodySmall(color: PSColors.neonRed)),
                      ]),
                    ),
                  ],
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
                      priorityColor.withAlpha(30),
                      isDark ? PSColors.darkBg : PSColors.lightBg,
                    ],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 80, 20, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Row(
                        children: [
                          PSPriorityBadge(priority: order.priority),
                          const SizedBox(width: 8),
                          PSStatusBadge(status: order.status),
                          if (order.isOverdue) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: PSColors.neonRed.withAlpha(30),
                                borderRadius: BorderRadius.circular(PSRadius.xs),
                                border: Border.all(
                                    color: PSColors.neonRed.withAlpha(100)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.warning_amber_rounded,
                                      size: 11, color: PSColors.neonRed),
                                  const SizedBox(width: 3),
                                  Text('OVERDUE',
                                      style: PSText.caption(color: PSColors.neonRed)
                                          .copyWith(fontWeight: FontWeight.w800,
                                              fontSize: 10)),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        order.clientName,
                        style: PSText.headline(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        order.description,
                        style: PSText.body(color: PSColors.textDark2),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Content ──────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Next action button
                if (hasNext && nextStatus != null) ...[
                  const SizedBox(height: 16),
                  _buildNextActionButton(nextStatus, isDark),
                ],
                const SizedBox(height: 16),

                // Status Timeline
                _SectionCard(
                  title: 'Progress Timeline',
                  isDark: isDark,
                  child: _StatusTimeline(
                    currentStatus: order.status,
                    statusFlow: _statusFlow,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(height: 12),

                // Order Details
                _SectionCard(
                  title: 'Order Details',
                  isDark: isDark,
                  child: Column(
                    children: [
                      _InfoRow(label: 'Order ID',   value: '#${order.id.substring(0, 8).toUpperCase()}', isDark: isDark),
                      _InfoRow(label: 'Material',   value: order.material, isDark: isDark),
                      _InfoRow(label: 'Quantity',   value: '${order.quantity} ${order.unit}', isDark: isDark),
                      _InfoRow(label: 'Duration',   value: _formatMins(order.estimatedDurationMins), isDark: isDark),
                      if (order.dueDate != null)
                        _InfoRow(
                          label: 'Due Date',
                          value: PSDateUtils.smartDateLabel(order.dueDate!),
                          valueColor: order.isOverdue ? PSColors.neonRed : null,
                          isDark: isDark,
                        ),
                      _InfoRow(label: 'Created',
                          value: PSDateUtils.smartDateLabel(order.createdAt),
                          isDark: isDark,
                          isLast: true),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Notes
                if (order.notes?.isNotEmpty == true)
                  _SectionCard(
                    title: 'Notes',
                    isDark: isDark,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        order.notes!,
                        style: PSText.body(
                            color: isDark ? PSColors.textDark2 : PSColors.textLight2),
                      ),
                    ),
                  ),

                if (order.notes?.isNotEmpty == true) const SizedBox(height: 12),

                // Status History
                _SectionCard(
                  title: 'Status History',
                  isDark: isDark,
                  child: _HistoryLog(orderId: order.id, isDark: isDark),
                ),
              ]),
            ),
          ),
        ],
      ),

      // ── FAB: Advance status ──────────────────────────────────────
      floatingActionButton: hasNext && nextStatus != null
          ? FloatingActionButton.extended(
              onPressed: _isUpdating ? null : _advanceStatus,
              backgroundColor: PSColors.brand,
              foregroundColor: Colors.white,
              icon: _isUpdating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Icon(nextStatus.$2, size: 20),
              label: Text(
                'Mark as ${nextStatus.$3}',
                style: PSText.body(color: Colors.white)
                    .copyWith(fontWeight: FontWeight.w700),
              ),
            )
          : null,
    );
  }

  Widget _buildNextActionButton(
    (String, IconData, String) nextStatus,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: PSColors.brandGradient,
        borderRadius: BorderRadius.circular(PSRadius.md),
      ),
      child: Row(
        children: [
          Icon(nextStatus.$2, color: Colors.white, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Next Step',
                    style: PSText.caption(color: Colors.white70)),
                Text(
                  'Mark as ${nextStatus.$3}',
                  style: PSText.body(color: Colors.white)
                      .copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _isUpdating ? null : _advanceStatus,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(40),
                borderRadius: BorderRadius.circular(PSRadius.sm),
              ),
              child: Text(
                'Advance →',
                style: PSText.bodySmall(color: Colors.white)
                    .copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatMins(int mins) {
    if (mins < 60) return '${mins}m';
    final h = mins ~/ 60;
    final m = mins % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Status Timeline Widget
// ══════════════════════════════════════════════════════════════════════════════

class _StatusTimeline extends StatelessWidget {
  final String currentStatus;
  final List<(String, IconData, String)> statusFlow;
  final bool isDark;
  const _StatusTimeline({
    required this.currentStatus,
    required this.statusFlow,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final currentIdx = statusFlow.indexWhere((s) => s.$1 == currentStatus);
    final isCancelled = currentStatus == 'CANCELLED';

    return Column(
      children: List.generate(statusFlow.length, (i) {
        final step = statusFlow[i];
        final isDone = isCancelled ? false : i < currentIdx;
        final isActive = !isCancelled && i == currentIdx;
        final isFuture = isCancelled ? true : i > currentIdx;

        final color = isCancelled
            ? PSColors.textDark3
            : isDone
                ? PSColors.neonGreen
                : isActive
                    ? PSColors.brand
                    : PSColors.textDark3;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Icon column ──────────────────────────────────
            SizedBox(
              width: 32,
              child: Column(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: isActive
                          ? PSColors.brand.withAlpha(30)
                          : isDone
                              ? PSColors.neonGreen.withAlpha(20)
                              : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isFuture && !isCancelled
                            ? (isDark ? PSColors.darkBorder : PSColors.lightBorder)
                            : color,
                        width: isActive ? 2 : 1,
                      ),
                    ),
                    child: Icon(
                      isDone
                          ? Icons.check_rounded
                          : isCancelled && i == currentIdx
                              ? Icons.close_rounded
                              : step.$2,
                      size: 14,
                      color: isFuture && !isCancelled
                          ? (isDark ? PSColors.textDark3 : PSColors.textLight3)
                          : color,
                    ),
                  ),
                  if (i < statusFlow.length - 1)
                    Container(
                      width: 1.5,
                      height: 28,
                      color: isDone
                          ? PSColors.neonGreen.withAlpha(80)
                          : isDark ? PSColors.darkBorder : PSColors.lightBorder,
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // ── Label ────────────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 28),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        step.$3,
                        style: PSText.bodySmall(
                          color: isFuture && !isCancelled
                              ? (isDark ? PSColors.textDark3 : PSColors.textLight3)
                              : isDark ? PSColors.textDark1 : PSColors.textLight1,
                          weight: isActive ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ),
                    if (isActive)
                      PSLiveIndicator(label: 'NOW', color: PSColors.brand),
                    if (isDone)
                      Icon(Icons.check_circle_rounded,
                          size: 14, color: PSColors.neonGreen),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Status History Log
// ══════════════════════════════════════════════════════════════════════════════

class _HistoryLog extends StatelessWidget {
  final String orderId;
  final bool isDark;
  const _HistoryLog({required this.orderId, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: OrderEngine.streamHistory(orderId),
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: PSColors.brand),
              ),
            ),
          );
        }

        final history = snap.data ?? [];
        if (history.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text('No history yet',
                style: PSText.body(color: PSColors.textDark3)),
          );
        }

        return Column(
          children: history.reversed.map((h) {
            final from = h['from_status'] as String? ?? '';
            final to   = h['to_status'] as String? ?? '';
            final notes = h['notes'] as String? ?? '';
            final ts = h['changed_at'];
            String timeStr = '';
            if (ts != null) {
              try {
                final dt = (ts as dynamic).toDate() as DateTime;
                timeStr = PSDateUtils.smartDateLabel(dt);
              } catch (_) {}
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(top: 5),
                    decoration: BoxDecoration(
                      color: PSColors.forStatus(to),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (from.isNotEmpty) ...[
                              Text(from,
                                  style: PSText.caption(color: PSColors.textDark3)),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 4),
                                child: Icon(Icons.arrow_forward_rounded,
                                    size: 10, color: PSColors.textDark3),
                              ),
                            ],
                            Text(to,
                                style: PSText.caption(
                                        color: PSColors.forStatus(to))
                                    .copyWith(fontWeight: FontWeight.w700)),
                          ],
                        ),
                        if (notes.isNotEmpty)
                          Text(notes,
                              style: PSText.caption(color: PSColors.textDark3)),
                        if (timeStr.isNotEmpty)
                          Text(timeStr,
                              style: PSText.caption(color: PSColors.textDark3)
                                  .copyWith(fontSize: 10)),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Helper Widgets
// ══════════════════════════════════════════════════════════════════════════════

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  final bool isDark;
  const _SectionCard({required this.title, required this.child, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? PSColors.darkCard : PSColors.lightCard,
        borderRadius: BorderRadius.circular(PSRadius.md),
        border: Border.all(
          color: isDark ? PSColors.darkBorder : PSColors.lightBorder,
          width: 0.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title.toUpperCase(), style: PSText.sectionHeader()),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool isDark;
  final bool isLast;
  const _InfoRow({
    required this.label,
    required this.value,
    required this.isDark,
    this.valueColor,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(label,
                    style: PSText.bodySmall(
                        color: isDark ? PSColors.textDark3 : PSColors.textLight3)),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  value,
                  style: PSText.bodySmall(
                    color: valueColor ??
                        (isDark ? PSColors.textDark1 : PSColors.textLight1),
                    weight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          Divider(
            height: 0.5,
            color: isDark ? PSColors.darkBorder : PSColors.lightBorder,
          ),
      ],
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? PSColors.darkBg : PSColors.lightBg,
      body: const Center(
        child: CircularProgressIndicator(color: PSColors.brand),
      ),
    );
  }
}

class _NotFoundScreen extends StatelessWidget {
  const _NotFoundScreen();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? PSColors.darkBg : PSColors.lightBg,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text('Order Detail', style: PSText.titleSmall()),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off_rounded,
                size: 48, color: PSColors.textDark3),
            const SizedBox(height: 16),
            Text('Order not found', style: PSText.title()),
            const SizedBox(height: 8),
            Text('It may have been deleted',
                style: PSText.body(color: PSColors.textDark2)),
          ],
        ),
      ),
    );
  }
}
