import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../auth/auth_provider.dart';
import 'two_factor_provider.dart';
import 'trusted_devices_provider.dart';

/// Security settings hub screen
/// Shows 2FA status and trusted devices with navigation to detailed screens
class SecuritySettingsScreen extends ConsumerStatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  ConsumerState<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends ConsumerState<SecuritySettingsScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(twoFactorSetupProvider.notifier).fetchStatus();
      ref.read(trustedDevicesProvider.notifier).fetchDevices();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final twoFactorState = ref.watch(twoFactorSetupProvider);
    final devicesState = ref.watch(trustedDevicesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Security'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(twoFactorSetupProvider.notifier).fetchStatus();
          await ref.read(trustedDevicesProvider.notifier).fetchDevices();
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 2FA Section
            _buildSectionHeader('Two-Factor Authentication'),
            const SizedBox(height: 8),
            _buildTwoFactorCard(context, twoFactorState, authState.user?.twoFactorEnabled ?? false),

            const SizedBox(height: 24),

            // Trusted Devices Section
            _buildSectionHeader('Trusted Devices'),
            const SizedBox(height: 8),
            _buildTrustedDevicesCard(context, devicesState),

            const SizedBox(height: 24),

            // Recovery Codes Section (only if 2FA is enabled)
            if (authState.user?.twoFactorEnabled == true) ...[
              _buildSectionHeader('Recovery Codes'),
              const SizedBox(height: 8),
              _buildRecoveryCodesCard(context, twoFactorState),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
      ),
    );
  }

  Widget _buildTwoFactorCard(
    BuildContext context,
    TwoFactorSetupState state,
    bool isEnabled,
  ) {
    return Card(
      child: InkWell(
        onTap: () => context.push('/settings/security/two-factor-setup'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isEnabled
                      ? AppColors.success.withValues(alpha: 0.1)
                      : AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isEnabled ? Icons.verified_user : Icons.security,
                  color: isEnabled ? AppColors.success : AppColors.warning,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEnabled ? 'Enabled' : 'Not Configured',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isEnabled
                          ? 'Your account is protected with ${state.status?.channelDisplayName ?? '2FA'}'
                          : 'Add an extra layer of security to your account',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrustedDevicesCard(BuildContext context, TrustedDevicesState state) {
    return Card(
      child: InkWell(
        onTap: () => context.push('/settings/security/trusted-devices'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.devices,
                  color: AppColors.secondary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${state.totalCount} Trusted Device${state.totalCount == 1 ? '' : 's'}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Manage devices that skip 2FA verification',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecoveryCodesCard(BuildContext context, TwoFactorSetupState state) {
    final codesRemaining = state.status?.recoveryCodesRemaining ?? 0;
    final isLow = codesRemaining <= 2;

    return Card(
      child: InkWell(
        onTap: () => context.push('/settings/security/recovery-codes'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isLow
                      ? AppColors.warning.withValues(alpha: 0.1)
                      : AppColors.textSecondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.key,
                  color: isLow ? AppColors.warning : AppColors.textSecondary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$codesRemaining Recovery Code${codesRemaining == 1 ? '' : 's'} Remaining',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isLow
                          ? 'Consider regenerating your recovery codes'
                          : 'Backup codes for account recovery',
                      style: TextStyle(
                        fontSize: 14,
                        color: isLow ? AppColors.warning : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
