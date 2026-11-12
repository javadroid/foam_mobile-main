import 'package:flutter/material.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
export 'package:onesignal_flutter/onesignal_flutter.dart'
    show OSPushSubscriptionChangedState, OSLogLevel;

/// Centralized service isolating all direct OneSignal SDK calls.
/// Follows Step 4 of OneSignal SDK Integration specification.
class OneSignalService {
  static final OneSignalService _instance = OneSignalService._internal();
  factory OneSignalService() => _instance;
  OneSignalService._internal();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  /// Initialize OneSignal SDK with provided App ID.
  /// Note: Push permission is NOT requested here per integration guidelines.
  Future<void> initialize(String appId) async {
    if (_isInitialized) return;
    if (appId.isEmpty || appId == 'your-onesignal-app-id') {
      debugPrint('[OneSignalService] Skipping init: unconfigured appId');
      return;
    }

    try {
      // Set log level to none to avoid main thread I/O overhead
      OneSignal.Debug.setLogLevel(OSLogLevel.none);

      // Initialize SDK asynchronously
      OneSignal.initialize(appId);
      _isInitialized = true;
      debugPrint(
          '[OneSignalService] Initialized successfully with App ID: $appId');
    } catch (e) {
      debugPrint('[OneSignalService] Error initializing: $e');
    }
  }

  /// Manage user identity - Login
  Future<void> login(String externalId) async {
    try {
      await OneSignal.login(externalId);
      debugPrint(
          '[OneSignalService] Logged in user with external_id: $externalId');
    } catch (e) {
      debugPrint('[OneSignalService] Error logging in user $externalId: $e');
    }
  }

  /// Manage user identity - Logout
  Future<void> logout() async {
    try {
      await OneSignal.logout();
      debugPrint('[OneSignalService] Logged out user');
    } catch (e) {
      debugPrint('[OneSignalService] Error logging out: $e');
    }
  }

  /// Set user email subscription
  Future<void> setEmail(String email) async {
    try {
      await OneSignal.User.addEmail(email);
      debugPrint('[OneSignalService] Set email: $email');
    } catch (e) {
      debugPrint('[OneSignalService] Error setting email: $e');
    }
  }

  /// Set user SMS phone number subscription
  Future<void> setSmsNumber(String number) async {
    try {
      await OneSignal.User.addSms(number);
      debugPrint('[OneSignalService] Set SMS number: $number');
    } catch (e) {
      debugPrint('[OneSignalService] Error setting SMS number: $e');
    }
  }

  /// Manage user tags
  Future<void> setTag(String key, String value) async {
    try {
      await OneSignal.User.addTagWithKey(key, value);
      debugPrint('[OneSignalService] Set tag: $key = $value');
    } catch (e) {
      debugPrint('[OneSignalService] Error setting tag $key: $e');
    }
  }

  /// Remove user tag
  Future<void> removeTag(String key) async {
    try {
      await OneSignal.User.removeTag(key);
      debugPrint('[OneSignalService] Removed tag: $key');
    } catch (e) {
      debugPrint('[OneSignalService] Error removing tag $key: $e');
    }
  }

  /// Control logging levels
  void setLogLevel(OSLogLevel level) {
    OneSignal.Debug.setLogLevel(level);
  }

  /// Request push notification permissions (only invoked on explicit user interaction)
  Future<bool> requestPermission({bool fallbackToSettings = true}) async {
    try {
      return await OneSignal.Notifications.requestPermission(
          fallbackToSettings);
    } catch (e) {
      debugPrint('[OneSignalService] Error requesting permission: $e');
      return false;
    }
  }

  /// Listen for notification clicks
  void setNotificationClickListener(
      void Function(OSNotificationClickEvent) handler) {
    try {
      OneSignal.Notifications.addClickListener(handler);
    } catch (e) {
      debugPrint('[OneSignalService] Error adding click listener: $e');
    }
  }

  /// Listen for foreground notifications
  void setNotificationForegroundListener(
      void Function(OSNotificationWillDisplayEvent) handler) {
    try {
      OneSignal.Notifications.addForegroundWillDisplayListener(handler);
    } catch (e) {
      debugPrint('[OneSignalService] Error adding foreground listener: $e');
    }
  }

  /// Add Push Subscription observer
  void addPushSubscriptionObserver(
      void Function(OSPushSubscriptionChangedState) observer) {
    try {
      OneSignal.User.pushSubscription.addObserver(observer);
    } catch (e) {
      debugPrint('[OneSignalService] Error adding push observer: $e');
    }
  }

  /// Remove Push Subscription observer
  void removePushSubscriptionObserver(
      void Function(OSPushSubscriptionChangedState) observer) {
    try {
      OneSignal.User.pushSubscription.removeObserver(observer);
    } catch (e) {
      debugPrint('[OneSignalService] Error removing push observer: $e');
    }
  }

  /// Get current push subscription ID
  String? get pushSubscriptionId {
    try {
      return OneSignal.User.pushSubscription.id;
    } catch (e) {
      debugPrint('[OneSignalService] Error getting pushSubscriptionId: $e');
      return null;
    }
  }
}
