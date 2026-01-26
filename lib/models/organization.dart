class Organization {
  final String id;
  final String name;
  final String uuid;

  const Organization({
    required this.id,
    required this.name,
    required this.uuid,
  });

  factory Organization.fromJson(Map<String, dynamic> json) {
    return Organization(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      uuid: json['uuid'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'uuid': uuid,
    };
  }
}
