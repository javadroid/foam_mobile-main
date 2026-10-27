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

  String role = 'USER';
  String businessName = '';
  String vendorStatus = 'NOT_STARTED';
  String? vendorRejectionReason;

  bool get isVendor => role.toUpperCase() == 'VENDOR';
  bool get isVendorVerified => isVendor && vendorStatus == 'APPROVED';
  bool get isVendorPending => isVendor && vendorStatus == 'PENDING';

  Map<String, dynamic> user = {};

  bool initDone = false;

  bool _initError = false;

  bool get initError => _initError;

  void updateDone(bool done) {
    initDone = done;
    notifyListeners();
    debugPrint('init done $initDone');
  }

  void updateError(bool error) {
    _initError = error;
    notifyListeners();
    debugPrint('init error $initError');
  }

  Map<String, dynamic> getUser() {
    user = {
      'firstName': firstName,
      'lastName': lastName,
      'middleName': middleName,
      'phoneNumber': phoneNumber,
      'email': email,
      'role': role,
      'businessName': businessName,
      'vendorStatus': vendorStatus,
      'vendorRejectionReason': vendorRejectionReason,
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
    role = 'USER';
    businessName = '';
    vendorStatus = 'NOT_STARTED';
    vendorRejectionReason = null;
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
    String userPhoneNumber, {
    String? role,
    String? businessName,
    String? vendorStatus,
    String? vendorRejectionReason,
  }) {
    firstName = userFirstName;
    lastName = userLastName;
    middleName = userMiddleName ?? '';
    email = userEmail;
    phoneNumber = userPhoneNumber;
    if (role != null) this.role = role;
    if (businessName != null) this.businessName = businessName;
    if (vendorStatus != null) this.vendorStatus = vendorStatus;
    if (vendorRejectionReason != null) {
      this.vendorRejectionReason = vendorRejectionReason;
    }
    notifyListeners();
  }

  void setVendorStatus(String status, {String? reason}) {
    vendorStatus = status;
    vendorRejectionReason = reason;
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
    addressCountry = userAddressCountry;
    notifyListeners();
  }
}
