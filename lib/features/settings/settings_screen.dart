import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/legal_document.dart';
import '../auth/auth_provider.dart';
import '../location/location_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final locationState = ref.watch(locationStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          // User Info Section
          _SectionHeader(title: 'Account'),
          ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Text(
                authState.user?.name.substring(0, 1).toUpperCase() ?? '?',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(authState.user?.name ?? 'Unknown'),
            subtitle: Text(authState.user?.email ?? ''),
          ),
          const Divider(),

          // Location Section
          _SectionHeader(title: 'Locations'),
          ListTile(
            leading: const Icon(Icons.location_on),
            title: Text('${locationState.locations.length} locations available'),
            subtitle: const Text('Tap to change location'),
            trailing: TextButton(
              onPressed: () => _showChangeLocationDialog(context, ref),
              child: const Text('Change'),
            ),
          ),
          const Divider(),

          // App Info Section
          _SectionHeader(title: 'About'),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('App Version'),
            subtitle: const Text('1.0.0'),
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('Terms of Service'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(
              '/settings/legal/${LegalDocumentType.termsOfService.value}',
            ),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Privacy Policy'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(
              '/settings/legal/${LegalDocumentType.privacyPolicy.value}',
            ),
          ),
          ListTile(
            leading: const Icon(Icons.verified_user_outlined),
            title: const Text('Acceptable Use Policy'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(
              '/settings/legal/${LegalDocumentType.acceptableUsePolicy.value}',
            ),
          ),
          ListTile(
            leading: const Icon(Icons.cookie_outlined),
            title: const Text('Cookie Policy'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(
              '/settings/legal/${LegalDocumentType.cookiePolicy.value}',
            ),
          ),
          ListTile(
            leading: const Icon(Icons.article_outlined),
            title: const Text('End User License Agreement'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(
              '/settings/legal/${LegalDocumentType.eula.value}',
            ),
          ),
          const Divider(),

          // Actions Section
          _SectionHeader(title: 'Actions'),
          ListTile(
            leading: Icon(
              Icons.logout,
              color: Theme.of(context).colorScheme.error,
            ),
            title: Text(
              'Sign Out',
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            onTap: () => _showLogoutDialog(context, ref),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _showChangeLocationDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Location'),
        content: const Text(
          'Are you sure you want to change your location? This will clear your current session.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.go('/location');
            },
            child: const Text('Change'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () async {
              Navigator.of(context).pop();
              await ref.read(authStateProvider.notifier).logout();
              if (context.mounted) {
                context.go('/login');
              }
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}
