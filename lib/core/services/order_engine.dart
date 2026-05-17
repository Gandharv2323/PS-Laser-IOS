/// OrderEngine — Central orchestration service for the Order Control System.
///
/// Responsibilities:
/// - Realtime Firestore streams (all orders, filtered by status/date/priority)
/// - Create / update / cancel orders with status history logging
/// - Dashboard metric aggregation
/// - Overdue detection
///
/// All methods are static — matches existing FirestoreService pattern.
library;

import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:flutter/foundation.dart';
import '../models/models.dart';
import 'firestore_service.dart';


class OrderEngine {
  OrderEngine._();

  // ── Raw collection ref ─────────────────────────────────────────────────────
  static CollectionReference get _col => FirestoreService.orders;
  static CollectionReference get _history => FirestoreService.orderStatusHistory;

  // ═══════════════════════════════════════════════════════════════════════════
  // STREAMS (Realtime)
  // ═══════════════════════════════════════════════════════════════════════════

  /// All active orders, ordered by due_date ascending.
  static Stream<List<Order>> streamAll() {
    return _col
        .orderBy('due_date', descending: false)
        .snapshots()
        .map(_snapToOrders);
  }

  /// Orders filtered by a single status.
  static Stream<List<Order>> streamByStatus(String status) {
    return _col
        .where('status', isEqualTo: status)
        .orderBy('due_date', descending: false)
        .snapshots()
        .map(_snapToOrders);
  }

  /// Orders that are active (not completed/delivered/cancelled).
  static Stream<List<Order>> streamActive() {
    return _col
        .where('status', whereIn: ['RECEIVED', 'SCHEDULED', 'IN_PROGRESS', 'QUALITY_CHECK'])
        .orderBy('due_date', descending: false)
        .snapshots()
        .map(_snapToOrders);
  }

