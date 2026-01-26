import '../../models/user.dart';
import '../../models/organization.dart';

enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  requiresTwoFactor,
  requiresOrgSelection,
  error,
}

class AuthState {
  final AuthStatus status;
  final User? user;
  final String? token;
  final String? challengeToken;
  final String? selectionToken;
  final List<Organization>? organizations;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.token,
    this.challengeToken,
    this.selectionToken,
    this.organizations,
    this.errorMessage,
  });

  bool get isAuthenticated => status == AuthStatus.authenticated && token != null;
  bool get isLoading => status == AuthStatus.loading;

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    String? token,
    String? challengeToken,
    String? selectionToken,
    List<Organization>? organizations,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      token: token ?? this.token,
      challengeToken: challengeToken ?? this.challengeToken,
      selectionToken: selectionToken ?? this.selectionToken,
      organizations: organizations ?? this.organizations,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  factory AuthState.initial() => const AuthState();

  factory AuthState.loading() => const AuthState(status: AuthStatus.loading);

  factory AuthState.authenticated({required User user, required String token}) {
    return AuthState(
      status: AuthStatus.authenticated,
      user: user,
      token: token,
    );
  }

  factory AuthState.unauthenticated() {
    return const AuthState(status: AuthStatus.unauthenticated);
  }

  factory AuthState.error(String message) {
    return AuthState(
      status: AuthStatus.error,
      errorMessage: message,
    );
  }
}
