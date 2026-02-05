enum NFCTagStatus {
  active,
  lost,
  damaged,
  deactivated;

  static NFCTagStatus fromString(String value) {
    switch (value.toUpperCase()) {
      case 'ACTIVE':
        return NFCTagStatus.active;
      case 'LOST':
        return NFCTagStatus.lost;
      case 'DAMAGED':
        return NFCTagStatus.damaged;
      case 'DEACTIVATED':
        return NFCTagStatus.deactivated;
      default:
        return NFCTagStatus.active;
    }
  }

  String toGraphQL() => name.toUpperCase();
}

/// Type of NFC tag technology used.
enum NFCTagType {
  /// Legacy static URL tag (organization/location/table encoded in URL path).
  static_,

  /// NTAG 424 DNA tag with Secure Dynamic Messaging (UID/counter/MAC in URL).
  dna;

  static NFCTagType fromString(String value) {
    switch (value.toUpperCase()) {
      case 'DNA':
        return NFCTagType.dna;
      case 'STATIC':
      default:
        return NFCTagType.static_;
    }
  }

  String toGraphQL() => this == dna ? 'DNA' : 'STATIC';
}

class NFCTag {
  final String id;
  final String uid;
  final NFCTagType tagType;
  final NFCTagStatus status;
  final String? label;
  final String? writtenUrl;
  final DateTime? lastScannedAt;
  final DateTime registeredAt;
  final String? notes;

  const NFCTag({
    required this.id,
    required this.uid,
    this.tagType = NFCTagType.static_,
    required this.status,
    this.label,
    this.writtenUrl,
    this.lastScannedAt,
    required this.registeredAt,
    this.notes,
  });

  /// Whether this is a DNA (NTAG 424) tag.
  bool get isDna => tagType == NFCTagType.dna;

  /// Whether this is a static (NTAG 21x) tag.
  bool get isStatic => tagType == NFCTagType.static_;

  factory NFCTag.fromJson(Map<String, dynamic> json) {
    return NFCTag(
      id: json['id'] as String? ?? '',
      uid: json['uid'] as String? ?? '',
      tagType: NFCTagType.fromString(json['tagType'] as String? ?? 'STATIC'),
      status: NFCTagStatus.fromString(json['status'] as String? ?? 'ACTIVE'),
      label: json['label'] as String?,
      writtenUrl: json['writtenUrl'] as String?,
      lastScannedAt: json['lastScannedAt'] != null
          ? DateTime.tryParse(json['lastScannedAt'] as String)
          : null,
      registeredAt: json['registeredAt'] != null
          ? DateTime.tryParse(json['registeredAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'uid': uid,
      'tagType': tagType.toGraphQL(),
      'status': status.toGraphQL(),
      'label': label,
      'writtenUrl': writtenUrl,
      'lastScannedAt': lastScannedAt?.toIso8601String(),
      'registeredAt': registeredAt.toIso8601String(),
      'notes': notes,
    };
  }
}
