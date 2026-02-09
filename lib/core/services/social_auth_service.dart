import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../../models/social_auth_credentials.dart';

/// Service for handling social authentication (Google and Apple Sign-In)
class SocialAuthService {
  static GoogleSignIn? _googleSignIn;

  /// Initialize Google Sign-In with appropriate client IDs
  static GoogleSignIn get _google {
    if (_googleSignIn == null) {
      final serverClientId = dotenv.env['GOOGLE_SERVER_CLIENT_ID'];

      _googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
        // serverClientId is required on Android to get authCode for backend exchange
        serverClientId: serverClientId,
      );
    }
    return _googleSignIn!;
  }

  /// Sign in with Google
  /// Returns credentials on success, null if cancelled
  static Future<SocialAuthCredentials?> signInWithGoogle() async {
    try {
      // Sign out first to ensure account picker is shown
      await _google.signOut();

      final account = await _google.signIn();
      if (account == null) {
        // User cancelled
        return null;
      }

      final auth = await account.authentication;

      return SocialAuthCredentials(
        provider: SocialProvider.google,
        accessToken: auth.accessToken,
        idToken: auth.idToken,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Sign in with Apple (iOS only)
  /// Returns credentials on success, null if cancelled
  static Future<SocialAuthCredentials?> signInWithApple() async {
    if (!Platform.isIOS) {
      throw UnsupportedError('Apple Sign-In is only available on iOS');
    }

    try {
      // Generate a secure nonce for Apple Sign-In
      final rawNonce = _generateNonce();
      final nonce = _sha256ofString(rawNonce);

      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );

      return SocialAuthCredentials(
        provider: SocialProvider.apple,
        idToken: credential.identityToken,
        authCode: credential.authorizationCode,
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        // User cancelled
        return null;
      }
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  /// Sign out from all social providers
  static Future<void> signOut() async {
    try {
      await _google.signOut();
    } catch (_) {
      // Ignore sign out errors
    }
  }

  /// Check if Apple Sign-In is available (iOS only)
  static bool get isAppleSignInAvailable => Platform.isIOS;

  /// Generate a cryptographically secure random nonce
  static String _generateNonce([int length = 32]) {
    const charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)]).join();
  }

  /// SHA256 hash of input string
  static String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
