import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  // Storage keys
  static const _tokenKey = 'auth_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _deviceTokenKey = 'device_token';
  static const _userKey = 'user_data';
  static const _pinHashKey = 'pin_hash';
  static const _pinAttemptsKey = 'pin_attempts';
  static const _pinLockoutKey = 'pin_lockout_until';

  // Token management
  static Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  static Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  static Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
  }

  // Refresh token management
  static Future<void> saveRefreshToken(String refreshToken) async {
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
  }

  static Future<String?> getRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }

  static Future<void> deleteRefreshToken() async {
    await _storage.delete(key: _refreshTokenKey);
  }

  // Device token management (for "remember this device" feature)
  static Future<void> saveDeviceToken(String deviceToken) async {
    await _storage.write(key: _deviceTokenKey, value: deviceToken);
  }

  static Future<String?> getDeviceToken() async {
    return await _storage.read(key: _deviceTokenKey);
  }

  static Future<void> deleteDeviceToken() async {
    await _storage.delete(key: _deviceTokenKey);
  }

  // User data management
  static Future<void> saveUserData(String userData) async {
    await _storage.write(key: _userKey, value: userData);
  }

  static Future<String?> getUserData() async {
    return await _storage.read(key: _userKey);
  }

  static Future<void> deleteUserData() async {
    await _storage.delete(key: _userKey);
  }

  // Clear all stored data (except device token for "remember device")
  static Future<void> clearAuthData() async {
    // Preserve device token for "remember this device" feature
    final deviceToken = await getDeviceToken();
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _userKey);
    // Restore device token if it existed
    if (deviceToken != null) {
      await saveDeviceToken(deviceToken);
    }
  }

  // Clear absolutely everything
  static Future<void> clearAll() async {
    await _storage.deleteAll();
  }

  // Check if user is authenticated
  static Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // PIN hash management
  static Future<void> savePinHash(String pinHash) async {
    await _storage.write(key: _pinHashKey, value: pinHash);
  }

  static Future<String?> getPinHash() async {
    return await _storage.read(key: _pinHashKey);
  }

  static Future<void> deletePinHash() async {
    await _storage.delete(key: _pinHashKey);
  }

  static Future<bool> hasPinSetup() async {
    final hash = await getPinHash();
    return hash != null && hash.isNotEmpty;
  }

  // PIN attempt tracking for brute-force protection
  static Future<int> getPinAttempts() async {
    final attempts = await _storage.read(key: _pinAttemptsKey);
    return attempts != null ? int.tryParse(attempts) ?? 0 : 0;
  }

  static Future<void> incrementPinAttempts() async {
    final current = await getPinAttempts();
    await _storage.write(key: _pinAttemptsKey, value: (current + 1).toString());
  }

  static Future<void> resetPinAttempts() async {
    await _storage.delete(key: _pinAttemptsKey);
  }

  // PIN lockout management
  static Future<DateTime?> getPinLockoutUntil() async {
    final lockout = await _storage.read(key: _pinLockoutKey);
    if (lockout == null) return null;
    return DateTime.tryParse(lockout);
  }

  static Future<void> setPinLockoutUntil(DateTime until) async {
    await _storage.write(key: _pinLockoutKey, value: until.toIso8601String());
  }

  static Future<void> clearPinLockout() async {
    await _storage.delete(key: _pinLockoutKey);
  }

  static Future<bool> isPinLockedOut() async {
    final lockoutUntil = await getPinLockoutUntil();
    if (lockoutUntil == null) return false;
    return DateTime.now().isBefore(lockoutUntil);
  }
}
