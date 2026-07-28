import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:foam_mobile/core/intro_screens/intro_page.dart';
import 'package:foam_mobile/feature/authentication/view/auth_pages/login_or_register_page.dart';
import 'package:foam_mobile/feature/authentication/view/sign_up_pages/sign_up_0.dart';
import 'package:foam_mobile/utils/values.dart';
import 'package:foam_mobile/widgets/click_button.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:foam_mobile/theme/theme_main_provider.dart';

class OnBoardingScreen extends StatefulWidget {
  const OnBoardingScreen({super.key});

  static const String id = '/onboarding';

  @override
  State<OnBoardingScreen> createState() => _OnBoardingScreenState();
}

class _OnBoardingScreenState extends State<OnBoardingScreen> {
  // page controller to get to the page you are in rightly
  int _currentScreenController = 0;
  Timer? timer;
  final screenController = PageController(initialPage: 0);

  @override
  void initState() {
    timer = Timer.periodic(const Duration(seconds: 5), (Timer timer) {
      if (_currentScreenController < 3) {
        _currentScreenController++;
      } else {
        _currentScreenController = 0;
      }

      screenController.animateToPage(
        _currentScreenController,
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeIn,
      );
    });
    super.initState();
  }

  @override
  void dispose() {
    timer?.cancel();
    screenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var mainProvider = Provider.of<ThemeProvider>(context, listen: true);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        body: Container(
          height: mainProvider.height,
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
              Row(
                children: [
                  Image.asset('assets/images/foam.png'),
                ],
              ),
              Expanded(
                child: PageView(
                  controller: screenController,
                  children: const [
                    IntroPage(
                      imageAsset: 'assets/images/laundry0.png',
                      text:
                          'Experience convenience and freshness like never before.',
                    ),
                    IntroPage(
                      imageAsset: 'assets/images/laundry1.png',
                      text:
                          'Simplify Your Life with Seamless Laundry Pickup and Delivery.',
                    ),
                    IntroPage(
                      imageAsset: 'assets/images/laundry2.png',
                      text:
                          'Eco-Friendly Cleaning that Cares for Your Clothes and the Planet',
                    ),
                    IntroPage(
                      imageAsset: 'assets/images/laundry3.png',
                      text: 'Join Us and Transform the Way You Do Laundry!',
                    ),
                  ],
                ),
              ),
              SmoothPageIndicator(
                controller: screenController,
                count: 4,
                effect: Constants.slideEffect1,
              ),
              const SizedBox(height: 24),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Schedule your pickup today',
                    style: GoogleFonts.dmSans(
                      color: AppColors.blackAccentColor,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: ClickButton(
                          text: 'Sign me up!',
                          textColor: Colors.white,
                          color: AppColors.secondaryBackgroundColor,
                          fontSize: 16.0,
                          onPressed: () =>
                              Navigator.of(context, rootNavigator: true)
                                  .pushNamed(
                            SignUpPage0.id,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  InkWell(
                    onTap: () =>
                        Navigator.of(context, rootNavigator: true).pushNamed(
                      LoginOrRegisterPage.id,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        'Log in with your existing account',
                        style: GoogleFonts.dmSans(
                          color: AppColors.blackAccentColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
