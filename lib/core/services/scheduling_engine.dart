/// SchedulingEngine — Free-slot calculation & workload analysis.
///
/// Operates on the 9:00–19:00 production window.
/// Computes available time blocks based on active orders assigned to machines/employees.
library;

import '../constants/app_constants.dart';
import '../models/models.dart';

class SchedulingEngine {
  SchedulingEngine._();

  // ── Constants ───────────────────────────────────────────────────────────────
  static const int _workStart = AppConstants.workStartHour; // 9
  static const int _workEnd   = AppConstants.workEndHour;   // 19
  static const int _minSlot   = AppConstants.minSlotMinutes; // 30

  // ═══════════════════════════════════════════════════════════════════════════
  // FREE SLOT CALCULATION
  // ═══════════════════════════════════════════════════════════════════════════

  /// Returns all free slots on [date] given the list of scheduled orders.
  ///
  /// A slot is free if:
  ///   1. It falls within [workStart, workEnd]
  ///   2. No existing order overlaps with it
  ///   3. Its duration is at least [_minSlot] minutes
  static List<ScheduleSlot> calculateFreeSlots(
    DateTime date,
    List<Order> orders,
  ) {
    final dayStart = DateTime(date.year, date.month, date.day, _workStart, 0);
    final dayEnd   = DateTime(date.year, date.month, date.day, _workEnd, 0);

    // Build occupied blocks from orders that have a due_date on this day
    // and are not cancelled/completed.
    final occupied = _buildOccupiedBlocks(date, orders);

    // Sort by start time
    occupied.sort((a, b) => a.start.compareTo(b.start));

    final List<ScheduleSlot> free = [];
    DateTime cursor = dayStart;

    for (final block in occupied) {
      if (block.start.isAfter(cursor)) {
        final gap = block.start.difference(cursor).inMinutes;
        if (gap >= _minSlot) {
          free.add(ScheduleSlot(start: cursor, end: block.start, isOccupied: false));
        }
      }
      if (block.end.isAfter(cursor)) cursor = block.end;
    }

    // Check trailing gap after last occupied block
    if (cursor.isBefore(dayEnd)) {
      final gap = dayEnd.difference(cursor).inMinutes;
      if (gap >= _minSlot) {
        free.add(ScheduleSlot(start: cursor, end: dayEnd, isOccupied: false));
      }
    }

    return free;
  }

  /// Returns all occupied blocks (orders visible on the timeline).
  static List<ScheduleSlot> buildTimeline(DateTime date, List<Order> orders) {
    final occupied = _buildOccupiedBlocks(date, orders);
    occupied.sort((a, b) => a.start.compareTo(b.start));
    return occupied;
  }

  /// Returns all slots (both free and occupied), sorted by start time.
  static List<ScheduleSlot> fullTimeline(DateTime date, List<Order> orders) {
    final free     = calculateFreeSlots(date, orders);
    final occupied = _buildOccupiedBlocks(date, orders);
    final all = [...free, ...occupied];
    all.sort((a, b) => a.start.compareTo(b.start));
    return all;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // WORKLOAD CALCULATION
  // ═══════════════════════════════════════════════════════════════════════════

  /// Returns a workload percentage (0–100) for the given day.
  ///
  /// Workload = (total occupied minutes / total work minutes) × 100
  static double calculateDayWorkload(DateTime date, List<Order> orders) {
    final occupied = _buildOccupiedBlocks(date, orders);
    final totalOccupied = occupied.fold<int>(
      0,
      (sum, slot) => sum + slot.durationMinutes,
    );
    const totalWork = AppConstants.totalWorkMinutes;
    return (totalOccupied / totalWork * 100).clamp(0, 100);
  }

  /// Returns workload for a specific employee on a given day.
  static double calculateEmployeeWorkload(
    String employeeId,
    DateTime date,
    List<Order> orders,
  ) {
    final employeeOrders = orders.where(
      (o) => o.assignedEmployeeId == employeeId && o.isActive,
    ).toList();
    return calculateDayWorkload(date, employeeOrders);
  }

  /// Returns workload for a specific machine on a given day.
  static double calculateMachineWorkload(
    String machineId,
    DateTime date,
    List<Order> orders,
  ) {
    final machineOrders = orders.where(
      (o) => o.assignedMachineId == machineId && o.isActive,
    ).toList();
    return calculateDayWorkload(date, machineOrders);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CONFLICT DETECTION
  // ═══════════════════════════════════════════════════════════════════════════

  /// Detects whether [newOrder] would conflict with any existing order
  /// on the same machine or employee.
  static List<Order> detectConflicts(
    Order newOrder,
    List<Order> existingOrders,
  ) {
    if (newOrder.dueDate == null) return [];

    final newStart = newOrder.dueDate!
        .subtract(Duration(minutes: newOrder.estimatedDurationMins));
    final newEnd   = newOrder.dueDate!;

    return existingOrders.where((o) {
      if (!o.isActive || o.id == newOrder.id) return false;
      if (o.dueDate == null) return false;

      // Only check same machine OR same employee conflicts
      final sameMachine = newOrder.assignedMachineId != null &&
          o.assignedMachineId == newOrder.assignedMachineId;
      final sameEmployee = newOrder.assignedEmployeeId != null &&
          o.assignedEmployeeId == newOrder.assignedEmployeeId;
      if (!sameMachine && !sameEmployee) return false;

      final oStart = o.dueDate!.subtract(Duration(minutes: o.estimatedDurationMins));
      final oEnd   = o.dueDate!;

      // Overlap check: newStart < oEnd && newEnd > oStart
      return newStart.isBefore(oEnd) && newEnd.isAfter(oStart);
    }).toList();
  }

  /// Returns the earliest available free slot that fits [durationMins].
  static ScheduleSlot? suggestNextFreeSlot(
    DateTime date,
    List<Order> orders,
    int durationMins,
  ) {
    final freeSlots = calculateFreeSlots(date, orders);
    for (final slot in freeSlots) {
      if (slot.durationMinutes >= durationMins) return slot;
    }
    return null;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PRIVATE HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  static List<ScheduleSlot> _buildOccupiedBlocks(DateTime date, List<Order> orders) {
    final dayStart = DateTime(date.year, date.month, date.day, _workStart, 0);
    final dayEnd   = DateTime(date.year, date.month, date.day, _workEnd, 0);

    final List<ScheduleSlot> blocks = [];

    for (final order in orders) {
      if (!order.isActive || order.dueDate == null) continue;
      final due = order.dueDate!;

      // Only include orders whose due date falls on this day
      if (due.year != date.year || due.month != date.month || due.day != date.day) {
        continue;
      }

      final start = due.subtract(Duration(minutes: order.estimatedDurationMins));
      // Clamp to working hours
      final clampedStart = start.isBefore(dayStart) ? dayStart : start;
      final clampedEnd   = due.isAfter(dayEnd) ? dayEnd : due;

      if (clampedEnd.isAfter(clampedStart)) {
        blocks.add(ScheduleSlot(
          start: clampedStart,
          end: clampedEnd,
          isOccupied: true,
          orderId: order.id,
          orderDescription: order.description,
          priority: order.priority,
        ));
      }
    }

    return blocks;
  }
}
