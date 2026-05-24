import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:foam_mobile/core/Screens/profile/profile_image/controller/profile_pic_auth.dart';
import 'package:foam_mobile/core/hive/hive.dart';
import 'package:foam_mobile/core/intro_screens/onboarding_screen.dart';
import 'package:foam_mobile/core/routes/app_router.dart';
import 'package:foam_mobile/core/splash_screen.dart';
import 'package:foam_mobile/feature/authentication/controller/provider/authprovider.dart';
import 'package:foam_mobile/theme/theme_main_provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // initialize hive
  await Hive.initFlutter();
  // open the hive box
  await Hive.openBox('foam');

  SystemChrome.setPreferredOrientations(
    [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown],
  ).then(
    (value) => runApp(
      // DevicePreview(
      //   builder: (context) =>
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => ThemeProvider(),
          ),
          ChangeNotifierProvider(
            create: (_) => AuthProvider(),
          ),
          ChangeNotifierProvider(
            create: (_) => ProfilePicAuth(),
          )
        ],
        child: const MyApp(),
      ),
    ),
    // ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    var mainProvider = Provider.of<ThemeProvider>(context, listen: true);
    mainProvider.height = MediaQuery.sizeOf(context).height;
    mainProvider.width = MediaQuery.sizeOf(context).width;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Foam',
      theme: mainProvider.themeData,
      themeAnimationCurve: Curves.decelerate,
      themeAnimationDuration: const Duration(milliseconds: 500),
      navigatorKey: AppRouter.navigatorKey,
      onGenerateRoute: AppRouter.onGenerateRoute,
      // locale: DevicePreview.locale(context),
      // builder: DevicePreview.appBuilder,
      home: HiveClass.tokenExist()
          ? const SplashScreen() /*const MainScreen()*/
          : const OnBoardingScreen(),
    );
  }
}
