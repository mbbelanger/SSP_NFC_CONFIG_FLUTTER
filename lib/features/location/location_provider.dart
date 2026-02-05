import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

import '../../core/api/graphql_client.dart';
import '../../core/api/graphql_queries.dart';
import '../../models/location.dart';
import '../auth/auth_provider.dart';

class LocationState {
  final bool isLoading;
  final List<Location> locations;
  final String? errorMessage;

  const LocationState({
    this.isLoading = false,
    this.locations = const [],
    this.errorMessage,
  });

  LocationState copyWith({
    bool? isLoading,
    List<Location>? locations,
    String? errorMessage,
  }) {
    return LocationState(
      isLoading: isLoading ?? this.isLoading,
      locations: locations ?? this.locations,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  Map<String, List<Location>> get locationsByOrganization {
    final map = <String, List<Location>>{};
    for (final location in locations) {
      final orgName = location.organization?.name ?? 'Unknown Organization';
      map.putIfAbsent(orgName, () => []).add(location);
    }
    return map;
  }
}

// Use autoDispose so provider is recreated when auth state changes
final locationStateProvider =
    StateNotifierProvider.autoDispose<LocationNotifier, LocationState>((ref) {
  final client = ref.watch(graphqlRawClientProvider);

  // Watch auth state - when it changes, this provider will be recreated
  final authState = ref.watch(authStateProvider);

  // Only create notifier and load locations if authenticated
  final notifier = LocationNotifier(client);
  if (authState.isAuthenticated) {
    // Delay loading to ensure token is available in AuthLink
    Future.microtask(() => notifier.loadLocations());
  }
  return notifier;
});

class LocationNotifier extends StateNotifier<LocationState> {
  final GraphQLClient _client;

  LocationNotifier(this._client) : super(const LocationState());

  Future<void> loadLocations() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final result = await _client.query(
        QueryOptions(
          document: gql(GraphQLQueries.getUserLocations),
          fetchPolicy: FetchPolicy.networkOnly,
        ),
      );

      if (result.hasException) {
        final message = result.exception?.graphqlErrors.firstOrNull?.message ??
            'Failed to load locations';
        state = state.copyWith(isLoading: false, errorMessage: message);
        return;
      }

      final data = result.data?['getUserLocations'] as List<dynamic>?;
      if (data == null) {
        state = state.copyWith(isLoading: false, errorMessage: 'No data received');
        return;
      }

      final locations = data
          .map((json) => Location.fromJson(json as Map<String, dynamic>))
          .toList();

      state = state.copyWith(isLoading: false, locations: locations);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Network error. Please try again.',
      );
    }
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}
