import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

import '../../core/api/graphql_client.dart';
import '../../core/api/graphql_queries.dart';
import '../../models/legal_document.dart';

/// State for legal document viewing
class LegalDocumentState {
  final bool isLoading;
  final LegalDocument? document;
  final String? errorMessage;

  const LegalDocumentState({
    this.isLoading = false,
    this.document,
    this.errorMessage,
  });

  LegalDocumentState copyWith({
    bool? isLoading,
    LegalDocument? document,
    String? errorMessage,
  }) {
    return LegalDocumentState(
      isLoading: isLoading ?? this.isLoading,
      document: document ?? this.document,
      errorMessage: errorMessage,
    );
  }
}

/// Provider for legal document viewing
final legalDocumentProvider =
    StateNotifierProvider<LegalDocumentNotifier, LegalDocumentState>((ref) {
  final client = ref.watch(graphqlRawClientProvider);
  return LegalDocumentNotifier(client);
});

class LegalDocumentNotifier extends StateNotifier<LegalDocumentState> {
  final GraphQLClient _client;

  LegalDocumentNotifier(this._client) : super(const LegalDocumentState());

  /// Fetch a legal document by type
  Future<void> fetchDocument(LegalDocumentType type, {String locale = 'en'}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final result = await _client.query(
        QueryOptions(
          document: gql(GraphQLQueries.legalDocument),
          variables: {
            'type': type.value,
            'locale': locale,
          },
          fetchPolicy: FetchPolicy.cacheFirst,
        ),
      );

      if (result.hasException) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: result.exception?.graphqlErrors.firstOrNull?.message ??
              'Failed to fetch legal document',
        );
        return;
      }

      final data = result.data?['legalDocument'];
      if (data != null) {
        final document = LegalDocument.fromJson(data as Map<String, dynamic>);
        state = state.copyWith(
          isLoading: false,
          document: document,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Document not found',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Network error. Please try again.',
      );
    }
  }

  /// Clear error message
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  /// Reset state
  void reset() {
    state = const LegalDocumentState();
  }
}
