class NFCUrlBuilder {
  static const String baseUrl = 'https://ssp.app/t';

  /// Build NFC URL for a table
  /// Format: ssp.app/t/{orgSlug}/{locationSlug}/{tableLocalId}
  static String buildUrl({
    required String organizationSlug,
    required String locationSlug,
    required int tableLocalId,
  }) {
    return '$baseUrl/$organizationSlug/$locationSlug/$tableLocalId';
  }

  /// Parse URL to extract components (for verification)
  static NFCUrlComponents? parseUrl(String url) {
    final regex = RegExp(r'ssp\.app/t/([^/]+)/([^/]+)/(\d+)');
    final match = regex.firstMatch(url);

    if (match == null) return null;

    return NFCUrlComponents(
      organizationSlug: match.group(1)!,
      locationSlug: match.group(2)!,
      tableLocalId: int.parse(match.group(3)!),
    );
  }
}

class NFCUrlComponents {
  final String organizationSlug;
  final String locationSlug;
  final int tableLocalId;

  NFCUrlComponents({
    required this.organizationSlug,
    required this.locationSlug,
    required this.tableLocalId,
  });
}
