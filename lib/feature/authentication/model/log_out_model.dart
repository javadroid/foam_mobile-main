import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:foam_mobile/core/hive/hive.dart';
import 'package:foam_mobile/core/intro_screens/onboarding_screen.dart';
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
      log(jsonEncode(response)); // Log properly

      if (res.statusCode == 200 || res.statusCode == 201) {
        MyMessageHandler.showSnackBar(
            scaffoldKey, response["message"] ?? "Logged out successfully");

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
        log(response["error"]?.toString() ?? "Unknown error");
      }
    } catch (e) {
      log("Exception: $e");
      MyMessageHandler.showSnackBar(scaffoldKey, "Check your network");
    }
  }

  static void logOut2(BuildContext context) {
    HiveClass.clearHive();
    Provider.of<AuthProvider>(context, listen: false).clearAuth();
    Navigator.pushNamedAndRemoveUntil(
      context,
      OnBoardingScreen.id,
      (route) => false,
    );
  }
}
