import 'dart:io';
import 'dart:typed_data';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/nfc_manager_android.dart';
import 'package:nfc_manager/nfc_manager_ios.dart';
import 'package:ndef_record/ndef_record.dart';

class NFCService {
  NfcTag? _currentTag;
  bool _sessionActive = false;

  /// Check if device supports NFC
  Future<bool> isAvailable() async {
    final availability = await NfcManager.instance.checkAvailability();
    return availability == NfcAvailability.enabled;
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
        pollingOptions: {NfcPollingOption.iso14443, NfcPollingOption.iso15693},
        onDiscovered: (NfcTag tag) async {
          _currentTag = tag;

          final uid = _extractUid(tag);
          if (uid != null) {
            onTagDetected(uid, tag);
          } else {
            onError('Could not read tag UID');
          }
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
        pollingOptions: {NfcPollingOption.iso14443, NfcPollingOption.iso15693},
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

            // Lock with password if provided (pass tagType to avoid redundant detection)
            if (password != null && password.isNotEmpty) {
              await _lockTag(tag, password, tagType: info.tagType);
            }

            // Stop session immediately after successful write
            stopSession();
            onSuccess(uid, info);
          } catch (e) {
            stopSession();
            onError(e.toString());
          }
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
        pollingOptions: {NfcPollingOption.iso14443, NfcPollingOption.iso15693},
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
      );
    } catch (e) {
      _sessionActive = false;
      onError('Failed to start NFC session: $e');
    }
  }

  /// Read the NDEF content from a tag
  Future<String?> _readTagContent(NfcTag tag) async {
    try {
      NdefMessage? message;

      if (Platform.isAndroid) {
        final ndef = NdefAndroid.from(tag);
        if (ndef == null) return null;
        message = await ndef.getNdefMessage();
      } else if (Platform.isIOS) {
        final ndef = NdefIos.from(tag);
        if (ndef == null) return null;
        message = await ndef.readNdef();
      }

      if (message == null || message.records.isEmpty) return null;

      // Try to parse as URL
      for (final record in message.records) {
        if (record.typeNameFormat == TypeNameFormat.wellKnown) {
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

  /// Get platform-specific NfcA instance (Android only)
  NfcAAndroid? _getNfcA(NfcTag tag) {
    if (Platform.isAndroid) {
      return NfcAAndroid.from(tag);
    }
    return null;
  }

  /// Extract UID from tag (handles multiple NFC types)
  String? _extractUid(NfcTag tag) {
    Uint8List? identifier;

    if (Platform.isAndroid) {
      // Get the tag ID from NfcTagAndroid
      final androidTag = NfcTagAndroid.from(tag);
      if (androidTag != null) {
        identifier = androidTag.id;
      }
    } else if (Platform.isIOS) {
      // Try iOS technologies
      final miFare = MiFareIos.from(tag);
      if (miFare != null) {
        identifier = miFare.identifier;
      }

      if (identifier == null) {
        final feliCa = FeliCaIos.from(tag);
        if (feliCa != null) {
          identifier = feliCa.currentIDm;
        }
      }

      if (identifier == null) {
        final iso15693 = Iso15693Ios.from(tag);
        if (iso15693 != null) {
          identifier = iso15693.identifier;
        }
      }

      if (identifier == null) {
        final iso7816 = Iso7816Ios.from(tag);
        if (iso7816 != null) {
          identifier = iso7816.identifier;
        }
      }
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
      final nfca = _getNfcA(tag);

      String? tagType;
      if (nfca != null) {
        tagType = await _detectNtagType(nfca);
      }

      bool isWritable = false;
      int maxSize = 0;
      bool isNdef = false;

      if (Platform.isAndroid) {
        final ndef = NdefAndroid.from(tag);
        if (ndef != null) {
          isNdef = true;
          isWritable = ndef.isWritable;
          maxSize = ndef.maxSize;
        }
      } else if (Platform.isIOS) {
        final ndef = NdefIos.from(tag);
        if (ndef != null) {
          isNdef = true;
          isWritable = ndef.status == NdefStatusIos.readWrite;
          maxSize = ndef.capacity;
        }
      }

      return NFCTagInfo(
        uid: _extractUid(tag),
        isNdef: isNdef,
        isWritable: isWritable,
        maxSize: maxSize,
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

  /// Create a URI NDEF record
  NdefRecord _createUriRecord(Uri uri) {
    final uriString = uri.toString();
    int prefixCode = 0x00;
    String uriBody = uriString;

    // Common URI prefixes
    const prefixes = {
      'http://www.': 0x01,
      'https://www.': 0x02,
      'http://': 0x03,
      'https://': 0x04,
      'tel:': 0x05,
      'mailto:': 0x06,
    };

    for (final entry in prefixes.entries) {
      if (uriString.startsWith(entry.key)) {
        prefixCode = entry.value;
        uriBody = uriString.substring(entry.key.length);
        break;
      }
    }

    final payload = Uint8List.fromList([prefixCode, ...uriBody.codeUnits]);

    return NdefRecord(
      typeNameFormat: TypeNameFormat.wellKnown,
      type: Uint8List.fromList([0x55]), // 'U' for URI
      identifier: Uint8List(0),
      payload: payload,
    );
  }

  /// Create a Text NDEF record
  NdefRecord _createTextRecord(String text) {
    const languageCode = 'en';
    final languageCodeBytes = languageCode.codeUnits;
    final textBytes = text.codeUnits;

    // Status byte: UTF-8 encoding (0) + language code length
    final statusByte = languageCodeBytes.length;

    final payload = Uint8List.fromList([
      statusByte,
      ...languageCodeBytes,
      ...textBytes,
    ]);

    return NdefRecord(
      typeNameFormat: TypeNameFormat.wellKnown,
      type: Uint8List.fromList([0x54]), // 'T' for Text
      identifier: Uint8List(0),
      payload: payload,
    );
  }

  /// Write URL to NFC tag as NDEF record
  Future<void> _writeUrlToTag(NfcTag tag, String url) async {
    // Create NDEF message with URL record
    final record = _createUriRecord(Uri.parse(url));
    final message = NdefMessage(records: [record]);

    if (Platform.isAndroid) {
      final ndef = NdefAndroid.from(tag);
      if (ndef == null) {
        throw NFCException('Tag does not support NDEF format');
      }
      if (!ndef.isWritable) {
        throw NFCException('Tag is write-protected');
      }
      // Check if URL fits on tag
      final messageSize = message.byteLength;
      if (messageSize > ndef.maxSize) {
        throw NFCException(
          'URL too long for tag ($messageSize bytes > ${ndef.maxSize} max)',
        );
      }
      await ndef.writeNdefMessage(message);
    } else if (Platform.isIOS) {
      final ndef = NdefIos.from(tag);
      if (ndef == null) {
        throw NFCException('Tag does not support NDEF format');
      }
      if (ndef.status != NdefStatusIos.readWrite) {
        throw NFCException('Tag is write-protected');
      }
      await ndef.writeNdef(message);
    }
  }

  /// Write URL to NFC tag (legacy method for compatibility)
  Future<void> writeUrl(String url) async {
    if (_currentTag == null) {
      throw NFCException('No tag available. Scan a tag first.');
    }
    await _writeUrlToTag(_currentTag!, url);
  }

  /// Lock NTAG with password protection (Android only)
  Future<void> _lockTag(NfcTag tag, String password, {String? tagType}) async {
    if (!Platform.isAndroid) {
      throw NFCException('Password protection is only supported on Android');
    }

    final nfca = _getNfcA(tag);

    if (nfca == null) {
      throw NFCException('Tag does not support password protection');
    }

    // Use provided tagType or detect it
    final detectedType = tagType ?? await _detectNtagType(nfca);
    if (detectedType == null) {
      throw NFCException('Could not detect NTAG type for password protection');
    }

    // NTAG password is 4 bytes
    final pwdBytes = _passwordToBytes(password);

    // PACK (Password Acknowledge) - 2 bytes
    final packBytes = Uint8List.fromList([0x80, 0x80]);

    final (pwdPage, cfgPage) = _getNtagPages(detectedType);

    // Write password
    await nfca.transceive(Uint8List.fromList([0xA2, pwdPage, ...pwdBytes]));

    // Write PACK
    await nfca.transceive(
      Uint8List.fromList([0xA2, pwdPage + 1, ...packBytes, 0x00, 0x00]),
    );

    // Set AUTH0 to protect from page 4 (after header)
    // and enable write protection
    await nfca.transceive(
      Uint8List.fromList([0xA2, cfgPage, 0x04, 0x00, 0x00, 0x00]),
    );

    // Set ACCESS byte (PROT=0 for write-only protection)
    await nfca.transceive(
      Uint8List.fromList([0xA2, cfgPage + 1, 0x00, 0x05, 0x00, 0x00]),
    );
  }

  /// Detect NTAG type by reading capability container (Android only)
  Future<String?> _detectNtagType(NfcAAndroid nfca) async {
    try {
      // Read page 3 (CC - Capability Container)
      final response = await nfca.transceive(
        Uint8List.fromList([0x30, 0x03]), // READ command, page 3
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

  /// Authenticate with password before writing to locked tag (Android only)
  Future<bool> authenticate(String password) async {
    if (_currentTag == null) {
      throw NFCException('No tag available');
    }

    if (!Platform.isAndroid) {
      throw NFCException('Password authentication is only supported on Android');
    }

    final nfca = _getNfcA(_currentTag!);
    if (nfca == null) {
      throw NFCException('Tag does not support authentication');
    }

    final pwdBytes = _passwordToBytes(password);

    try {
      // PWD_AUTH command (0x1B) followed by 4-byte password
      final response = await nfca.transceive(
        Uint8List.fromList([0x1B, ...pwdBytes]),
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
        pollingOptions: {NfcPollingOption.iso14443, NfcPollingOption.iso15693},
        onDiscovered: (NfcTag tag) async {
          _currentTag = tag;

          final uid = _extractUid(tag);
          if (uid == null) {
            onError('Could not read tag UID');
            return;
          }

          try {
            final info = await _getTagInfo(tag);

            // Authenticate if password provided (Android only)
            if (password != null && password.isNotEmpty && Platform.isAndroid) {
              final nfca = _getNfcA(tag);
              if (nfca != null) {
                final pwdBytes = _passwordToBytes(password);
                try {
                  await nfca.transceive(Uint8List.fromList([0x1B, ...pwdBytes]));
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
      );
    } catch (e) {
      _sessionActive = false;
      onError('Failed to start NFC session: $e');
    }
  }

  /// Erase NDEF content from tag by writing an empty message
  Future<void> _eraseTag(NfcTag tag) async {
    // Write an empty NDEF message (this effectively erases the tag content)
    // We create a minimal empty record
    final record = _createTextRecord('');
    final emptyMessage = NdefMessage(records: [record]);

    if (Platform.isAndroid) {
      final ndef = NdefAndroid.from(tag);
      if (ndef == null) {
        throw NFCException('Tag does not support NDEF format');
      }
      if (!ndef.isWritable) {
        throw NFCException('Tag is write-protected. Cannot erase.');
      }
      await ndef.writeNdefMessage(emptyMessage);
    } else if (Platform.isIOS) {
      final ndef = NdefIos.from(tag);
      if (ndef == null) {
        throw NFCException('Tag does not support NDEF format');
      }
      if (ndef.status != NdefStatusIos.readWrite) {
        throw NFCException('Tag is write-protected. Cannot erase.');
      }
      await ndef.writeNdef(emptyMessage);
    }
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
