import 'dart:typed_data';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/platform_tags.dart';

class NFCService {
  NfcTag? _currentTag;
  bool _sessionActive = false;

  /// Check if device supports NFC
  Future<bool> isAvailable() async {
    return await NfcManager.instance.isAvailable();
  }

  /// Start NFC session and listen for tags
  Future<void> startSession({
    required Function(String uid, NfcTag tag) onTagDetected,
    required Function(String error) onError,
  }) async {
    if (_sessionActive) {
      stopSession();
    }

    try {
      _sessionActive = true;
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
          _sessionActive = false;
          onError(error.message);
        },
      );
    } catch (e) {
      _sessionActive = false;
      onError('Failed to start NFC session: $e');
    }
  }

  /// Start a session that reads, writes, and optionally locks - all in one tap
  /// This is the key fix: we do everything in the onDiscovered callback
  /// while the tag is still connected
  Future<void> startWriteSession({
    required String url,
    String? password,
    required Function(String uid, NFCTagInfo info) onSuccess,
    required Function(String error) onError,
  }) async {
    if (_sessionActive) {
      stopSession();
    }

    try {
      _sessionActive = true;
      await NfcManager.instance.startSession(
        onDiscovered: (NfcTag tag) async {
          _currentTag = tag;

          final uid = _extractUid(tag);
          if (uid == null) {
            onError('Could not read tag UID');
            return;
          }

          try {
            // Get tag info
            final info = await _getTagInfo(tag);

            // Write URL to tag
            await _writeUrlToTag(tag, url);

            // Lock with password if provided
            if (password != null && password.isNotEmpty) {
              await _lockTag(tag, password);
            }

            onSuccess(uid, info);
          } catch (e) {
            onError(e.toString());
          }
        },
        onError: (NfcError error) async {
          _sessionActive = false;
          onError(error.message);
        },
      );
    } catch (e) {
      _sessionActive = false;
      onError('Failed to start NFC session: $e');
    }
  }

  /// Start a test/read session to verify what's on the tag
  Future<void> startReadSession({
    required Function(String uid, NFCTagInfo info, String? content) onTagRead,
    required Function(String error) onError,
  }) async {
    if (_sessionActive) {
      stopSession();
    }

    try {
      _sessionActive = true;
      await NfcManager.instance.startSession(
        onDiscovered: (NfcTag tag) async {
          _currentTag = tag;

          final uid = _extractUid(tag);
          if (uid == null) {
            onError('Could not read tag UID');
            return;
          }

          try {
            final info = await _getTagInfo(tag);
            final content = await _readTagContent(tag);
            onTagRead(uid, info, content);
          } catch (e) {
            onError('Failed to read tag: $e');
          }
        },
        onError: (NfcError error) async {
          _sessionActive = false;
          onError(error.message);
        },
      );
    } catch (e) {
      _sessionActive = false;
      onError('Failed to start NFC session: $e');
    }
  }

  /// Read the NDEF content from a tag
  Future<String?> _readTagContent(NfcTag tag) async {
    try {
      final ndef = Ndef.from(tag);
      if (ndef == null) return null;

      final message = await ndef.read();
      if (message.records.isEmpty) return null;

      // Try to parse as URL
      for (final record in message.records) {
        if (record.typeNameFormat == NdefTypeNameFormat.nfcWellknown) {
          // URI record (type = 'U')
          if (record.type.isNotEmpty && record.type[0] == 0x55) {
            return _parseUriRecord(record);
          }
          // Text record (type = 'T')
          if (record.type.isNotEmpty && record.type[0] == 0x54) {
            return _parseTextRecord(record);
          }
        }
        // External or other type - try as raw text
        if (record.payload.isNotEmpty) {
          try {
            return String.fromCharCodes(record.payload);
          } catch (_) {
            // Not valid text
          }
        }
      }

      return null;
    } catch (e) {
      // Tag might not have NDEF content or is blank
      return null;
    }
  }

  /// Parse URI record payload
  String? _parseUriRecord(NdefRecord record) {
    if (record.payload.isEmpty) return null;

    // First byte is the URI identifier code
    final uriCode = record.payload[0];
    final uriBody = String.fromCharCodes(record.payload.sublist(1));

    // Common URI prefixes
    const uriPrefixes = {
      0x00: '',
      0x01: 'http://www.',
      0x02: 'https://www.',
      0x03: 'http://',
      0x04: 'https://',
      0x05: 'tel:',
      0x06: 'mailto:',
    };

    final prefix = uriPrefixes[uriCode] ?? '';
    return '$prefix$uriBody';
  }

  /// Parse Text record payload
  String? _parseTextRecord(NdefRecord record) {
    if (record.payload.isEmpty) return null;

    // First byte contains status (encoding + language code length)
    final statusByte = record.payload[0];
    final languageCodeLength = statusByte & 0x3F;

    // Skip status byte and language code
    final textStart = 1 + languageCodeLength;
    if (textStart >= record.payload.length) return null;

    return String.fromCharCodes(record.payload.sublist(textStart));
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

  /// Get tag info
  Future<NFCTagInfo> _getTagInfo(NfcTag tag) async {
    try {
      final ndef = Ndef.from(tag);
      final nfca = NfcA.from(tag);

      String? tagType;
      if (nfca != null) {
        tagType = await _detectNtagType(nfca);
      }

      return NFCTagInfo(
        uid: _extractUid(tag),
        isNdef: ndef != null,
        isWritable: ndef?.isWritable ?? false,
        maxSize: ndef?.maxSize ?? 0,
        tagType: tagType,
        canLock: nfca != null && tagType != null,
      );
    } catch (e) {
      // Return basic info if tag reading fails
      return NFCTagInfo(
        uid: _extractUid(tag),
        isNdef: false,
        isWritable: false,
        maxSize: 0,
        tagType: null,
        canLock: false,
      );
    }
  }

  /// Write URL to NFC tag as NDEF record
  Future<void> _writeUrlToTag(NfcTag tag, String url) async {
    final ndef = Ndef.from(tag);

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

    await ndef.write(message);
  }

  /// Write URL to NFC tag (legacy method for compatibility)
  Future<void> writeUrl(String url) async {
    if (_currentTag == null) {
      throw NFCException('No tag available. Scan a tag first.');
    }
    await _writeUrlToTag(_currentTag!, url);
  }

  /// Lock NTAG with password protection
  Future<void> _lockTag(NfcTag tag, String password) async {
    final nfca = NfcA.from(tag);

    if (nfca == null) {
      throw NFCException('Tag does not support password protection');
    }

    // Detect tag type
    final tagType = await _detectNtagType(nfca);
    if (tagType == null) {
      throw NFCException('Could not detect NTAG type for password protection');
    }

    // NTAG password is 4 bytes
    final pwdBytes = _passwordToBytes(password);

    // PACK (Password Acknowledge) - 2 bytes
    final packBytes = Uint8List.fromList([0x80, 0x80]);

    final (pwdPage, cfgPage) = _getNtagPages(tagType);

    // Write password
    await nfca.transceive(
      data: Uint8List.fromList([0xA2, pwdPage, ...pwdBytes]),
    );

    // Write PACK
    await nfca.transceive(
      data: Uint8List.fromList([0xA2, pwdPage + 1, ...packBytes, 0x00, 0x00]),
    );

    // Set AUTH0 to protect from page 4 (after header)
    // and enable write protection
    await nfca.transceive(
      data: Uint8List.fromList([0xA2, cfgPage, 0x04, 0x00, 0x00, 0x00]),
    );

    // Set ACCESS byte (PROT=0 for write-only protection)
    await nfca.transceive(
      data: Uint8List.fromList([0xA2, cfgPage + 1, 0x00, 0x05, 0x00, 0x00]),
    );
  }

  /// Detect NTAG type by reading capability container
  Future<String?> _detectNtagType(NfcA nfca) async {
    try {
      // Read page 3 (CC - Capability Container)
      final response = await nfca.transceive(
        data: Uint8List.fromList([0x30, 0x03]), // READ command, page 3
      );

      if (response.length >= 4) {
        final size = response[2]; // CC byte 2 contains size info

        if (size <= 0x12) return 'NTAG213';
        if (size <= 0x3E) return 'NTAG215';
        return 'NTAG216';
      }
    } catch (e) {
      // Ignore errors
    }
    return null;
  }

  /// Get configuration page numbers for NTAG type
  (int pwdPage, int cfgPage) _getNtagPages(String tagType) {
    switch (tagType) {
      case 'NTAG213':
        return (0x2B, 0x29);
      case 'NTAG215':
        return (0x85, 0x83);
      case 'NTAG216':
        return (0xE5, 0xE3);
      default:
        return (0x2B, 0x29);
    }
  }

  /// Convert password string to 4 bytes
  Uint8List _passwordToBytes(String password) {
    final bytes = password.codeUnits.take(4).toList();
    while (bytes.length < 4) {
      bytes.add(0);
    }
    return Uint8List.fromList(bytes.take(4).toList());
  }

  /// Authenticate with password before writing to locked tag
  Future<bool> authenticate(String password) async {
    if (_currentTag == null) {
      throw NFCException('No tag available');
    }

    final nfca = NfcA.from(_currentTag!);
    if (nfca == null) {
      throw NFCException('Tag does not support authentication');
    }

    final pwdBytes = _passwordToBytes(password);

    try {
      // PWD_AUTH command (0x1B) followed by 4-byte password
      final response = await nfca.transceive(
        data: Uint8List.fromList([0x1B, ...pwdBytes]),
      );

      // Successful auth returns 2-byte PACK
      return response.length >= 2;
    } catch (e) {
      return false;
    }
  }

  /// Start an erase session - wipes all NDEF data from the tag
  Future<void> startEraseSession({
    String? password,
    required Function(String uid, NFCTagInfo info) onSuccess,
    required Function(String error) onError,
  }) async {
    if (_sessionActive) {
      stopSession();
    }

    try {
      _sessionActive = true;
      await NfcManager.instance.startSession(
        onDiscovered: (NfcTag tag) async {
          _currentTag = tag;

          final uid = _extractUid(tag);
          if (uid == null) {
            onError('Could not read tag UID');
            return;
          }

          try {
            final info = await _getTagInfo(tag);

            // Authenticate if password provided
            if (password != null && password.isNotEmpty) {
              final nfca = NfcA.from(tag);
              if (nfca != null) {
                final pwdBytes = _passwordToBytes(password);
                try {
                  await nfca.transceive(
                    data: Uint8List.fromList([0x1B, ...pwdBytes]),
                  );
                } catch (e) {
                  onError('Authentication failed. Wrong password?');
                  return;
                }
              }
            }

            // Erase NDEF data
            await _eraseTag(tag);

            onSuccess(uid, info);
          } catch (e) {
            onError(e.toString());
          }
        },
        onError: (NfcError error) async {
          _sessionActive = false;
          onError(error.message);
        },
      );
    } catch (e) {
      _sessionActive = false;
      onError('Failed to start NFC session: $e');
    }
  }

  /// Erase NDEF content from tag by writing an empty message
  Future<void> _eraseTag(NfcTag tag) async {
    final ndef = Ndef.from(tag);

    if (ndef == null) {
      throw NFCException('Tag does not support NDEF format');
    }

    if (!ndef.isWritable) {
      throw NFCException('Tag is write-protected. Cannot erase.');
    }

    // Write an empty NDEF message (this effectively erases the tag content)
    // We create a minimal empty record
    final emptyMessage = NdefMessage([
      NdefRecord.createText(''),
    ]);

    await ndef.write(emptyMessage);
  }

  /// Stop NFC session
  void stopSession() {
    if (_sessionActive) {
      NfcManager.instance.stopSession();
      _sessionActive = false;
    }
    _currentTag = null;
  }

  /// Check if session is active
  bool get isSessionActive => _sessionActive;

  /// Get current tag
  NfcTag? get currentTag => _currentTag;
}

class NFCTagInfo {
  final String? uid;
  final bool isNdef;
  final bool isWritable;
  final int maxSize;
  final String? tagType;
  final bool canLock;

  NFCTagInfo({
    this.uid,
    required this.isNdef,
    required this.isWritable,
    required this.maxSize,
    this.tagType,
    required this.canLock,
  });

  @override
  String toString() {
    return 'NFCTagInfo(uid: $uid, type: $tagType, ndef: $isNdef, writable: $isWritable, size: $maxSize, canLock: $canLock)';
  }
}

class NFCException implements Exception {
  final String message;
  NFCException(this.message);

  @override
  String toString() => message;
}
