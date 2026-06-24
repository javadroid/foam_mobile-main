import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:foam_mobile/core/hive/hive.dart';
import 'package:foam_mobile/feature/authentication/model/log_out_model.dart';
import 'package:foam_mobile/utils/values.dart';
import 'package:foam_mobile/widgets/message_handler.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ChangePasswordModel {
  static Future<void> changePassword(
    BuildContext context,
    GlobalKey<ScaffoldMessengerState> scaffoldKey,
    String oldPassword,
    String newPassword,
  ) async {
    try {
      http.Response res = await http.put(
        Uri.parse(
          "${Constants.url}/api/user/password",
        ),
        headers: {
          "Accept": "application/json",
          'Content-Type': 'application/json',
          "Authorization": "Bearer ${HiveClass.getToken()}",
        },
        body: jsonEncode(
          {
            "oldPassword": oldPassword,
            "newPassword": newPassword,
          },
        ),
      );
      
      if (res.statusCode == 401) {
        LogoutClass.logOut2(context);
        return;
      }
      
      var response = json.decode(res.body);

      log(response);

      if (res.statusCode == 200 || res.statusCode == 201) {
        // if status code is 200 show the message
        MyMessageHandler.showSnackBar(scaffoldKey, response["message"]);
      } else {
        MyMessageHandler.showSnackBar(scaffoldKey, response["error"]);
        log(response["error"]);
      }
    } catch (e) {
      log(e.toString());
      MyMessageHandler.showSnackBar(scaffoldKey, "Check your network");
    }
  }
}
