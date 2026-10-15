import 'dart:developer';
import 'package:onesignal_flutter/onesignal_flutter.dart';

class NotificationService {
  static bool _initialized = false;

  /// Initialize OneSignal SDK on app startup
  static Future<void> initOneSignal(String appId) async {
    if (_initialized || appId.isEmpty || appId == 'your-onesignal-app-id') {
      log('[OneSignal] Skipping init: unconfigured appId');
      return;
    }

    try {
      OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
      OneSignal.initialize(appId);

      // Prompt for push notification permissions
      await OneSignal.Notifications.requestPermission(true);

      // Foreground notification listener
      OneSignal.Notifications.addForegroundWillDisplayListener((event) {
        log('[OneSignal] Foreground notification received: ${event.notification.title}');
        event.notification.display();
      });

      // Notification opened/clicked listener
      OneSignal.Notifications.addClickListener((event) {
        log('[OneSignal] Notification clicked: ${event.notification.jsonRepresentation()}');
      });

      _initialized = true;
      log('[OneSignal] Initialized successfully');
    } catch (e) {
      log('[OneSignal] Error initializing: $e');
    }
  }

  /// Register user with OneSignal using their Foam userId as the external_id
  static Future<void> registerUser(int userId) async {
    try {
      final externalId = userId.toString();
      await OneSignal.login(externalId);
      log('[OneSignal] Logged in user with external_id: $externalId');
    } catch (e) {
      log('[OneSignal] Error registering user $userId: $e');
    }
  }

  /// Logout user from OneSignal on sign-out
  static Future<void> logoutUser() async {
    try {
      await OneSignal.logout();
      log('[OneSignal] Logged out user');
    } catch (e) {
      log('[OneSignal] Error logging out: $e');
    }
  }
}
