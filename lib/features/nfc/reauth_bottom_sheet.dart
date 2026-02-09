import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

import '../../core/services/reauth_service.dart';
import '../../core/storage/secure_storage.dart';
import '../../core/theme/app_theme.dart';
import '../../models/reauth_result.dart';

/// Bottom sheet for re-authentication before NFC operations
class ReAuthBottomSheet extends ConsumerStatefulWidget {
  final String title;
  final String subtitle;
  final bool showPinOption;
  final bool showTotpOption;

  const ReAuthBottomSheet({
    super.key,
    this.title = 'Verify your identity',
    this.subtitle = 'Authentication required to configure NFC tags',
    this.showPinOption = true,
    this.showTotpOption = true,
  });

  /// Show the bottom sheet and return the result
  static Future<ReAuthResult?> show(
    BuildContext context, {
    String title = 'Verify your identity',
    String subtitle = 'Authentication required to configure NFC tags',
    bool showPinOption = true,
    bool showTotpOption = true,
  }) {
    return showModalBottomSheet<ReAuthResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ReAuthBottomSheet(
        title: title,
        subtitle: subtitle,
        showPinOption: showPinOption,
        showTotpOption: showTotpOption,
      ),
    );
  }

  @override
  ConsumerState<ReAuthBottomSheet> createState() => _ReAuthBottomSheetState();
}

enum _AuthMode { selection, pin, totp }

class _ReAuthBottomSheetState extends ConsumerState<ReAuthBottomSheet> {
  bool _isLoading = false;
  bool _biometricAvailable = false;
  bool _pinAvailable = false;
  String _biometricName = 'Biometric';
  String? _errorMessage;
  _AuthMode _currentMode = _AuthMode.selection;

