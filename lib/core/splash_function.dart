import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:foam_mobile/core/hive/hive.dart';
import 'package:foam_mobile/core/intro_screens/onboarding_screen.dart';
import 'package:foam_mobile/feature/authentication/controller/provider/authprovider.dart';
import 'package:foam_mobile/feature/authentication/model/log_out_model.dart';
import 'package:foam_mobile/utils/values.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

class SplashFunction {
  static Future<bool> init(BuildContext context) async {
    var authProvider = Provider.of<AuthProvider>(context, listen: false);

    final String? token = HiveClass.getToken();
    if (token == null || token.isEmpty) {
      return false;
    }

    try {
      final http.Response res = await http.get(
        Uri.parse(
          "${Constants.url}/api/user/profile",
        ),
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
          'Content-Type': 'application/json'
        },
      ).timeout(const Duration(seconds: 7));
      debugPrint('Profile response status: ${res.statusCode}');
      debugPrint('Profile response body: ${res.body}');
      
      if (res.statusCode == 401) {
        LogoutClass.logOut2(context);
        return false;
      }
      
      var response = json.decode(res.body);

      if (res.statusCode == 200 || res.statusCode == 201) {
        var user = response["user"];
        authProvider.fillAuth(
          user["firstName"],
          user["lastName"],
          user["middleName"] ?? '',
          user["email"],
          user["phone"],
        );

        bool hasAddress = false;
        if (user["address"] != null && user["address"] is List && (user["address"] as List).isNotEmpty) {
          var address = user["address"][0];
          authProvider.fillAddress(
            address["street"],
            address["city"],
            address["postalCode"],
            address["country"],
          );
          hasAddress = true;
        } else {
          hasAddress = await getAddress(context);
        }

        authProvider.updateDone(true);
        return hasAddress;
      } else {
        debugPrint('Profile request failed with status: ${res.statusCode}');
        authProvider.updateError(true);
        return false;
      }
    } catch (e, stackTrace) {
      debugPrint('Error in init: $e');
      debugPrint('Stack trace: $stackTrace');
      authProvider.updateError(true);
      return false;
    }
  }

  static Future<bool> getAddress(BuildContext context) async {
    try {
      final res = await http.get(
        Uri.parse(
          "${Constants.url}/api/user/address",
        ),
        headers: {
          // here you get authorize by adding the token like a key to the header to have answers
          "Authorization": "Bearer ${HiveClass.getToken()}",
          "Accept": "application/json",
          'Content-Type': 'application/json'
        },
      );
      debugPrint('Address response status: ${res.statusCode}');
      debugPrint('Address response body: ${res.body}');
      
      if (res.statusCode == 401) {
        LogoutClass.logOut2(context);
        return false;
      }
      
      var response = json.decode(res.body);
      if (res.statusCode == 200 || res.statusCode == 201) {
        var authProvider = Provider.of<AuthProvider>(context, listen: false);
        if (response["address"] != null && (response["address"] as List).isNotEmpty) {
          var address = response["address"][0];
          authProvider.fillAddress(
            address["street"],
            address["city"],
            address["postalCode"],
            address["country"],
          );
          return true;
        }
        return false;
      } else {
        debugPrint('Address request failed with status: ${res.statusCode}');
        return false;
      }
    } catch (e, stackTrace) {
      debugPrint('Error in getAddress: $e');
      debugPrint('Stack trace: $stackTrace');
      return false;
    }
  }
}
