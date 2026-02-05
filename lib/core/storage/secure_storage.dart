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
}
