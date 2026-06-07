import 'package:flutter/material.dart';
import 'package:foam_mobile/feature/authentication/view/forgot_password_pages/create_new_password.dart';
import 'package:foam_mobile/feature/authentication/view/sign_up_pages/sign_up_0.dart';
import 'package:foam_mobile/utils/values.dart';
import 'package:foam_mobile/widgets/custom_digit_field.dart';
import 'package:foam_mobile/widgets/gradient_button.dart';

import 'package:foam_mobile/feature/authentication/controller/provider/authprovider.dart';
import 'package:foam_mobile/feature/authentication/model/verification_model.dart';
import 'package:provider/provider.dart';

class VerificationScreen extends StatefulWidget {
  final bool isForgotPassword;
  const VerificationScreen({super.key, this.isForgotPassword = false});

  static const String id = 'verification_screen';

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final GlobalKey<ScaffoldMessengerState> _scaffoldKey =
      GlobalKey<ScaffoldMessengerState>();

  //text editing controllers
  final List<TextEditingController> controllers = List.generate(6, (index) => TextEditingController());

  bool loading = false;

  @override
  Widget build(BuildContext context) {
    var authProvider = Provider.of<AuthProvider>(context);
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
                        'Enter The 6 digit code sent to ${authProvider.email}',
                        textAlign: TextAlign.center,
                        style: Constants.textStyle,
                      ),

                      AppSpaces.verticalSpace5,

                      CustomDigitField(
                        controllers: controllers,
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
                              onPressed: () async {
                                await VerifyClass.resend(context, _scaffoldKey);
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
                  AppSpaces.verticalSpace40,
                  Column(
                    children: [
                      //sign in button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          GradientButton(
                            isLoading: loading,
                            onPressed: () async {
                              setState(() {
                                loading = true;
                              });
                              String code = controllers.map((e) => e.text).join();
                              if (widget.isForgotPassword) {
                                await VerifyClass.verifyForgotPassword(code, context, _scaffoldKey);
                              } else {
                                await VerifyClass.verify(code, context, _scaffoldKey);
                              }
                              setState(() {
                                loading = false;
                              });
                            },
                            text: widget.isForgotPassword ? 'Create New Password' : 'Verify',
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
