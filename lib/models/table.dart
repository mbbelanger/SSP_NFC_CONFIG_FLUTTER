import 'nfc_tag.dart';
import 'location.dart';

enum TableStatus {
  available,
  occupied,
  reserved;

  static TableStatus fromString(String value) {
    switch (value.toUpperCase()) {
      case 'AVAILABLE':
        return TableStatus.available;
      case 'OCCUPIED':
        return TableStatus.occupied;
      case 'RESERVED':
        return TableStatus.reserved;
      default:
        return TableStatus.available;
    }
  }

  String get displayName {
    switch (this) {
      case TableStatus.available:
        return 'Available';
      case TableStatus.occupied:
        return 'Occupied';
      case TableStatus.reserved:
        return 'Reserved';
    }
  }
}

class SSPTable {
  final String id;
  final String name;
  final int? localId;
  final int numberOfSeats;
  final TableStatus status;
  final NFCTag? nfcTag;
  final Location? location;

  const SSPTable({
    required this.id,
    required this.name,
    this.localId,
    required this.numberOfSeats,
    required this.status,
    this.nfcTag,
    this.location,
  });

  bool get hasActiveNfc => nfcTag != null && nfcTag!.status == NFCTagStatus.active;
  bool get hasDamagedNfc => nfcTag != null &&
      (nfcTag!.status == NFCTagStatus.damaged || nfcTag!.status == NFCTagStatus.lost);
  bool get hasNoNfc => nfcTag == null;

  /// Returns the active NFC tag if one exists and is active
  NFCTag? get activeNfcTag => hasActiveNfc ? nfcTag : null;

  factory SSPTable.fromJson(Map<String, dynamic> json) {
    return SSPTable(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Unknown Table',
      localId: json['local_id'] as int?,
      numberOfSeats: json['number_of_seats'] as int? ?? json['numberOfSeats'] as int? ?? 0,
      status: TableStatus.fromString(json['status'] as String? ?? 'AVAILABLE'),
      nfcTag: json['nfcTag'] != null
          ? NFCTag.fromJson(json['nfcTag'] as Map<String, dynamic>)
          : null,
      location: json['location'] != null
          ? Location.fromJson(json['location'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'local_id': localId,
      'number_of_seats': numberOfSeats,
      'status': status.name.toUpperCase(),
      'nfcTag': nfcTag?.toJson(),
      'location': location?.toJson(),
    };
  }
}
