import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:foam_mobile/core/Screens/main_screen.dart';
import 'package:foam_mobile/core/hive/hive.dart';
import 'package:foam_mobile/core/splash_function.dart';
import 'package:foam_mobile/feature/authentication/controller/provider/authprovider.dart';
import 'package:foam_mobile/utils/values.dart';
import 'package:foam_mobile/widgets/error_widget.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:provider/provider.dart';

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
    init(context);
    log(HiveClass.getToken());
    log(HiveClass.getPic());
    super.initState();
  }

  init(BuildContext context) async {
    Future.delayed(const Duration(seconds: 2), () {
      SplashFunction.init(context);
    }).then(
      (value) {
        var authProvider = Provider.of<AuthProvider>(context, listen: false);
        if (authProvider.initDone) {
          Navigator.pushNamed(context, MainScreen.id);
        } else {
          setState(() {
            loadScreen = true;
          });
        }
      },
    );
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

    return authProvider.initDone
        ? const MainScreen()
        : authProvider.initError
            ? ErrorScreen(
                message:
                    "Oops!,\nError has Occured \nCheck your internet connection",
                onTap: () {
                  authProvider.updateError(false);
                  SplashFunction.init(context);
                  //     .then(
                  //   (value) {
                  //     // if (value) {
                  //     //   SplashFunction.initService(context).then((value) {
                  //     //     if (value) {
                  //     //       SplashFunction.initProduct(context);
                  //     //     }
                  //     //   });
                  //     // }
                  //   },
                  // );
                },
                logout: true,
              )
            : Scaffold(
                body: Center(
                  child: LoadingAnimationWidget.fourRotatingDots(
                    color: AppColors.primaryAccentColor,
                    // rightDotColor: Constant.generalColor,
                    size: 60,
                  ),
                ),
              );
  }
}
