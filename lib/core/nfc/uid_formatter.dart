/// Utility class for NFC tag UID format conversions.
///
/// The app uses colon-separated format (04:A8:14:4A:BE:2A:81) for display,
/// but DNA tags use compact format (04A8144ABE2A81) in URLs and API calls.
class UidFormatter {
  /// Convert colon-separated UID to compact format (no separators).
  ///
  /// Example: "04:A8:14:4A:BE:2A:81" -> "04A8144ABE2A81"
  static String toCompact(String colonSeparated) {
    return colonSeparated.replaceAll(':', '').toUpperCase();
  }

  /// Convert compact UID to colon-separated format.
  ///
  /// Example: "04A8144ABE2A81" -> "04:A8:14:4A:BE:2A:81"
  static String toColonSeparated(String compact) {
    final buffer = StringBuffer();
    final normalized = compact.toUpperCase();

    for (int i = 0; i < normalized.length; i += 2) {
      if (i > 0) buffer.write(':');
      final end = (i + 2 <= normalized.length) ? i + 2 : normalized.length;
      buffer.write(normalized.substring(i, end));
    }

    return buffer.toString();
  }

  /// Validate DNA UID format (14 hex characters = 7 bytes).
  static bool isValidDnaUid(String uid) {
    if (uid.length != 14) return false;
    return RegExp(r'^[0-9A-Fa-f]{14}$').hasMatch(uid);
  }

  /// Validate static UID format (colon-separated, typically 7 bytes).
  static bool isValidStaticUid(String uid) {
    // Format: XX:XX:XX:XX:XX:XX:XX (7 bytes with colons = 20 chars)
    // or other lengths depending on tag type
    final colonPattern = RegExp(r'^([0-9A-Fa-f]{2}:)+[0-9A-Fa-f]{2}$');
    return colonPattern.hasMatch(uid);
  }

  /// Normalize a UID to uppercase.
  static String normalize(String uid) {
    return uid.toUpperCase();
  }
}
