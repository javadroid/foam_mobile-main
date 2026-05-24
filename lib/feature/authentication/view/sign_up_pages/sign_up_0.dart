import 'package:flutter/material.dart';
import 'package:foam_mobile/feature/authentication/controller/provider/authprovider.dart';
import 'package:foam_mobile/feature/authentication/model/sign_up_model.dart';
import 'package:foam_mobile/utils/values.dart';
import 'package:foam_mobile/widgets/gradient_button.dart';
import 'package:foam_mobile/widgets/login_with_button.dart';
import 'package:foam_mobile/widgets/my_text_field.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class SignUpPage0 extends StatefulWidget {
  const SignUpPage0({
    super.key,
  });

  static const String id = '/signup';

  @override
  State<SignUpPage0> createState() => _SignUpPage0State();
}

class _SignUpPage0State extends State<SignUpPage0> {
  //text editing controllers
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final phoneNumberController = TextEditingController();
  final emailController = TextEditingController();
  final createPasswordController = TextEditingController();
  final repeatPasswordController = TextEditingController();

  bool loading = false;
  bool isVerified = false;

  final GlobalKey<ScaffoldMessengerState> _scaffoldKey =
      GlobalKey<ScaffoldMessengerState>();

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

  @override
  Widget build(BuildContext context) {
    Provider.of<AuthProvider>(context, listen: true);

    return ScaffoldMessenger(
      key: _scaffoldKey,
      child: Scaffold(
        appBar: AppBar(
          actions: const [
            Padding(
              padding: EdgeInsets.only(right: 18.0),
              child: Text('step 1 of 2'),
            ),
          ],
        ),
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
                          'Let\'s set up your account',
                          textAlign: TextAlign.left,
                          style: TextStyle(
                            color: Colors.grey[900],
                            fontSize: 25,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                      AppSpaces.verticalSpace20,
                      AppSpaces.verticalSpace5,

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                            flex: 1,
                            child: MyTextField(
                              controller: firstNameController,
                              hinText: 'First Name',
                              obscureText: false,
                              isPassword: false,
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: MyTextField(
                              controller: lastNameController,
                              hinText: 'Last Name',
                              obscureText: false,
                              isPassword: false,
                            ),
                          ),
                        ],
                      ),

                      AppSpaces.verticalSpace10,

                      //username textfield
                      MyTextField(
                        controller: phoneNumberController,
                        hinText: 'Phone Number',
                        keyboardType: TextInputType.number,
                        obscureText: false,
                        isPassword: false,
                      ),

                      AppSpaces.verticalSpace10,

                      MyTextField(
                        controller: emailController,
                        hinText: 'Email',
                        keyboardType: TextInputType.emailAddress,
                        obscureText: false,
                        isPassword: false,
                      ),

                      AppSpaces.verticalSpace10,

                      //password textfield
                      MyTextField(
                        controller: createPasswordController,
                        hinText: 'Password',
                        obscureText: true,
                        isPassword: true,
                      ),

                      AppSpaces.verticalSpace10,

                      MyTextField(
                        controller: repeatPasswordController,
                        hinText: 'Repeat Password',
                        obscureText: true,
                        isPassword: true,
                      ),

                      AppSpaces.verticalSpace10,
                    ],
                  ),
                  AppSpaces.verticalSpace20,
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
                                text: 'Next',
                                isLoading: loading,
                                onPressed: () async {
                                  if (phoneNumberController.text.length != 11) {
                                    showErrorMessage(
                                      'Phone number should be 11 characters: (ex:01234567890)',
                                    );
                                  } else if (createPasswordController.text ==
                                      repeatPasswordController.text) {
                                    setState(() {
                                      loading = true;
                                    });

                                    isVerified = await SignUpModel.signUp(
                                      context,
                                      emailController.text,
                                      createPasswordController.text,
                                      phoneNumberController.text,
                                      _scaffoldKey,
                                    );

                                    if (isVerified) {
                                      await SignUpModel.getStarted(
                                        context,
                                        firstNameController.text,
                                        lastNameController.text,
                                        phoneNumberController.text,
                                        emailController.text,
                                        createPasswordController.text,
                                        _scaffoldKey,
                                      );
                                      await SignUpModel.inputToken(
                                        context,
                                        emailController.text,
                                        createPasswordController.text,
                                        _scaffoldKey,
                                      );
                                    }

                                    setState(() {
                                      loading = false;
                                    });
                                  } else {
                                    showErrorMessage('Password not matching');
                                  }
                                },
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

                      //agreeing with terms and conditions
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'By clicking next you agree to our',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.dmSans(
                              fontSize: 18,
                            ),
                          ),
                          AppSpaces.horizontalSpace5,
                          GestureDetector(
                            onTap: () {},
                            child: Text(
                              'Terms and',
                              style: GoogleFonts.dmSans(
                                color: AppColors.primaryAccentColor,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Conditions ',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.dmSans(
                              fontSize: 18,
                              color: AppColors.primaryAccentColor,
                            ),
                          ),
                          Text(
                            'and',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.dmSans(
                              fontSize: 18,
                            ),
                          ),
                          AppSpaces.horizontalSpace5,
                          GestureDetector(
                            onTap: () {},
                            child: Text(
                              'Privacy Policy',
                              style: GoogleFonts.dmSans(
                                color: AppColors.primaryAccentColor,
                                fontSize: 18,
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
