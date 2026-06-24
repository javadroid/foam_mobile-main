import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:foam_mobile/core/hive/hive.dart';
import 'package:foam_mobile/feature/authentication/model/log_out_model.dart';
import 'package:foam_mobile/utils/values.dart';
import 'package:foam_mobile/widgets/message_handler.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ChangeAddressController {
  static Future<void> changeAddress(
    BuildContext context,
    GlobalKey<ScaffoldMessengerState> scaffoldKey, {
    required String street,
    required String city,
    required String country,
  }) async {
    try {
      http.Response res = await http.post(
        Uri.parse(
          "${Constants.url}/api/user/address",
        ),
        headers: {
          "Accept": "application/json",
          'Content-Type': 'application/json',
          "Authorization": "Bearer ${HiveClass.getToken()}",
        },
        body: jsonEncode({
          "street": street,
          "city": city,
          "postalCode": "",
          "country": country
        }),
      );
      
      if (res.statusCode == 401) {
        LogoutClass.logOut2(context);
        return;
      }

      var response = json.decode(res.body);

      log(jsonEncode(response)); // Convert Map to String

      if (res.statusCode == 200 || res.statusCode == 201) {
        MyMessageHandler.showSnackBar(
            scaffoldKey, response["message"] ?? "Address updated successfully");
      } else {
        MyMessageHandler.showSnackBar(
            scaffoldKey, response["error"] ?? "An unknown error occurred");
        log("@@@@@@ERROR");
        log(response["error"].toString()); // Ensure it's a String
      }
    } catch (e) {
      log(e.toString());
      MyMessageHandler.showSnackBar(scaffoldKey, "Check your network");
    }
  }
}
