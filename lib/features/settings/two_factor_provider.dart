import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

import '../../core/api/graphql_client.dart';
import '../../core/api/graphql_mutations.dart';
import '../../core/api/graphql_queries.dart';
import '../../models/two_factor_status.dart';

/// State for 2FA setup and management
class TwoFactorSetupState {
  final bool isLoading;
  final TwoFactorStatus? status;
  final TwoFactorAvailability? availability;
  final String? qrCode;
  final String? setupMessage;
  final List<String>? recoveryCodes;
  final String? errorMessage;
  final TwoFactorSetupStep currentStep;

  const TwoFactorSetupState({
    this.isLoading = false,
    this.status,
    this.availability,
    this.qrCode,
    this.setupMessage,
    this.recoveryCodes,
    this.errorMessage,
    this.currentStep = TwoFactorSetupStep.initial,
  });

  TwoFactorSetupState copyWith({
    bool? isLoading,
    TwoFactorStatus? status,
    TwoFactorAvailability? availability,
    String? qrCode,
    String? setupMessage,
    List<String>? recoveryCodes,
    String? errorMessage,
    TwoFactorSetupStep? currentStep,
  }) {
    return TwoFactorSetupState(
      isLoading: isLoading ?? this.isLoading,
      status: status ?? this.status,
      availability: availability ?? this.availability,
      qrCode: qrCode ?? this.qrCode,
      setupMessage: setupMessage ?? this.setupMessage,
      recoveryCodes: recoveryCodes ?? this.recoveryCodes,
      errorMessage: errorMessage,
      currentStep: currentStep ?? this.currentStep,
    );
  }
}

/// Steps in the 2FA setup flow
enum TwoFactorSetupStep {
  initial,
  selectChannel,
  enterPhone,
  scanQrCode,
  verifyCode,
  showRecoveryCodes,
  complete,
}

/// Provider for 2FA setup and management
final twoFactorSetupProvider =
    StateNotifierProvider<TwoFactorSetupNotifier, TwoFactorSetupState>((ref) {
  final client = ref.watch(graphqlRawClientProvider);
  return TwoFactorSetupNotifier(client);
});

class TwoFactorSetupNotifier extends StateNotifier<TwoFactorSetupState> {
  final GraphQLClient _client;

  TwoFactorSetupNotifier(this._client) : super(const TwoFactorSetupState());

  /// Fetch current 2FA status
  Future<void> fetchStatus() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final result = await _client.query(
        QueryOptions(
          document: gql(GraphQLQueries.twoFactorStatus),
          fetchPolicy: FetchPolicy.networkOnly,
        ),
      );

      if (result.hasException) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: result.exception?.graphqlErrors.firstOrNull?.message ??
              'Failed to fetch 2FA status',
        );
        return;
      }

      final data = result.data?['twoFactorStatus'];
      if (data != null) {
        state = state.copyWith(
          isLoading: false,
          status: TwoFactorStatus.fromJson(data),
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

  /// Fetch available 2FA channels
  Future<void> fetchAvailability() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final result = await _client.query(
        QueryOptions(
          document: gql(GraphQLQueries.twoFactorAvailability),
          fetchPolicy: FetchPolicy.networkOnly,
        ),
      );

      if (result.hasException) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: result.exception?.graphqlErrors.firstOrNull?.message ??
              'Failed to fetch 2FA options',
        );
        return;
      }

      final data = result.data?['twoFactorAvailability'];
      if (data != null) {
        state = state.copyWith(
          isLoading: false,
          availability: TwoFactorAvailability.fromJson(data),
          currentStep: TwoFactorSetupStep.selectChannel,
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

  /// Enable 2FA with the selected channel
  Future<void> enableTwoFactor(TwoFactorChannel channel, {String? phone}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final channelName = channel.name.toUpperCase();

      final result = await _client.mutate(
        MutationOptions(
          document: gql(GraphQLMutations.enableTwoFactorAuthentication),
          variables: {
            'channel': channelName,
            'phone': phone,
          },
        ),
      );

      if (result.hasException) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: result.exception?.graphqlErrors.firstOrNull?.message ??
              'Failed to enable 2FA',
        );
        return;
      }

      final data = result.data?['enableTwoFactorAuthentication'];
      if (data != null) {
        state = state.copyWith(
          isLoading: false,
          qrCode: data['qr_code'] as String?,
          setupMessage: data['message'] as String?,
          currentStep: channel == TwoFactorChannel.totp
              ? TwoFactorSetupStep.scanQrCode
              : TwoFactorSetupStep.verifyCode,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Invalid response from server',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Network error. Please try again.',
      );
    }
  }

  /// Confirm 2FA setup with verification code
  Future<void> confirmSetup(String code) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final result = await _client.mutate(
        MutationOptions(
          document: gql(GraphQLMutations.confirmTwoFactorAuthentication),
          variables: {'code': code},
        ),
      );

      if (result.hasException) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: result.exception?.graphqlErrors.firstOrNull?.message ??
              'Invalid code. Please try again.',
        );
        return;
      }

      final data = result.data?['confirmTwoFactorAuthentication'];
      if (data != null && data['success'] == true) {
        final codes = (data['recovery_codes'] as List?)
            ?.map((c) => c.toString())
            .toList();

        state = state.copyWith(
          isLoading: false,
          recoveryCodes: codes,
          currentStep: TwoFactorSetupStep.showRecoveryCodes,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Verification failed. Please try again.',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Network error. Please try again.',
      );
    }
  }

  /// Disable 2FA
  Future<bool> disableTwoFactor({String? password, String? code}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final result = await _client.mutate(
        MutationOptions(
          document: gql(GraphQLMutations.disableTwoFactorAuthentication),
          variables: {
            'currentPassword': password,
            'code': code,
          },
        ),
      );

      if (result.hasException) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: result.exception?.graphqlErrors.firstOrNull?.message ??
              'Failed to disable 2FA',
        );
        return false;
      }

      state = state.copyWith(
        isLoading: false,
        status: const TwoFactorStatus(isEnabled: false),
        currentStep: TwoFactorSetupStep.initial,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Network error. Please try again.',
      );
      return false;
    }
  }

  /// Regenerate recovery codes
  Future<List<String>?> regenerateRecoveryCodes(String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final result = await _client.mutate(
        MutationOptions(
          document: gql(GraphQLMutations.regenerateTwoFactorRecoveryCodes),
          variables: {'password': password},
        ),
      );

      if (result.hasException) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: result.exception?.graphqlErrors.firstOrNull?.message ??
              'Failed to regenerate codes',
        );
        return null;
      }

      final data = result.data?['regenerateTwoFactorRecoveryCodes'];
      if (data != null) {
        final codes = (data['recovery_codes'] as List?)
            ?.map((c) => c.toString())
            .toList();

        state = state.copyWith(
          isLoading: false,
          recoveryCodes: codes,
        );
        return codes;
      }

      state = state.copyWith(isLoading: false);
      return null;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Network error. Please try again.',
      );
      return null;
    }
  }

  /// Move to phone entry step for SMS
  void goToPhoneEntry() {
    state = state.copyWith(currentStep: TwoFactorSetupStep.enterPhone);
  }

  /// Complete the setup flow
  void completeSetup() {
    state = state.copyWith(
      currentStep: TwoFactorSetupStep.complete,
      recoveryCodes: null,
    );
  }

  /// Reset state to initial
  void reset() {
    state = const TwoFactorSetupState();
  }

  /// Clear error message
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}
