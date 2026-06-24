import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:foam_mobile/core/hive/hive.dart';
import 'package:foam_mobile/feature/authentication/view/auth_pages/login_or_register_page.dart';
import 'package:foam_mobile/feature/authentication/view/verify_pages/verification_screen.dart';
import 'package:foam_mobile/utils/values.dart';
import 'package:foam_mobile/utils/values/validator.dart';
import 'package:foam_mobile/widgets/message_handler.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:foam_mobile/feature/authentication/controller/provider/authprovider.dart';

import 'package:foam_mobile/core/Screens/main_screen.dart';
import 'package:foam_mobile/core/splash_function.dart';

class SignUpModel {
  static void login(BuildContext context) {
    Navigator.of(context).pushNamed(LoginOrRegisterPage.id);
  }

  static Future<bool> signUp(
    BuildContext context,
    String email,
    String password,
    String phoneNumber,
    GlobalKey<ScaffoldMessengerState> scaffoldKey,
  ) async {
    if (phoneNumber.isEmpty) {
      MyMessageHandler.showSnackBar(scaffoldKey, "Input Phone number");
      return false;
    } else if (!phoneNumber.isValidPhoneNumber()) {
      MyMessageHandler.showSnackBar(scaffoldKey, "Input a valid phone number");
      return false;
    } else if (!email.trim().isValidEmail()) {
      MyMessageHandler.showSnackBar(scaffoldKey, 'Enter a valid email');
      return false;
    } else if ((password.length < 8)) {
      MyMessageHandler.showSnackBar(scaffoldKey, 'Password is too short');
      return false;
    } else {
      // Response
      return true;
    }
  }

  static Future<void> getStarted(
      BuildContext context,
      String firstName,
      String lastName,
      String phoneNumber,
      String email,
      String password,
      GlobalKey<ScaffoldMessengerState> scaffoldKey) async {
    if (firstName.isEmpty) {
      MyMessageHandler.showSnackBar(scaffoldKey, "Input Fisrt Name");
    } else if (lastName.isEmpty) {
      MyMessageHandler.showSnackBar(scaffoldKey, "Input Last Name");
    } else if (phoneNumber.isEmpty) {
      MyMessageHandler.showSnackBar(scaffoldKey, "Input Phone number");
    } else if (!phoneNumber.isValidPhoneNumber()) {
      MyMessageHandler.showSnackBar(
          scaffoldKey, "Input a valid phone number stating with 0");
    } else {
      try {
        http.Response res = await http.post(
          Uri.parse("${Constants.url}/api/auth/register"),
          headers: {
            "Accept": "application/json",
            'Content-Type': 'application/json'
          },
          body: jsonEncode(
            {
              "firstName": firstName,
              "lastName": lastName,
              "email": email,
              "middleName": '',
              "password": password,
              "phone": phoneNumber,
            },
          ),
        );

        var response = json.decode(res.body);
        debugPrint("SignUpModel getStarted response: ${res.body}");

        if (res.statusCode == 201 || res.statusCode == 200) {
          var authProvider = Provider.of<AuthProvider>(context, listen: false);
          authProvider.fillAuth(firstName, lastName, '', email, phoneNumber);
          authProvider.password = password;

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const VerificationScreen(),
            ),
          );
          MyMessageHandler.showSnackBar(scaffoldKey, response["message"]);
        } else {
          MyMessageHandler.showSnackBar(scaffoldKey, response["error"]);
        }
      } catch (e) {
        debugPrint("SignUpModel getStarted error: ${e.toString()}");
        MyMessageHandler.showSnackBar(scaffoldKey, "Check your network");
      }
    }
  }

  static Future<void> inputToken(
    BuildContext context,
    String email,
    String password,
    GlobalKey<ScaffoldMessengerState> scaffoldKey,
  ) async {
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

      if (res.statusCode == 200) {
        // if status code is 200 show the message
        MyMessageHandler.showSnackBar(scaffoldKey, 'Get Started...');
        // then insert user token
        HiveClass.insertToken(
          response["token"],
        );
      } else {
        MyMessageHandler.showSnackBar(scaffoldKey, response["error"]);
      }
    } catch (e) {
      MyMessageHandler.showSnackBar(scaffoldKey, "Check your network");
    }
  }

  static Future<void> getInputAddress(
      BuildContext context,
      String street,
      String city,
      String postalCode,
      String country,
      GlobalKey<ScaffoldMessengerState> scaffoldKey) async {
    if (street.isEmpty) {
      MyMessageHandler.showSnackBar(scaffoldKey, "Input Street Name");
    } else if (city.isEmpty) {
      MyMessageHandler.showSnackBar(scaffoldKey, "Input City Name");
    } else if (postalCode.isEmpty) {
      MyMessageHandler.showSnackBar(scaffoldKey, "Input Postal Code number");
    } else if (country.isEmpty) {
      MyMessageHandler.showSnackBar(scaffoldKey, "Input Country Name");
    } else {
      try {
        http.Response res = await http.post(
          Uri.parse("${Constants.url}/api/user/address"),
          headers: {
            // here you get authorize by adding the token like a key to the header to have answers
            "Authorization": "Bearer ${HiveClass.getToken()}",
            "Accept": "application/json",
            'Content-Type': 'application/json'
          },
          body: jsonEncode(
            {
              "street": street,
              "city": city,
              "postalCode": postalCode,
              "country": country,
            },
          ),
        );

        var response = json.decode(res.body);
        log(res.body);

        if (res.statusCode == 201 || res.statusCode == 200) {
          // Reload all data before navigating to home
          await SplashFunction.init(context);

          Navigator.of(context, rootNavigator: true)
              .pushNamedAndRemoveUntil(MainScreen.id, (route) => false);
          MyMessageHandler.showSnackBar(scaffoldKey, response["message"]);
        } else {
          MyMessageHandler.showSnackBar(scaffoldKey, response["error"]);
        }
      } catch (e) {
        log(e.toString());
        log(country);
        log(city);
        log(postalCode);
        log(street);
        log(HiveClass.getToken());
        MyMessageHandler.showSnackBar(scaffoldKey, e.toString());
      }
    }
  }
}
