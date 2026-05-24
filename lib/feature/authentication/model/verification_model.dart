import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:foam_mobile/feature/authentication/controller/provider/authprovider.dart';
import 'package:foam_mobile/feature/authentication/view/forgot_password_pages/create_new_password.dart';
import 'package:foam_mobile/utils/values.dart';
import 'package:foam_mobile/widgets/message_handler.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

class VerifyClass {
  static Future<void> verify(String code, BuildContext context,
      GlobalKey<ScaffoldMessengerState> scaffoldKey) async {
    try {
      http.Response res = await http.post(
        Uri.parse("${Constants.url}/api/verify/email"),
        headers: {
          "Accept": "application/json",
          'Content-Type': 'application/json'
        },
        body: jsonEncode(
          {
            "otp_code": code,
          },
        ),
      );
      var response = json.decode(res.body);
      if (response["status"]) {
        log(response);
        Navigator.pushNamed(context, CreateNewPassword.id);
      } else {
        MyMessageHandler.showSnackBar(scaffoldKey, "Wrong code");
      }
    } catch (e) {
      MyMessageHandler.showSnackBar(scaffoldKey, "Check your network");
    }
  }

  static Future<void> resend(
    BuildContext context,
    GlobalKey<ScaffoldMessengerState> scaffoldKey,
  ) async {
    var authProvider = Provider.of<AuthProvider>(context, listen: false);
    try {
      http.Response res = await http.post(
        Uri.parse("${Constants.url}/api/resend/email"),
        headers: {
          "Accept": "application/json",
          'Content-Type': 'application/json'
        },
        body: jsonEncode(
          {
            "email": authProvider.email,
          },
        ),
      );
      var response = json.decode(res.body);
      if (response["status"]) {
        MyMessageHandler.showSnackBar(scaffoldKey, response["message"]);
      } else {
        MyMessageHandler.showSnackBar(scaffoldKey, response["message"]);
      }
    } catch (e) {
      MyMessageHandler.showSnackBar(scaffoldKey, "Check your network");
    }
  }
}
