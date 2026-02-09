import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';

/// Service for getting device information
/// Used for trusted device naming and identification
class DeviceInfoService {
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  static AndroidDeviceInfo? _androidInfo;
  static IosDeviceInfo? _iosInfo;

  /// Get a human-readable device name
  /// e.g., "Samsung Galaxy S21" or "iPhone 15 Pro"
  static Future<String> getDeviceName() async {
    try {
      if (Platform.isAndroid) {
        _androidInfo ??= await _deviceInfo.androidInfo;
        final brand = _androidInfo!.brand;
        final model = _androidInfo!.model;
        // Capitalize brand name
        final brandCapitalized = brand.isNotEmpty
            ? brand[0].toUpperCase() + brand.substring(1)
            : brand;
        return '$brandCapitalized $model';
      } else if (Platform.isIOS) {
        _iosInfo ??= await _deviceInfo.iosInfo;
        return _iosInfo!.name;
      }
      return 'Unknown Device';
    } catch (e) {
      return 'Unknown Device';
    }
  }

  /// Get a unique device identifier
  /// Used for device token association
  static Future<String> getDeviceId() async {
    try {
      if (Platform.isAndroid) {
        _androidInfo ??= await _deviceInfo.androidInfo;
        return _androidInfo!.id;
      } else if (Platform.isIOS) {
        _iosInfo ??= await _deviceInfo.iosInfo;
        return _iosInfo!.identifierForVendor ?? 'unknown';
      }
      return 'unknown';
    } catch (e) {
      return 'unknown';
    }
  }

  /// Get the operating system name and version
  /// e.g., "Android 14" or "iOS 17.2"
  static Future<String> getOsInfo() async {
    try {
      if (Platform.isAndroid) {
        _androidInfo ??= await _deviceInfo.androidInfo;
        return 'Android ${_androidInfo!.version.release}';
      } else if (Platform.isIOS) {
        _iosInfo ??= await _deviceInfo.iosInfo;
        return 'iOS ${_iosInfo!.systemVersion}';
      }
      return 'Unknown OS';
    } catch (e) {
      return 'Unknown OS';
    }
  }

  /// Get full device description for trusted device display
  /// e.g., "Samsung Galaxy S21 (Android 14)"
  static Future<String> getFullDeviceDescription() async {
    final name = await getDeviceName();
    final os = await getOsInfo();
    return '$name ($os)';
  }
}
