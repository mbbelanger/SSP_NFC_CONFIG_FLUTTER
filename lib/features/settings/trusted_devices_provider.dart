import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

import '../../core/api/graphql_client.dart';
import '../../core/api/graphql_mutations.dart';
import '../../core/api/graphql_queries.dart';
import '../../models/trusted_device.dart';

/// State for trusted devices management
class TrustedDevicesState {
  final bool isLoading;
  final List<TrustedDevice> devices;
  final int totalCount;
  final String? errorMessage;
  final String? currentDeviceId;

  const TrustedDevicesState({
    this.isLoading = false,
    this.devices = const [],
    this.totalCount = 0,
    this.errorMessage,
    this.currentDeviceId,
  });

  TrustedDevicesState copyWith({
    bool? isLoading,
    List<TrustedDevice>? devices,
    int? totalCount,
    String? errorMessage,
    String? currentDeviceId,
  }) {
    return TrustedDevicesState(
      isLoading: isLoading ?? this.isLoading,
      devices: devices ?? this.devices,
      totalCount: totalCount ?? this.totalCount,
      errorMessage: errorMessage,
      currentDeviceId: currentDeviceId ?? this.currentDeviceId,
    );
  }
}

/// Provider for trusted devices management
final trustedDevicesProvider =
    StateNotifierProvider<TrustedDevicesNotifier, TrustedDevicesState>((ref) {
  final client = ref.watch(graphqlRawClientProvider);
  return TrustedDevicesNotifier(client);
});

class TrustedDevicesNotifier extends StateNotifier<TrustedDevicesState> {
  final GraphQLClient _client;

  TrustedDevicesNotifier(this._client) : super(const TrustedDevicesState());

  /// Fetch all trusted devices
  Future<void> fetchDevices({String? currentDeviceId}) async {
    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      currentDeviceId: currentDeviceId,
    );

    try {
      final result = await _client.query(
        QueryOptions(
          document: gql(GraphQLQueries.trustedDevices),
          fetchPolicy: FetchPolicy.networkOnly,
        ),
      );

      if (result.hasException) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: result.exception?.graphqlErrors.firstOrNull?.message ??
              'Failed to fetch trusted devices',
        );
        return;
      }

      final data = result.data?['trustedDevices'];
      if (data != null) {
        final devicesList = (data['devices'] as List?)
                ?.map((d) => TrustedDevice.fromJson(d as Map<String, dynamic>))
                .toList() ??
            [];

        state = state.copyWith(
          isLoading: false,
          devices: devicesList,
          totalCount: data['count'] as int? ?? devicesList.length,
        );
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Network error. Please try again.',
      );
    }
  }

  /// Revoke a specific trusted device
  Future<bool> revokeDevice(String deviceId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final result = await _client.mutate(
        MutationOptions(
          document: gql(GraphQLMutations.revokeTrustedDevice),
          variables: {'deviceId': deviceId},
        ),
      );

      if (result.hasException) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: result.exception?.graphqlErrors.firstOrNull?.message ??
              'Failed to revoke device',
        );
        return false;
      }

      final data = result.data?['revokeTrustedDevice'];
      if (data != null && data['success'] == true) {
        // Remove the device from the list
        final updatedDevices =
            state.devices.where((d) => d.id != deviceId).toList();

        state = state.copyWith(
          isLoading: false,
          devices: updatedDevices,
          totalCount: updatedDevices.length,
        );
        return true;
      }

      state = state.copyWith(
        isLoading: false,
        errorMessage: data?['message'] ?? 'Failed to revoke device',
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Network error. Please try again.',
      );
      return false;
    }
  }

  /// Revoke all trusted devices
  Future<bool> revokeAllDevices() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final result = await _client.mutate(
        MutationOptions(
          document: gql(GraphQLMutations.revokeAllTrustedDevices),
        ),
      );

      if (result.hasException) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: result.exception?.graphqlErrors.firstOrNull?.message ??
              'Failed to revoke devices',
        );
        return false;
      }

      final data = result.data?['revokeAllTrustedDevices'];
      if (data != null && data['success'] == true) {
        state = state.copyWith(
          isLoading: false,
          devices: const [],
          totalCount: 0,
        );
        return true;
      }

      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to revoke devices',
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Network error. Please try again.',
      );
      return false;
    }
  }

  /// Clear error message
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  /// Reset state
  void reset() {
    state = const TrustedDevicesState();
  }
}
