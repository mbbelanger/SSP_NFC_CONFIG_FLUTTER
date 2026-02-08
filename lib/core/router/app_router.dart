import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/login_screen.dart';
import '../../features/auth/two_factor_screen.dart';
import '../../features/auth/auth_provider.dart';
import '../../features/auth/auth_state.dart';
import '../../features/location/location_select_screen.dart';
import '../../features/scan/scan_screen.dart';
import '../../features/tables/tables_screen.dart';
import '../../features/session/session_summary_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/settings/security_settings_screen.dart';
import '../../features/settings/trusted_devices_screen.dart';
import '../../features/settings/recovery_codes_screen.dart';
import '../../features/nfc/pin_setup_screen.dart';
import '../../features/nfc/lock_screen.dart';
import '../../features/legal/legal_document_detail_screen.dart';
import '../../models/legal_document.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final isLoggedIn = authState.isAuthenticated;
      final isLoggingIn = state.matchedLocation == '/login';
      final isOnTwoFactor = state.matchedLocation == '/two-factor';
      final isOnOrgSelection = state.matchedLocation == '/select-organization';

      // Allow 2FA and org selection flows
      if (authState.status == AuthStatus.requiresTwoFactor && !isOnTwoFactor) {
        return '/two-factor';
      }
      if (authState.status == AuthStatus.requiresOrgSelection && !isOnOrgSelection) {
        return '/select-organization';
      }

      // Redirect to login if not authenticated
      if (!isLoggedIn && !isLoggingIn && !isOnTwoFactor && !isOnOrgSelection) {
        return '/login';
      }

      // Redirect to locations if already logged in and trying to access login
      if (isLoggedIn && isLoggingIn) {
        return '/locations';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/two-factor',
        name: 'two-factor',
        builder: (context, state) => const TwoFactorScreen(),
      ),
      GoRoute(
        path: '/locations',
        name: 'locations',
        builder: (context, state) => const LocationSelectScreen(),
      ),
      // Legacy route alias
      GoRoute(
        path: '/location',
        redirect: (context, state) => '/locations',
      ),
      GoRoute(
        path: '/scan/:locationId',
        name: 'scan',
        builder: (context, state) {
          final locationId = state.pathParameters['locationId']!;
          final locationName = state.uri.queryParameters['name'] ?? '';
          return ScanScreen(
            locationId: locationId,
            locationName: locationName,
          );
        },
      ),
      GoRoute(
        path: '/tables/:locationId',
        name: 'tables',
        builder: (context, state) {
          final locationId = state.pathParameters['locationId']!;
          final locationName = state.uri.queryParameters['name'] ?? '';
          return TablesScreen(
            locationId: locationId,
            locationName: locationName,
          );
        },
      ),
      GoRoute(
        path: '/session/:locationId',
        name: 'session',
        builder: (context, state) {
          final locationId = state.pathParameters['locationId']!;
          final locationName = state.uri.queryParameters['name'] ?? '';
          return SessionSummaryScreen(
            locationId: locationId,
            locationName: locationName,
          );
        },
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      // Security settings routes
      GoRoute(
        path: '/settings/security',
        name: 'security-settings',
        builder: (context, state) => const SecuritySettingsScreen(),
      ),
      GoRoute(
        path: '/settings/security/trusted-devices',
        name: 'trusted-devices',
        builder: (context, state) => const TrustedDevicesScreen(),
      ),
      GoRoute(
        path: '/settings/security/recovery-codes',
        name: 'recovery-codes',
        builder: (context, state) => const RecoveryCodesScreen(),
      ),
      // PIN management routes
      GoRoute(
        path: '/pin-setup',
        name: 'pin-setup',
        builder: (context, state) {
          final returnRoute = state.uri.queryParameters['returnRoute'];
          return PinSetupScreen(returnRoute: returnRoute);
        },
      ),
      GoRoute(
        path: '/pin-change',
        name: 'pin-change',
        builder: (context, state) {
          final returnRoute = state.uri.queryParameters['returnRoute'];
          return PinSetupScreen(
            isChangingPin: true,
            returnRoute: returnRoute,
          );
        },
      ),
      // Lock screen route
      GoRoute(
        path: '/lock',
        name: 'lock',
        builder: (context, state) {
          final returnRoute = state.uri.queryParameters['returnRoute'];
          return LockScreen(returnRoute: returnRoute);
        },
      ),
      // Legal document routes
      GoRoute(
        path: '/settings/legal/:type',
        name: 'legal-document',
        builder: (context, state) {
          final typeString = state.pathParameters['type']!;
          final documentType = LegalDocumentType.fromString(typeString);
          return LegalDocumentDetailScreen(documentType: documentType);
        },
      ),
    ],
  );
});
