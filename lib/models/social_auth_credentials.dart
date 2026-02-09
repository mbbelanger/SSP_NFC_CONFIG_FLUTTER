/// Supported social login providers
enum SocialProvider {
  google,
  apple,
}

/// Credentials returned from social login SDK
class SocialAuthCredentials {
  final SocialProvider provider;
  final String? accessToken;
  final String? idToken;
  final String? authCode;

  const SocialAuthCredentials({
    required this.provider,
    this.accessToken,
    this.idToken,
    this.authCode,
  });

  /// Convert provider to GraphQL enum value
  String get providerName => provider.name.toUpperCase();
}
