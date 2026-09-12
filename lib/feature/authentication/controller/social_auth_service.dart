import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:foam_mobile/core/hive/hive.dart';
import 'package:foam_mobile/feature/authentication/model/login_model.dart';
import 'package:foam_mobile/utils/values.dart';
import 'package:foam_mobile/widgets/gradient_button.dart';
import 'package:foam_mobile/widgets/message_handler.dart';
import 'package:foam_mobile/widgets/my_text_field.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class SocialAuthService {
  static bool _initialized = false;

  static Future<GoogleSignIn> _getGoogleSignIn() async {
    final GoogleSignIn signIn = GoogleSignIn.instance;
    if (!_initialized) {
      final String clientId = Platform.isAndroid
          ? Constants.googleClientId
          : Constants.googleIosClientId;
      await signIn.initialize(
        serverClientId: clientId,
        clientId: clientId,
      );
      _initialized = true;
    }
    return signIn;
  }

  /// Handle Google Sign In / Registration
  static Future<void> handleGoogleSignIn(
    BuildContext context,
    GlobalKey<ScaffoldMessengerState>? scaffoldKey,
  ) async {
    try {
      final GoogleSignIn googleSignIn = await _getGoogleSignIn();

      // Disconnect previous session to allow selecting an account again if needed
      try {
        await googleSignIn.signOut();
      } catch (_) {}

      final GoogleSignInAccount account =
          await googleSignIn.authenticate(scopeHint: const <String>['email']);

      final GoogleSignInAuthentication auth = account.authentication;
      final String? idToken = auth.idToken;

      if (idToken == null) {
        _showError(scaffoldKey,
            'Unable to retrieve Google authentication token. Please try again.');
        return;
      }

      debugPrint("Google Sign-In successful for: ${account.email}");
      debugPrint(
          "idToken: ${Uri.parse('${Constants.url}/api/auth/google/callback/login?idToken=${Uri.encodeComponent(idToken)}').toString()}");

      // 1. Try logging in first
      final http.Response loginRes = await http.get(
        Uri.parse(
            '${Constants.url}/api/auth/google/callback/login?idToken=${Uri.encodeComponent(idToken)}'),
        headers: <String, String>{
          'Accept': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
      );

      debugPrint('loginRes: $loginRes');
      final dynamic loginBody = jsonDecode(loginRes.body);
      debugPrint(
          'Google login status: ${loginRes.statusCode}, body: $loginBody');

      if (loginRes.statusCode == 200) {
        final String token = loginBody['token'];
        HiveClass.insertToken(token);
        _showSuccess(scaffoldKey, 'Google sign in successful');
        if (context.mounted) {
          await LoginClass.getProfile(context, scaffoldKey!, isSignup: false);
        }
        return;
      }

      // 2. If user is not found (404), prompt for phone number to register
      if (loginRes.statusCode == 404) {
        if (!context.mounted) return;
        await _showPhonePromptDialog(
          context: context,
          scaffoldKey: scaffoldKey,
          providerName: 'Google',
          email: account.email,
          displayName: account.displayName,
          onComplete: (String phoneNumber) async {
            await _registerGoogleUser(
              context: context,
              scaffoldKey: scaffoldKey,
              idToken: idToken,
              phoneNumber: phoneNumber,
            );
          },
        );
        return;
      }

      // Other error response
      final String errorMsg = loginBody['error'] ??
          'Google sign in could not be completed. Please try again.';
      _showError(scaffoldKey, errorMsg);
    } catch (e, stackTrace) {
      final String errStr = e.toString();
      // Handle user cancellation gracefully without intrusive error toast
      if (errStr.contains('canceled') ||
          errStr.contains('cancelled') ||
          errStr.contains('sign_in_canceled')) {
        log('Google Sign-In cancelled by user');
        return;
      }
      debugPrint('Google Sign In Error: $e');
      log('Google Sign In Error: $e', stackTrace: stackTrace);
      _showError(scaffoldKey, 'Unable to sign in with Google.');
    }
  }

  /// Register new user with Google ID token & Phone Number
  static Future<void> _registerGoogleUser({
    required BuildContext context,
    required GlobalKey<ScaffoldMessengerState>? scaffoldKey,
    required String idToken,
    required String phoneNumber,
  }) async {
    try {
      final http.Response regRes = await http.post(
        Uri.parse(
            '${Constants.url}/api/auth/google/callback/register?idToken=${Uri.encodeComponent(idToken)}'),
        headers: <String, String>{
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode(<String, dynamic>{
          'phone': phoneNumber,
        }),
      );

      final dynamic regBody = jsonDecode(regRes.body);
      log('Google register status: ${regRes.statusCode}, body: $regBody');

      if (regRes.statusCode == 200 || regRes.statusCode == 201) {
        final String token = regBody['token'];
        HiveClass.insertToken(token);
        _showSuccess(
            scaffoldKey, regBody['message'] ?? 'Registration successful');
        if (context.mounted) {
          await LoginClass.getProfile(context, scaffoldKey!, isSignup: true);
        }
      } else {
        final String errorMsg = regBody['error'] ??
            'Google registration could not be completed. Please try again.';
        _showError(scaffoldKey, errorMsg);
      }
    } catch (e) {
      log('Google Register Error: $e');
      _showError(scaffoldKey,
          'Unable to complete registration. Please check your connection and try again.');
    }
  }

  /// Handle Apple Sign In / Registration
  static Future<void> handleAppleSignIn(
    BuildContext context,
    GlobalKey<ScaffoldMessengerState>? scaffoldKey,
  ) async {
    try {
      // Check if running on Android or Apple Sign In is not supported on this device
      if (Platform.isAndroid) {
        _showError(
          scaffoldKey,
          'Apple Sign-In is only available on iOS devices. Please continue with Google or Email.',
        );
        return;
      }

      final bool isAvailable = await SignInWithApple.isAvailable();
      if (!isAvailable) {
        _showError(
          scaffoldKey,
          'Apple Sign-In is not supported on this device. Please continue with Google or Email.',
        );
        return;
      }

      final AuthorizationCredentialAppleID credential =
          await SignInWithApple.getAppleIDCredential(
        scopes: <AppleIDAuthorizationScopes>[
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final String? identityToken = credential.identityToken;
      if (identityToken == null) {
        _showError(scaffoldKey,
            'Unable to retrieve Apple authentication token. Please try again.');
        return;
      }

      final String? appleEmail = credential.email;
      final String? firstName = credential.givenName;
      final String? lastName = credential.familyName;

      log('Apple Sign-In successful. User: ${credential.userIdentifier}, email: $appleEmail');

      // 1. Try logging in first
      final http.Response loginRes = await http.get(
        Uri.parse(
            '${Constants.url}/api/auth/apple/callback/login?identityToken=${Uri.encodeComponent(identityToken)}'),
        headers: <String, String>{
          'Accept': 'application/json',
          'Authorization': 'Bearer $identityToken',
        },
      );

      final dynamic loginBody = jsonDecode(loginRes.body);
      log('Apple login status: ${loginRes.statusCode}, body: $loginBody');

      if (loginRes.statusCode == 200) {
        final String token = loginBody['token'];
        HiveClass.insertToken(token);
        _showSuccess(scaffoldKey, 'Apple sign in successful');
        if (context.mounted) {
          await LoginClass.getProfile(context, scaffoldKey!, isSignup: false);
        }
        return;
      }

      // 2. If user is not found (404), prompt for phone number & registration details
      if (loginRes.statusCode == 404) {
        if (!context.mounted) return;
        await _showPhonePromptDialog(
          context: context,
          scaffoldKey: scaffoldKey,
          providerName: 'Apple',
          email: appleEmail,
          displayName: [firstName, lastName]
              .where((s) => s != null && s.isNotEmpty)
              .join(' '),
          requireEmail: appleEmail == null,
          onCompleteWithDetails: (String phoneNumber, String? email,
              String? fName, String? lName) async {
            await _registerAppleUser(
              context: context,
              scaffoldKey: scaffoldKey,
              identityToken: identityToken,
              phoneNumber: phoneNumber,
              email: email ?? appleEmail,
              firstName: fName ?? firstName,
              lastName: lName ?? lastName,
            );
          },
        );
        return;
      }

      // Other error response
      final String errorMsg = loginBody['error'] ??
          'Apple sign in could not be completed. Please try again.';
      _showError(scaffoldKey, errorMsg);
    } on SignInWithAppleAuthorizationException catch (e, stackTrace) {
      log('Apple Auth Exception: ${e.code}', stackTrace: stackTrace);
      if (e.code == AuthorizationErrorCode.canceled) {
        // User cancelled Apple sign in dialog
        return;
      }
      _showError(scaffoldKey,
          'Apple Sign-In was cancelled or could not be completed.');
    } catch (e, stackTrace) {
      log('Apple Sign In Error: $e', stackTrace: stackTrace);
      _showError(scaffoldKey,
          'Apple Sign-In is unavailable on this device. Please use Google or Email.');
    }
  }

  /// Register new user with Apple identity token & details
  static Future<void> _registerAppleUser({
    required BuildContext context,
    required GlobalKey<ScaffoldMessengerState>? scaffoldKey,
    required String identityToken,
    required String phoneNumber,
    String? email,
    String? firstName,
    String? lastName,
  }) async {
    try {
      final http.Response regRes = await http.post(
        Uri.parse(
            '${Constants.url}/api/auth/apple/callback/register?identityToken=${Uri.encodeComponent(identityToken)}'),
        headers: <String, String>{
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $identityToken',
        },
        body: jsonEncode(<String, dynamic>{
          'phone': phoneNumber,
          if (email != null) 'email': email,
          if (firstName != null) 'firstName': firstName,
          if (lastName != null) 'lastName': lastName,
        }),
      );

      final dynamic regBody = jsonDecode(regRes.body);
      log('Apple register status: ${regRes.statusCode}, body: $regBody');

      if (regRes.statusCode == 200 || regRes.statusCode == 201) {
        final String token = regBody['token'];
        HiveClass.insertToken(token);
        _showSuccess(
            scaffoldKey, regBody['message'] ?? 'Registration successful');
        if (context.mounted) {
          await LoginClass.getProfile(context, scaffoldKey!, isSignup: true);
        }
      } else {
        final String errorMsg = regBody['error'] ??
            'Apple registration could not be completed. Please try again.';
        _showError(scaffoldKey, errorMsg);
      }
    } catch (e) {
      log('Apple Register Error: $e');
      _showError(scaffoldKey,
          'Unable to complete registration. Please check your connection and try again.');
    }
  }

  /// Bottom sheet to prompt for phone number (and email/name if missing)
  static Future<void> _showPhonePromptDialog({
    required BuildContext context,
    required GlobalKey<ScaffoldMessengerState>? scaffoldKey,
    required String providerName,
    String? email,
    String? displayName,
    bool requireEmail = false,
    Function(String phoneNumber)? onComplete,
    Function(String phoneNumber, String? email, String? firstName,
            String? lastName)?
        onCompleteWithDetails,
  }) async {
    final TextEditingController phoneController = TextEditingController();
    final TextEditingController emailController =
        TextEditingController(text: email ?? '');
    final TextEditingController nameController =
        TextEditingController(text: displayName ?? '');
    bool isSubmitting = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext sheetContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 24,
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Complete Your Profile',
                      style: GoogleFonts.dmSans(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Please provide your phone number to finish setting up your account with $providerName.',
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (requireEmail || (email == null || email.isEmpty)) ...[
                      MyTextField(
                        controller: emailController,
                        hinText: 'Email address',
                        keyboardType: TextInputType.emailAddress,
                        obscureText: false,
                        isPassword: false,
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (displayName == null || displayName.isEmpty) ...[
                      MyTextField(
                        controller: nameController,
                        hinText: 'Full Name',
                        obscureText: false,
                        isPassword: false,
                      ),
                      const SizedBox(height: 12),
                    ],
                    MyTextField(
                      controller: phoneController,
                      hinText: 'Phone Number (e.g. 08012345678)',
                      keyboardType: TextInputType.phone,
                      obscureText: false,
                      isPassword: false,
                    ),
                    const SizedBox(height: 24),
                    GradientButton(
                      text: 'Complete Registration',
                      isLoading: isSubmitting,
                      onPressed: () async {
                        final String phone = phoneController.text.trim();
                        if (phone.length < 10 || phone.length > 15) {
                          _showError(scaffoldKey,
                              'Please enter a valid phone number (10-15 digits)');
                          return;
                        }

                        if (requireEmail &&
                            (emailController.text.trim().isEmpty ||
                                !emailController.text.contains('@'))) {
                          _showError(scaffoldKey,
                              'Please enter a valid email address');
                          return;
                        }

                        setState(() {
                          isSubmitting = true;
                        });

                        Navigator.of(sheetContext).pop();

                        final List<String> nameParts =
                            nameController.text.trim().split(RegExp(r'\s+'));
                        final String? fName =
                            nameParts.isNotEmpty ? nameParts.first : null;
                        final String? lName = nameParts.length > 1
                            ? nameParts.sublist(1).join(' ')
                            : null;

                        if (onComplete != null) {
                          await onComplete(phone);
                        } else if (onCompleteWithDetails != null) {
                          await onCompleteWithDetails(
                            phone,
                            emailController.text.trim().isNotEmpty
                                ? emailController.text.trim()
                                : email,
                            fName,
                            lName,
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  static void _showError(
      GlobalKey<ScaffoldMessengerState>? scaffoldKey, String message) {
    if (scaffoldKey != null) {
      MyMessageHandler.showSnackBar(scaffoldKey, message);
    }
  }

  static void _showSuccess(
      GlobalKey<ScaffoldMessengerState>? scaffoldKey, String message) {
    if (scaffoldKey != null) {
      MyMessageHandler.showSnackBar(scaffoldKey, message);
    }
  }
}
