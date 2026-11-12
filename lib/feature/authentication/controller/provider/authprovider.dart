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
  String addressState = '';
  String addressLga = '';
  String addressPostalCode = '';
  String addressCountry = '';
  double? addressLatitude;
  double? addressLongitude;

  String role = 'USER';
  String businessName = '';
  String vendorStatus = 'NOT_STARTED';
  String? vendorRejectionReason;
  String avatarUrl = '';

  bool get isVendor => role.toUpperCase() == 'VENDOR';
  bool get isVendorVerified => isVendor && vendorStatus == 'APPROVED';
  bool get isVendorPending => isVendor && vendorStatus == 'PENDING';

  bool isRiderRegistered = false;
  String riderStatus = 'NOT_REGISTERED';
  bool get isRider => role.toUpperCase() == 'RIDER' || isRiderRegistered;
  bool get isRiderVerified => isRider && riderStatus == 'APPROVED';
  bool get isRiderPending => isRider && riderStatus == 'PENDING';

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
      'avatarUrl': avatarUrl,
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
    avatarUrl = '';
    role = 'USER';
    businessName = '';
    vendorStatus = 'NOT_STARTED';
    vendorRejectionReason = null;
    isRiderRegistered = false;
    riderStatus = 'NOT_REGISTERED';
    addressStreet = '';
    addressCity = '';
    addressState = '';
    addressLga = '';
    addressPostalCode = '';
    addressCountry = '';
    addressLatitude = null;
    addressLongitude = null;
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
    String? avatarUrl,
    dynamic rider,
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
    if (avatarUrl != null) this.avatarUrl = avatarUrl;
    if (rider != null && rider is Map) {
      isRiderRegistered = true;
      riderStatus = (rider['approvalStatus'] ?? 'PENDING').toString().toUpperCase();
    }
    notifyListeners();
  }

  void updateAvatarUrl(String url) {
    avatarUrl = url;
    notifyListeners();
  }

  void setRiderRegistered(bool registered, {String status = 'PENDING'}) {
    isRiderRegistered = registered;
    riderStatus = status;
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
    String userAddressCountry, {
    String? state,
    String? lga,
    double? latitude,
    double? longitude,
  }) {
    addressStreet = userAddressStreet;
    addressCity = userAddressCity;
    addressPostalCode = userAddressPostalCode;
    addressCountry = userAddressCountry;
    if (state != null) addressState = state;
    if (lga != null) addressLga = lga;
    if (latitude != null) addressLatitude = latitude;
    if (longitude != null) addressLongitude = longitude;
    notifyListeners();
  }
}
