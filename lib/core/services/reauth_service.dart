import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth/error_codes.dart' as auth_error;

import '../../models/reauth_result.dart';

/// Service for handling re-authentication before sensitive operations
/// Supports biometric, PIN, and 2FA code verification
class ReAuthService {
  static final LocalAuthentication _localAuth = LocalAuthentication();

  /// Check if biometric authentication is available on this device
  static Future<bool> isBiometricAvailable() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isSupported = await _localAuth.isDeviceSupported();
      return canCheck && isSupported;
    } catch (e) {
      return false;
    }
  }

  /// Get list of available biometric types
  static Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      return [];
    }
  }

  /// Check if device has fingerprint enrolled
  static Future<bool> hasFingerprintEnrolled() async {
    final biometrics = await getAvailableBiometrics();
    return biometrics.contains(BiometricType.fingerprint) ||
           biometrics.contains(BiometricType.strong);
  }

  /// Check if device has face recognition enrolled
  static Future<bool> hasFaceIdEnrolled() async {
    final biometrics = await getAvailableBiometrics();
    return biometrics.contains(BiometricType.face);
  }

  /// Authenticate with biometrics
  /// Returns a ReAuthResult with success/failure and optional biometric signature
  static Future<ReAuthResult> authenticateWithBiometric({
    String reason = 'Verify your identity to configure NFC tags',
  }) async {
    try {
      final success = await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true, // Don't cancel on app pause
          biometricOnly: true, // No device PIN fallback
          useErrorDialogs: true,
        ),
      );

      if (success) {
        // Generate a simple signature for the backend
        // In production, this could be signed with device keystore
        final timestamp = DateTime.now().toUtc().toIso8601String();
        final signature = 'biometric_verified_$timestamp';

        return ReAuthResult.success(
          ReAuthMethod.biometric,
          biometricSignature: signature,
        );
      }

      return ReAuthResult.cancelled(ReAuthMethod.biometric);
    } on PlatformException catch (e) {
      String message;
      switch (e.code) {
        case auth_error.notAvailable:
          message = 'Biometric authentication not available';
          break;
        case auth_error.notEnrolled:
          message = 'No biometrics enrolled on this device';
          break;
        case auth_error.lockedOut:
          message = 'Too many attempts. Please try again later';
          break;
        case auth_error.permanentlyLockedOut:
          message = 'Biometric permanently locked. Use another method';
          break;
        default:
          message = e.message ?? 'Biometric authentication failed';
      }
      return ReAuthResult.failed(ReAuthMethod.biometric, message);
    } catch (e) {
      return ReAuthResult.failed(
        ReAuthMethod.biometric,
        'Biometric authentication failed',
      );
    }
  }

  /// Get a human-readable name for the available biometric type
  static Future<String> getBiometricName() async {
    final biometrics = await getAvailableBiometrics();

    if (biometrics.contains(BiometricType.face)) {
      return 'Face ID';
    } else if (biometrics.contains(BiometricType.fingerprint) ||
               biometrics.contains(BiometricType.strong)) {
      return 'Fingerprint';
    } else if (biometrics.contains(BiometricType.iris)) {
      return 'Iris';
    }

    return 'Biometric';
  }

  /// Get icon name for the available biometric type
  static Future<String> getBiometricIconName() async {
    final biometrics = await getAvailableBiometrics();

    if (biometrics.contains(BiometricType.face)) {
      return 'face';
    }
    return 'fingerprint';
  }
}
