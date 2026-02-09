import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import 'two_factor_provider.dart';

/// Screen to display and manage recovery codes
class RecoveryCodesScreen extends ConsumerStatefulWidget {
  /// If true, this is shown after 2FA setup with new codes
  final bool isInitialSetup;

  const RecoveryCodesScreen({
    super.key,
    this.isInitialSetup = false,
  });

  @override
  ConsumerState<RecoveryCodesScreen> createState() => _RecoveryCodesScreenState();
}

class _RecoveryCodesScreenState extends ConsumerState<RecoveryCodesScreen> {
  bool _hasSavedCodes = false;
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(twoFactorSetupProvider);
    final codes = state.recoveryCodes ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recovery Codes'),
        leading: widget.isInitialSetup
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.pop(),
              ),
        automaticallyImplyLeading: !widget.isInitialSetup,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Warning banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.warning.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: AppColors.warning,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Save these codes securely',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.isInitialSetup
                              ? 'These codes will only be shown once. Store them in a safe place.'
                              : 'Each code can only be used once to access your account if you lose your 2FA device.',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Recovery codes grid
            if (codes.isNotEmpty) ...[
              _buildCodesGrid(codes),
              const SizedBox(height: 24),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _copyAllCodes(codes),
                      icon: const Icon(Icons.copy, size: 18),
                      label: const Text('Copy All'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _downloadCodes(codes),
                      icon: const Icon(Icons.download, size: 18),
                      label: const Text('Download'),
                    ),
                  ),
                ],
              ),
            ] else ...[
              // No codes available - show remaining count or prompt to regenerate
              _buildNoCodesState(state),
            ],

            const SizedBox(height: 24),

            // Confirmation checkbox for initial setup
            if (widget.isInitialSetup && codes.isNotEmpty) ...[
              CheckboxListTile(
                value: _hasSavedCodes,
                onChanged: (value) {
                  setState(() => _hasSavedCodes = value ?? false);
                },
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: const Text(
                  'I have saved these recovery codes',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _hasSavedCodes ? _completSetup : null,
                  child: const Text('Continue'),
                ),
              ),
            ],

            // Regenerate button for existing users
            if (!widget.isInitialSetup) ...[
              const Divider(height: 32),
              const Text(
                'Need new codes?',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Regenerating codes will invalidate all previous recovery codes.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => _showRegenerateConfirmation(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.warning,
                  side: const BorderSide(color: AppColors.warning),
                ),
                child: const Text('Regenerate Codes'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCodesGrid(List<String> codes) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        children: [
          for (int i = 0; i < codes.length; i += 2)
            Padding(
              padding: EdgeInsets.only(bottom: i < codes.length - 2 ? 12 : 0),
              child: Row(
                children: [
                  Expanded(
                    child: _buildCodeItem(i + 1, codes[i]),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: i + 1 < codes.length
                        ? _buildCodeItem(i + 2, codes[i + 1])
                        : const SizedBox(),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCodeItem(int index, String code) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          alignment: Alignment.center,
          child: Text(
            '$index',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            code,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              fontFamily: 'monospace',
              letterSpacing: 1.2,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNoCodesState(TwoFactorSetupState state) {
    final remaining = state.status?.recoveryCodesRemaining ?? 0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        children: [
          Icon(
            Icons.key_off,
            size: 48,
            color: AppColors.textHint.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            remaining > 0
                ? '$remaining recovery code${remaining == 1 ? '' : 's'} remaining'
                : 'No recovery codes available',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Recovery codes are shown once when generated. Regenerate to get new codes.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  void _copyAllCodes(List<String> codes) {
    final text = codes.asMap().entries.map((e) => '${e.key + 1}. ${e.value}').join('\n');

    Clipboard.setData(ClipboardData(text: text));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Recovery codes copied to clipboard'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _downloadCodes(List<String> codes) {
    // For simplicity, just copy to clipboard with a note about saving
    // In a real app, you'd use path_provider and file_picker for proper file saving
    final text = '''SSP NFC Registration - Recovery Codes
Generated: ${DateTime.now().toIso8601String()}

${codes.asMap().entries.map((e) => '${e.key + 1}. ${e.value}').join('\n')}

IMPORTANT: Store these codes securely. Each code can only be used once.
''';

    Clipboard.setData(ClipboardData(text: text));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Recovery codes copied - paste into a secure document'),
        backgroundColor: AppColors.success,
        duration: Duration(seconds: 4),
      ),
    );
  }

  void _showRegenerateConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Regenerate Recovery Codes'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This will invalidate all existing recovery codes. Enter your password to confirm.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                hintText: 'Enter your password',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _passwordController.clear();
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final password = _passwordController.text;
              _passwordController.clear();
              Navigator.pop(context);

              if (password.isNotEmpty) {
                final codes = await ref
                    .read(twoFactorSetupProvider.notifier)
                    .regenerateRecoveryCodes(password);

                if (mounted && codes != null) {
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    const SnackBar(
                      content: Text('New recovery codes generated'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.warning),
            child: const Text('Regenerate'),
          ),
        ],
      ),
    );
  }

  void _completSetup() {
    ref.read(twoFactorSetupProvider.notifier).completeSetup();
    context.go('/locations');
  }
}
