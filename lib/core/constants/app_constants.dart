/// App-wide constants for the PS LASER Manufacturing Operating System.
library;

class AppConstants {
  AppConstants._();

  // ── App Identity ────────────────────────────────────────────────────────────
  static const String appName = 'PS LASER';
  static const String appTagline = 'Manufacturing OS';
  static const String appVersion = '2.0.0';

  // ── Working Hours ───────────────────────────────────────────────────────────
  /// Production floor starts at 9:00 AM
  static const int workStartHour = 9;

  /// Production floor ends at 7:00 PM
  static const int workEndHour = 19;

  /// Total working minutes in a day (9 AM – 7 PM = 10 hours)
  static const int totalWorkMinutes = (workEndHour - workStartHour) * 60;

  // ── Order Priorities ────────────────────────────────────────────────────────
  static const List<String> orderPriorities = [
    'LOW',
    'MEDIUM',
    'HIGH',
    'URGENT',
  ];

  // ── Order Statuses ──────────────────────────────────────────────────────────
  static const List<String> orderStatuses = [
    'RECEIVED',
    'SCHEDULED',
    'IN_PROGRESS',
    'QUALITY_CHECK',
    'COMPLETED',
    'DELIVERED',
    'CANCELLED',
  ];

  // ── Status Display Labels ───────────────────────────────────────────────────
  static const Map<String, String> statusLabels = {
    'RECEIVED': 'Received',
    'SCHEDULED': 'Scheduled',
    'IN_PROGRESS': 'In Progress',
    'QUALITY_CHECK': 'Quality Check',
    'COMPLETED': 'Completed',
    'DELIVERED': 'Delivered',
    'CANCELLED': 'Cancelled',
  };

  // ── User Roles ──────────────────────────────────────────────────────────────
  static const List<String> userRoles = [
    'Worker',
    'Supervisor',
    'Manager',
    'Owner',
  ];

  // ── Scheduling ──────────────────────────────────────────────────────────────
  /// Minimum slot duration in minutes (used for free-slot calculation)
  static const int minSlotMinutes = 30;

  /// Overload threshold — if workload exceeds this %, show as red
  static const double overloadThresholdPercent = 80.0;

  /// Moderate threshold — if workload exceeds this %, show as yellow
  static const double moderateThresholdPercent = 50.0;

  // ── Notifications ───────────────────────────────────────────────────────────
  /// Hour for daily summary notification (8:30 AM)
  static const int dailySummaryHour = 8;
  static const int dailySummaryMinute = 30;

  /// Rolling alert interval (every 2 hours)
  static const int rollingAlertIntervalHours = 2;

  // ── AI ──────────────────────────────────────────────────────────────────────
  static const String openRouterBaseUrl = 'https://openrouter.ai/api/v1';
  static const int aiTimeoutSeconds = 30;
  static const int maxChatHistory = 20;

  // ── Firestore Collections ───────────────────────────────────────────────────
  static const String colEmployees = 'employees';
  static const String colClients = 'clients';
  static const String colOrders = 'orders';
  static const String colWorkOrders = 'workOrders';
  static const String colOrderStatusHistory = 'orderStatusHistory';
  static const String colOrderAttachments = 'orderAttachments';
  static const String colAttendance = 'attendance';
  static const String colPayroll = 'payroll';
  static const String colInventory = 'inventory';
  static const String colInventoryTransactions = 'inventoryTransactions';
  static const String colMachines = 'machines';
  static const String colCylinders = 'cylinders';
  static const String colLeaves = 'leaves';
  static const String colAlerts = 'alerts';
  static const String colNotifications = 'notifications';
  static const String colAuditLog = 'auditLog';
  static const String colFcmTokens = 'fcmTokens';
}
