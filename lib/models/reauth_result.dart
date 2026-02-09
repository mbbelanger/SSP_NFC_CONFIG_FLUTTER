/// Available re-authentication methods
enum ReAuthMethod {
  biometric,
  appPin,
  totp,
  smsCode,
  emailCode,
  password,
}

/// Result of a re-authentication attempt
class ReAuthResult {
  final bool success;
  final ReAuthMethod method;
  final String? errorMessage;
  final String? biometricSignature;
  final String? credential; // PIN or TOTP code for backend verification

  const ReAuthResult({
    required this.success,
    required this.method,
    this.errorMessage,
    this.biometricSignature,
    this.credential,
  });

  factory ReAuthResult.success(
    ReAuthMethod method, {
    String? biometricSignature,
    String? credential,
  }) {
    return ReAuthResult(
      success: true,
      method: method,
      biometricSignature: biometricSignature,
      credential: credential,
    );
  }

  factory ReAuthResult.failed(ReAuthMethod method, String errorMessage) {
    return ReAuthResult(
      success: false,
      method: method,
      errorMessage: errorMessage,
    );
  }

  factory ReAuthResult.cancelled(ReAuthMethod method) {
    return ReAuthResult(
      success: false,
      method: method,
      errorMessage: 'Authentication cancelled',
    );
  }

  /// Convert method to GraphQL enum value
  String get methodName {
    switch (method) {
      case ReAuthMethod.biometric:
        return 'BIOMETRIC';
      case ReAuthMethod.appPin:
        return 'APP_PIN';
      case ReAuthMethod.totp:
        return 'TOTP';
      case ReAuthMethod.smsCode:
        return 'SMS_CODE';
      case ReAuthMethod.emailCode:
        return 'EMAIL_CODE';
      case ReAuthMethod.password:
        return 'PASSWORD';
    }
  }
}
