import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

import '../../core/theme/app_theme.dart';

/// Widget for entering a 6-digit PIN code
class PinEntryWidget extends StatefulWidget {
  final String title;
  final String? subtitle;
  final String? errorMessage;
  final bool isLoading;
  final int? attemptsRemaining;
  final Duration? lockoutRemaining;
  final ValueChanged<String> onCompleted;
  final VoidCallback? onCancel;

  const PinEntryWidget({
    super.key,
    this.title = 'Enter PIN',
    this.subtitle,
    this.errorMessage,
    this.isLoading = false,
    this.attemptsRemaining,
    this.lockoutRemaining,
    required this.onCompleted,
    this.onCancel,
  });

  @override
  State<PinEntryWidget> createState() => _PinEntryWidgetState();
}

class _PinEntryWidgetState extends State<PinEntryWidget> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    // Auto-focus the PIN field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void didUpdateWidget(PinEntryWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Clear PIN on error
    if (widget.errorMessage != null && oldWidget.errorMessage == null) {
      _controller.clear();
      setState(() {
        _hasError = true;
      });
      // Re-focus after clearing
      _focusNode.requestFocus();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLocked = widget.lockoutRemaining != null &&
                     widget.lockoutRemaining!.inSeconds > 0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Title
        Text(
          widget.title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),

        if (widget.subtitle != null) ...[
          const SizedBox(height: 8),
          Text(
            widget.subtitle!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],

        const SizedBox(height: 32),

        // PIN input fields
        if (isLocked)
          _buildLockoutMessage()
        else
          _buildPinInput(),

        // Error message
        if (widget.errorMessage != null && !isLocked) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: AppColors.error,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    widget.errorMessage!,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.error,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        // Attempts remaining
        if (widget.attemptsRemaining != null && !isLocked) ...[
          const SizedBox(height: 12),
          Text(
            '${widget.attemptsRemaining} attempt${widget.attemptsRemaining == 1 ? '' : 's'} remaining',
            style: TextStyle(
              fontSize: 13,
              color: widget.attemptsRemaining! <= 2
                  ? AppColors.warning
                  : AppColors.textSecondary,
            ),
          ),
        ],

        const SizedBox(height: 24),

        // Cancel button
        if (widget.onCancel != null)
          TextButton(
            onPressed: widget.isLoading ? null : widget.onCancel,
            child: const Text('Cancel'),
          ),
      ],
    );
  }

  Widget _buildPinInput() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: PinCodeTextField(
        appContext: context,
        length: 6,
        controller: _controller,
        focusNode: _focusNode,
        autoFocus: true,
        obscureText: true,
        obscuringCharacter: '●',
        animationType: AnimationType.scale,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        enabled: !widget.isLoading,
        pinTheme: PinTheme(
          shape: PinCodeFieldShape.box,
          borderRadius: BorderRadius.circular(8),
          fieldHeight: 56,
          fieldWidth: 44,
          activeFillColor: Colors.white,
          inactiveFillColor: Colors.white,
          selectedFillColor: Colors.white,
          activeColor: _hasError ? AppColors.error : AppColors.primary,
          inactiveColor: AppColors.borderColor,
          selectedColor: AppColors.primary,
          errorBorderColor: AppColors.error,
        ),
        animationDuration: const Duration(milliseconds: 200),
        enableActiveFill: true,
        onChanged: (value) {
          setState(() {
            _hasError = false;
          });
        },
        onCompleted: (value) {
          if (!widget.isLoading) {
            widget.onCompleted(value);
          }
        },
        beforeTextPaste: (text) {
          // Only allow pasting 6-digit numbers
          return text != null &&
                 text.length == 6 &&
                 RegExp(r'^\d{6}$').hasMatch(text);
        },
      ),
    );
  }

  Widget _buildLockoutMessage() {
    final seconds = widget.lockoutRemaining?.inSeconds ?? 0;
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;

    String timeText;
    if (minutes > 0) {
      timeText = '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
    } else {
      timeText = '$seconds seconds';
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.lock_clock,
            color: AppColors.error,
            size: 48,
          ),
          const SizedBox(height: 16),
          const Text(
            'Too many attempts',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please try again in $timeText',
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
