import 'package:flutter/material.dart';
import 'package:foam_mobile/core/services/onesignal_service.dart';

class NotificationService {
  /// Initialize OneSignal SDK on app startup.
  /// NOTE: Per OneSignal integration requirements, push permission
  /// is NOT requested here; it is requested strictly via explicit user action.
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

      // Defer attaching listeners to avoid race condition with native init thread
      Future.delayed(const Duration(milliseconds: 1500), () {
        try {
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
          debugPrint('[NotificationService] OneSignal listeners attached successfully');
        } catch (e) {
          debugPrint('[NotificationService] Error attaching listeners: $e');
        }
      });

      debugPrint('[NotificationService] OneSignal initialized successfully');
    } catch (e) {
      debugPrint('[NotificationService] Error initializing OneSignal: $e');
    }
  }

  /// Register user with OneSignal using their Foam userId as the external_id
  static Future<void> registerUser(dynamic userId) async {
    try {
      final externalId = userId?.toString() ?? '';
      if (externalId.isNotEmpty) {
        await OneSignalService().login(externalId);
      }
    } catch (e) {
      debugPrint('[NotificationService] Error registering user: $e');
    }
  }

  /// Logout user from OneSignal on sign-out
  static Future<void> logoutUser() async {
    try {
      await OneSignalService().logout();
    } catch (e) {
      debugPrint('[NotificationService] Error logging out user: $e');
    }
  }
}
