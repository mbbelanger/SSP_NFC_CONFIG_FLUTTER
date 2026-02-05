import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

import '../../core/theme/app_theme.dart';
import 'auth_provider.dart';
import 'auth_state.dart';

class TwoFactorScreen extends ConsumerStatefulWidget {
  const TwoFactorScreen({super.key});

  @override
  ConsumerState<TwoFactorScreen> createState() => _TwoFactorScreenState();
}

class _TwoFactorScreenState extends ConsumerState<TwoFactorScreen> {
  final TextEditingController _codeController = TextEditingController();
  bool _rememberDevice = false;
  int _attemptsLeft = 5;
  DateTime? _codeExpiryTime;
  Timer? _countdownTimer;
  bool _showRecoveryCode = false;
  final TextEditingController _recoveryCodeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _codeExpiryTime = DateTime.now().add(const Duration(minutes: 10));
    _startCountdown();
  }

  @override
  void dispose() {
    _codeController.dispose();
    _recoveryCodeController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_codeExpiryTime != null && _codeExpiryTime!.isBefore(DateTime.now())) {
        _countdownTimer?.cancel();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Code expired. Please request a new one.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
      if (mounted) setState(() {});
    });
  }

  String get _countdownText {
    if (_codeExpiryTime == null) return '';
    final remaining = _codeExpiryTime!.difference(DateTime.now());
    if (remaining.isNegative) return 'Expired';
    return '${remaining.inMinutes.toString().padLeft(2, '0')}:${(remaining.inSeconds % 60).toString().padLeft(2, '0')}';
  }

  Future<void> _verifyCode() async {
    final code = _codeController.text.trim();
    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the 6-digit code'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    await ref.read(authStateProvider.notifier).verifyTwoFactor(
          code,
          rememberDevice: _rememberDevice,
        );
  }

  Future<void> _verifyRecoveryCode() async {
    final code = _recoveryCodeController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your recovery code'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    await ref.read(authStateProvider.notifier).verifyWithRecoveryCode(code);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    ref.listen<AuthState>(authStateProvider, (previous, next) {
      if (next.status == AuthStatus.authenticated) {
        context.go('/locations');
      } else if (next.status == AuthStatus.requiresTwoFactor && next.errorMessage != null) {
        _attemptsLeft--;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: AppColors.error,
          ),
        );
        _codeController.clear();
        ref.read(authStateProvider.notifier).clearError();
      }
    });

    final email = authState.email ?? 'your email';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Two-Factor Authentication'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 24),

            // Icon
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _showRecoveryCode ? Icons.key : Icons.security,
                size: 48,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),

            // Title
            Text(
              _showRecoveryCode ? 'Recovery Code' : 'Verification Required',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),

            // Subtitle
            Text(
              _showRecoveryCode
                  ? 'Enter your recovery code to access your account'
                  : 'Enter the verification code sent to $email',
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            if (!_showRecoveryCode) ...[
              // PIN Code Input
              PinCodeTextField(
                appContext: context,
                length: 6,
                controller: _codeController,
                keyboardType: TextInputType.number,
                autoFocus: true,
                cursorColor: AppColors.primary,
                animationType: AnimationType.fade,
                pinTheme: PinTheme(
                  shape: PinCodeFieldShape.box,
                  borderRadius: BorderRadius.circular(8),
                  fieldHeight: 55,
                  fieldWidth: 45,
                  activeFillColor: Colors.white,
                  inactiveFillColor: AppColors.background,
                  selectedFillColor: Colors.white,
                  activeColor: AppColors.primary,
                  selectedColor: AppColors.primary,
                  inactiveColor: AppColors.borderColor,
                ),
                animationDuration: const Duration(milliseconds: 200),
                enableActiveFill: true,
                onCompleted: (_) => _verifyCode(),
                onChanged: (_) {},
              ),
              const SizedBox(height: 16),

              // Remember Device Checkbox
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Checkbox(
                    value: _rememberDevice,
                    onChanged: (v) => setState(() => _rememberDevice = v ?? false),
                    activeColor: AppColors.primary,
                  ),
                  const Text(
                    'Remember this device',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Attempts and Countdown
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Attempts left: $_attemptsLeft',
                    style: TextStyle(
                      color: _attemptsLeft <= 2 ? AppColors.error : AppColors.textSecondary,
                      fontWeight: _attemptsLeft <= 2 ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(width: 24),
                  Text(
                    'Expires in: $_countdownText',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Verify Button
              SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton(
                  onPressed: authState.isLoading ? null : _verifyCode,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: authState.isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Verify',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ] else ...[
              // Recovery Code Input
              TextField(
                controller: _recoveryCodeController,
                decoration: InputDecoration(
                  hintText: 'Enter recovery code',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 32),

              // Verify Recovery Button
              SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton(
                  onPressed: authState.isLoading ? null : _verifyRecoveryCode,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: authState.isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Verify Recovery Code',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Toggle between code and recovery
            TextButton(
              onPressed: () {
                setState(() {
                  _showRecoveryCode = !_showRecoveryCode;
                });
              },
              child: Text(
                _showRecoveryCode
                    ? 'Use verification code instead'
                    : 'Use recovery code instead',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
