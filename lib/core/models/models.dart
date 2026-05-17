/// Typed data models for the PS LASER Manufacturing OS.
/// Replaces raw Map<String, dynamic> throughout the app.
library;

import 'package:cloud_firestore/cloud_firestore.dart';

// ── Order Model ─────────────────────────────────────────────────────────────

class Order {
  final String id;
  final String clientId;
  final String clientName;
  final String description;
  final String material;
  final double quantity;
  final String unit;
  final String priority; // LOW | MEDIUM | HIGH | URGENT
  final String status; // RECEIVED | SCHEDULED | IN_PROGRESS | QUALITY_CHECK | COMPLETED | DELIVERED | CANCELLED
  final DateTime? dueDate;
  final int estimatedDurationMins;
  final String? assignedMachineId;
  final String? assignedEmployeeId;
  final String? notes;
  final String? voiceTranscription;
  final List<String> attachmentUrls;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Order({
    required this.id,
    required this.clientId,
    required this.clientName,
    required this.description,
    required this.material,
    required this.quantity,
    required this.unit,
    required this.priority,
    required this.status,
    required this.estimatedDurationMins,
    this.dueDate,
    this.assignedMachineId,
    this.assignedEmployeeId,
    this.notes,
    this.voiceTranscription,
    this.attachmentUrls = const [],
    required this.createdAt,
    this.updatedAt,
  });

  bool get isOverdue {
    if (dueDate == null) return false;
    if (status == 'COMPLETED' || status == 'DELIVERED' || status == 'CANCELLED') return false;
    return DateTime.now().isAfter(dueDate!);
  }

  bool get isDueToday {
    if (dueDate == null) return false;
    final now = DateTime.now();
    return dueDate!.year == now.year &&
        dueDate!.month == now.month &&
        dueDate!.day == now.day;
  }

  bool get isActive =>
      status == 'RECEIVED' ||
      status == 'SCHEDULED' ||
      status == 'IN_PROGRESS' ||
      status == 'QUALITY_CHECK';

  Duration? get timeUntilDue {
    if (dueDate == null) return null;
    return dueDate!.difference(DateTime.now());
  }

  factory Order.fromMap(Map<String, dynamic> map) {
    return Order(
      id: map['id'] as String? ?? '',
      clientId: map['client_id'] as String? ?? '',
      clientName: map['client_name'] as String? ?? '',
      description: map['description'] as String? ?? '',
      material: map['material'] as String? ?? '',
      quantity: (map['quantity'] as num?)?.toDouble() ?? 0,
      unit: map['unit'] as String? ?? 'pcs',
      priority: map['priority'] as String? ?? 'MEDIUM',
      status: map['status'] as String? ?? 'RECEIVED',
      estimatedDurationMins: (map['estimated_duration_mins'] as num?)?.toInt() ?? 60,
      dueDate: _toDateTime(map['due_date']),
      assignedMachineId: map['assigned_machine_id'] as String?,
      assignedEmployeeId: map['assigned_employee_id'] as String?,
      notes: map['notes'] as String?,
      voiceTranscription: map['voice_transcription'] as String?,
      attachmentUrls: _toStringList(map['attachment_urls']),
      createdAt: _toDateTime(map['created_at']) ?? DateTime.now(),
      updatedAt: _toDateTime(map['updated_at']),
    );
  }

  Map<String, dynamic> toMap() => {
    'client_id': clientId,
    'client_name': clientName,
    'description': description,
    'material': material,
    'quantity': quantity,
    'unit': unit,
    'priority': priority,
    'status': status,
    'estimated_duration_mins': estimatedDurationMins,
    'due_date': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
    'assigned_machine_id': assignedMachineId,
    'assigned_employee_id': assignedEmployeeId,
    'notes': notes,
    'voice_transcription': voiceTranscription,
    'attachment_urls': attachmentUrls,
    'updated_at': FieldValue.serverTimestamp(),
  };

