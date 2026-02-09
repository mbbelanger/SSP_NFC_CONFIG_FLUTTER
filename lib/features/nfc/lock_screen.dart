import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/reauth_service.dart';
import '../../core/storage/secure_storage.dart';
import '../../core/theme/app_theme.dart';
import '../auth/auth_provider.dart';
import 'pin_entry_widget.dart';

/// Lock screen shown after session timeout
class LockScreen extends ConsumerStatefulWidget {
  final String? returnRoute;

  const LockScreen({
    super.key,
    this.returnRoute,
  });

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  bool _isLoading = false;
  String? _errorMessage;
  int? _attemptsRemaining;
  Duration? _lockoutRemaining;
  bool _showPinEntry = false;
  bool _biometricAvailable = false;

  @override
  void initState() {
    super.initState();
    _checkAuthMethods();
  }

  Future<void> _checkAuthMethods() async {
    final biometricAvailable = await ReAuthService.isBiometricAvailable();
    final hasPinSetup = await SecureStorage.hasPinSetup();
    final isLockedOut = await SecureStorage.isPinLockedOut();

    if (mounted) {
      setState(() {
        _biometricAvailable = biometricAvailable;
        // Show PIN entry if no biometric or user chooses PIN
        _showPinEntry = !biometricAvailable || !hasPinSetup;
      });

      if (isLockedOut) {
        final lockoutUntil = await SecureStorage.getPinLockoutUntil();
        if (lockoutUntil != null) {
          setState(() {
            _lockoutRemaining = lockoutUntil.difference(DateTime.now());
          });
          _startLockoutCountdown();
        }
      }

      // Auto-trigger biometric if available
      if (biometricAvailable && !isLockedOut) {
        _handleBiometric();
      }
    }
  }

  void _startLockoutCountdown() {
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;

      setState(() {
        if (_lockoutRemaining != null) {
          final newDuration = _lockoutRemaining! - const Duration(seconds: 1);
          if (newDuration.inSeconds <= 0) {
            _lockoutRemaining = null;
            SecureStorage.clearPinLockout();
          } else {
            _lockoutRemaining = newDuration;
            _startLockoutCountdown();
          }
        }
      });
    });
  }

  Future<void> _handleBiometric() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await ReAuthService.authenticateWithBiometric(
      reason: 'Verify your identity to unlock the app',
    );

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (result.success) {
      _unlockAndNavigate();
    } else if (result.errorMessage != null &&
               result.errorMessage != 'Authentication cancelled') {
      setState(() {
        _errorMessage = result.errorMessage;
        _showPinEntry = true;
      });
    }
  }

  Future<void> _handlePinCompleted(String pin) async {
    // Check if locked out
    if (await SecureStorage.isPinLockedOut()) {
      final lockoutUntil = await SecureStorage.getPinLockoutUntil();
      if (lockoutUntil != null) {
        setState(() {
          _lockoutRemaining = lockoutUntil.difference(DateTime.now());
        });
        _startLockoutCountdown();
      }
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Verify PIN
    final storedHash = await SecureStorage.getPinHash();
    final inputHash = sha256.convert(utf8.encode(pin)).toString();

    if (storedHash == inputHash) {
      // Success - reset attempts and unlock
      await SecureStorage.resetPinAttempts();
      if (mounted) {
        _unlockAndNavigate();
      }
    } else {
      // Failed - increment attempts
      await SecureStorage.incrementPinAttempts();
      final attempts = await SecureStorage.getPinAttempts();

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        // Progressive lockout: 30s (4-5), 2min (6-8), 15min (9), disabled (10)
        if (attempts >= 10) {
          // PIN disabled - force full re-login
          await SecureStorage.deletePinHash();
          await ref.read(authStateProvider.notifier).logout();
          if (mounted) {
            context.go('/login');
          }
        } else if (attempts >= 9) {
          _setLockout(const Duration(minutes: 15));
        } else if (attempts >= 6) {
          _setLockout(const Duration(minutes: 2));
        } else if (attempts >= 4) {
          _setLockout(const Duration(seconds: 30));
        } else {
          setState(() {
            _attemptsRemaining = 10 - attempts;
            _errorMessage = 'Incorrect PIN';
          });
        }
      }
    }
  }

  Future<void> _setLockout(Duration duration) async {
    final lockoutUntil = DateTime.now().add(duration);
    await SecureStorage.setPinLockoutUntil(lockoutUntil);

    setState(() {
      _lockoutRemaining = duration;
      _errorMessage = null;
    });
    _startLockoutCountdown();
  }

  void _unlockAndNavigate() {
    if (widget.returnRoute != null) {
      context.go(widget.returnRoute!);
    } else {
      context.go('/locations');
    }
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text(
          'Are you sure you want to log out? You will need to sign in again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(authStateProvider.notifier).logout();
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),

              // Lock icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_outline,
                  color: AppColors.primary,
                  size: 40,
                ),
              ),
              const SizedBox(height: 24),

              // Title
              const Text(
                'Session Locked',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Verify your identity to continue',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
              ),

              const SizedBox(height: 48),

              // Auth method
              if (_showPinEntry)
                PinEntryWidget(
                  title: 'Enter PIN',
                  errorMessage: _errorMessage,
                  isLoading: _isLoading,
                  attemptsRemaining: _attemptsRemaining,
                  lockoutRemaining: _lockoutRemaining,
                  onCompleted: _handlePinCompleted,
                )
              else if (_biometricAvailable)
                _buildBiometricPrompt(),

              const Spacer(),

              // Alternative options
              if (_biometricAvailable && _showPinEntry)
                TextButton.icon(
                  onPressed: _isLoading ? null : () {
                    setState(() => _showPinEntry = false);
                    _handleBiometric();
                  },
                  icon: const Icon(Icons.fingerprint),
                  label: const Text('Use Biometric'),
                )
              else if (_biometricAvailable && !_showPinEntry)
                TextButton.icon(
                  onPressed: _isLoading ? null : () {
                    setState(() => _showPinEntry = true);
                  },
                  icon: const Icon(Icons.dialpad),
                  label: const Text('Use PIN'),
                ),

              const SizedBox(height: 16),

              // Logout button
              TextButton(
                onPressed: _handleLogout,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                ),
                child: const Text('Log out and sign in again'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBiometricPrompt() {
    return Column(
      children: [
        if (_isLoading)
          const CircularProgressIndicator()
        else
          InkWell(
            onTap: _handleBiometric,
            borderRadius: BorderRadius.circular(40),
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.fingerprint,
                color: AppColors.primary,
                size: 48,
              ),
            ),
          ),
        const SizedBox(height: 16),
        Text(
          _isLoading ? 'Verifying...' : 'Tap to authenticate',
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _errorMessage!,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
