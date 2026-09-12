import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:foam_mobile/core/Screens/main_screen.dart';
import 'package:foam_mobile/core/Screens/profile/profile_image/view/profile_image.dart';
import 'package:foam_mobile/core/hive/hive.dart';
import 'package:foam_mobile/feature/authentication/controller/location/select_location_controlller.dart';
import 'package:foam_mobile/feature/authentication/controller/provider/authprovider.dart';
import 'package:foam_mobile/feature/authentication/model/change_address_controller.dart';
import 'package:foam_mobile/feature/authentication/model/change_password_model.dart';
import 'package:foam_mobile/utils/values.dart';
import 'package:foam_mobile/widgets/custom_API_button.dart';
import 'package:foam_mobile/widgets/click_button.dart';
import 'package:foam_mobile/widgets/my_text_field.dart';
import 'package:foam_mobile/widgets/profile_tile.dart';
import 'package:foam_mobile/feature/authentication/view/sign_up_pages/sign_up_1.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback? toHome;

  const ProfileScreen({
    this.toHome,
    super.key,
  });

  static const String id = '/profile';

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final GlobalKey<ScaffoldMessengerState> scaffoldKey =
      GlobalKey<ScaffoldMessengerState>();
  String? firstName;
  String? lastName;
  String? addressStreet;
  String? phoneNumber;
  bool loading = false;
  final TextEditingController _addressController = TextEditingController();

  Future<void> fetchAddress() async {
    try {
      final res = await http.get(
        Uri.parse("${Constants.url}/api/user/address"),
        headers: {
          "Authorization": "Bearer ${HiveClass.getToken()}",
          "Accept": "application/json",
          "Content-Type": "application/json",
        },
      );
      if (!mounted) return;
      var response = json.decode(res.body);
      if (res.statusCode == 200 || res.statusCode == 201) {
        var authProvider = Provider.of<AuthProvider>(context, listen: false);
        if (response["address"] != null &&
            (response["address"] as List).isNotEmpty) {
          var address = response["address"][0];
          authProvider.fillAddress(
            address["street"],
            address["city"],
            address["postalCode"],
            address["country"],
          );
          setState(() {
            _addressController.text = address["street"] ?? '';
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching address: $e");
    }
  }

  // password matching error message
  void showErrorMessage(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                message,
                overflow: TextOverflow.visible,
                style: const TextStyle(
                  fontWeight: FontWeight.normal,
                  fontSize: 17,
                  color: Colors.black54,
                ),
              ),
              IconButton(
                onPressed: () {
                  //pop once to remove the dialog box
                  Navigator.pop(context);
                },
                icon: const Icon(
                  Icons.cancel,
                  color: Colors.red,
                  size: 40.0,
                ),
              )
            ],
          ),
        );
      },
    );
  }

  // to change the password
  void changePassword(String message) {
    TextEditingController oldPassword = TextEditingController();
    TextEditingController newPassword = TextEditingController();
    TextEditingController confirmPassword = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              Row(
                children: [
                  AppSpaces.horizontalSpace10,
                  Text(
                    message,
                    overflow: TextOverflow.visible,
                    style: Constants.headingStyle.copyWith(fontSize: 18),
                  ),
                  AppSpaces.horizontalSpace10,
                ],
              ),
              AppSpaces.verticalSpace20,
              MyTextField(
                controller: oldPassword,
                hinText: 'Current password',
                obscureText: true,
                isPassword: true,
              ),
              AppSpaces.verticalSpace10,
              MyTextField(
                controller: newPassword,
                hinText: 'New password',
                obscureText: true,
                isPassword: true,
              ),
              AppSpaces.verticalSpace10,
              MyTextField(
                controller: confirmPassword,
                hinText: 'Confirm password',
                obscureText: true,
                isPassword: true,
              ),
              AppSpaces.verticalSpace20,
              CustomAPIButton(
                text: 'Save Password',
                isLoading: loading,
                color: AppColors.secondaryBackgroundColor,
                onPressed: () async {
                  if (oldPassword.text == '' || newPassword.text == '') {
                    showErrorMessage('Insert Password');
                  } else if (newPassword.text == confirmPassword.text) {
                    setState(() {
                      loading = true;
                    });

                    // then pop up
                    Navigator.pop(context);

                    await ChangePasswordModel.changePassword(
                      context,
                      scaffoldKey,
                      oldPassword.text,
                      newPassword.text,
                    );

                    setState(() {
                      loading = false;
                    });
                  } else {
                    showErrorMessage('Password not matching');
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void initState() {
    var authProvider = Provider.of<AuthProvider>(context, listen: false);
    super.initState();
    setState(() {
      lastName = authProvider.lastName;
      _addressController.text = authProvider.addressStreet;
      firstName = authProvider.firstName;
      phoneNumber = authProvider.phoneNumber;
    });
    // Fetch address in case it's not already loaded
    fetchAddress();
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: scaffoldKey,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new,
              color: AppColors.blackAccentColor,
            ),
            onPressed: () {
              Navigator.pushReplacementNamed(context, MainScreen.id);
            },
          ),
          title: Text(
            'Profile',
            overflow: TextOverflow.ellipsis,
            style: Constants.headingStyle,
          ),
        ),
        body: ListView(
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 20),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  ProfileImage(
                    radius: MediaQuery.sizeOf(context).height * 0.045,
                    initials: '${firstName![0]} ${lastName![0]}',
                  ),
                ],
              ),
            ),
            AppSpaces.verticalSpace20,
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  flex: 1,
                  child: ProfileTile(
                    title: 'First Name',
                    label: firstName!,
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: ProfileTile(
                    title: 'Last Name',
                    label: lastName!,
                  ),
                ),
              ],
            ),
            AppSpaces.verticalSpace20,
            ProfileTile(
              title: 'Phone Number',
              label: phoneNumber!,
            ),
            AppSpaces.verticalSpace20,
            Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                // Update _addressController if authProvider.addressStreet changed
                if (_addressController.text != authProvider.addressStreet) {
                  _addressController.text = authProvider.addressStreet;
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_addressController.text == '')
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Address'),
                            AppSpaces.verticalSpace10,
                            LocationAutocompleteWidget(
                              onLocationSelected: (String address) {},
                              onLocationCoordinatesSelected: (String address, double? lat, double? lng) {
                                setState(() {
                                  List<String> parts = address
                                      .split(',')
                                      .map((part) => part.trim())
                                      .toList();
                                  String street = parts.isNotEmpty ? parts[0] : address;
                                  String city = parts.length > 1 ? parts[1] : 'Port Harcourt';
                                  String country = parts.length > 2 ? parts.last : 'Nigeria';
                                  ChangeAddressController.changeAddress(
                                    context,
                                    scaffoldKey,
                                    street: street,
                                    city: city,
                                    country: country,
                                    latitude: lat,
                                    longitude: lng,
                                  );
                                  _addressController.text = address;
                                  Provider.of<AuthProvider>(context,
                                          listen: false)
                                      .addressStreet = address;
                                });
                              },
                            ),
                          ],
                        ),
                      )
                    else
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SignUpPage1(),
                            ),
                          );
                        },
                        child: ProfileTile(
                          title: 'Address',
                          label: _addressController.text,
                        ),
                      ),
                  ],
                );
              },
            ),
            AppSpaces.verticalSpace50,
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18.0),
              child: ClickButton(
                text: 'Update Address',
                textColor: Colors.white,
                color: AppColors.secondaryBackgroundColor,
                fontSize: 16,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SignUpPage1(),
                    ),
                  );
                },
              ),
            ),
            AppSpaces.verticalSpace20,
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18.0),
              child: ClickButton(
                text: 'Change Password',
                textColor: Colors.white,
                color: AppColors.secondaryBackgroundColor,
                fontSize: 16,
                onPressed: () {
                  changePassword(
                    'Change Password',
                  );
                  // ChangePasswordWidget();
                },
              ),
            ),
            AppSpaces.verticalSpace20,
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18.0),
              child: ClickButton(
                text: 'Delete Account',
                textColor: Colors.white,
                color: AppColors.secondaryBackgroundColor,
                fontSize: 16,
                onPressed: () {},
              ),
            ),
          ],
        ),
      ),
    );
  }
}
