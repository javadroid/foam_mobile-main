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
import 'package:foam_mobile/core/services/notification_service.dart';
import 'package:foam_mobile/core/services/socket_service.dart';
import 'package:foam_mobile/feature/vendor/onboarding/vendor_approved_screen.dart';
import 'package:foam_mobile/feature/vendor/onboarding/vendor_pending_verification_screen.dart';
import 'package:foam_mobile/feature/vendor/onboarding/vendor_rejected_screen.dart';
import 'package:foam_mobile/feature/vendor/vendor_main_screen.dart';
import 'package:foam_mobile/feature/vendor/onboarding/vendor_onboarding_stepper_screen.dart';
import 'package:foam_mobile/feature/vendor/controller/vendor_provider.dart';
import 'package:foam_mobile/widgets/app_fullscreen_loader.dart';
import 'package:foam_mobile/feature/rider/controller/rider_provider.dart';
import 'package:foam_mobile/feature/rider/models/rider_models.dart';
import 'package:foam_mobile/feature/rider/views/rider_dashboard_screen.dart';
import 'package:foam_mobile/feature/authentication/view/verify_pages/verification_screen.dart';

class LoginClass {
  static Future<void> login(BuildContext context, String email, String password,
      GlobalKey<ScaffoldMessengerState> scaffoldKey,
      {bool isSignup = false}) async {
    if (!email.trim().isValidEmail()) {
      MyMessageHandler.showSnackBar(scaffoldKey, "Please input a valid email");
    } else if (password.isEmpty) {
      MyMessageHandler.showSnackBar(scaffoldKey, "Please Input a password");
    } else {
      debugPrint("email $email password $password");
      AppFullScreenLoader.show(
        context,
        message: 'Signing you in...',
        subtitle: 'Welcome back, checking your informations...',
      );
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

        debugPrint(response.toString());

        final bool requiresVerification = response is Map &&
            (response["requiresVerification"] == true ||
                response["isVerified"] == false);

        if (res.statusCode == 200 && !requiresVerification) {
          // if status code is 200 show the message
          MyMessageHandler.showSnackBar(
              scaffoldKey, response["message"] ?? "Welcome");
          // then insert user token
          HiveClass.insertToken(
            response["token"],
          );

          if (response["isRider"] == true ||
              response["userType"] == "RIDER" ||
              response["role"] == "RIDER") {
            AppFullScreenLoader.hide(context);
            final riderProvider =
                Provider.of<RiderProvider>(context, listen: false);
            if (response["rider"] != null) {
              final riderProfile = RiderProfile.fromJson(response["rider"]);
              riderProvider.setCurrentRiderForTesting(riderProfile,
                  token: response["token"]);
            }
            Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil(
              RiderDashboardScreen.id,
              (Route<dynamic> route) => false,
            );
            return;
          }

          getProfile(context, scaffoldKey, isSignup: isSignup);
        } else if (requiresVerification) {
          AppFullScreenLoader.hide(context);
          MyMessageHandler.showSnackBar(
            scaffoldKey,
            response["message"] ??
                "Your email is not verified. A 6-digit verification code has been sent.",
          );

          final authProvider =
              Provider.of<AuthProvider>(context, listen: false);
          authProvider.email = email.trim();
          authProvider.password = password;

          Navigator.of(context).pushNamed(VerificationScreen.id);
        } else {
          AppFullScreenLoader.hide(context);
          MyMessageHandler.showSnackBar(
              scaffoldKey,
              response["error"] ??
                  response["message"] ??
                  "Invalid email or password");
        }
      } catch (e) {
        AppFullScreenLoader.hide(context);
        debugPrint('Login Error: $e');
        MyMessageHandler.showSnackBar(scaffoldKey,
            "Unable to connect to server. Please check your internet connection.");
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
      debugPrint(res.body);
      var user = response["user"];
      authProvider.fillAuth(
        user["firstName"] ?? '',
        user["lastName"] ?? '',
        user["middleName"] ?? '',
        user["email"] ?? '',
        user["phone"] ?? '',
        role: user["role"] ?? 'USER',
        businessName: user["businessName"] ?? '',
        vendorStatus: user["vendorStatus"] ?? 'NOT_STARTED',
        vendorRejectionReason: user["vendorRejectionReason"],
        avatarUrl: user["avatarUrl"],
      );

      // Register user with OneSignal using their Foam userId as external_id & connect live socket
      if (user["id"] != null) {
        final String userId = user["id"].toString();
        if (userId.isNotEmpty) {
          debugPrint("FOAM_ID $userId");
          NotificationService.registerUser(userId);
          SocketService.connect();
        }
      }

      if (user["role"] == 'RIDER' || user["isRider"] == true) {
        AppFullScreenLoader.hide(context);
        final riderProvider = Provider.of<RiderProvider>(context, listen: false);
        if (user["riderProfile"] != null) {
          riderProvider.setCurrentRiderForTesting(
            RiderProfile.fromJson(user["riderProfile"]),
            token: HiveClass.getToken(),
          );
        }
        Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil(
          RiderDashboardScreen.id,
          (Route<dynamic> route) => false,
        );
        return;
      }

      if (authProvider.isVendor) {
        AppFullScreenLoader.hide(context);
        if (authProvider.vendorStatus == 'APPROVED') {
          final vendorProvider = Provider.of<VendorProvider>(context, listen: false);
          await vendorProvider.fetchStores();
          if (context.mounted) {
            if (vendorProvider.stores.isEmpty) {
              Navigator.of(context).pushNamedAndRemoveUntil(
                VendorApprovedScreen.id,
                (Route<dynamic> route) => false,
              );
            } else {
              Navigator.of(context).pushNamedAndRemoveUntil(
                VendorMainScreen.id,
                (Route<dynamic> route) => false,
              );
            }
          }
        } else if (authProvider.vendorStatus == 'REJECTED') {
          Navigator.of(context).pushNamedAndRemoveUntil(
            VendorRejectedScreen.id,
            (Route<dynamic> route) => false,
          );
        } else if (authProvider.vendorStatus == 'PENDING') {
          Navigator.of(context).pushNamedAndRemoveUntil(
            VendorPendingVerificationScreen.id,
            (Route<dynamic> route) => false,
          );
        } else {
          Navigator.of(context).pushNamedAndRemoveUntil(
            VendorOnboardingStepperScreen.id,
            (Route<dynamic> route) => false,
          );
        }
        return;
      }

      getAddress(context, scaffoldKey, isSignup: isSignup);

      // returndebugPrint(message)(message)(response);
    } else {
      AppFullScreenLoader.hide(context);
      debugPrint(res.reasonPhrase.toString());
      debugPrint(res.statusCode.toString());
      debugPrint(res.headers.toString());
      debugPrint(res.body);
      MyMessageHandler.showSnackBar(scaffoldKey, "Failed to load profile");
    }
  }

  static Future<void> getAddress(
      BuildContext context, GlobalKey<ScaffoldMessengerState> scaffoldKey,
      {bool isSignup = false}) async {
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
          debugPrint(
              "Address list length: ${(response["address"] as List).length}");
        }

        if (response["address"] != null &&
            (response["address"] as List).isNotEmpty) {
          var address = response["address"][0];
          authProvider.fillAddress(
            address["street"],
            address["city"],
            address["postalCode"],
            address["country"],
          );
          debugPrint(authProvider.user.toString());

          // Reload all data to be sure
          await SplashFunction.init(context);

          AppFullScreenLoader.hide(context);

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
          AppFullScreenLoader.hide(context);
          // No address found, go to add address screen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const SignUpPage1(),
            ),
          );
        }
        return debugPrint(response.toString());
      } else {
        AppFullScreenLoader.hide(context);
        debugPrint(res.reasonPhrase.toString());
        debugPrint(res.statusCode.toString());
        debugPrint(res.headers.toString());
        debugPrint(res.body);
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
      AppFullScreenLoader.hide(context);
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
