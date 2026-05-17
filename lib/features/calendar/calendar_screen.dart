/// Calendar Screen — Production Timeline with table_calendar.
///
/// Shows all orders on a monthly calendar, color-coded by priority.
/// Tapping a date reveals the orders scheduled for that day.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../core/models/models.dart';
import '../../core/services/order_engine.dart';
import '../../core/theme/ios_design_system.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  // ── Event loader ────────────────────────────────────────────────────────────

  List<Order> _getOrdersForDay(DateTime day, List<Order> allOrders) {
    return allOrders.where((o) {
      if (o.dueDate == null) return false;
      return isSameDay(o.dueDate!, day);
    }).toList();
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
          final selectedOrders = _getOrdersForDay(_selectedDay, orders);

          return CustomScrollView(
            slivers: [
              // ── App Bar ──────────────────────────────────────────────
              SliverAppBar(
                pinned: true,
                backgroundColor: isDark ? PSColors.darkBg : PSColors.lightBg,
                surfaceTintColor: Colors.transparent,
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Calendar', style: PSText.title()),
                    Text(
                      'Production Timeline',
                      style: PSText.caption(color: PSColors.textDark3),
                    ),
                  ],
                ),
                actions: [
                  // Jump to today
                  IconButton(
                    icon: const Icon(Icons.today_rounded),
                    tooltip: 'Jump to Today',
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _focusedDay = DateTime.now();
                        _selectedDay = DateTime.now();
                      });
                    },
                  ),
                  const SizedBox(width: 4),
                ],
              ),

              // ── Summary chips ────────────────────────────────────────
              SliverToBoxAdapter(
                child: _SummaryStrip(orders: orders),
              ),

              // ── Calendar widget ──────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: _buildCalendar(isDark, orders),
                ),
              ),

              // ── Selected day header ──────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          gradient: PSColors.brandGradient,
                          borderRadius: BorderRadius.circular(PSRadius.sm),
                        ),
                        child: Text(
                          DateFormat('d').format(_selectedDay),
                          style: PSText.body(color: Colors.white)
                              .copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        DateFormat('EEEE, MMMM d').format(_selectedDay),
                        style: PSText.body(color: PSColors.textDark1)
                            .copyWith(fontWeight: FontWeight.w600),
                      ),
                      const Spacer(),
                      Text(
                        '${selectedOrders.length} order${selectedOrders.length == 1 ? '' : 's'}',
                        style: PSText.caption(color: PSColors.textDark3),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Day's order list ─────────────────────────────────────
              if (selectedOrders.isEmpty)
                SliverToBoxAdapter(
                  child: _EmptyDayMessage(isDark: isDark),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => _OrderCard(
                      order: selectedOrders[i],
                      isDark: isDark,
                    ),
                    childCount: selectedOrders.length,
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          );
        },
      ),
    );
  }

  // ── Calendar widget ──────────────────────────────────────────────────────────

  Widget _buildCalendar(bool isDark, List<Order> orders) {
    final now = DateTime.now();

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 4),
      decoration: BoxDecoration(
        color: isDark ? PSColors.darkCard : PSColors.lightCard,
        borderRadius: BorderRadius.circular(PSRadius.lg),
        border: Border.all(
          color: isDark ? PSColors.darkBorder : PSColors.lightBorder,
          width: 0.5,
        ),
      ),
      child: TableCalendar<Order>(
        firstDay: DateTime(now.year - 1),
        lastDay: DateTime(now.year + 2),
        focusedDay: _focusedDay,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        calendarFormat: _calendarFormat,
        startingDayOfWeek: StartingDayOfWeek.monday,
        eventLoader: (day) => _getOrdersForDay(day, orders),

        // ── Interactions ──────────────────────────────────────────
        onDaySelected: (selected, focused) {
          HapticFeedback.selectionClick();
          setState(() {
            _selectedDay = selected;
            _focusedDay = focused;
          });
        },
        onFormatChanged: (format) {
          setState(() => _calendarFormat = format);
        },
        onPageChanged: (focusedDay) {
          _focusedDay = focusedDay;
        },

        // ── Styling ───────────────────────────────────────────────
        headerStyle: HeaderStyle(
          formatButtonVisible: true,
          titleCentered: true,
          formatButtonDecoration: BoxDecoration(
            border: Border.all(color: PSColors.brand, width: 0.8),
            borderRadius: BorderRadius.circular(PSRadius.sm),
          ),
          formatButtonTextStyle: PSText.caption(color: PSColors.brand),
          titleTextStyle: PSText.body(
            color: isDark ? PSColors.textDark1 : PSColors.textLight1,
          ).copyWith(fontWeight: FontWeight.w700),
          leftChevronIcon: Icon(Icons.chevron_left_rounded,
              color: isDark ? PSColors.textDark2 : PSColors.textLight2),
          rightChevronIcon: Icon(Icons.chevron_right_rounded,
              color: isDark ? PSColors.textDark2 : PSColors.textLight2),
        ),

        daysOfWeekStyle: DaysOfWeekStyle(
          weekdayStyle: PSText.caption(color: PSColors.textDark3)
              .copyWith(fontWeight: FontWeight.w600, fontSize: 11),
          weekendStyle: PSText.caption(color: PSColors.textDark3)
              .copyWith(fontWeight: FontWeight.w600, fontSize: 11),
        ),

        calendarStyle: CalendarStyle(
          outsideDaysVisible: false,
          cellMargin: const EdgeInsets.all(3),

          // Today
          todayDecoration: BoxDecoration(
            color: PSColors.brand.withAlpha(30),
            shape: BoxShape.circle,
            border: Border.all(color: PSColors.brand, width: 1.5),
          ),
          todayTextStyle: PSText.body(color: PSColors.brand)
              .copyWith(fontWeight: FontWeight.w700, fontSize: 13),

          // Selected
          selectedDecoration: const BoxDecoration(
            gradient: PSColors.brandGradient,
            shape: BoxShape.circle,
          ),
          selectedTextStyle: PSText.body(color: Colors.white)
              .copyWith(fontWeight: FontWeight.w700, fontSize: 13),

          // Default
          defaultTextStyle: PSText.body(
            color: isDark ? PSColors.textDark1 : PSColors.textLight1,
          ).copyWith(fontSize: 13),
          weekendTextStyle: PSText.body(
            color: isDark ? PSColors.textDark2 : PSColors.textLight2,
          ).copyWith(fontSize: 13),

          // Markers (order dots below the date)
          markersMaxCount: 3,
          markerDecoration: const BoxDecoration(
            color: PSColors.brand,
            shape: BoxShape.circle,
          ),
          markerSize: 5.0,
          markerMargin: const EdgeInsets.symmetric(horizontal: 1),
        ),

        calendarBuilders: CalendarBuilders<Order>(
          // Custom marker builder — color-coded by priority
          markerBuilder: (ctx, day, events) {
            if (events.isEmpty) return null;
            return Positioned(
              bottom: 2,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: events.take(3).map((order) {
                  return Container(
                    width: 5,
                    height: 5,
                    margin: const EdgeInsets.symmetric(horizontal: 0.8),
                    decoration: BoxDecoration(
                      color: PSColors.forPriority(order.priority),
                      shape: BoxShape.circle,
                    ),
                  );
                }).toList(),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Sub-widgets
// ══════════════════════════════════════════════════════════════════════════════

class _SummaryStrip extends StatelessWidget {
  final List<Order> orders;
  const _SummaryStrip({required this.orders});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final active = orders.where((o) => o.isActive).length;
    final overdue = orders.where((o) => o.isOverdue).length;
    final dueToday = orders.where((o) => o.isDueToday).length;
    final thisMonth = orders.where((o) {
      if (o.dueDate == null) return false;
      return o.dueDate!.year == now.year && o.dueDate!.month == now.month;
    }).length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      child: Row(
        children: [
          _Chip(label: 'Active', count: active, color: PSColors.neonCyan),
          const SizedBox(width: 8),
          _Chip(label: 'Overdue', count: overdue, color: PSColors.neonRed),
          const SizedBox(width: 8),
          _Chip(label: 'Today', count: dueToday, color: PSColors.neonOrange),
          const SizedBox(width: 8),
          _Chip(
              label: 'This Mo.',
              count: thisMonth,
              color: PSColors.neonPurple),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _Chip({required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withAlpha(15),
          borderRadius: BorderRadius.circular(PSRadius.sm),
          border: Border.all(color: color.withAlpha(40), width: 0.5),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: PSText.body(color: color)
                  .copyWith(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            Text(
              label,
              style: PSText.caption(color: color).copyWith(fontSize: 9),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyDayMessage extends StatelessWidget {
  final bool isDark;
  const _EmptyDayMessage({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(vertical: 36),
      decoration: BoxDecoration(
        color: isDark ? PSColors.darkCard : PSColors.lightCard,
        borderRadius: BorderRadius.circular(PSRadius.md),
        border: Border.all(
          color: isDark ? PSColors.darkBorder : PSColors.lightBorder,
          width: 0.5,
        ),
      ),
      child: Column(
        children: [
          Icon(Icons.event_available_rounded,
              size: 36, color: PSColors.textDark3.withAlpha(80)),
          const SizedBox(height: 10),
          Text('No orders due this day',
              style: PSText.body(color: PSColors.textDark3)),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Order order;
  final bool isDark;
  const _OrderCard({required this.order, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final priorityColor = PSColors.forPriority(order.priority);
    final statusColor = PSColors.forStatus(order.status);

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        context.go('/orders/detail/${order.id}');
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? PSColors.darkCard : PSColors.lightCard,
          borderRadius: BorderRadius.circular(PSRadius.md),
          border: Border(
            left: BorderSide(color: priorityColor, width: 3),
            top: BorderSide(
              color: isDark ? PSColors.darkBorder : PSColors.lightBorder,
              width: 0.5,
            ),
            right: BorderSide(
              color: isDark ? PSColors.darkBorder : PSColors.lightBorder,
              width: 0.5,
            ),
            bottom: BorderSide(
              color: isDark ? PSColors.darkBorder : PSColors.lightBorder,
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          children: [
            // Left content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          order.description,
                          style: PSText.body(
                            color: isDark
                                ? PSColors.textDark1
                                : PSColors.textLight1,
                          ).copyWith(fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      // Priority chip
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: priorityColor.withAlpha(20),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                              color: priorityColor.withAlpha(60), width: 0.5),
                        ),
                        child: Text(
                          order.priority,
                          style: PSText.caption(color: priorityColor)
                              .copyWith(
                                  fontSize: 9, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.person_outline_rounded,
                          size: 13, color: PSColors.textDark3),
                      const SizedBox(width: 4),
                      Text(
                        order.clientName,
                        style:
                            PSText.caption(color: PSColors.textDark3),
                      ),
                      const SizedBox(width: 12),
                      // Status dot
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        order.status.replaceAll('_', ' '),
                        style: PSText.caption(color: statusColor)
                            .copyWith(fontSize: 10),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded,
                size: 20, color: PSColors.textDark3),
          ],
        ),
      ),
    );
  }
}
