import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/login_screen.dart';
import '../../features/auth/auth_provider.dart';
import '../../features/location/location_select_screen.dart';
import '../../features/scan/scan_screen.dart';
import '../../features/tables/tables_screen.dart';
import '../../features/session/session_summary_screen.dart';
import '../../features/settings/settings_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final isLoggedIn = authState.isAuthenticated;
      final isLoggingIn = state.matchedLocation == '/login';

      if (!isLoggedIn && !isLoggingIn) {
        return '/login';
      }

      if (isLoggedIn && isLoggingIn) {
        return '/location';
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
        path: '/location',
        name: 'location',
        builder: (context, state) => const LocationSelectScreen(),
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
    ],
  );
});
