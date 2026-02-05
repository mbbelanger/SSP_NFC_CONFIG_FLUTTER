import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

import '../../core/api/graphql_client.dart';
import '../../core/api/graphql_mutations.dart';
import '../../core/api/graphql_queries.dart';
import '../../core/nfc/nfc_service.dart';
import '../../core/nfc/nfc_tag_detector.dart';
import '../../models/nfc_tag.dart';
import '../../models/table.dart';
import 'scan_state.dart';

// NFC Service Provider
final nfcServiceProvider = Provider<NFCService>((ref) => NFCService());

// Tables Provider for a specific location
final tablesProvider = FutureProvider.family<List<SSPTable>, String>(
  (ref, locationId) async {
    final client = ref.watch(graphqlRawClientProvider);

    final result = await client.query(
      QueryOptions(
        document: gql(GraphQLQueries.getLocationTables),
        variables: {'locationId': locationId},
        fetchPolicy: FetchPolicy.networkOnly,
      ),
    );

    if (result.hasException) {
      throw Exception(
        result.exception?.graphqlErrors.firstOrNull?.message ??
            'Failed to load tables',
      );
    }

    final data = result.data?['getLocationTables'] as List<dynamic>?;
    if (data == null) return [];

    return data
        .map((json) => SSPTable.fromJson(json as Map<String, dynamic>))
        .toList();
  },
);

// Delete NFC Tag function provider
Future<bool> deleteNfcTag(GraphQLClient client, String tagId) async {
  final result = await client.mutate(
    MutationOptions(
      document: gql(GraphQLMutations.deleteNFCTag),
      variables: {'id': tagId},
    ),
  );

  if (result.hasException) {
    throw Exception(
      result.exception?.graphqlErrors.firstOrNull?.message ??
          'Failed to delete NFC tag',
    );
  }

  return result.data?['deleteNFCTag'] == true;
}

// Scan State Provider
final scanStateProvider =
    StateNotifierProvider.autoDispose<ScanNotifier, ScanState>((ref) {
  final nfcService = ref.watch(nfcServiceProvider);
  final client = ref.watch(graphqlRawClientProvider);
  return ScanNotifier(nfcService, client);
});

class ScanNotifier extends StateNotifier<ScanState> {
  final NFCService _nfcService;
  final GraphQLClient _client;
  Completer<void>? _writeCompleter;

  ScanNotifier(this._nfcService, this._client) : super(const ScanState()) {
    _initialize();
  }

  Future<void> _initialize() async {
    final isAvailable = await _nfcService.isAvailable();

    if (!isAvailable) {
      state = state.copyWith(
        status: ScanStatus.error,
        errorMessage: 'NFC is not available on this device',
      );
      return;
    }

    await startScanning();
  }

  Future<void> startScanning() async {
    state = state.reset();

    // Use startReadSession to get tag content for DNA detection
    await _nfcService.startReadSession(
      onTagRead: (uid, info, content) {
        // Detect tag type from content
        final detection = NFCTagDetector.detect(content);
        final isDna = detection.kind == NFCTagKind.dna;

        state = state.copyWith(
          status: ScanStatus.tagDetected,
          detectedUid: uid,
          tagInfo: info,
          tagContent: content,
          detectedTagType: detection,
          dnaParams: detection.dnaParams,
          isDnaTag: isDna,
          // Auto-disable write URL for DNA tags (they're pre-encoded)
          writeUrlEnabled: isDna ? false : state.writeUrlEnabled,
        );
      },
      onError: (error) {
        state = state.copyWith(
          status: ScanStatus.error,
          errorMessage: error,
        );
      },
    );
  }

  /// Start test/read mode to verify tag content
  Future<void> startTestMode() async {
    _nfcService.stopSession();
    state = state.copyWith(
      status: ScanStatus.ready,
      errorMessage: 'Test mode: Tap tag to read content',
    );

    await _nfcService.startReadSession(
      onTagRead: (uid, info, content) {
        state = state.copyWith(
          status: ScanStatus.tagDetected,
          detectedUid: uid,
          tagInfo: info,
          tagContent: content,
          errorMessage: null,
        );
      },
      onError: (error) {
        state = state.copyWith(
          status: ScanStatus.error,
          errorMessage: error,
        );
      },
    );
  }

  void selectTable(String tableId) {
    state = state.copyWith(selectedTableId: tableId);
  }

  void toggleWriteUrl(bool enabled) {
    state = state.copyWith(writeUrlEnabled: enabled);
  }

  void setPassword(String? password) {
    state = state.copyWith(lockPassword: password);
  }