  final _pinController = TextEditingController();
  final _totpController = TextEditingController();
  final _pinFocusNode = FocusNode();
  final _totpFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _checkAvailability();
  }

  @override
  void dispose() {
    _pinController.dispose();
    _totpController.dispose();
    _pinFocusNode.dispose();
    _totpFocusNode.dispose();
    super.dispose();
  }

  Future<void> _checkAvailability() async {
    final biometricAvailable = await ReAuthService.isBiometricAvailable();
    final biometricName = await ReAuthService.getBiometricName();
    final pinAvailable = await SecureStorage.hasPinSetup();

    if (mounted) {
      setState(() {
        _biometricAvailable = biometricAvailable;
        _biometricName = biometricName;
        _pinAvailable = pinAvailable;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Icon
              Center(
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getModeIcon(),
                    color: AppColors.primary,
                    size: 32,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title
              Text(
                _getModeTitle(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),

              // Subtitle
              Text(
                _getModeSubtitle(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),

              // Error message
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.error,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Content based on mode
              _buildModeContent(),

              const SizedBox(height: 16),

              // Back/Cancel button
              TextButton(
                onPressed: _isLoading ? null : _handleBack,
                child: Text(_currentMode == _AuthMode.selection ? 'Cancel' : 'Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getModeIcon() {
    switch (_currentMode) {
      case _AuthMode.selection:
        return Icons.security;
      case _AuthMode.pin:
        return Icons.dialpad;
      case _AuthMode.totp:
        return Icons.smartphone;
    }
  }

  String _getModeTitle() {
    switch (_currentMode) {
      case _AuthMode.selection:
        return widget.title;
      case _AuthMode.pin:
        return 'Enter PIN';
      case _AuthMode.totp:
        return 'Enter Code';
    }
  }

  String _getModeSubtitle() {
    switch (_currentMode) {
      case _AuthMode.selection:
        return widget.subtitle;
      case _AuthMode.pin:
        return 'Enter your 6-digit PIN';
      case _AuthMode.totp:
        return 'Enter the code from your authenticator app';
    }
  }

  Widget _buildModeContent() {
    switch (_currentMode) {
      case _AuthMode.selection:
        return _buildSelectionMode();
      case _AuthMode.pin:
        return _buildPinEntry();
      case _AuthMode.totp:
        return _buildTotpEntry();
    }
  }

  Widget _buildSelectionMode() {
    return Column(
      children: [
        // Biometric button (primary)
        if (_biometricAvailable)
          _buildAuthButton(
            icon: Icons.fingerprint,
            label: 'Use $_biometricName',
            isPrimary: true,
            onPressed: _isLoading ? null : _handleBiometric,
          ),

        if (_biometricAvailable) const SizedBox(height: 12),

        // Other methods text
        if (_biometricAvailable && (widget.showPinOption || widget.showTotpOption))
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Or use another method:',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ),

        // Secondary options row
        if (widget.showPinOption || widget.showTotpOption)
          Row(
            children: [
              if (widget.showPinOption && _pinAvailable)
                Expanded(
                  child: _buildAuthButton(
                    icon: Icons.dialpad,
                    label: 'PIN',
                    isPrimary: !_biometricAvailable,
                    onPressed: _isLoading ? null : () => _switchMode(_AuthMode.pin),
                  ),
                ),
              if (widget.showPinOption && _pinAvailable && widget.showTotpOption)
                const SizedBox(width: 12),
              if (widget.showTotpOption)
                Expanded(
                  child: _buildAuthButton(
                    icon: Icons.smartphone,
                    label: 'Authenticator',
                    isPrimary: !_biometricAvailable && !_pinAvailable,
                    onPressed: _isLoading ? null : () => _switchMode(_AuthMode.totp),
                  ),
                ),
            ],
          ),
      ],
    );
  }

  Widget _buildPinEntry() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: PinCodeTextField(
        appContext: context,
        length: 6,
        controller: _pinController,
        focusNode: _pinFocusNode,
        autoFocus: true,
        obscureText: true,
        obscuringCharacter: '●',
        animationType: AnimationType.scale,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        enabled: !_isLoading,
        pinTheme: PinTheme(
          shape: PinCodeFieldShape.box,
          borderRadius: BorderRadius.circular(8),
          fieldHeight: 56,
          fieldWidth: 44,
          activeFillColor: Colors.white,
          inactiveFillColor: Colors.white,
          selectedFillColor: Colors.white,
          activeColor: _errorMessage != null ? AppColors.error : AppColors.primary,
          inactiveColor: AppColors.borderColor,
          selectedColor: AppColors.primary,
        ),
        animationDuration: const Duration(milliseconds: 200),
        enableActiveFill: true,
        onChanged: (value) {
          if (_errorMessage != null) {
            setState(() => _errorMessage = null);
          }
        },
        onCompleted: _handlePinCompleted,
      ),
    );
  }

  Widget _buildTotpEntry() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: PinCodeTextField(
        appContext: context,
        length: 6,
        controller: _totpController,
        focusNode: _totpFocusNode,
        autoFocus: true,
        animationType: AnimationType.scale,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        enabled: !_isLoading,
        pinTheme: PinTheme(
          shape: PinCodeFieldShape.box,
          borderRadius: BorderRadius.circular(8),
          fieldHeight: 56,
          fieldWidth: 44,
          activeFillColor: Colors.white,
          inactiveFillColor: Colors.white,
          selectedFillColor: Colors.white,
          activeColor: _errorMessage != null ? AppColors.error : AppColors.primary,
          inactiveColor: AppColors.borderColor,
          selectedColor: AppColors.primary,
        ),
        animationDuration: const Duration(milliseconds: 200),
        enableActiveFill: true,
        onChanged: (value) {
          if (_errorMessage != null) {
            setState(() => _errorMessage = null);
          }
        },
        onCompleted: _handleTotpCompleted,
      ),
    );
  }

  Widget _buildAuthButton({
    required IconData icon,
    required String label,
    required bool isPrimary,
    VoidCallback? onPressed,
  }) {
    if (isPrimary) {
      return SizedBox(
        height: 56,
        child: ElevatedButton.icon(
          onPressed: onPressed,
          icon: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Icon(icon),
          label: Text(label),
        ),
      );
    }

    return SizedBox(
      height: 56,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(label),
      ),
    );
  }

  void _switchMode(_AuthMode mode) {
    setState(() {
      _currentMode = mode;
      _errorMessage = null;
      _pinController.clear();
      _totpController.clear();
    });

    // Request focus after mode switch
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mode == _AuthMode.pin) {
        _pinFocusNode.requestFocus();
      } else if (mode == _AuthMode.totp) {
        _totpFocusNode.requestFocus();
      }
    });
  }

  void _handleBack() {
    if (_currentMode == _AuthMode.selection) {
      Navigator.pop(context);
    } else {
      setState(() {
        _currentMode = _AuthMode.selection;
        _errorMessage = null;
        _pinController.clear();
        _totpController.clear();
      });
    }
  }

  Future<void> _handleBiometric() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await ReAuthService.authenticateWithBiometric(
      reason: widget.subtitle,
    );

    if (mounted) {
      setState(() => _isLoading = false);

      if (result.success) {
        Navigator.pop(context, result);
      } else if (result.errorMessage != null &&
                 result.errorMessage != 'Authentication cancelled') {
        setState(() => _errorMessage = result.errorMessage);
      }
    }
  }

  Future<void> _handlePinCompleted(String pin) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Verify PIN locally
    final storedHash = await SecureStorage.getPinHash();
    final inputHash = sha256.convert(utf8.encode(pin)).toString();

    if (mounted) {
      if (storedHash == inputHash) {
        // Reset attempts on success
        await SecureStorage.resetPinAttempts();

        Navigator.pop(
          context,
          ReAuthResult.success(ReAuthMethod.appPin, credential: pin),
        );
      } else {
        // Increment attempts
        await SecureStorage.incrementPinAttempts();
        final attempts = await SecureStorage.getPinAttempts();

        setState(() {
          _isLoading = false;
          _pinController.clear();

          if (attempts >= 10) {
            _errorMessage = 'Too many attempts. PIN has been disabled.';
          } else {
            _errorMessage = 'Incorrect PIN. ${10 - attempts} attempts remaining.';
          }
        });
      }
    }
  }

  Future<void> _handleTotpCompleted(String code) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // TOTP verification should happen on the backend
    // For now, we return the code and let the caller verify
    Navigator.pop(
      context,
      ReAuthResult.success(ReAuthMethod.totp, credential: code),
    );
  }
}
