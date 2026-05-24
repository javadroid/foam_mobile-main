import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class AuthProvider extends ChangeNotifier {
  // User details initially empty
  String firstName = '';
  String lastName = '';
  String middleName = '';
  String phoneNumber = '';
  String email = '';
  String password = '';
  String addressStreet = '';
  String addressCity = '';
  String addressPostalCode = '';
  String addressCountry = '';

  Map<String, dynamic> user = {};

  bool initDone = false;

  bool _initError = false;

  bool get initError => _initError;

  void updateDone(bool done) {
    initDone = done;
    notifyListeners();
    log('init done $initDone');
  }

  void updateError(bool error) {
    _initError = error;
    notifyListeners();
    log('init error $initError');
  }

  Map<String, dynamic> getUser() {
    user = {
      'firstName': firstName,
      'lastName': lastName,
      'middleName': middleName,
      'phoneNumber': phoneNumber,
      'email': email,
      'addressStreet': addressStreet,
      'addressCity': addressCity,
      'addressPostalCode': addressPostalCode,
      'addressCountry': addressCountry,
    };
    return user;
  }

  void clearAuth() {
    firstName = '';
    lastName = '';
    middleName = '';
    phoneNumber = '';
    email = '';
    password = '';
    addressStreet = '';
    addressCity = '';
    addressPostalCode = '';
    addressCountry = '';
    user = {};
    notifyListeners();
  }

  void fillAuth(
    String userFirstName,
    String userLastName,
    String? userMiddleName,
    String userEmail,
    String userPhoneNumber,
  ) {
    firstName = userFirstName;
    lastName = userLastName;
    middleName = userMiddleName ?? '';
    email = userEmail;
    phoneNumber = userPhoneNumber;
    notifyListeners();
  }

  void fillAddress(
    String userAddressStreet,
    String userAddressCity,
    String userAddressPostalCode,
    String userAddressCountry,
  ) {
    addressStreet = userAddressStreet;
    addressCity = userAddressCity;
    addressPostalCode = userAddressPostalCode;
    addressCountry = userAddressPostalCode;
    notifyListeners();
  }
}
