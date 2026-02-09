import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/storage/secure_storage.dart';
import 'pin_entry_widget.dart';

/// Screen for setting up or changing the app PIN
class PinSetupScreen extends ConsumerStatefulWidget {
  final bool isChangingPin;
  final String? returnRoute;

  const PinSetupScreen({
    super.key,
    this.isChangingPin = false,
    this.returnRoute,
  });

  @override
  ConsumerState<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends ConsumerState<PinSetupScreen> {
  PinSetupStep _currentStep = PinSetupStep.enterCurrent;
  String? _firstPin;
  String? _errorMessage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // If not changing PIN, skip to enter new PIN step
    if (!widget.isChangingPin) {
      _currentStep = PinSetupStep.enterNew;
    }
  }

  String get _title {
    switch (_currentStep) {
      case PinSetupStep.enterCurrent:
        return 'Enter Current PIN';
      case PinSetupStep.enterNew:
        return widget.isChangingPin ? 'Enter New PIN' : 'Create PIN';
      case PinSetupStep.confirmNew:
        return 'Confirm PIN';
    }
  }

  String get _subtitle {
    switch (_currentStep) {
      case PinSetupStep.enterCurrent:
        return 'Enter your current 6-digit PIN to continue';
      case PinSetupStep.enterNew:
        return 'Choose a 6-digit PIN for quick authentication';
      case PinSetupStep.confirmNew:
        return 'Enter your PIN again to confirm';
    }
  }

  Future<void> _handlePinCompleted(String pin) async {
    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    try {
      switch (_currentStep) {
        case PinSetupStep.enterCurrent:
          // Verify current PIN
          final isValid = await _verifyCurrentPin(pin);
          if (isValid) {
            setState(() {
              _currentStep = PinSetupStep.enterNew;
              _isLoading = false;
            });
          } else {
            setState(() {
              _errorMessage = 'Incorrect PIN. Please try again.';
              _isLoading = false;
            });
          }
          break;

        case PinSetupStep.enterNew:
          // Store first entry and move to confirmation
          _firstPin = pin;
          setState(() {
            _currentStep = PinSetupStep.confirmNew;
            _isLoading = false;
          });
          break;

        case PinSetupStep.confirmNew:
          // Verify PINs match
          if (pin == _firstPin) {
            await _savePin(pin);
            if (mounted) {
              _showSuccessAndNavigate();
            }
          } else {
            setState(() {
              _errorMessage = 'PINs do not match. Please try again.';
              _currentStep = PinSetupStep.enterNew;
              _firstPin = null;
              _isLoading = false;
            });
          }
          break;
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred. Please try again.';
        _isLoading = false;
      });
    }
  }

  Future<bool> _verifyCurrentPin(String pin) async {
    // Verify against stored PIN hash
    final storedHash = await SecureStorage.getPinHash();
    if (storedHash == null) return false;

    // Simple hash comparison (in production, use proper Argon2id)
    final inputHash = _hashPin(pin);
    return inputHash == storedHash;
  }

  String _hashPin(String pin) {
    // Simple hash for local verification
    // In production, use Argon2id or similar
    final bytes = utf8.encode(pin);
    return sha256.convert(bytes).toString();
  }

  Future<void> _savePin(String pin) async {
    // Save PIN hash locally for offline verification
    final hash = _hashPin(pin);
    await SecureStorage.savePinHash(hash);

    // TODO: Also sync with backend via setupAppPin or changeAppPin mutation
    // This requires the GraphQL client and device ID
  }

  void _showSuccessAndNavigate() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          widget.isChangingPin
              ? 'PIN changed successfully'
              : 'PIN created successfully',
        ),
        backgroundColor: AppColors.success,
      ),
    );

    if (widget.returnRoute != null) {
      context.go(widget.returnRoute!);
    } else {
      context.pop();
    }
  }

  void _handleCancel() {
    if (_currentStep == PinSetupStep.confirmNew) {
      // Go back to enter new PIN
      setState(() {
        _currentStep = PinSetupStep.enterNew;
        _firstPin = null;
        _errorMessage = null;
      });
    } else if (_currentStep == PinSetupStep.enterNew && widget.isChangingPin) {
      // Go back to enter current PIN
      setState(() {
        _currentStep = PinSetupStep.enterCurrent;
        _errorMessage = null;
      });
    } else {
      // Exit the screen
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.isChangingPin ? 'Change PIN' : 'Set Up PIN'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),

              // Step indicator
              _buildStepIndicator(),
              const SizedBox(height: 32),

              // PIN entry widget
              PinEntryWidget(
                key: ValueKey(_currentStep),
                title: _title,
                subtitle: _subtitle,
                errorMessage: _errorMessage,
                isLoading: _isLoading,
                onCompleted: _handlePinCompleted,
                onCancel: _handleCancel,
              ),

              const Spacer(),

              // Security note
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppColors.secondary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Your PIN is used for quick authentication when configuring NFC tags.',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    final totalSteps = widget.isChangingPin ? 3 : 2;
    final currentStepIndex = widget.isChangingPin
        ? _currentStep.index
        : _currentStep.index - 1;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalSteps, (index) {
        final isActive = index <= currentStepIndex;
        final isCurrent = index == currentStepIndex;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isCurrent ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : AppColors.borderColor,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

enum PinSetupStep {
  enterCurrent,
  enterNew,
  confirmNew,
}
