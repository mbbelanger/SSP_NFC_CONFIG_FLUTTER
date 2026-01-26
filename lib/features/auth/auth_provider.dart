import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

import '../../core/api/graphql_client.dart';
import '../../core/api/graphql_mutations.dart';
import '../../core/storage/secure_storage.dart';
import '../../models/user.dart';
import '../../models/organization.dart';
import 'auth_state.dart';

final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final client = ref.watch(graphqlRawClientProvider);
  return AuthNotifier(client);
});

class AuthNotifier extends StateNotifier<AuthState> {
  final GraphQLClient _client;

  AuthNotifier(this._client) : super(const AuthState()) {
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    final isAuthenticated = await SecureStorage.isAuthenticated();
    if (isAuthenticated) {
      final userData = await SecureStorage.getUserData();
      final token = await SecureStorage.getToken();
      if (userData != null && token != null) {
        try {
          final user = User.fromJson(jsonDecode(userData));
          state = AuthState.authenticated(user: user, token: token);
        } catch (e) {
          await SecureStorage.clearAll();
          state = AuthState.unauthenticated();
        }
      } else {
        state = AuthState.unauthenticated();
      }
    } else {
      state = AuthState.unauthenticated();
    }
  }

  Future<void> login(String email, String password) async {
    state = AuthState.loading();

    try {
      final result = await _client.mutate(
        MutationOptions(
          document: gql(GraphQLMutations.loginSSPUser),
          variables: {
            'email': email,
            'password': password,
          },
        ),
      );

      if (result.hasException) {
        final message = result.exception?.graphqlErrors.firstOrNull?.message ??
            'Login failed. Please try again.';
        state = AuthState.error(message);
        return;
      }

      final data = result.data?['loginSSPUser'];
      if (data == null) {
        state = AuthState.error('Invalid response from server');
        return;
      }

      // Check if 2FA is required
      if (data['requiresTwoFactor'] == true) {
        state = state.copyWith(
          status: AuthStatus.requiresTwoFactor,
          challengeToken: data['challenge_token'],
        );
        return;
      }

      // Check if org selection is required
      if (data['requiresOrganizationSelection'] == true) {
        final orgs = (data['organizations'] as List)
            .map((o) => Organization.fromJson(o))
            .toList();
        state = state.copyWith(
          status: AuthStatus.requiresOrgSelection,
          selectionToken: data['selection_token'],
          organizations: orgs,
        );
        return;
      }

      // Direct login success
      await _handleLoginSuccess(data);
    } catch (e) {
      state = AuthState.error('Network error. Please check your connection.');
    }
  }

  Future<void> verifyTwoFactor(String code) async {
    if (state.challengeToken == null) {
      state = AuthState.error('Invalid state. Please try logging in again.');
      return;
    }

    state = state.copyWith(status: AuthStatus.loading);

    try {
      final result = await _client.mutate(
        MutationOptions(
          document: gql(GraphQLMutations.verifyTwoFactorAuthentication),
          variables: {
            'challengeToken': state.challengeToken,
            'code': code,
          },
        ),
      );

      if (result.hasException) {
        final message = result.exception?.graphqlErrors.firstOrNull?.message ??
            'Invalid code. Please try again.';
        state = state.copyWith(
          status: AuthStatus.requiresTwoFactor,
          errorMessage: message,
        );
        return;
      }

      final data = result.data?['verifyTwoFactorAuthentication'];
      if (data == null) {
        state = AuthState.error('Invalid response from server');
        return;
      }

      await _handleLoginSuccess(data);
    } catch (e) {
      state = AuthState.error('Network error. Please check your connection.');
    }
  }

  Future<void> selectOrganization(String organizationId) async {
    if (state.selectionToken == null) {
      state = AuthState.error('Invalid state. Please try logging in again.');
      return;
    }

    state = state.copyWith(status: AuthStatus.loading);

    try {
      final result = await _client.mutate(
        MutationOptions(
          document: gql(GraphQLMutations.selectOrganization),
          variables: {
            'selectionToken': state.selectionToken,
            'organizationId': organizationId,
          },
        ),
      );

      if (result.hasException) {
        final message = result.exception?.graphqlErrors.firstOrNull?.message ??
            'Failed to select organization.';
        state = state.copyWith(
          status: AuthStatus.requiresOrgSelection,
          errorMessage: message,
        );
        return;
      }

      final data = result.data?['selectOrganization'];
      if (data == null) {
        state = AuthState.error('Invalid response from server');
        return;
      }

      await _handleLoginSuccess(data);
    } catch (e) {
      state = AuthState.error('Network error. Please check your connection.');
    }
  }

  Future<void> _handleLoginSuccess(Map<String, dynamic> data) async {
    final token = data['token'] as String;
    final userData = data['user'] as Map<String, dynamic>;
    final user = User.fromJson(userData);

    await SecureStorage.saveToken(token);
    await SecureStorage.saveUserData(jsonEncode(userData));

    state = AuthState.authenticated(user: user, token: token);
  }

  Future<void> logout() async {
    await SecureStorage.clearAll();
    state = AuthState.unauthenticated();
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}
