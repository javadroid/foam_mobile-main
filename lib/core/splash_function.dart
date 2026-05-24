import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:foam_mobile/core/hive/hive.dart';
import 'package:foam_mobile/feature/authentication/controller/provider/authprovider.dart';
import 'package:foam_mobile/utils/values.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

class SplashFunction {
  static Future<bool> init(BuildContext context) async {
    var authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      final http.Response res = await http.get(
        Uri.parse(
          "${Constants.url}/api/user/profile",
        ),
        headers: {
          // here you get authorize by adding the token like a key to the header to have answers
          "Authorization": "Bearer ${HiveClass.getToken()}",
          "Accept": "application/json",
          'Content-Type': 'application/json'
        },
      );
      var response = json.decode(res.body);

      if (res.statusCode == 200 || res.statusCode == 201) {
        // print(res.body);
        var user = response["user"];
        authProvider.fillAuth(
          user["firstName"],
          user["lastName"],
          user["middleName"],
          user["email"],
          user["phone"],
        );
        await getAddress(context);
        authProvider.updateDone(true);
        return true;
      } else {
        authProvider.updateError(true);
        // print(res.reasonPhrase);
        // print(res.statusCode);
        // print(res.headers);
        // print(res.body);
        return false;
      }
    } catch (e) {
      authProvider.updateError(true);
      return false;
    }
  }

  static Future<void> getAddress(BuildContext context) async {
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
      // print(res.body);
      var response = json.decode(res.body);
      if (res.statusCode == 200 || res.statusCode == 201) {
        var authProvider = Provider.of<AuthProvider>(context, listen: false);
        var address = response["address"][0];
        authProvider.fillAddress(
          address["street"],
          address["city"],
          address["postalCode"],
          address["country"],
        );
        // print(authProvider.user);
        return response;
      } else {
        // print(res.reasonPhrase);
        // print(res.statusCode);
        // print(res.headers);
        // print(res.body);
        return response;
      }
    } catch (e) {
      // print(e.toString());
      Exception(e);
    }
  }
}
