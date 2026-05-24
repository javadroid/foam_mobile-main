import 'package:flutter/material.dart';
import 'package:foam_mobile/feature/authentication/view/verify_pages/verification_screen.dart';
import 'package:foam_mobile/theme/theme_main_provider.dart';
import 'package:foam_mobile/utils/values.dart';
import 'package:foam_mobile/widgets/gradient_button.dart';
import 'package:foam_mobile/widgets/my_text_field.dart';
import 'package:provider/provider.dart';

class ForgotPasswordEmail extends StatefulWidget {
  const ForgotPasswordEmail({super.key});

  static const String id = '/forgotemail';

  @override
  State<ForgotPasswordEmail> createState() => _ForgotPasswordEmailState();
}

class _ForgotPasswordEmailState extends State<ForgotPasswordEmail> {
  final GlobalKey<ScaffoldMessengerState> _scaffoldKey =
      GlobalKey<ScaffoldMessengerState>();

  //text editing controllers
  final emailController = TextEditingController();

  bool loading = false;

  @override
  Widget build(BuildContext context) {
    var mainProvider = Provider.of<ThemeProvider>(context, listen: true);
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
                        padding: EdgeInsets.symmetric(
                          horizontal: mainProvider.width / 20,
                        ),
                        child: Text(
                          'Forgot Password',
                          textAlign: TextAlign.left,
                          style: Constants.headingStyle,
                        ),
                      ),

                      AppSpaces.verticalSpace20,
                      AppSpaces.verticalSpace5,

                      //username textfield
                      MyTextField(
                        controller: emailController,
                        hinText: 'Email',
                        obscureText: false,
                        isPassword: false,
                      ),

                      AppSpaces.verticalSpace5,

                      //forgot password?
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: mainProvider.width / 15.0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () =>
                                  Navigator.of(context, rootNavigator: true)
                                      .pushNamed('/forgotnumber'),
                              child: Text(
                                'Phone Number',
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
                            onPressed: () => Navigator.pushNamed(
                              context,
                              VerificationScreen.id,
                            ),
                            text: 'Verify',
                          ),
                        ],
                      ),

                      AppSpaces.verticalSpace50,

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
