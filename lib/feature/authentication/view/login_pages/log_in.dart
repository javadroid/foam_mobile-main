import 'package:flutter/material.dart';
import 'package:foam_mobile/feature/authentication/model/login_model.dart';
import 'package:foam_mobile/utils/values.dart';
import 'package:foam_mobile/widgets/gradient_button.dart';
import 'package:foam_mobile/widgets/login_with_button.dart';
import 'package:foam_mobile/widgets/my_text_field.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginPage extends StatefulWidget {
  final Function()? onTap;

  const LoginPage({
    super.key,
    required this.onTap,
  });

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final GlobalKey<ScaffoldMessengerState> _scaffoldKey =
      GlobalKey<ScaffoldMessengerState>();

  //text editing controllers
  final _emailController = TextEditingController();

  final _passwordController = TextEditingController();

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
                          'Log In',
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
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        hinText: 'Email or Phone Number',
                        obscureText: false,
                        isPassword: false,
                      ),

                      AppSpaces.verticalSpace10,

                      //password textfield
                      MyTextField(
                        controller: _passwordController,
                        hinText: 'Password',
                        obscureText: true,
                        isPassword: true,
                      ),

                      AppSpaces.verticalSpace10,

                      //forgot password?
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 25.0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () =>
                                  LoginClass.forgotPassword(context),
                              child: Text(
                                'Forgot your Password?',
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
                  AppSpaces.verticalSpace50,
                  AppSpaces.verticalSpace40,
                  Column(
                    children: [
                      //sign in button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            flex: 1,
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 25.0),
                              child: GradientButton(
                                isLoading: loading,
                                onPressed: () async {
                                  setState(() {
                                    loading = true;
                                  });

                                  await LoginClass.login(
                                    context,
                                    _emailController.text,
                                    _passwordController.text,
                                    _scaffoldKey,
                                  );

                                  setState(() {
                                    loading = false;
                                  });
                                },
                                text: 'Log in',
                              ),
                            ),
                          ),
                        ],
                      ),

                      AppSpaces.verticalSpace20,
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'OR',
                            style: GoogleFonts.dmSans(
                              fontSize: 18,
                            ),
                          )
                        ],
                      ),
                      AppSpaces.verticalSpace20,

                      const Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              LoginWithButton(text: 'Google'),
                            ],
                          ),
                          AppSpaces.verticalSpace20,
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              LoginWithButton(text: 'Apple'),
                            ],
                          ),
                        ],
                      ),

                      AppSpaces.verticalSpace50,

                      //not a member, register here
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Don\'t Have An Account?',
                            style: GoogleFonts.dmSans(
                              fontSize: 18,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                          const SizedBox(
                            width: 5.0,
                          ),
                          GestureDetector(
                            onTap: widget.onTap,
                            child: Text(
                              'Sign Up',
                              style: GoogleFonts.dmSans(
                                fontSize: 18,
                                color: AppColors.primaryAccentColor,
                                fontWeight: FontWeight.w300,
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
