import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/services/device_info_service.dart';
import '../../core/theme/app_theme.dart';
import '../../models/trusted_device.dart';
import 'trusted_devices_provider.dart';

/// Screen to manage trusted devices
class TrustedDevicesScreen extends ConsumerStatefulWidget {
  const TrustedDevicesScreen({super.key});

  @override
  ConsumerState<TrustedDevicesScreen> createState() => _TrustedDevicesScreenState();
}

class _TrustedDevicesScreenState extends ConsumerState<TrustedDevicesScreen> {
  String? _currentDeviceId;

  @override
  void initState() {
    super.initState();
    _loadCurrentDeviceId();
  }

  Future<void> _loadCurrentDeviceId() async {
    final deviceId = await DeviceInfoService.getDeviceId();
    setState(() => _currentDeviceId = deviceId);
    ref.read(trustedDevicesProvider.notifier).fetchDevices(currentDeviceId: deviceId);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(trustedDevicesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trusted Devices'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (state.devices.isNotEmpty)
            TextButton(
              onPressed: state.isLoading ? null : () => _showRevokeAllDialog(context),
              child: Text(
                'Revoke All',
                style: TextStyle(
                  color: state.isLoading ? AppColors.textHint : AppColors.error,
                ),
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(trustedDevicesProvider.notifier).fetchDevices(
              currentDeviceId: _currentDeviceId,
            ),
        child: state.isLoading && state.devices.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : state.devices.isEmpty
                ? _buildEmptyState()
                : _buildDevicesList(state),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.devices_other,
              size: 64,
              color: AppColors.textHint.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'No Trusted Devices',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'When you select "Remember this device" during login, it will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDevicesList(TrustedDevicesState state) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: state.devices.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final device = state.devices[index];
        final isCurrentDevice = device.id == _currentDeviceId;

        return _buildDeviceCard(device, isCurrentDevice, state.isLoading);
      },
    );
  }

  Widget _buildDeviceCard(TrustedDevice device, bool isCurrentDevice, bool isLoading) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final timeFormat = DateFormat('h:mm a');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getDeviceIcon(device.deviceName),
                    color: AppColors.secondary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              device.deviceName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isCurrentDevice) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.success.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'This device',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.success,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Last used: ${dateFormat.format(device.lastUsedAt)} at ${timeFormat.format(device.lastUsedAt)}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.schedule,
                  size: 14,
                  color: device.isExpired ? AppColors.error : AppColors.textHint,
                ),
                const SizedBox(width: 4),
                Text(
                  device.isExpired
                      ? 'Expired'
                      : 'Expires: ${dateFormat.format(device.expiresAt)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: device.isExpired ? AppColors.error : AppColors.textHint,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: isLoading ? null : () => _showRevokeDialog(device),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.error,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  child: const Text('Revoke'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getDeviceIcon(String deviceName) {
    final name = deviceName.toLowerCase();
    if (name.contains('iphone') || name.contains('ipad')) {
      return Icons.phone_iphone;
    } else if (name.contains('android') || name.contains('pixel') ||
               name.contains('samsung') || name.contains('galaxy')) {
      return Icons.phone_android;
    } else if (name.contains('mac') || name.contains('imac')) {
      return Icons.desktop_mac;
    } else if (name.contains('windows') || name.contains('pc')) {
      return Icons.desktop_windows;
    }
    return Icons.devices;
  }

  void _showRevokeDialog(TrustedDevice device) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Revoke Device'),
        content: Text(
          'Are you sure you want to revoke trust for "${device.deviceName}"?\n\n'
          'This device will need to verify with 2FA on the next login.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await ref
                  .read(trustedDevicesProvider.notifier)
                  .revokeDevice(device.id);

              if (mounted && success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Device revoked successfully'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Revoke'),
          ),
        ],
      ),
    );
  }

  void _showRevokeAllDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Revoke All Devices'),
        content: const Text(
          'Are you sure you want to revoke trust for all devices?\n\n'
          'All devices will need to verify with 2FA on the next login, including this one.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await ref
                  .read(trustedDevicesProvider.notifier)
                  .revokeAllDevices();

              if (mounted && success) {
                ScaffoldMessenger.of(this.context).showSnackBar(
                  const SnackBar(
                    content: Text('All devices revoked successfully'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Revoke All'),
          ),
        ],
      ),
    );
  }
}
