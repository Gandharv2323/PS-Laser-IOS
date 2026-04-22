import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/firestore_service.dart';

/// Authentication service — uses Firestore as the backend.
/// PIN hashing and session management remain fully local and secure.
class SecureAuthService {
  static const String _keyPrefix = 'ps_secure_';
  static const String _sessionKey = '${_keyPrefix}session';
  static const String _loginAttemptsKey = '${_keyPrefix}attempts';
  static const String _lastLoginKey = '${_keyPrefix}last_login';
  static const String _rememberMeKey = '${_keyPrefix}remember_me';
  static const int _maxLoginAttempts = 5;
  static const int _lockoutDurationMinutes = 15;
  static const int _sessionTimeoutHours = 8;
  static const int _rememberMeDays = 365;

  // ─── Cryptographic primitives ─────────────────────────────────────────────

  static String _hashPin(String pin, String salt) {
    final bytes = utf8.encode(pin + salt);
    return sha256.convert(bytes).toString();
  }

  static String _hashAnswer(String answer) {
    final normalized = answer.trim().toLowerCase();
    final bytes = utf8.encode(normalized);
    return sha256.convert(bytes).toString();
  }

  static String _generateSalt() {
    final rng = Random.secure();
    final bytes = List<int>.generate(32, (_) => rng.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  static String _generateSessionToken() {
    final rng = Random.secure();
    final bytes = List<int>.generate(64, (_) => rng.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  // ─── Registration ─────────────────────────────────────────────────────────

  /// Register new user — writes directly to Firestore /employees collection
  static Future<Map<String, dynamic>> registerUser({
    required String name,
    required String pin,
    required String role,
    required String department,
    String? shift,
    String? secretQuestion,
    String? secretAnswer,
  }) async {
    final userCount = await FirestoreService.countEmployees();
    final effectiveRole = userCount == 0 ? 'Owner' : role;

    final salt = _generateSalt();
    final hashedPin = _hashPin(pin, salt);
    final hashedAnswer =
        (secretAnswer?.isNotEmpty ?? false) ? _hashAnswer(secretAnswer!) : null;

    final userId = await FirestoreService.addEmployee({
      'name': name,
      'role': effectiveRole,
      'department': department,
      'shift': shift ?? 'Morning',
      'is_active': 1,
      'pin_hash': hashedPin,
      'pin_salt': salt,
      'secret_question': secretQuestion,
      'secret_answer_hash': hashedAnswer,
    });

    await _logSecurityEvent('USER_REGISTERED', userId, 'New user: $name');

    return {
      'id': userId,
      'name': name,
      'role': effectiveRole,
      'department': department,
      'shift': shift ?? 'Morning',
    };
  }

  // ─── Lookup helpers ───────────────────────────────────────────────────────

  static Future<bool> isNameTaken(String name) async {
    final user = await FirestoreService.findEmployeeByName(name);
    return user != null;
  }

  static Future<bool> hasAnyUsers() async {
    final count = await FirestoreService.countEmployees();
    return count > 0;
  }

  // ─── Lockout management ───────────────────────────────────────────────────

  static Future<bool> isAccountLocked(String employeeId) async {
    final prefs = await SharedPreferences.getInstance();
    final attemptsJson = prefs.getString('$_loginAttemptsKey$employeeId');
    if (attemptsJson == null) return false;

    final data = jsonDecode(attemptsJson);
    final attempts = data['count'] as int;
    final lastAttempt = DateTime.parse(data['lastAttempt'] as String);

    if (attempts >= _maxLoginAttempts) {
      final lockoutEnd =
          lastAttempt.add(const Duration(minutes: _lockoutDurationMinutes));
      return DateTime.now().isBefore(lockoutEnd);
    }
    return false;
  }

  static Future<void> recordFailedAttempt(String employeeId) async {
    final prefs = await SharedPreferences.getInstance();
    final attemptsJson = prefs.getString('$_loginAttemptsKey$employeeId');

    int attempts = 1;
    if (attemptsJson != null) {
      final data = jsonDecode(attemptsJson);
      attempts = (data['count'] as int) + 1;
    }

    await prefs.setString(
      '$_loginAttemptsKey$employeeId',
      jsonEncode({
        'count': attempts,
        'lastAttempt': DateTime.now().toIso8601String(),
      }),
    );
    await _logSecurityEvent('FAILED_LOGIN', employeeId, 'Attempt $attempts');
  }

  static Future<void> clearFailedAttempts(String employeeId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_loginAttemptsKey$employeeId');
  }

  static Future<Duration?> getLockoutTimeRemaining(String employeeId) async {
    final prefs = await SharedPreferences.getInstance();
    final attemptsJson = prefs.getString('$_loginAttemptsKey$employeeId');
    if (attemptsJson == null) return null;

    final data = jsonDecode(attemptsJson);
    final attempts = data['count'] as int;
    final lastAttempt = DateTime.parse(data['lastAttempt'] as String);

    if (attempts >= _maxLoginAttempts) {
      final lockoutEnd =
          lastAttempt.add(const Duration(minutes: _lockoutDurationMinutes));
      final remaining = lockoutEnd.difference(DateTime.now());
      return remaining.isNegative ? null : remaining;
    }
    return null;
  }

  // ─── Authentication ───────────────────────────────────────────────────────

  /// Authenticate user by name (looks up Firestore, verifies PIN hash locally)
  static Future<Map<String, dynamic>?> authenticateUser(
      String nameOrId, String pin) async {
    if (await isAccountLocked(nameOrId)) {
      final remaining = await getLockoutTimeRemaining(nameOrId);
      throw AuthException(
          'Account locked. Try again in ${remaining?.inMinutes ?? 0} minutes.');
    }

    // Look up user in Firestore by name
    Map<String, dynamic>? user =
        await FirestoreService.findEmployeeByName(nameOrId.trim());

    if (user == null) {
      await recordFailedAttempt(nameOrId);
      throw AuthException('Invalid employee name or PIN');
    }

    final storedHash = user['pin_hash'] as String?;
    final salt = user['pin_salt'] as String?;

    if (storedHash == null || salt == null) {
      throw AuthException(
          'Account not properly configured. Contact administrator.');
    }

    final inputHash = _hashPin(pin, salt);
    if (inputHash != storedHash) {
      await recordFailedAttempt(nameOrId);
      throw AuthException('Invalid employee name or PIN');
    }

    await clearFailedAttempts(nameOrId);
    await _logSecurityEvent(
        'SUCCESSFUL_LOGIN', user['id'].toString(), 'Login successful');
    return user;
  }

  // ─── Forgot PIN ───────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>?> findUserForReset(String name) async {
    final user = await FirestoreService.findEmployeeByName(name.trim());
    if (user == null) return null;
    return {
      'id': user['id'],
      'name': user['name'],
      'secret_question': user['secret_question'],
      'secret_answer_hash': user['secret_answer_hash'],
    };
  }

  static Future<bool> verifySecretAnswer(String userId, String answer) async {
    final user = await FirestoreService.getEmployee(userId);
    if (user == null) return false;
    final storedHash = user['secret_answer_hash'] as String?;
    if (storedHash == null || storedHash.isEmpty) return false;
    return _hashAnswer(answer) == storedHash;
  }

  static Future<void> resetPin(String userId, String newPin) async {
    final salt = _generateSalt();
    final hashedPin = _hashPin(newPin, salt);
    await FirestoreService.updateEmployee(userId, {
      'pin_hash': hashedPin,
      'pin_salt': salt,
    });
    await _logSecurityEvent('PIN_RESET', userId, 'PIN reset via secret answer');
  }

  // ─── Edit user ────────────────────────────────────────────────────────────

  static Future<void> updateUser({
    required String userId,
    required String name,
    required String role,
    required String department,
    required String shift,
    required bool isActive,
    String? newPin,
  }) async {
    final updateData = <String, dynamic>{
      'name': name,
      'role': role,
      'department': department,
      'shift': shift,
      'is_active': isActive ? 1 : 0,
    };

    if (newPin != null && newPin.isNotEmpty) {
      final salt = _generateSalt();
      updateData['pin_hash'] = _hashPin(newPin, salt);
      updateData['pin_salt'] = salt;
    }

    await FirestoreService.updateEmployee(userId, updateData);
    await _logSecurityEvent('USER_UPDATED', userId, 'Profile updated');
  }

  // ─── Session management ───────────────────────────────────────────────────

  static Future<void> createSecureSession(
    Map<String, dynamic> userData, {
    bool rememberMe = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    final duration = rememberMe
        ? Duration(days: _rememberMeDays)
        : Duration(hours: _sessionTimeoutHours);

    final sessionData = {
      'userId': userData['id'],
      'userName': userData['name'],
      'role': userData['role'],
      'department': userData['department'],
      'shift': userData['shift'] ?? 'Morning',
      'loginTime': DateTime.now().toIso8601String(),
      'expiryTime': DateTime.now().add(duration).toIso8601String(),
      'sessionToken': _generateSessionToken(),
      'rememberMe': rememberMe,
    };

    await prefs.setString(_sessionKey, jsonEncode(sessionData));
    await prefs.setString(_lastLoginKey, DateTime.now().toIso8601String());
    if (rememberMe) {
      await prefs.setBool(_rememberMeKey, true);
    }
  }

  static Future<bool> isSessionValid() async {
    final prefs = await SharedPreferences.getInstance();
    final sessionJson = prefs.getString(_sessionKey);
    if (sessionJson == null) return false;

    try {
      final sessionData = jsonDecode(sessionJson);
      final expiryTime = DateTime.parse(sessionData['expiryTime'] as String);
      return DateTime.now().isBefore(expiryTime);
    } catch (e) {
      return false;
    }
  }

  static Future<Map<String, dynamic>?> getCurrentSession() async {
    if (!await isSessionValid()) return null;
    final prefs = await SharedPreferences.getInstance();
    final sessionJson = prefs.getString(_sessionKey);
    if (sessionJson == null) return null;
    return jsonDecode(sessionJson);
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    final sessionJson = prefs.getString(_sessionKey);

    if (sessionJson != null) {
      final sessionData = jsonDecode(sessionJson);
      await _logSecurityEvent(
          'LOGOUT', sessionData['userId'].toString(), 'User logged out');
    }

    await prefs.remove(_sessionKey);
    await prefs.remove(_rememberMeKey);
  }

  // ─── Security audit log ───────────────────────────────────────────────────

  static Future<void> _logSecurityEvent(
      String eventType, String userId, String details) async {
    try {
      await FirestoreService.logAction(
        userId: userId,
        action: eventType,
        source: 'AUTH',
        details: details,
      );
    } catch (e) {
      if (kDebugMode) print('Security log error: $e');
    }
  }

  /// No-op — kept for compatibility (schema migration not needed in Firestore)
  static Future<void> setupSecurePins() async {}
}

class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => message;
}