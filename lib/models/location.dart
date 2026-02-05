import 'organization.dart';

class Location {
  final String id;
  final String name;
  final String? address;
  final String? city;
  final String? state;
  final String? status;
  final String? timezone;
  final Organization? organization;
  final int? tableCount;
  final int? tablesWithNfc;

  const Location({
    required this.id,
    required this.name,
    this.address,
    this.city,
    this.state,
    this.status,
    this.timezone,
    this.organization,
    this.tableCount,
    this.tablesWithNfc,
  });

  int get tablesWithoutNfc => (tableCount ?? 0) - (tablesWithNfc ?? 0);

  String get fullAddress {
    final parts = <String>[];
    if (address != null && address!.isNotEmpty) parts.add(address!);
    if (city != null && city!.isNotEmpty) parts.add(city!);
    if (state != null && state!.isNotEmpty) parts.add(state!);
    return parts.join(', ');
  }

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      address: json['address'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      status: json['status'] as String?,
      timezone: json['timezone'] as String?,
      organization: json['organization'] != null
          ? Organization.fromJson(json['organization'] as Map<String, dynamic>)
          : null,
      tableCount: json['tableCount'] as int?,
      tablesWithNfc: json['tablesWithNfc'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'city': city,
      'state': state,
      'status': status,
      'timezone': timezone,
      'organization': organization?.toJson(),
      'tableCount': tableCount,
      'tablesWithNfc': tablesWithNfc,
    };
  }
}
