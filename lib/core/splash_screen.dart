import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:foam_mobile/core/Screens/main_screen.dart';
import 'package:foam_mobile/core/hive/hive.dart';
import 'package:foam_mobile/core/intro_screens/onboarding_screen.dart';
import 'package:foam_mobile/core/splash_function.dart';
import 'package:foam_mobile/feature/authentication/controller/provider/authprovider.dart';
import 'package:foam_mobile/utils/values.dart';
import 'package:foam_mobile/widgets/error_widget.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:provider/provider.dart';

import 'package:foam_mobile/feature/authentication/view/sign_up_pages/sign_up_1.dart';

class SplashScreen extends StatefulWidget {
  static const String id = '/splash_screen';

  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool loadScreen = false;

  @override
  void initState() {
    super.initState();
    init(context);
    log('Splash token check: ${HiveClass.getToken()}');
  }

  init(BuildContext context) async {
    // Show splash branding for at least 2 seconds
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final String? token = HiveClass.getToken();
    if (token == null || token.isEmpty) {
      // User is not logged in -> navigate to OnBoarding
      Navigator.pushReplacementNamed(context, OnBoardingScreen.id);
      return;
    }

    // User has a token -> validate with backend
    bool hasAddress = false;
    try {
      hasAddress = await SplashFunction.init(context).timeout(const Duration(seconds: 6));
    } catch (e) {
      debugPrint('Splash init error: $e');
    }

    if (!mounted) return;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (authProvider.initDone) {
      if (hasAddress) {
        Navigator.pushReplacementNamed(context, MainScreen.id);
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const SignUpPage1()),
        );
      }
    } else {
      if (authProvider.initError) {
        setState(() {
          loadScreen = true;
        });
      } else {
        // Unauthenticated or expired token -> clear and go to onboarding
        HiveClass.clearHive();
        Navigator.pushReplacementNamed(context, OnBoardingScreen.id);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return loadScreen ? const Loading() : const Splash();
  }
}

class Splash extends StatelessWidget {
  const Splash({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              "assets/images/foam.png",
              width: 400,
              height: 400,
            ),
          ],
        ),
      ),
    );
  }
}

class Loading extends StatefulWidget {
  const Loading({super.key});

  @override
  State<Loading> createState() => _LoadingState();
}

class _LoadingState extends State<Loading> {
  @override
  Widget build(BuildContext context) {
    var authProvider = Provider.of<AuthProvider>(context, listen: true);

    if (authProvider.initDone) {
      if (authProvider.addressStreet.isNotEmpty) {
        return const MainScreen();
      } else {
        return const SignUpPage1();
      }
    }

    return authProvider.initError
        ? ErrorScreen(
            message:
                "Oops!,\nError has Occured \nCheck your internet connection",
            onTap: () {
              debugPrint("onTap ${authProvider.initError}");
              authProvider.updateError(false);
              SplashFunction.init(context);
            }, logout: true,
          )
        : Scaffold(
            body: Center(
              child: LoadingAnimationWidget.staggeredDotsWave(
                color: AppColors.primaryAccentColor,
                size: 100,
              ),
            ),
          );
  }
}
