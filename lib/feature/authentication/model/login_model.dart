import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:foam_mobile/core/Screens/main_screen.dart';
import 'package:foam_mobile/core/hive/hive.dart';
import 'package:foam_mobile/feature/authentication/controller/provider/authprovider.dart';
import 'package:foam_mobile/feature/authentication/view/forgot_password_pages/forgot_email_page.dart';
import 'package:foam_mobile/feature/authentication/view/sign_up_pages/sign_up_0.dart';
import 'package:foam_mobile/utils/values.dart';
import 'package:foam_mobile/utils/values/validator.dart';
import 'package:foam_mobile/widgets/message_handler.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';

import 'package:foam_mobile/core/splash_function.dart';
import 'package:foam_mobile/feature/authentication/view/sign_up_pages/sign_up_1.dart';

class LoginClass {
  static Future<void> login(BuildContext context, String email, String password,
      GlobalKey<ScaffoldMessengerState> scaffoldKey, {bool isSignup = false}) async {
    if (!email.trim().isValidEmail()) {
      MyMessageHandler.showSnackBar(scaffoldKey, "Please input a valid email");
    } else if (password.isEmpty) {
      MyMessageHandler.showSnackBar(scaffoldKey, "Please Input a password");
    } else {
      log("email $email password $password");
      try {
        http.Response res = await http.post(
          Uri.parse(
            "${Constants.url}/api/auth/login",
          ),
          headers: {
            "Accept": "application/json",
            'Content-Type': 'application/json'
          },
          body: jsonEncode(
            {
              "email": email,
              "password": password,
            },
          ),
        );
        var response = json.decode(res.body);

        log(response.toString());

        if (res.statusCode == 200) {
          // if status code is 200 show the message
          MyMessageHandler.showSnackBar(scaffoldKey, response["message"]);
          // then insert user token
          HiveClass.insertToken(
            response["token"],
          );
          getProfile(context, scaffoldKey, isSignup: isSignup);
        } else {
          MyMessageHandler.showSnackBar(scaffoldKey, response["error"]);
        }
      } catch (e) {
        log(e.toString());
        MyMessageHandler.showSnackBar(scaffoldKey, e.toString());
      }
    }
  }

  static Future<void> getProfile(
    BuildContext context,
    GlobalKey<ScaffoldMessengerState> scaffoldKey, {
    bool isSignup = false,
  }) async {
    final res = await http.get(
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
      var authProvider = Provider.of<AuthProvider>(context, listen: false);
      log(res.body);
      var user = response["user"];
      authProvider.fillAuth(
        user["firstName"],
        user["lastName"],
        user["middleName"] ?? '',
        user["email"],
        user["phone"],
      );
      // log(message)(message)(authProvider.getUser());
      getAddress(context, scaffoldKey, isSignup: isSignup);
      // return log(message)(message)(response);
    } else {
      log(res.reasonPhrase.toString());
      log(res.statusCode.toString());
      log(res.headers.toString());
      log(res.body);
      MyMessageHandler.showSnackBar(scaffoldKey, "Failed to load profile");
    }
  }

  static Future<void> getAddress(BuildContext context,
      GlobalKey<ScaffoldMessengerState> scaffoldKey, {bool isSignup = false}) async {
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
      var response = json.decode(res.body);
      debugPrint("Address API status code: ${res.statusCode}");
      debugPrint("Address API response: $response");
      debugPrint("Is signup: $isSignup");
      
      if (res.statusCode == 200 || res.statusCode == 201) {
        var authProvider = Provider.of<AuthProvider>(context, listen: false);
        debugPrint("Response address: ${response["address"]}");
        debugPrint("Address is list: ${response["address"] is List}");
        if (response["address"] is List) {
          debugPrint("Address list length: ${(response["address"] as List).length}");
        }
        
        if (response["address"] != null && (response["address"] as List).isNotEmpty) {
          var address = response["address"][0];
          authProvider.fillAddress(
            address["street"],
            address["city"],
            address["postalCode"],
            address["country"],
          );
          log(authProvider.user.toString());

          // Reload all data to be sure
          await SplashFunction.init(context);

          // If it's not a signup, go to main screen
          if (!isSignup) {
            debugPrint("Going to main screen");
            Navigator.of(context).pushNamedAndRemoveUntil(
              MainScreen.id,
              (Route<dynamic> route) => false,
            );
          } else {
            debugPrint("Going to address page (signup flow)");
            // If it's a signup, go to address page even if address exists
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SignUpPage1(),
              ),
            );
          }
        } else {
          debugPrint("No address found, going to address page");
          // No address found, go to add address screen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const SignUpPage1(),
            ),
          );
        }
        return log(response);
      } else {
        log(res.reasonPhrase.toString());
        log(res.statusCode.toString());
        log(res.headers.toString());
        log(res.body);
        MyMessageHandler.showSnackBar(scaffoldKey, "Failed to load address");
        // Fallback to MainScreen if address fetch fails but status code is not 200 and it's not a signup
        if (!isSignup) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            MainScreen.id,
            (Route<dynamic> route) => false,
          );
        } else {
          // If it's a signup, go to address page
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const SignUpPage1(),
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      debugPrint("Error in getAddress: $e");
      debugPrint("Stack trace: $stackTrace");
      MyMessageHandler.showSnackBar(scaffoldKey, "Address not fetched");
      // Fallback to MainScreen if something goes wrong and it's not a signup
      if (!isSignup) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          MainScreen.id,
          (Route<dynamic> route) => false,
        );
      } else {
        // If it's a signup, go to address page
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const SignUpPage1(),
          ),
        );
      }
    }
  }

  static void register(BuildContext context) =>
      Navigator.of(context).pushNamed(SignUpPage0.id);

  static void forgotPassword(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ForgotPasswordEmail(),
      ),
    );
  }
}