  /// Register or claim tag based on detected type.
  Future<void> registerTag({
    required String tableId,
    required String tableName,
    String? label,
  }) async {
    if (state.isDnaTag) {
      await _claimDnaTag(tableId: tableId, tableName: tableName, label: label);
    } else {
      await _registerStaticTag(tableId: tableId, tableName: tableName, label: label);
    }
  }

  /// Claim a DNA tag from inventory (no writing needed).
  Future<void> _claimDnaTag({
    required String tableId,
    required String tableName,
    String? label,
  }) async {
    final dnaParams = state.dnaParams;
    if (dnaParams == null) {
      state = state.copyWith(
        status: ScanStatus.error,
        errorMessage: 'DNA tag parameters not detected',
      );
      return;
    }

    state = state.copyWith(status: ScanStatus.claiming);

    try {
      final result = await _client.mutate(
        MutationOptions(
          document: gql(GraphQLMutations.claimNFCTag),
          variables: {
            'input': {
              'uid': dnaParams.uid, // Already in compact format from URL
              'tableId': tableId,
              'label': label,
            },
          },
        ),
      );

      if (result.hasException) {
        final graphqlError = result.exception?.graphqlErrors.firstOrNull;
        final code = graphqlError?.extensions?['code'];

        String message;
        switch (code) {
          case 'TAG_NOT_IN_INVENTORY':
            message = 'This DNA tag is not in the inventory. Was it imported?';
            break;
          case 'TAG_ALREADY_CLAIMED':
            message = 'This DNA tag has already been claimed by another organization.';
            break;
          case 'NFC_UID_DUPLICATE':
            message = 'This NFC tag is already registered to another table.';
            break;
          case 'TABLE_HAS_ACTIVE_TAG':
            message = 'This table already has an active NFC tag.';
            break;
          case 'PERMISSION_DENIED':
            message = "You don't have permission to manage NFC tags.";
            break;
          default:
            message = graphqlError?.message ?? 'Failed to claim DNA tag';
        }

        _addHistoryEntry(dnaParams.uid, tableId, tableName, false, message);
        state = state.copyWith(
          status: ScanStatus.error,
          errorMessage: message,
        );
        return;
      }

      final tagData = result.data!['claimNFCTag'];
      final tag = NFCTag.fromJson(tagData);

      // DNA tags are pre-encoded - no writing step needed
      _addHistoryEntry(dnaParams.uid, tableId, tableName, true, null);
      state = state.copyWith(
        status: ScanStatus.success,
        registeredTag: tag,
        lastRegisteredTableName: tableName,
      );
    } catch (e) {
      _addHistoryEntry(dnaParams.uid, tableId, tableName, false, 'Network error');
      state = state.copyWith(
        status: ScanStatus.error,
        errorMessage: 'Network error. Please try again.',
      );
    }
  }

  /// Register a static NTAG 21x tag (existing flow with optional URL writing).
  Future<void> _registerStaticTag({
    required String tableId,
    required String tableName,
    String? label,
  }) async {
    final uid = state.detectedUid;
    if (uid == null) return;

    state = state.copyWith(status: ScanStatus.registering);

    try {
      // Step 1: Register with backend
      final result = await _client.mutate(
        MutationOptions(
          document: gql(GraphQLMutations.registerNFCTag),
          variables: {
            'input': {
              'uid': uid,
              'tableId': tableId,
              'label': label,
            },
          },
        ),
      );

      if (result.hasException) {
        final graphqlError = result.exception?.graphqlErrors.firstOrNull;
        final code = graphqlError?.extensions?['code'];

        String message;
        switch (code) {
          case 'NFC_UID_DUPLICATE':
            message = 'This NFC tag is already registered to another table.';
            break;
          case 'TABLE_HAS_ACTIVE_TAG':
            message = 'This table already has an active NFC tag.';
            break;
          case 'PERMISSION_DENIED':
            message = "You don't have permission to manage NFC tags.";
            break;
          default:
            message = graphqlError?.message ?? 'Registration failed';
        }

        _addHistoryEntry(uid, tableId, tableName, false, message);
        state = state.copyWith(
          status: ScanStatus.error,
          errorMessage: message,
        );
        return;
      }

      final tagData = result.data!['registerNFCTag'];
      final tag = NFCTag.fromJson(tagData);
      final urlToWrite = tagData['writtenUrl'] as String?;

      // Step 2: Write URL to tag if enabled
      if (state.writeUrlEnabled && urlToWrite != null) {
        state = state.copyWith(
          status: ScanStatus.writing,
          pendingUrl: urlToWrite,
          registeredTag: tag,
        );

        // Stop current session and start write session
        _nfcService.stopSession();

        _writeCompleter = Completer<void>();
        String? writeError;
        bool writeSuccess = false;

        await _nfcService.startWriteSession(
          url: urlToWrite,
          password: state.lockPassword,
          onSuccess: (writtenUid, info) {
            writeSuccess = true;
            _writeCompleter?.complete();
          },
          onError: (error) {
            writeError = error;
            _writeCompleter?.complete();
          },
        );

        // Wait for user to tap tag again (with timeout)
        try {
          await _writeCompleter!.future.timeout(
            const Duration(seconds: 60),
            onTimeout: () {
              writeError = 'Write timed out. Tag registered but not written.';
            },
          );
        } catch (e) {
          writeError = e.toString();
        }

        _nfcService.stopSession();
        _writeCompleter = null;

        if (!writeSuccess && writeError != null) {
          _addHistoryEntry(uid, tableId, tableName, true, 'URL write failed: $writeError');
          state = state.copyWith(
            status: ScanStatus.success,
            registeredTag: tag,
            lastRegisteredTableName: tableName,
            errorMessage: 'Tag registered but URL write failed: $writeError',
            pendingUrl: null,
          );
          return;
        }
      }

      _addHistoryEntry(uid, tableId, tableName, true, null);
      state = state.copyWith(
        status: ScanStatus.success,
        registeredTag: tag,
        lastRegisteredTableName: tableName,
        pendingUrl: null,
      );
    } catch (e) {
      _addHistoryEntry(uid, tableId, tableName, false, 'Network error');
      state = state.copyWith(
        status: ScanStatus.error,
        errorMessage: 'Network error. Please try again.',
      );
    }
  }

