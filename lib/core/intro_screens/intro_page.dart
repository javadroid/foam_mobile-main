import 'package:flutter/material.dart';
import 'package:foam_mobile/feature/authentication/view/auth_pages/login_or_register_page.dart';
import 'package:foam_mobile/feature/authentication/view/sign_up_pages/sign_up_0.dart';
import 'package:foam_mobile/utils/values.dart';
import 'package:foam_mobile/widgets/click_button.dart';
import 'package:google_fonts/google_fonts.dart';

class IntroPage extends StatelessWidget {
  final String imageAsset;
  final String text;
  final Color color;

  const IntroPage({
    super.key,
    required this.imageAsset,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.sizeOf(context);
    return Scaffold(
      body: SizedBox(
        height: size.height,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: const Alignment(0, 0),
              end: const Alignment(0, 0.9),
              colors: [
                ...AppColors.gradientColor,
              ],
            ),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(5),
            ),
          ),
          padding: const EdgeInsets.only(
            top: 50,
            left: 15.0,
            right: 15.0,
          ),
          child: Column(
            children: [
              Expanded(
                flex: 1,
                child: Row(
                  children: [
                    Image.asset('assets/images/foam.png'),
                  ],
                ),
              ),
              Expanded(
                flex: 4,
                child: Image.asset(
                  imageAsset,
                ),
              ),
              const Expanded(
                flex: 1,
                child: AppSpaces.verticalSpace10,
              ),
              Expanded(
                flex: 4,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text(
                        text,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.dmSans(
                          color: AppColors.blackAccentColor,
                          fontSize: 25,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Text(
                      'Schedule your pickup today',
                      style: GoogleFonts.dmSans(
                        color: AppColors.blackAccentColor,
                        fontSize: 19,
                        textStyle: const TextStyle(
                          textBaseline: TextBaseline.ideographic,
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: ClickButton(
                            text: 'Sign me up!',
                            textColor: Colors.white,
                            color: AppColors.secondaryBackgroundColor,
                            fontSize: 20.0,
                            onPressed: () =>
                                Navigator.of(context, rootNavigator: true)
                                    .pushNamed(
                              SignUpPage0.id,
                            ),
                          ),
                        ),
                      ],
                    ),
                    InkWell(
                      onTap: () =>
                          Navigator.of(context, rootNavigator: true).pushNamed(
                        LoginOrRegisterPage.id,
                      ),
                      child: Text(
                        'Log in with your existing account',
                        style: GoogleFonts.dmSans(
                          color: AppColors.blackAccentColor,
                          fontSize: 14,
                          textStyle: const TextStyle(
                            textBaseline: TextBaseline.ideographic,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