  /// Orders due today.
  static Stream<List<Order>> streamToday() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));
    return _col
        .where('due_date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('due_date', isLessThan: Timestamp.fromDate(end))
        .orderBy('due_date', descending: false)
        .snapshots()
        .map(_snapToOrders);
  }

  /// Orders that are overdue (due_date < now and not completed/delivered).
  static Stream<List<Order>> streamOverdue() {
    return _col
        .where('due_date', isLessThan: Timestamp.fromDate(DateTime.now()))
        .where('status', whereIn: ['RECEIVED', 'SCHEDULED', 'IN_PROGRESS', 'QUALITY_CHECK'])
        .orderBy('due_date', descending: false)
        .snapshots()
        .map(_snapToOrders);
  }

  /// Orders for a specific client.
  static Stream<List<Order>> streamForClient(String clientId) {
    return _col
        .where('client_id', isEqualTo: clientId)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map(_snapToOrders);
  }

  /// Stream status history for a specific order.
  static Stream<List<Map<String, dynamic>>> streamHistory(String orderId) {
    return _history
        .where('order_id', isEqualTo: orderId)
        .orderBy('changed_at', descending: false)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => FirestoreService.docToMap(d))
            .toList());
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ONE-SHOT FETCHES
  // ═══════════════════════════════════════════════════════════════════════════

  static Future<Order?> getOrder(String id) async {
    final doc = await _col.doc(id).get();
    if (!doc.exists) return null;
    return Order.fromMap(FirestoreService.docToMap(doc));
  }

  static Future<List<Order>> getActiveOrders() async {
    final snap = await _col
        .where('status', whereIn: ['RECEIVED', 'SCHEDULED', 'IN_PROGRESS', 'QUALITY_CHECK'])
        .orderBy('due_date', descending: false)
        .get();
    return _snapToOrders(snap);
  }

  static Future<List<Order>> getTodayOrders() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));
    final snap = await _col
        .where('due_date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('due_date', isLessThan: Timestamp.fromDate(end))
        .get();
    return _snapToOrders(snap);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MUTATIONS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Create a new order. Returns the Firestore document ID.
  static Future<String> createOrder(Order order, String createdByEmployeeId) async {
    final ref = _col.doc();
    final data = {
      ...order.toMap(),
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    };
    await ref.set(data);

    // Log initial status history entry
    await _logStatusChange(
      orderId: ref.id,
      fromStatus: '',
      toStatus: order.status,
      changedBy: createdByEmployeeId,
      notes: 'Order created',
    );

    // Write audit log
    await FirestoreService.auditLog.add({
      'action': 'ORDER_CREATED',
      'entity': 'orders',
      'entity_id': ref.id,
      'performed_by': createdByEmployeeId,
      'timestamp': FieldValue.serverTimestamp(),
      'details': 'Order for ${order.clientName}: ${order.description}',
    });

    debugPrint('✅ Order created: ${ref.id}');
    return ref.id;
  }

  /// Update an order's status and log the transition.
  static Future<void> updateStatus({
    required String orderId,
    required String newStatus,
    required String changedByEmployeeId,
    String? notes,
  }) async {
    // Fetch current status for history log
    final doc = await _col.doc(orderId).get();
    String current = '';
    if (doc.exists) {
      final data = doc.data();
      if (data != null) {
        current = (data as Map<String, dynamic>)['status'] as String? ?? '';
      }
    }

    await _col.doc(orderId).update({
      'status': newStatus,
      'updated_at': FieldValue.serverTimestamp(),
    });

    await _logStatusChange(
      orderId: orderId,
      fromStatus: current,
      toStatus: newStatus,
      changedBy: changedByEmployeeId,
      notes: notes,
    );
  }

  /// Update any arbitrary fields on an order.
  static Future<void> updateOrder(
    String orderId,
    Map<String, dynamic> fields,
    String changedByEmployeeId,
  ) async {
    await _col.doc(orderId).update({
      ...fields,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  /// Soft-delete: set status to CANCELLED.
  static Future<void> cancelOrder(
    String orderId,
    String cancelledByEmployeeId, {
    String? reason,
  }) async {
    await updateStatus(
      orderId: orderId,
      newStatus: 'CANCELLED',
      changedByEmployeeId: cancelledByEmployeeId,
      notes: reason ?? 'Order cancelled',
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DASHBOARD METRICS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Returns a real-time stream of aggregated dashboard metrics.
  static Stream<OrderMetrics> streamMetrics() {
    return _col.snapshots().map((snap) {
      final orders = _snapToOrders(snap);
      return _computeMetrics(orders);
    });
  }

  static OrderMetrics _computeMetrics(List<Order> orders) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    int received = 0, scheduled = 0, inProgress = 0, qc = 0;
    int completed = 0, overdue = 0, todayCount = 0;

    for (final o in orders) {
      if (o.status == 'RECEIVED')       received++;
      else if (o.status == 'SCHEDULED')      scheduled++;
      else if (o.status == 'IN_PROGRESS')    inProgress++;
      else if (o.status == 'QUALITY_CHECK')  qc++;
      else if (o.status == 'COMPLETED' || o.status == 'DELIVERED') completed++;

      if (o.isOverdue) overdue++;
      if (o.dueDate != null &&
          o.dueDate!.isAfter(todayStart) &&
          o.dueDate!.isBefore(todayEnd)) {
        todayCount++;
      }
    }

    final active = received + scheduled + inProgress + qc;
    final completionRate = (active + completed) > 0
        ? (completed / (active + completed) * 100).round()
        : 0;

    return OrderMetrics(
      total: orders.length,
      active: active,
      received: received,
      scheduled: scheduled,
      inProgress: inProgress,
      qualityCheck: qc,
      completed: completed,
      overdue: overdue,
      dueToday: todayCount,
      completionRate: completionRate,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PRIVATE HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  static Future<void> _logStatusChange({
    required String orderId,
    required String fromStatus,
    required String toStatus,
    required String changedBy,
    String? notes,
  }) async {
    await _history.add({
      'order_id': orderId,
      'from_status': fromStatus,
      'to_status': toStatus,
      'changed_by': changedBy,
      'changed_at': FieldValue.serverTimestamp(),
      'notes': notes ?? '',
    });
  }

  static List<Order> _snapToOrders(QuerySnapshot snap) {
    return snap.docs
        .map((d) => Order.fromMap(FirestoreService.docToMap(d)))
        .toList();
  }
}

// ── Dashboard Metrics Model ────────────────────────────────────────────────

class OrderMetrics {
  final int total;
  final int active;
  final int received;
  final int scheduled;
  final int inProgress;
  final int qualityCheck;
  final int completed;
  final int overdue;
  final int dueToday;
  final int completionRate;

  const OrderMetrics({
    required this.total,
    required this.active,
    required this.received,
    required this.scheduled,
    required this.inProgress,
    required this.qualityCheck,
    required this.completed,
    required this.overdue,
    required this.dueToday,
    required this.completionRate,
  });

  static const empty = OrderMetrics(
    total: 0, active: 0, received: 0, scheduled: 0, inProgress: 0,
    qualityCheck: 0, completed: 0, overdue: 0, dueToday: 0, completionRate: 0,
  );
}