  /// Write URL directly to a tag (without backend registration)
  Future<void> writeUrlOnly({
    required String url,
    String? password,
  }) async {
    state = state.copyWith(
      status: ScanStatus.writing,
      pendingUrl: url,
    );

    _nfcService.stopSession();

    _writeCompleter = Completer<void>();
    String? writeError;
    bool writeSuccess = false;

    await _nfcService.startWriteSession(
      url: url,
      password: password,
      onSuccess: (uid, info) {
        writeSuccess = true;
        state = state.copyWith(
          detectedUid: uid,
          tagInfo: info,
        );
        _writeCompleter?.complete();
      },
      onError: (error) {
        writeError = error;
        _writeCompleter?.complete();
      },
    );

    // Wait for write
    try {
      await _writeCompleter!.future.timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          writeError = 'Write timed out';
        },
      );
    } catch (e) {
      writeError = e.toString();
    }

    _nfcService.stopSession();
    _writeCompleter = null;

    if (writeSuccess) {
      state = state.copyWith(
        status: ScanStatus.success,
        errorMessage: 'URL written successfully!',
        pendingUrl: null,
      );
    } else {
      state = state.copyWith(
        status: ScanStatus.error,
        errorMessage: writeError ?? 'Failed to write URL',
        pendingUrl: null,
      );
    }
  }

  /// Erase/delete content from a tag
  Future<void> eraseTag({String? password}) async {
    state = state.copyWith(
      status: ScanStatus.erasing,
      errorMessage: 'Tap tag to erase content',
    );

    _nfcService.stopSession();

    _writeCompleter = Completer<void>();
    String? eraseError;
    bool eraseSuccess = false;

    await _nfcService.startEraseSession(
      password: password,
      onSuccess: (uid, info) {
        eraseSuccess = true;
        state = state.copyWith(
          detectedUid: uid,
          tagInfo: info,
        );
        _writeCompleter?.complete();
      },
      onError: (error) {
        eraseError = error;
        _writeCompleter?.complete();
      },
    );

    // Wait for erase
    try {
      await _writeCompleter!.future.timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          eraseError = 'Erase timed out';
        },
      );
    } catch (e) {
      eraseError = e.toString();
    }

    _nfcService.stopSession();
    _writeCompleter = null;

    if (eraseSuccess) {
      state = state.copyWith(
        status: ScanStatus.success,
        errorMessage: 'Tag erased successfully!',
      );
    } else {
      state = state.copyWith(
        status: ScanStatus.error,
        errorMessage: eraseError ?? 'Failed to erase tag',
      );
    }
  }

  void _addHistoryEntry(String uid, String tableId, String tableName, bool success, String? error) {
    final entry = SessionHistoryEntry(
      nfcUid: uid,
      tableId: tableId,
      tableName: tableName,
      timestamp: DateTime.now(),
      success: success,
      errorMessage: error,
    );
    state = state.copyWith(
      sessionHistory: [...state.sessionHistory, entry],
    );
  }

  void resetForNextTag() {
    _writeCompleter?.complete();
    _writeCompleter = null;
    _nfcService.stopSession();
    startScanning();
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  @override
  void dispose() {
    _writeCompleter?.complete();
    _nfcService.stopSession();
    super.dispose();
  }
}
