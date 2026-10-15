import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:foam_mobile/core/hive/hive.dart';
import 'package:foam_mobile/core/intro_screens/onboarding_screen.dart';
import 'package:foam_mobile/core/services/notification_service.dart';
import 'package:foam_mobile/core/services/socket_service.dart';
import 'package:foam_mobile/feature/authentication/controller/provider/authprovider.dart';
import 'package:foam_mobile/utils/values.dart';
import 'package:foam_mobile/widgets/message_handler.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LogoutClass {
  static Future<void> logOut(BuildContext context,
      GlobalKey<ScaffoldMessengerState> scaffoldKey) async {
    try {
      final res = await http.post(
        Uri.parse("${Constants.url}/api/auth/logout"),
        headers: {
          "Accept": "application/json",
          "Content-Type": "application/json",
          "Authorization": "Bearer ${HiveClass.getToken()}",
        },
      );

      var response = json.decode(res.body);
      debugPrint(jsonEncode(response));

      if (res.statusCode == 200 || res.statusCode == 201) {
        MyMessageHandler.showSnackBar(
            scaffoldKey, response["message"] ?? "Logged out successfully");

        // Unregister OneSignal and disconnect socket
        await NotificationService.logoutUser();
        SocketService.disconnect();

        // Clear user token and authentication data
        HiveClass.clearHive();
        Provider.of<AuthProvider>(context, listen: false).clearAuth();

        // Navigate to onboarding screen
        Navigator.pushNamedAndRemoveUntil(
          context,
          OnBoardingScreen.id,
          (route) => false,
        );
      } else {
        MyMessageHandler.showSnackBar(
            scaffoldKey, response["error"]?.toString() ?? "Logout failed");
        debugPrint(response["error"]?.toString() ?? "Unknown error");
      }
    } catch (e) {
      debugPrint("Exception: $e");
      MyMessageHandler.showSnackBar(scaffoldKey, "Check your network");
    }
  }

  static void logOut2(BuildContext context) {
    NotificationService.logoutUser();
    SocketService.disconnect();
    HiveClass.clearHive();
    Provider.of<AuthProvider>(context, listen: false).clearAuth();
    Navigator.pushNamedAndRemoveUntil(
      context,
      OnBoardingScreen.id,
      (route) => false,
    );
  }
}
