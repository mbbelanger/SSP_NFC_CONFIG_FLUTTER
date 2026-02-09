import '../../models/nfc_write_authorization.dart';

/// In-memory store for NFC write authorization tokens
/// Tokens are ephemeral and not persisted to storage
class NfcAuthorizationStore {
  static NfcWriteAuthorization? _currentAuthorization;
  static int _operationsUsed = 0;

  /// Get the current authorization token if valid
  static NfcWriteAuthorization? get current {
    final auth = _currentAuthorization;
    if (auth == null) return null;

    // Check if expired
    if (auth.isExpired) {
      invalidate();
      return null;
    }

    // Check if single-use token already consumed
    if (auth.singleUse && _operationsUsed > 0) {
      invalidate();
      return null;
    }

    // Check if bulk operation limit reached
    if (auth.maxOperations != null && _operationsUsed >= auth.maxOperations!) {
      invalidate();
      return null;
    }

    return auth;
  }

  /// Check if we have a valid authorization
  static bool get hasValidAuthorization => current != null;

  /// Store a new authorization token
  static void store(NfcWriteAuthorization authorization) {
    _currentAuthorization = authorization;
    _operationsUsed = 0;
  }

  /// Mark an operation as used (consumes single-use tokens)
  static void markOperationUsed() {
    _operationsUsed++;

    final auth = _currentAuthorization;
    if (auth == null) return;

    // Invalidate if single-use
    if (auth.singleUse) {
      invalidate();
    }

    // Invalidate if bulk limit reached
    if (auth.maxOperations != null && _operationsUsed >= auth.maxOperations!) {
      invalidate();
    }
  }

  /// Invalidate the current authorization
  static void invalidate() {
    _currentAuthorization = null;
    _operationsUsed = 0;
  }

  /// Get remaining operations for bulk authorization
  static int? get remainingOperations {
    final auth = _currentAuthorization;
    if (auth == null) return null;
    if (auth.singleUse) return _operationsUsed == 0 ? 1 : 0;
    if (auth.maxOperations == null) return null;
    return auth.maxOperations! - _operationsUsed;
  }

  /// Get remaining time until expiration
  static Duration? get remainingTime {
    final auth = _currentAuthorization;
    if (auth == null) return null;
    final remaining = auth.expiresAt.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// Get the token string for API calls
  static String? get token => current?.token;
}
