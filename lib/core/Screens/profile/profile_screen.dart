import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:foam_mobile/core/Screens/main_screen.dart';
import 'package:foam_mobile/core/Screens/profile/profile_image/view/profile_image.dart';
import 'package:foam_mobile/feature/authentication/controller/location/select_location_controlller.dart';
import 'package:foam_mobile/feature/authentication/controller/provider/authprovider.dart';
import 'package:foam_mobile/feature/authentication/model/change_address_controller.dart';
import 'package:foam_mobile/feature/authentication/model/change_password_model.dart';
import 'package:foam_mobile/utils/values.dart';
import 'package:foam_mobile/widgets/custom_API_button.dart';
import 'package:foam_mobile/widgets/click_button.dart';
import 'package:foam_mobile/widgets/my_text_field.dart';
import 'package:foam_mobile/widgets/profile_tile.dart';
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
                    style: Constants.headingStyle.copyWith(fontSize: 24),
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
      _addressController.text =
          Provider.of<AuthProvider>(context, listen: false).addressStreet ?? '';
      firstName = authProvider.firstName;
      phoneNumber = authProvider.phoneNumber;
    });
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
                    initials: 'YN',
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () async {
                    setState(() {
                      _addressController.text = '';
                    });
                  },
                  child: (_addressController.text == '')
                      ? Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 18.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Address'),
                              AppSpaces.verticalSpace10,
                              LocationAutocompleteWidget(
                                onLocationSelected: (String address) {
                                  setState(() {
                                    List<String> parts = address
                                        .split(',')
                                        .map((part) => part.trim())
                                        .toList();
                                    String street = parts[0];
                                    String city = parts[1];
                                    String country = parts[2];
                                    ChangeAddressController.changeAddress(
                                      context,
                                      scaffoldKey,
                                      street: street,
                                      city: city,
                                      country: country,
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
                      : ProfileTile(
                          title: 'Address',
                          label: _addressController.text,
                        ),
                ),
              ],
            ),
            AppSpaces.verticalSpace50,
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18.0),
              child: ClickButton(
                text: 'Change Passsword',
                textColor: Colors.white,
                color: AppColors.secondaryBackgroundColor,
                fontSize: 20,
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
                fontSize: 20,
                onPressed: () {},
              ),
            ),
          ],
        ),
      ),
    );
  }
}
