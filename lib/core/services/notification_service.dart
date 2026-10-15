import 'package:flutter/material.dart';
import 'package:foam_mobile/core/services/onesignal_service.dart';

class NotificationService {
  /// Initialize OneSignal SDK on app startup.
  /// NOTE: Per OneSignal integration requirements, push permission
  /// is NOT requested here; it is requested strictly via the
  /// Push Subscription Verification Dialog on button tap.
  static Future<void> initOneSignal(String appId) async {
    final oneSignal = OneSignalService();
    if (oneSignal.isInitialized ||
        appId.isEmpty ||
        appId == 'your-onesignal-app-id') {
      debugPrint(
          '[NotificationService] Skipping init: unconfigured or already initialized appId');
      return;
    }

    try {
      await oneSignal.initialize(appId);

      // Foreground notification listener
      oneSignal.setNotificationForegroundListener((event) {
        debugPrint(
            '[OneSignal] Foreground notification received: ${event.notification.title}');
      });

      // Notification opened/clicked listener
      oneSignal.setNotificationClickListener((event) {
        debugPrint(
            '[OneSignal] Notification clicked: ${event.notification.jsonRepresentation()}');
      });

      debugPrint('[NotificationService] OneSignal initialized successfully');
    } catch (e) {
      debugPrint('[NotificationService] Error initializing OneSignal: $e');
    }
  }

  /// Register user with OneSignal using their Foam userId as the external_id
  static Future<void> registerUser(dynamic userId) async {
    final externalId = userId.toString();
    await OneSignalService().login(externalId);
  }

  /// Logout user from OneSignal on sign-out
  static Future<void> logoutUser() async {
    await OneSignalService().logout();
  }
}
