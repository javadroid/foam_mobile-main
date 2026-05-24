import 'package:flutter/material.dart';
import 'package:foam_mobile/utils/values.dart';

class MyMessageHandler {
  static void showSnackBar(
      GlobalKey<ScaffoldMessengerState> scaffoldKey, String message) {
    scaffoldKey.currentState!.hideCurrentSnackBar();
    scaffoldKey.currentState!.showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 2),
        backgroundColor: AppColors.primaryAccentColor,
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 18,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
