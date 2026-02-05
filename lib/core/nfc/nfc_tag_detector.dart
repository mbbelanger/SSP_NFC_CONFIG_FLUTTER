/// Tag type detection for NFC tags.
///
/// Detects whether a scanned tag is an NTAG 21x (static) or NTAG 424 DNA
/// by parsing the URL content read from the tag.

/// Enum representing NFC tag types
enum NFCTagKind {
  /// NTAG 21x static tag - requires URL encoding by the app
  static_,

  /// NTAG 424 DNA tag - pre-encoded with uid/ctr/mac parameters
  dna,

  /// Unknown or blank tag
  unknown,
}

/// Parsed DNA tag URL parameters
class DNATagParameters {
  /// Tag UID as 14 hex characters (e.g., "040F67BA851B90")
  final String uid;

  /// Read counter as 6 hex characters (e.g., "000006")
  final String ctr;

  /// CMAC signature as 16 hex characters (e.g., "9FCF3D28CF2ECFBD")
  final String mac;

  /// The raw URL that was parsed
  final String rawUrl;

  const DNATagParameters({
    required this.uid,
    required this.ctr,
    required this.mac,
    required this.rawUrl,
  });

  @override
  String toString() =>
      'DNATagParameters(uid: $uid, ctr: $ctr, mac: $mac)';
}

/// Result of detecting tag type from scanned content
class TagDetectionResult {
  /// The detected tag kind
  final NFCTagKind kind;

  /// DNA tag parameters (only set for DNA tags)
  final DNATagParameters? dnaParams;

  /// The raw URL content from the tag
  final String? rawUrl;

  const TagDetectionResult._({
    required this.kind,
    this.dnaParams,
    this.rawUrl,
  });

  /// Create result for a DNA tag
  factory TagDetectionResult.dna(DNATagParameters params) {
    return TagDetectionResult._(
      kind: NFCTagKind.dna,
      dnaParams: params,
      rawUrl: params.rawUrl,
    );
  }

  /// Create result for a static tag
  factory TagDetectionResult.static_([String? url]) {
    return TagDetectionResult._(
      kind: NFCTagKind.static_,
      rawUrl: url,
    );
  }

  /// Create result for an unknown/blank tag
  factory TagDetectionResult.unknown() {
    return const TagDetectionResult._(kind: NFCTagKind.unknown);
  }

  /// Whether this is a DNA tag
  bool get isDna => kind == NFCTagKind.dna;

  /// Whether this is a static tag
  bool get isStatic => kind == NFCTagKind.static_;

  @override
  String toString() => 'TagDetectionResult(kind: $kind, dnaParams: $dnaParams)';
}

/// Main detector class for NFC tag types
class NFCTagDetector {
  /// DNA tag URL host pattern
  static const String _dnaHost = 'splt.ca';

  /// DNA tag URL path
  static const String _dnaPath = '/t';

  /// Detect tag type from URL content read from tag
  ///
  /// Returns [TagDetectionResult] with the detected type and parsed parameters.
  static TagDetectionResult detect(String? content) {
    if (content == null || content.isEmpty) {
      return TagDetectionResult.unknown();
    }

    // Try to parse as URL
    final uri = Uri.tryParse(content);
    if (uri == null) {
      // Not a valid URL - treat as unknown
      return TagDetectionResult.unknown();
    }

    // Check for DNA URL pattern: splt.ca/t?uid=...&ctr=...&mac=...
    if (_isDnaUrl(uri)) {
      final params = _parseDnaUrl(uri, content);
      if (params != null) {
        return TagDetectionResult.dna(params);
      }
    }

    // Any other valid URL is treated as static
    // (could be blank, ssp.app URL, or other content)
    return TagDetectionResult.static_(content);
  }

  /// Check if URI matches DNA tag pattern
  static bool _isDnaUrl(Uri uri) {
    return uri.host.contains(_dnaHost) &&
        uri.path == _dnaPath &&
        uri.queryParameters.containsKey('uid') &&
        uri.queryParameters.containsKey('ctr') &&
        uri.queryParameters.containsKey('mac');
  }

  /// Parse DNA tag parameters from URI
  static DNATagParameters? _parseDnaUrl(Uri uri, String rawUrl) {
    final uid = uri.queryParameters['uid'];
    final ctr = uri.queryParameters['ctr'];
    final mac = uri.queryParameters['mac'];

    if (uid == null || ctr == null || mac == null) {
      return null;
    }

    // Validate parameter formats
    if (!_isValidUid(uid) || !_isValidCtr(ctr) || !_isValidMac(mac)) {
      return null;
    }

    return DNATagParameters(
      uid: uid.toUpperCase(),
      ctr: ctr.toUpperCase(),
      mac: mac.toUpperCase(),
      rawUrl: rawUrl,
    );
  }

  /// Validate UID format: 14 hex characters (7 bytes)
  static bool _isValidUid(String uid) {
    return RegExp(r'^[0-9A-Fa-f]{14}$').hasMatch(uid);
  }

  /// Validate counter format: 6 hex characters (3 bytes)
  static bool _isValidCtr(String ctr) {
    return RegExp(r'^[0-9A-Fa-f]{6}$').hasMatch(ctr);
  }

  /// Validate MAC format: 16 hex characters (8 bytes, truncated CMAC)
  static bool _isValidMac(String mac) {
    return RegExp(r'^[0-9A-Fa-f]{16}$').hasMatch(mac);
  }

  /// Validate DNA tag parameters (public method for external validation)
  static bool validateDnaParams(DNATagParameters params) {
    return _isValidUid(params.uid) &&
        _isValidCtr(params.ctr) &&
        _isValidMac(params.mac);
  }
}
