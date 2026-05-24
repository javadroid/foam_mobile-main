import 'package:flutter/material.dart';
import 'package:foam_mobile/core/Screens/main_screen.dart';
import 'package:foam_mobile/utils/values.dart';
import 'package:foam_mobile/widgets/gradient_button.dart';
import 'package:foam_mobile/widgets/my_text_field.dart';

class CreateNewPassword extends StatefulWidget {
  const CreateNewPassword({super.key});

  static const String id = '/createnewpassword';

  @override
  State<CreateNewPassword> createState() => _CreateNewPasswordState();
}

class _CreateNewPasswordState extends State<CreateNewPassword> {
  final GlobalKey<ScaffoldMessengerState> _scaffoldKey =
      GlobalKey<ScaffoldMessengerState>();

  //text editing controllers
  final passwordController = TextEditingController();

  final newpasswordController = TextEditingController();

  bool loading = false;

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: _scaffoldKey,
      child: Scaffold(
        appBar: AppBar(),
        backgroundColor: AppColors.primaryBackgroundColor,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 17.0),
                        child: Text(
                          'Create New Password',
                          textAlign: TextAlign.left,
                          style: TextStyle(
                            color: AppColors.blackAccentColor,
                            fontSize: 25,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      AppSpaces.verticalSpace20,
                      AppSpaces.verticalSpace5,

                      //username textfield
                      MyTextField(
                        controller: passwordController,
                        hinText: 'New Password',
                        obscureText: true,
                        isPassword: true,
                      ),

                      AppSpaces.verticalSpace10,

                      //password textfield
                      MyTextField(
                        controller: newpasswordController,
                        hinText: 'Confirm Password',
                        obscureText: true,
                        isPassword: true,
                      ),

                      AppSpaces.verticalSpace10,
                    ],
                  ),
                  AppSpaces.verticalSpace250,
                  AppSpaces.verticalSpace100,
                  AppSpaces.verticalSpace50,
                  Column(
                    children: [
                      //sign in button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          GradientButton(
                            isLoading: loading,
                            onPressed: () =>
                                Navigator.of(context).pushNamedAndRemoveUntil(
                              MainScreen.id,
                              (Route<dynamic> route) => false,
                            ),
                            text: 'Save',
                          ),
                        ],
                      ),

                      AppSpaces.verticalSpace50,

                      //not a member, register here
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Don\'t Have An Account?'),
                          AppSpaces.horizontalSpace5,
                          GestureDetector(
                            onTap: () =>
                                Navigator.of(context, rootNavigator: true)
                                    .pushNamed('/signup'),
                            child: Text(
                              'Sign Up',
                              style: TextStyle(
                                color: AppColors.primaryAccentColor,
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                          ),
                        ],
                      ),
                      AppSpaces.horizontalSpace50,
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
