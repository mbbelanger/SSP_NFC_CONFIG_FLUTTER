/// Available 2FA authentication channels
enum TwoFactorChannel {
  totp,
  email,
  sms,
}

/// Current 2FA status for a user
class TwoFactorStatus {
  final bool isEnabled;
  final TwoFactorChannel? activeChannel;
  final String? maskedPhone;
  final DateTime? confirmedAt;
  final int recoveryCodesRemaining;

  const TwoFactorStatus({
    required this.isEnabled,
    this.activeChannel,
    this.maskedPhone,
    this.confirmedAt,
    this.recoveryCodesRemaining = 0,
  });

  factory TwoFactorStatus.fromJson(Map<String, dynamic> json) {
    return TwoFactorStatus(
      isEnabled: json['enabled'] as bool? ?? false,
      activeChannel: _parseChannel(json['active_channel'] as String?),
      maskedPhone: json['masked_phone'] as String?,
      confirmedAt: json['confirmed_at'] != null
          ? DateTime.parse(json['confirmed_at'] as String)
          : null,
      recoveryCodesRemaining: json['recovery_codes_remaining'] as int? ?? 0,
    );
  }

  static TwoFactorChannel? _parseChannel(String? value) {
    if (value == null) return null;
    switch (value.toUpperCase()) {
      case 'TOTP':
        return TwoFactorChannel.totp;
      case 'EMAIL':
        return TwoFactorChannel.email;
      case 'SMS':
        return TwoFactorChannel.sms;
      default:
        return null;
    }
  }

  /// Get display name for the active channel
  String get channelDisplayName {
    switch (activeChannel) {
      case TwoFactorChannel.totp:
        return 'Authenticator App';
      case TwoFactorChannel.email:
        return 'Email';
      case TwoFactorChannel.sms:
        return 'SMS';
      default:
        return 'Not configured';
    }
  }

  /// Check if recovery codes are running low
  bool get hasLowRecoveryCodes => recoveryCodesRemaining <= 2;
}

/// Available 2FA channels for setup
class TwoFactorAvailability {
  final bool totpAvailable;
  final bool emailAvailable;
  final bool smsAvailable;
  final String? phoneNumber;
  final bool requiresPhoneForSms;

  const TwoFactorAvailability({
    required this.totpAvailable,
    required this.emailAvailable,
    required this.smsAvailable,
    this.phoneNumber,
    required this.requiresPhoneForSms,
  });

  factory TwoFactorAvailability.fromJson(Map<String, dynamic> json) {
    return TwoFactorAvailability(
      totpAvailable: json['totp_available'] as bool? ?? true,
      emailAvailable: json['email_available'] as bool? ?? true,
      smsAvailable: json['sms_available'] as bool? ?? false,
      phoneNumber: json['phone_number'] as String?,
      requiresPhoneForSms: json['requires_phone_for_sms'] as bool? ?? true,
    );
  }
}
