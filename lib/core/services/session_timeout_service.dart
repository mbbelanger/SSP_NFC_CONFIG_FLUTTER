import 'dart:async';

import 'package:flutter/widgets.dart';

import 'nfc_authorization_store.dart';

/// Callback type for session timeout events
typedef SessionTimeoutCallback = void Function();

/// Service for managing session timeouts
/// Handles idle detection and background timeout
class SessionTimeoutService with WidgetsBindingObserver {
  static SessionTimeoutService? _instance;

  /// Singleton instance
  static SessionTimeoutService get instance {
    _instance ??= SessionTimeoutService._();
    return _instance!;
  }

  SessionTimeoutService._();

  Timer? _idleTimer;
  Timer? _backgroundTimer;

  /// Timeout durations
  static const Duration idleTimeout = Duration(minutes: 15);
  static const Duration backgroundTimeout = Duration(minutes: 2);

  /// Callbacks
  SessionTimeoutCallback? onIdleTimeout;
  SessionTimeoutCallback? onBackgroundTimeout;

  bool _isInitialized = false;
  bool _isInBackground = false;
  DateTime? _backgroundStartTime;

  /// Initialize the service and start observing app lifecycle
  void initialize({
    SessionTimeoutCallback? onIdle,
    SessionTimeoutCallback? onBackground,
  }) {
    if (_isInitialized) return;

    onIdleTimeout = onIdle;
    onBackgroundTimeout = onBackground;

    WidgetsBinding.instance.addObserver(this);
    _startIdleTimer();
    _isInitialized = true;
  }

  /// Dispose the service
  void dispose() {
    _idleTimer?.cancel();
    _backgroundTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _isInitialized = false;
  }

  /// Call this on any user activity to reset the idle timer
  void onUserActivity() {
    if (!_isInitialized) return;
    _startIdleTimer();
  }

  /// Start or restart the idle timer
  void _startIdleTimer() {
    _idleTimer?.cancel();
    _idleTimer = Timer(idleTimeout, _onIdleTimeout);
  }

  /// Called when idle timeout is reached
  void _onIdleTimeout() {
    // Invalidate NFC authorization on idle
    NfcAuthorizationStore.invalidate();
    onIdleTimeout?.call();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        _onAppPaused();
        break;
      case AppLifecycleState.resumed:
        _onAppResumed();
        break;
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        // App is being terminated or hidden
        _onAppDetached();
        break;
    }
  }

  /// Called when app goes to background
  void _onAppPaused() {
    if (_isInBackground) return;

    _isInBackground = true;
    _backgroundStartTime = DateTime.now();

    // Immediately invalidate NFC write tokens when backgrounded
    NfcAuthorizationStore.invalidate();

    // Start background timeout timer
    _backgroundTimer = Timer(backgroundTimeout, _onBackgroundTimeout);
  }

  /// Called when app returns to foreground
  void _onAppResumed() {
    _backgroundTimer?.cancel();

    if (_isInBackground && _backgroundStartTime != null) {
      final elapsed = DateTime.now().difference(_backgroundStartTime!);

      // If we exceeded background timeout, trigger callback
      if (elapsed >= backgroundTimeout) {
        onBackgroundTimeout?.call();
      }
    }

    _isInBackground = false;
    _backgroundStartTime = null;

    // Restart idle timer
    _startIdleTimer();
  }

  /// Called when app is being terminated
  void _onAppDetached() {
    // Clear all sensitive state
    NfcAuthorizationStore.invalidate();
  }

  /// Called when background timeout is reached
  void _onBackgroundTimeout() {
    onBackgroundTimeout?.call();
  }

  /// Check if we're currently in background
  bool get isInBackground => _isInBackground;

  /// Get time spent in background
  Duration? get timeInBackground {
    if (!_isInBackground || _backgroundStartTime == null) return null;
    return DateTime.now().difference(_backgroundStartTime!);
  }

  /// Pause the idle timer (e.g., during a long operation)
  void pauseIdleTimer() {
    _idleTimer?.cancel();
  }

  /// Resume the idle timer
  void resumeIdleTimer() {
    _startIdleTimer();
  }
}
