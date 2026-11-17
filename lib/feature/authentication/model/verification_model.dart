import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:foam_mobile/feature/authentication/controller/provider/authprovider.dart';
import 'package:foam_mobile/feature/authentication/view/forgot_password_pages/create_new_password.dart';
import 'package:foam_mobile/utils/values.dart';
import 'package:foam_mobile/widgets/message_handler.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import 'package:foam_mobile/core/hive/hive.dart';
import 'package:foam_mobile/feature/authentication/model/login_model.dart';

class VerifyClass {
  static Future<void> verify(String code, BuildContext context,
      GlobalKey<ScaffoldMessengerState> scaffoldKey) async {
    var authProvider = Provider.of<AuthProvider>(context, listen: false);
    try {
      http.Response res = await http.post(
        Uri.parse("${Constants.url}/api/auth/validateSmsOtp"),
        headers: {
          "Accept": "application/json",
          'Content-Type': 'application/json'
        },
        body: jsonEncode(
          {
            "email": authProvider.email,
            "pin": code,
          },
        ),
      );
      var response = json.decode(res.body);
      debugPrint(res.body);

      if (res.statusCode == 200 || res.statusCode == 201) {
        MyMessageHandler.showSnackBar(
            scaffoldKey, response["message"] ?? "Verification successful");
        if (response["token"] != null) {
          HiveClass.insertToken(response["token"]);
          LoginClass.getProfile(context, scaffoldKey, isSignup: true);
        } else {
          // After successful verification, login the user and indicate it's a signup
          LoginClass.login(
              context, authProvider.email, authProvider.password, scaffoldKey,
              isSignup: true);
        }
      } else {
        MyMessageHandler.showSnackBar(
            scaffoldKey, response["error"] ?? "Wrong code");
      }
    } catch (e) {
      debugPrint(e.toString());
      MyMessageHandler.showSnackBar(scaffoldKey, "Check your network");
    }
  }

  static Future<bool> verifyForgotPassword(
    String code,
    BuildContext context,
    GlobalKey<ScaffoldMessengerState> scaffoldKey, {
    String? email,
  }) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final targetEmail = (email != null && email.isNotEmpty) ? email : authProvider.email;

    try {
      final res = await http.post(
        Uri.parse("${Constants.url}/api/auth/validateOtp"),
        headers: {
          "Accept": "application/json",
          'Content-Type': 'application/json'
        },
        body: jsonEncode(
          {
            "email": targetEmail.trim().toLowerCase(),
            "otp": code.trim(),
          },
        ),
      );
      final response = json.decode(res.body);
      if (res.statusCode == 200 || response["status"] == true) {
        if (!context.mounted) return false;
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => CreateNewPassword(
              email: targetEmail.trim().toLowerCase(),
              otp: code.trim(),
            ),
          ),
        );
        return true;
      } else {
        MyMessageHandler.showSnackBar(
          scaffoldKey,
          response["error"] ?? response["message"] ?? "Invalid or expired verification code",
        );
        return false;
      }
    } catch (e) {
      debugPrint("verifyForgotPassword error: $e");
      MyMessageHandler.showSnackBar(scaffoldKey, "Check your network connection");
      return false;
    }
  }

  static Future<void> resend(
    BuildContext context,
    GlobalKey<ScaffoldMessengerState> scaffoldKey, {
    bool isForgotPassword = false,
    String? email,
  }) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final targetEmail = (email != null && email.isNotEmpty) ? email : authProvider.email;

    try {
      final endpoint = isForgotPassword
          ? "${Constants.url}/api/auth/forgotPassword"
          : "${Constants.url}/api/auth/resend/email";

      final res = await http.post(
        Uri.parse(endpoint),
        headers: {
          "Accept": "application/json",
          'Content-Type': 'application/json'
        },
        body: jsonEncode(
          {
            "email": targetEmail.trim().toLowerCase(),
          },
        ),
      );
      final response = json.decode(res.body);
      final msg = response["message"] ?? (res.statusCode == 200 ? "Code resent successfully" : response["error"]);
      MyMessageHandler.showSnackBar(scaffoldKey, msg ?? "Code sent");
    } catch (e) {
      MyMessageHandler.showSnackBar(scaffoldKey, "Check your network connection");
    }
  }
}
