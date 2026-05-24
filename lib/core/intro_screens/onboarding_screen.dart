import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:foam_mobile/core/intro_screens/intro_page.dart';
import 'package:foam_mobile/utils/values.dart';
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
    super.dispose();
    // discount slider CONTROLLER
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var mainProvider = Provider.of<ThemeProvider>(context, listen: true);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        body: Stack(
          children: [
            SizedBox(
              height: mainProvider.height,
              child: PageView(
                controller: screenController,
                children: [
                  IntroPage(
                    imageAsset: 'assets/images/laundry0.png',
                    text:
                        'Experience convenience and freshness like never before.',
                    color: AppColors.primaryAccentColor,
                  ),
                  IntroPage(
                    imageAsset: 'assets/images/laundry1.png',
                    text:
                        'Simplify Your Life with Seamless Laundry Pickup and Delivery.',
                    color: AppColors.primaryAccentColor,
                  ),
                  IntroPage(
                    imageAsset: 'assets/images/laundry2.png',
                    text:
                        'Eco-Friendly Cleaning that Cares for Your Clothes and the Planet',
                    color: AppColors.primaryAccentColor,
                  ),
                  IntroPage(
                    imageAsset: 'assets/images/laundry3.png',
                    text: 'Join Us and Transform the Way You Do Laundry!',
                    color: AppColors.primaryAccentColor,
                  ),
                ],
              ),
            ),

            //dot controller
            Container(
              alignment: const Alignment(0, 0.20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  //dot indicator
                  SmoothPageIndicator(
                    controller: screenController,
                    count: 4,
                    effect: Constants.slideEffect1,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
