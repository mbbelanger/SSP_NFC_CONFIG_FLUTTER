import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

import '../../core/api/graphql_client.dart';
import '../../core/api/graphql_mutations.dart';
import '../../core/api/graphql_queries.dart';
import '../../core/nfc/nfc_service.dart';
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

    await _nfcService.startSession(
      onTagDetected: (uid, tag) {
        state = state.copyWith(
          status: ScanStatus.tagDetected,
          detectedUid: uid,
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

  Future<void> registerTag({
    required String tableId,
    required String tableName,
    String? label,
  }) async {
    final uid = state.detectedUid;
    if (uid == null) return;

    state = state.copyWith(status: ScanStatus.registering);

    try {
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

      // Write URL to tag if enabled
      if (state.writeUrlEnabled && tagData['writtenUrl'] != null) {
        state = state.copyWith(status: ScanStatus.writing);

        try {
          await _nfcService.writeUrl(tagData['writtenUrl']);
        } catch (e) {
          // URL write failed, but registration succeeded
          _addHistoryEntry(uid, tableId, tableName, true, 'URL write failed: $e');
          state = state.copyWith(
            status: ScanStatus.success,
            registeredTag: tag,
            lastRegisteredTableName: tableName,
            errorMessage: 'Tag registered but URL write failed: $e',
          );
          return;
        }
      }

      _addHistoryEntry(uid, tableId, tableName, true, null);
      state = state.copyWith(
        status: ScanStatus.success,
        registeredTag: tag,
        lastRegisteredTableName: tableName,
      );
    } catch (e) {
      _addHistoryEntry(uid, tableId, tableName, false, 'Network error');
      state = state.copyWith(
        status: ScanStatus.error,
        errorMessage: 'Network error. Please try again.',
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
    _nfcService.stopSession();
    startScanning();
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  @override
  void dispose() {
    _nfcService.stopSession();
    super.dispose();
  }
}
