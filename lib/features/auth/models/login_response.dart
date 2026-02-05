import '../../../models/user.dart';
import '../../../models/organization.dart';

class LoginResponse {
  final String? token;
  final int? expiresIn;
  final bool? requiresTwoFactor;
  final String? challengeToken;
  final String? deviceToken;
  final bool? requiresOrganizationSelection;
  final String? selectionToken;
  final User? user;
  final List<Organization>? organizations;

  LoginResponse({
    this.token,
    this.expiresIn,
    this.requiresTwoFactor,
    this.challengeToken,
    this.deviceToken,
    this.requiresOrganizationSelection,
    this.selectionToken,
    this.user,
    this.organizations,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      token: json['token'] as String?,
      expiresIn: json['expires_in'] as int?,
      requiresTwoFactor: json['requiresTwoFactor'] as bool?,
      challengeToken: json['challenge_token'] as String?,
      deviceToken: json['device_token'] as String?,
      requiresOrganizationSelection: json['requiresOrganizationSelection'] as bool?,
      selectionToken: json['selection_token'] as String?,
      user: json['user'] != null
          ? User.fromJson(json['user'] as Map<String, dynamic>)
          : null,
      organizations: (json['organizations'] as List<dynamic>?)
          ?.map((e) => Organization.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  bool get isFullyAuthenticated =>
      token != null &&
      !(requiresTwoFactor ?? false) &&
      !(requiresOrganizationSelection ?? false);
}

class TwoFAResponse {
  final bool success;
  final String? status;
  final String? token;
  final String? deviceToken;
  final User? user;

  TwoFAResponse({
    required this.success,
    this.status,
    this.token,
    this.deviceToken,
    this.user,
  });

  factory TwoFAResponse.fromJson(Map<String, dynamic> json) {
    return TwoFAResponse(
      success: json['success'] as bool? ?? false,
      status: json['status'] as String?,
      token: json['token'] as String?,
      deviceToken: json['device_token'] as String?,
      user: json['user'] != null
          ? User.fromJson(json['user'] as Map<String, dynamic>)
          : null,
    );
  }
}

class ResendCodeResponse {
  final bool success;
  final String? message;
  final DateTime? expiresAt;

  ResendCodeResponse({
    required this.success,
    this.message,
    this.expiresAt,
  });

  factory ResendCodeResponse.fromJson(Map<String, dynamic> json) {
    return ResendCodeResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String?,
      expiresAt: json['expires_at'] != null
          ? DateTime.tryParse(json['expires_at'] as String)
          : null,
    );
  }
}
