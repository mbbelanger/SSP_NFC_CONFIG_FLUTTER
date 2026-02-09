/// Authorization token for NFC write operations
/// Short-lived, single-use token issued after re-authentication
class NfcWriteAuthorization {
  final String token;
  final DateTime expiresAt;
  final bool singleUse;
  final int? maxOperations;

  const NfcWriteAuthorization({
    required this.token,
    required this.expiresAt,
    required this.singleUse,
    this.maxOperations,
  });

  factory NfcWriteAuthorization.fromJson(Map<String, dynamic> json) {
    return NfcWriteAuthorization(
      token: json['nfc_write_token'] as String,
      expiresAt: DateTime.parse(json['expires_at'] as String),
      singleUse: json['single_use'] as bool? ?? true,
      maxOperations: json['max_operations'] as int?,
    );
  }

  /// Check if the authorization has expired
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// Check if the authorization is still valid
  bool get isValid => !isExpired;

  /// Get remaining time until expiration
  Duration get remainingTime => expiresAt.difference(DateTime.now());

  /// Check if this is a bulk authorization
  bool get isBulkAuthorization => maxOperations != null && maxOperations! > 1;
}
