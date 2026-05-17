import 'package:cloud_firestore/cloud_firestore.dart';

/// Central Firestore service — replaces all direct DatabaseHelper calls.
/// All data now lives in Firebase Firestore (cloud) instead of local SQLite.
class FirestoreService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Public access to the Firestore instance (for batch ops, etc.)
  static FirebaseFirestore get db => _db;

  // ── Collection references ──────────────────────────────────────────────────
  static CollectionReference get employees => _db.collection('employees');
  static CollectionReference get clients => _db.collection('clients');
  static CollectionReference get workOrders => _db.collection('workOrders');
  static CollectionReference get orders => _db.collection('orders');
  static CollectionReference get attendance => _db.collection('attendance');
  static CollectionReference get payroll => _db.collection('payroll');
  static CollectionReference get inventory => _db.collection('inventory');
  static CollectionReference get inventoryTransactions =>
      _db.collection('inventoryTransactions');
  static CollectionReference get machines => _db.collection('machines');
  static CollectionReference get cylinders => _db.collection('cylinders');
  static CollectionReference get leaves => _db.collection('leaves');
  static CollectionReference get alerts => _db.collection('alerts');
  static CollectionReference get auditLog => _db.collection('auditLog');

  // ── Phase 2: Order Control System ─────────────────────────────────────────
  static CollectionReference get orderStatusHistory =>
      _db.collection('orderStatusHistory');
  static CollectionReference get orderAttachments =>
      _db.collection('orderAttachments');
  static CollectionReference get notifications =>
      _db.collection('notifications');


  // ────────────────────────────────────────────────────────────────────────────
  // EMPLOYEES
  // ────────────────────────────────────────────────────────────────────────────

  /// Watch all employees in real-time
  static Stream<List<Map<String, dynamic>>> watchEmployees() {
    return employees
        .orderBy('name')
        .snapshots()
        .map((snap) => snap.docs.map(docToMap).toList());
  }

  /// Get all employees once
  static Future<List<Map<String, dynamic>>> getEmployees() async {
    final snap = await employees.orderBy('name').get();
    return snap.docs.map(docToMap).toList();
  }

  /// Get single employee by Firestore document ID
  static Future<Map<String, dynamic>?> getEmployee(String id) async {
    final doc = await employees.doc(id).get();
    if (!doc.exists) return null;
    return docToMap(doc);
  }

  /// Find employee by name (for auth lookup)
  static Future<Map<String, dynamic>?> findEmployeeByName(String name) async {
    final snap = await employees
        .where('name', isEqualTo: name)
        .where('is_active', isEqualTo: 1)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return docToMap(snap.docs.first);
  }

  /// Add new employee — returns Firestore document ID
  static Future<String> addEmployee(Map<String, dynamic> data) async {
    final ref = await employees.add({
      ...data,
      'created_at': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  /// Update employee
  static Future<void> updateEmployee(
      String id, Map<String, dynamic> data) async {
    await employees.doc(id).update(data);
  }

  /// Count all employees
  static Future<int> countEmployees() async {
    final snap = await employees.count().get();
    return snap.count ?? 0;
  }

  // ────────────────────────────────────────────────────────────────────────────
  // CLIENTS
  // ────────────────────────────────────────────────────────────────────────────

  static Stream<List<Map<String, dynamic>>> watchClients() {
    return clients
        .orderBy('name')
        .snapshots()
        .map((snap) => snap.docs.map(docToMap).toList());
  }

  static Future<List<Map<String, dynamic>>> getClients() async {
    final snap = await clients.orderBy('name').get();
    return snap.docs.map(docToMap).toList();
  }

  static Future<Map<String, dynamic>?> getClient(String id) async {
    final doc = await clients.doc(id).get();
    if (!doc.exists) return null;
    return docToMap(doc);
  }

  static Future<String> addClient(Map<String, dynamic> data) async {
    final ref = await clients.add({
      ...data,
      'created_at': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  static Future<void> updateClient(
      String id, Map<String, dynamic> data) async {
    await clients.doc(id).update(data);
  }

  static Future<void> deleteClient(String id) async {
    await clients.doc(id).delete();
  }

  static Future<int> countClients() async {
    final snap = await clients.count().get();
    return snap.count ?? 0;
  }

  // ────────────────────────────────────────────────────────────────────────────
  // WORK ORDERS
  // ────────────────────────────────────────────────────────────────────────────

  static Stream<List<Map<String, dynamic>>> watchWorkOrders(
      {String? statusFilter}) {
    Query q = workOrders.orderBy('created_at', descending: true);
    if (statusFilter != null && statusFilter != 'ALL') {
      q = q.where('status', isEqualTo: statusFilter);
    }
    return q.snapshots().map((snap) => snap.docs.map(docToMap).toList());
  }

  static Future<List<Map<String, dynamic>>> getWorkOrders(
      {String? statusFilter}) async {
    Query q = workOrders.orderBy('created_at', descending: true);
    if (statusFilter != null && statusFilter != 'ALL') {
      q = q.where('status', isEqualTo: statusFilter);
    }
    final snap = await q.get();
    return snap.docs.map(docToMap).toList();
  }

  static Future<Map<String, dynamic>?> getWorkOrder(String id) async {
    final doc = await workOrders.doc(id).get();
    if (!doc.exists) return null;
    return docToMap(doc);
  }

  static Future<String> addWorkOrder(Map<String, dynamic> data) async {
    final ref = await workOrders.add({
      ...data,
      'created_at': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  static Future<void> updateWorkOrder(
      String id, Map<String, dynamic> data) async {
    await workOrders.doc(id).update(data);
  }

  static Future<void> deleteWorkOrder(String id) async {
    await workOrders.doc(id).delete();
  }

  static Future<int> countWorkOrdersByStatus(String status) async {
    final snap =
        await workOrders.where('status', isEqualTo: status).count().get();
    return snap.count ?? 0;
  }

  static Future<int> countWorkOrders() async {
    final snap = await workOrders.count().get();
    return snap.count ?? 0;
  }

  // ────────────────────────────────────────────────────────────────────────────
  // ORDERS (Client Orders)
  // ────────────────────────────────────────────────────────────────────────────

  static Stream<List<Map<String, dynamic>>> watchOrders({String? clientId}) {
    Query q = orders.orderBy('created_at', descending: true);
    if (clientId != null) q = q.where('client_id', isEqualTo: clientId);
    return q.snapshots().map((snap) => snap.docs.map(docToMap).toList());
  }

  static Future<List<Map<String, dynamic>>> getOrders({String? clientId}) async {
    Query q = orders.orderBy('created_at', descending: true);
    if (clientId != null) q = q.where('client_id', isEqualTo: clientId);
    final snap = await q.get();
    return snap.docs.map(docToMap).toList();
  }

  static Future<String> addOrder(Map<String, dynamic> data) async {
    final ref = await orders.add({
      ...data,
      'created_at': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  static Future<void> updateOrder(String id, Map<String, dynamic> data) async {
    await orders.doc(id).update(data);
  }

  static Future<int> countOrders() async {
    final snap = await orders.count().get();
    return snap.count ?? 0;
  }

  // ────────────────────────────────────────────────────────────────────────────
  // ATTENDANCE
  // ────────────────────────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getAttendance({
    String? employeeId,
    String? date,
  }) async {
    Query q = attendance;
    if (employeeId != null) q = q.where('employee_id', isEqualTo: employeeId);
    if (date != null) q = q.where('date', isEqualTo: date);
    final snap = await q.get();
    return snap.docs.map(docToMap).toList();
  }

  static Future<String> addAttendance(Map<String, dynamic> data) async {
    final ref = await attendance.add({
      ...data,
      'created_at': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  static Future<void> updateAttendance(
      String id, Map<String, dynamic> data) async {
    await attendance.doc(id).update(data);
  }

  // ────────────────────────────────────────────────────────────────────────────
  // PAYROLL
  // ────────────────────────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getPayroll({String? month}) async {
    Query q = payroll.orderBy('created_at', descending: true);
    if (month != null) q = q.where('month', isEqualTo: month);
    final snap = await q.get();
    return snap.docs.map(docToMap).toList();
  }

  static Future<String> addPayroll(Map<String, dynamic> data) async {
    final ref = await payroll.add({
      ...data,
      'created_at': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  static Future<void> updatePayroll(
      String id, Map<String, dynamic> data) async {
    await payroll.doc(id).update(data);
  }

  // ────────────────────────────────────────────────────────────────────────────
  // INVENTORY
  // ────────────────────────────────────────────────────────────────────────────

  static Stream<List<Map<String, dynamic>>> watchInventory() {
    return inventory
        .orderBy('name')
        .snapshots()
        .map((snap) => snap.docs.map(docToMap).toList());
  }

  static Future<List<Map<String, dynamic>>> getInventory() async {
    final snap = await inventory.orderBy('name').get();
    return snap.docs.map(docToMap).toList();
  }

  static Future<String> addInventoryItem(Map<String, dynamic> data) async {
    final ref = await inventory.add({
      ...data,
      'created_at': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  static Future<void> updateInventoryItem(
      String id, Map<String, dynamic> data) async {
    await inventory.doc(id).update(data);
  }

  static Future<void> addInventoryTransaction(
      Map<String, dynamic> data) async {
    await inventoryTransactions.add({
      ...data,
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  // ────────────────────────────────────────────────────────────────────────────
  // MACHINES
  // ────────────────────────────────────────────────────────────────────────────

  static Stream<List<Map<String, dynamic>>> watchMachines() {
    return machines
        .orderBy('name')
        .snapshots()
        .map((snap) => snap.docs.map(docToMap).toList());
  }

  static Future<List<Map<String, dynamic>>> getMachines() async {
    final snap = await machines.orderBy('name').get();
    return snap.docs.map(docToMap).toList();
  }

  static Future<String> addMachine(Map<String, dynamic> data) async {
    final ref = await machines.add({
      ...data,
      'created_at': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  static Future<void> updateMachine(
      String id, Map<String, dynamic> data) async {
    await machines.doc(id).update(data);
  }

  // ────────────────────────────────────────────────────────────────────────────
  // CYLINDERS
  // ────────────────────────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getCylinders() async {
    final snap = await cylinders.orderBy('serial_no').get();
    return snap.docs.map(docToMap).toList();
  }

  static Future<String> addCylinder(Map<String, dynamic> data) async {
    final ref = await cylinders.add({
      ...data,
      'created_at': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  static Future<void> updateCylinder(
      String id, Map<String, dynamic> data) async {
    await cylinders.doc(id).update(data);
  }

  // ────────────────────────────────────────────────────────────────────────────
  // LEAVES
  // ────────────────────────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getLeaves(
      {String? employeeId}) async {
    Query q = leaves.orderBy('created_at', descending: true);
    if (employeeId != null) q = q.where('employee_id', isEqualTo: employeeId);
    final snap = await q.get();
    return snap.docs.map(docToMap).toList();
  }

  static Future<String> addLeave(Map<String, dynamic> data) async {
    final ref = await leaves.add({
      ...data,
      'created_at': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  static Future<void> updateLeave(String id, Map<String, dynamic> data) async {
    await leaves.doc(id).update(data);
  }

  // ────────────────────────────────────────────────────────────────────────────
  // ALERTS
  // ────────────────────────────────────────────────────────────────────────────

  static Stream<List<Map<String, dynamic>>> watchAlerts() {
    return alerts
        .where('is_resolved', isEqualTo: 0)
        .orderBy('triggered_at', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(docToMap).toList());
  }

  static Future<List<Map<String, dynamic>>> getAlerts() async {
    final snap = await alerts
        .orderBy('triggered_at', descending: true)
        .limit(50)
        .get();
    return snap.docs.map(docToMap).toList();
  }

  static Future<String> addAlert(Map<String, dynamic> data) async {
    final ref = await alerts.add({
      ...data,
      'triggered_at': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  static Future<void> resolveAlert(String id) async {
    await alerts.doc(id).update({
      'is_resolved': 1,
      'resolved_at': FieldValue.serverTimestamp(),
    });
  }

  static Future<int> countUnresolvedAlerts() async {
    final snap =
        await alerts.where('is_resolved', isEqualTo: 0).count().get();
    return snap.count ?? 0;
  }

  // ────────────────────────────────────────────────────────────────────────────
  // AUDIT LOG
  // ────────────────────────────────────────────────────────────────────────────

  static Future<void> logAction({
    required String userId,
    required String action,
    String source = 'APP',
    String? details,
  }) async {
    await auditLog.add({
      'user_id': userId,
      'action': action,
      'source': source,
      'details': details,
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  // ────────────────────────────────────────────────────────────────────────────
  // HELPER
  // ────────────────────────────────────────────────────────────────────────────

  /// Convert a Firestore document snapshot to a simple Map,
  /// injecting the document ID as 'id' field so all existing screens work.
  static Map<String, dynamic> docToMap(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return {'id': doc.id, ...data};
  }
}
