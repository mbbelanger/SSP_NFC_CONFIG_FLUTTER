import 'organization.dart';

class Location {
  final String id;
  final String name;
  final Organization? organization;
  final int? tableCount;
  final int? tablesWithNfc;

  const Location({
    required this.id,
    required this.name,
    this.organization,
    this.tableCount,
    this.tablesWithNfc,
  });

  int get tablesWithoutNfc => (tableCount ?? 0) - (tablesWithNfc ?? 0);

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
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
      'organization': organization?.toJson(),
      'tableCount': tableCount,
      'tablesWithNfc': tablesWithNfc,
    };
  }
}
