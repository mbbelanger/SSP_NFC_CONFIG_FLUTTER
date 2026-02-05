import 'location.dart';
import 'organization.dart';

class User {
  final String id;
  final String name;
  final String email;
  final String? username;
  final String? status;
  final bool? twoFactorEnabled;
  final List<Location>? locations;
  final Organization? organization;

  const User({
    required this.id,
    required this.name,
    required this.email,
    this.username,
    this.status,
    this.twoFactorEnabled,
    this.locations,
    this.organization,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      username: json['username'] as String?,
      status: json['status'] as String?,
      twoFactorEnabled: json['two_factor_enabled'] as bool?,
      locations: (json['locations'] as List<dynamic>?)
          ?.map((e) => Location.fromJson(e as Map<String, dynamic>))
          .toList(),
      organization: json['organization'] != null
          ? Organization.fromJson(json['organization'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'username': username,
      'status': status,
      'two_factor_enabled': twoFactorEnabled,
      'locations': locations?.map((e) => e.toJson()).toList(),
      'organization': organization?.toJson(),
    };
  }
}
