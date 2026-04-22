import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'firestore_service.dart';

/// Background message handler — must be top-level, annotated vm:entry-point.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // OS handles background notification display via FCM platform layer.
  // No UI operations allowed here.
}

/// Central push-notification service for ForgeOps ERP.
///
/// Usage:
///   1. Call [NotificationService.init] in main() after Firebase.initializeApp().
///   2. Call [bindEmployee] after login, [unbindEmployee] before logout.
///   3. Call [triggerAlert] anywhere to fire a push + Firestore alert.
class NotificationService {
  NotificationService._();

  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  static const _channelId = 'forgeops_alerts';
  static const _channelName = 'ForgeOps Alerts';
  static const _channelDesc =
      'Critical ERP alerts — low stock, machine faults, leave approvals';

  /// Global navigator key — pass to MaterialApp.navigatorKey for tap routing.
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  // ── Initialize ─────────────────────────────────────────────────────────────

  static Future<void> init({String? employeeId}) async {
    // 1. Request notification permissions (Android 13+ / iOS)
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    // 2. Initialise flutter_local_notifications (v21: named params)
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _local.initialize(
      settings: const InitializationSettings(android: androidSettings),
      onDidReceiveNotificationResponse: _onLocalTap,
    );

    // 3. Create high-priority Android notification channel
    await _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            _channelId,
            _channelName,
            description: _channelDesc,
            importance: Importance.max,
            playSound: true,
            enableVibration: true,
          ),
        );

    // 4. Register background message handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // 5. Show local notification when app is in foreground
    FirebaseMessaging.onMessage.listen(_showLocal);

    // 6. Save FCM token to Firestore for this employee
    final token = await _fcm.getToken();
    if (token != null && employeeId != null) {
      await _saveToken(employeeId, token);
    }

    // 7. Refresh token whenever FCM rotates it
    _fcm.onTokenRefresh.listen((newToken) async {
      if (employeeId != null) await _saveToken(employeeId, newToken);
    });
  }

  // ── Token management ───────────────────────────────────────────────────────

  static Future<void> _saveToken(String employeeId, String token) async {
    await FirestoreService.db.collection('fcmTokens').doc(employeeId).set({
      'token': token,
      'employee_id': employeeId,
      'updated_at': FieldValue.serverTimestamp(),
      'platform': 'android',
    }, SetOptions(merge: true));
  }

  /// Call after login to bind the FCM token to this employee in Firestore.
  static Future<void> bindEmployee(String employeeId) async {
    final token = await _fcm.getToken();
    if (token != null) await _saveToken(employeeId, token);
  }

  /// Call before logout to remove the FCM token from Firestore & local cache.
  static Future<void> unbindEmployee(String employeeId) async {
    await FirestoreService.db
        .collection('fcmTokens')
        .doc(employeeId)
        .delete()
        .catchError((_) {});
    await _fcm.deleteToken();
  }

  // ── Show local notification ─────────────────────────────────────────────────

  static Future<void> _showLocal(RemoteMessage message) async {
    final notification = message.notification;
    final title = notification?.title ?? message.data['title'] ?? 'ForgeOps';
    final body = notification?.body ?? message.data['body'] ?? '';

    // v21 API: all named parameters
    await _local.show(
      id: message.hashCode,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          styleInformation: BigTextStyleInformation(body),
        ),
      ),
      payload: jsonEncode(message.data),
    );
  }

  // ── Notification tap handler ────────────────────────────────────────────────

  static void _onLocalTap(NotificationResponse response) {
    if (response.payload == null) return;
    try {
      final data = jsonDecode(response.payload!) as Map<String, dynamic>;
      final route = data['route'] as String?;
      if (route != null) {
        navigatorKey.currentState?.pushNamed(route);
      }
    } catch (_) {}
  }

  // ── Trigger alert ──────────────────────────────────────────────────────────

  /// Writes an alert to Firestore AND shows a local notification immediately.
  /// All employees will see the alert in the Alerts list (via Firestore stream).
  /// The triggering device gets an immediate local notification.
  static Future<void> triggerAlert({
    required String title,
    required String body,
    required String type, // 'LOW_STOCK' | 'MACHINE_FAULT' | 'LEAVE_REQUEST' | 'PAYROLL'
    String route = '/alerts',
    String? relatedId,
  }) async {
    // Write alert document to Firestore (visible to all users in real-time)
    await FirestoreService.alerts.add({
      'title': title,
      'body': body,
      'type': type,
      'route': route,
      'related_id': relatedId,
      'is_resolved': 0,
      'triggered_at': FieldValue.serverTimestamp(),
    });

    // Show local notification immediately on this device
    final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    await _local.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          styleInformation: BigTextStyleInformation(body),
        ),
      ),
      payload: jsonEncode({'route': route, 'related_id': relatedId ?? ''}),
    );
  }
}
