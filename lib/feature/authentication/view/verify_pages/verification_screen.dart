import 'package:flutter/material.dart';
import 'package:foam_mobile/feature/authentication/view/forgot_password_pages/create_new_password.dart';
import 'package:foam_mobile/feature/authentication/view/sign_up_pages/sign_up_0.dart';
import 'package:foam_mobile/utils/values.dart';
import 'package:foam_mobile/widgets/custom_digit_field.dart';
import 'package:foam_mobile/widgets/gradient_button.dart';

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({super.key});

  static const String id = 'verification_screen';

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final GlobalKey<ScaffoldMessengerState> _scaffoldKey =
      GlobalKey<ScaffoldMessengerState>();

  //text editing controllers
  final emailController = TextEditingController();
  final TextEditingController codeController0 = TextEditingController();
  final TextEditingController codeController1 = TextEditingController();
  final TextEditingController codeController2 = TextEditingController();
  final TextEditingController codeController3 = TextEditingController();

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
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 17.0),
                        child: Text(
                          'Verification',
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

                      //Instruction
                      Text(
                        'Enter The 4 digit code sent to jessica@example.com',
                        textAlign: TextAlign.center,
                        style: Constants.textStyle,
                      ),

                      AppSpaces.verticalSpace5,

                      CustomDigitField(
                        codeController0: codeController0,
                        codeController1: codeController1,
                        codeController2: codeController2,
                        codeController3: codeController3,
                        hintText: '0',
                      ),

                      //forgot password?
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 15.0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TextButton(
                              onPressed: () => {
                                debugPrint(codeController0.text +
                                    codeController1.text +
                                    codeController2.text +
                                    codeController3.text),
                              },
                              child: Text(
                                'Resend Code',
                                style: TextStyle(
                                  color: AppColors.primaryAccentColor,
                                  fontSize: MediaQuery.of(context).size.height *
                                      0.018,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  AppSpaces.verticalSpace100,
                  AppSpaces.verticalSpace100,
                  AppSpaces.verticalSpace100,
                  AppSpaces.verticalSpace40,
                  Column(
                    children: [
                      //sign in button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          GradientButton(
                            isLoading: loading,
                            onPressed: () => Navigator.pushNamed(
                              context,
                              CreateNewPassword.id,
                            ),
                            text: 'Create New Password',
                          ),
                        ],
                      ),

                      const SizedBox(
                        height: 50.0,
                      ),

                      //not a member, register here
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Don\'t Have An Account?'),
                          const SizedBox(
                            width: 5.0,
                          ),
                          GestureDetector(
                            onTap: () => Navigator.of(context).pushNamed(
                              SignUpPage0.id,
                            ),
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