  Order copyWith({
    String? status,
    String? priority,
    String? assignedMachineId,
    String? assignedEmployeeId,
    String? notes,
    DateTime? dueDate,
    int? estimatedDurationMins,
  }) => Order(
    id: id,
    clientId: clientId,
    clientName: clientName,
    description: description,
    material: material,
    quantity: quantity,
    unit: unit,
    priority: priority ?? this.priority,
    status: status ?? this.status,
    estimatedDurationMins: estimatedDurationMins ?? this.estimatedDurationMins,
    dueDate: dueDate ?? this.dueDate,
    assignedMachineId: assignedMachineId ?? this.assignedMachineId,
    assignedEmployeeId: assignedEmployeeId ?? this.assignedEmployeeId,
    notes: notes ?? this.notes,
    voiceTranscription: voiceTranscription,
    attachmentUrls: attachmentUrls,
    createdAt: createdAt,
    updatedAt: DateTime.now(),
  );
}

// ── Client Model ────────────────────────────────────────────────────────────

class Client {
  final String id;
  final String name;
  final String? phone;
  final String? email;
  final String? address;
  final String? gstNumber;
  final DateTime? createdAt;

  const Client({
    required this.id,
    required this.name,
    this.phone,
    this.email,
    this.address,
    this.gstNumber,
    this.createdAt,
  });

  factory Client.fromMap(Map<String, dynamic> map) => Client(
    id: map['id'] as String? ?? '',
    name: map['name'] as String? ?? '',
    phone: map['phone'] as String?,
    email: map['email'] as String?,
    address: map['address'] as String?,
    gstNumber: map['gst_number'] as String?,
    createdAt: _toDateTime(map['created_at']),
  );

  Map<String, dynamic> toMap() => {
    'name': name,
    'phone': phone,
    'email': email,
    'address': address,
    'gst_number': gstNumber,
  };
}

// ── Schedule Slot Model ─────────────────────────────────────────────────────

class ScheduleSlot {
  final DateTime start;
  final DateTime end;
  final bool isOccupied;
  final String? orderId;
  final String? orderDescription;
  final String? priority;

  const ScheduleSlot({
    required this.start,
    required this.end,
    required this.isOccupied,
    this.orderId,
    this.orderDescription,
    this.priority,
  });

  Duration get duration => end.difference(start);
  int get durationMinutes => duration.inMinutes;
}

// ── Notification Item Model ─────────────────────────────────────────────────

class NotificationItem {
  final String id;
  final String type; // DAILY_SUMMARY | ROLLING_ALERT | INSTANT
  final String title;
  final String body;
  final String? relatedEntityType;
  final String? relatedEntityId;
  final bool isRead;
  final DateTime? readAt;
  final String priority; // LOW | MEDIUM | HIGH | CRITICAL
  final DateTime createdAt;

  const NotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.relatedEntityType,
    this.relatedEntityId,
    required this.isRead,
    this.readAt,
    required this.priority,
    required this.createdAt,
  });

  factory NotificationItem.fromMap(Map<String, dynamic> map) => NotificationItem(
    id: map['id'] as String? ?? '',
    type: map['type'] as String? ?? 'INSTANT',
    title: map['title'] as String? ?? '',
    body: map['body'] as String? ?? '',
    relatedEntityType: map['related_entity_type'] as String?,
    relatedEntityId: map['related_entity_id'] as String?,
    isRead: map['is_read'] as bool? ?? false,
    readAt: _toDateTime(map['read_at']),
    priority: map['priority'] as String? ?? 'MEDIUM',
    createdAt: _toDateTime(map['created_at']) ?? DateTime.now(),
  );
}

// ── Helpers ─────────────────────────────────────────────────────────────────

DateTime? _toDateTime(dynamic value) {
  if (value == null) return null;
  if (value is Timestamp) return value.toDate();
  if (value is String) return DateTime.tryParse(value);
  return null;
}

List<String> _toStringList(dynamic value) {
  if (value == null) return [];
  if (value is List) return value.map((e) => e.toString()).toList();
  return [];
}
