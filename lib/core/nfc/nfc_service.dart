import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/platform_tags.dart';

class NFCService {
  NfcTag? _currentTag;

  /// Check if device supports NFC
  Future<bool> isAvailable() async {
    return await NfcManager.instance.isAvailable();
  }

  /// Start NFC session and listen for tags
  Future<void> startSession({
    required Function(String uid, NfcTag tag) onTagDetected,
    required Function(String error) onError,
  }) async {
    try {
      await NfcManager.instance.startSession(
        onDiscovered: (NfcTag tag) async {
          _currentTag = tag;

          final uid = _extractUid(tag);
          if (uid != null) {
            onTagDetected(uid, tag);
          } else {
            onError('Could not read tag UID');
          }
        },
        onError: (NfcError error) async {
          onError(error.message);
        },
      );
    } catch (e) {
      onError('Failed to start NFC session: $e');
    }
  }

  /// Extract UID from tag (handles multiple NFC types)
  String? _extractUid(NfcTag tag) {
    List<int>? identifier;

    // Try each NFC technology
    final nfca = NfcA.from(tag);
    if (nfca != null) {
      identifier = nfca.identifier;
    }

    final nfcb = NfcB.from(tag);
    if (nfcb != null && identifier == null) {
      identifier = nfcb.identifier;
    }

    final nfcf = NfcF.from(tag);
    if (nfcf != null && identifier == null) {
      identifier = nfcf.identifier;
    }

    final nfcv = NfcV.from(tag);
    if (nfcv != null && identifier == null) {
      identifier = nfcv.identifier;
    }

    final isoDep = IsoDep.from(tag);
    if (isoDep != null && identifier == null) {
      identifier = isoDep.identifier;
    }

    if (identifier == null) return null;

    // Format as colon-separated hex string: "04:A8:14:4A:BE:2A:81"
    return identifier
        .map((byte) => byte.toRadixString(16).padLeft(2, '0').toUpperCase())
        .join(':');
  }

  /// Write URL to NFC tag as NDEF record
  Future<void> writeUrl(String url) async {
    if (_currentTag == null) {
      throw NFCException('No tag available. Scan a tag first.');
    }

    final ndef = Ndef.from(_currentTag!);

    if (ndef == null) {
      throw NFCException('Tag does not support NDEF format');
    }

    if (!ndef.isWritable) {
      throw NFCException('Tag is write-protected');
    }

    // Create NDEF message with URL record
    final message = NdefMessage([
      NdefRecord.createUri(Uri.parse(url)),
    ]);

    // Check if URL fits on tag
    final messageSize = message.byteLength;
    if (messageSize > ndef.maxSize) {
      throw NFCException(
        'URL too long for tag ($messageSize bytes > ${ndef.maxSize} max)',
      );
    }

    try {
      await ndef.write(message);
    } catch (e) {
      throw NFCException('Failed to write to tag: $e');
    }
  }

  /// Stop NFC session
  void stopSession() {
    NfcManager.instance.stopSession();
    _currentTag = null;
  }

  /// Get current tag (for write after read)
  NfcTag? get currentTag => _currentTag;
}

class NFCException implements Exception {
  final String message;
  NFCException(this.message);

  @override
  String toString() => message;
}
