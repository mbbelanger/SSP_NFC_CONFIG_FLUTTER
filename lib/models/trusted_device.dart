/// Represents a device that has been marked as trusted for 2FA bypass
class TrustedDevice {
  final String id;
  final String deviceName;
  final DateTime lastUsedAt;
  final DateTime expiresAt;
  final bool isActive;
  final String? createdIp;

  const TrustedDevice({
    required this.id,
    required this.deviceName,
    required this.lastUsedAt,
    required this.expiresAt,
    required this.isActive,
    this.createdIp,
  });

  factory TrustedDevice.fromJson(Map<String, dynamic> json) {
    return TrustedDevice(
      id: json['id'] as String,
      deviceName: json['device_name'] as String? ?? 'Unknown Device',
      lastUsedAt: DateTime.parse(json['last_used_at'] as String),
      expiresAt: DateTime.parse(json['expires_at'] as String),
      isActive: json['is_active'] as bool? ?? false,
      createdIp: json['created_ip'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'device_name': deviceName,
      'last_used_at': lastUsedAt.toIso8601String(),
      'expires_at': expiresAt.toIso8601String(),
      'is_active': isActive,
      'created_ip': createdIp,
    };
  }

  /// Check if the device trust has expired
  bool get isExpired => DateTime.now().isAfter(expiresAt);
}
