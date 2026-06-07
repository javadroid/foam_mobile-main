import 'package:flutter/material.dart';
import 'package:foam_mobile/feature/authentication/view/verify_pages/verification_screen.dart';
import 'package:foam_mobile/utils/values.dart';
import 'package:foam_mobile/widgets/gradient_button.dart';
import 'package:foam_mobile/widgets/my_text_field.dart';

class ForgotPasswordNumber extends StatefulWidget {
  const ForgotPasswordNumber({super.key});

  static const String id = '/forgotnumber';

  @override
  State<ForgotPasswordNumber> createState() => _ForgotPasswordNumberState();
}

class _ForgotPasswordNumberState extends State<ForgotPasswordNumber> {
  final GlobalKey<ScaffoldMessengerState> _scaffoldKey =
      GlobalKey<ScaffoldMessengerState>();

  //text editing controllers
  final numberController = TextEditingController();

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
                          'Forgot Password',
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
                        controller: numberController,
                        hinText: 'Phone Number',
                        obscureText: false,
                        isPassword: false,
                      ),

                      AppSpaces.verticalSpace5,

                      //forgot password?
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 15.0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () =>
                                  Navigator.of(context, rootNavigator: true)
                                      .pushNamed('/forgotemail'),
                              child: Text(
                                'Email',
                                style: TextStyle(
                                  color: AppColors.primaryAccentColor,
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
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const VerificationScreen(isForgotPassword: true),
                              ),
                            ),
                            text: 'Verify',
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
