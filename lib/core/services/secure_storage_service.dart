import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Encrypted key-value storage backed by:
/// - Android: AES-256 via Android Keystore
/// - iOS: Keychain
/// - Web: localStorage (fallback, no hardware encryption)
class SecureStorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(),
    iOptions:
        IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  // ─── Key constants ────────────────────────────────────────────────────────
  static const keyOpenRouterApiKey = 'openrouter_api_key';
  static const keySessionToken = 'session_token';

  // ─── Core operations ──────────────────────────────────────────────────────

  /// Write a value securely. Silently fails on unsupported platforms.
  static Future<void> write(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
    } catch (e) {
      debugPrint('[SecureStorage] Write failed for $key: $e');
    }
  }

  /// Read a value. Returns null if key doesn't exist or read fails.
  static Future<String?> read(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (e) {
      debugPrint('[SecureStorage] Read failed for $key: $e');
      return null;
    }
  }

  /// Delete a single key.
  static Future<void> delete(String key) async {
    try {
      await _storage.delete(key: key);
    } catch (e) {
      debugPrint('[SecureStorage] Delete failed for $key: $e');
    }
  }

  /// Delete all secure keys (used on full logout or wipe).
  static Future<void> deleteAll() async {
    try {
      await _storage.deleteAll();
    } catch (e) {
      debugPrint('[SecureStorage] DeleteAll failed: $e');
    }
  }

  // ─── Typed helpers ────────────────────────────────────────────────────────

  static Future<String?> getOpenRouterKey() => read(keyOpenRouterApiKey);

  static Future<void> setOpenRouterKey(String key) =>
      write(keyOpenRouterApiKey, key);

  static Future<void> clearOpenRouterKey() => delete(keyOpenRouterApiKey);
}
