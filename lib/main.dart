import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:foam_mobile/core/Screens/profile/profile_image/controller/profile_pic_auth.dart';
import 'package:foam_mobile/core/hive/hive.dart';
import 'package:foam_mobile/core/intro_screens/onboarding_screen.dart';
import 'package:foam_mobile/core/routes/app_router.dart';
import 'package:foam_mobile/core/splash_screen.dart';
import 'package:foam_mobile/core/services/notification_service.dart';
import 'package:foam_mobile/utils/values.dart';
import 'package:foam_mobile/core/provider/basket_provider.dart';
import 'package:foam_mobile/feature/authentication/controller/provider/authprovider.dart';
import 'package:foam_mobile/feature/vendor/controller/vendor_provider.dart';
import 'package:foam_mobile/feature/schedule_pickup/controller/schedule_pickup_provider.dart';
import 'package:foam_mobile/feature/wallet/controller/wallet_provider.dart';
import 'package:foam_mobile/feature/rider/controller/rider_provider.dart';
import 'package:foam_mobile/theme/theme_main_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Use local font assets and filter repetitive GoogleFonts stack traces to a 1-line notice
  GoogleFonts.config.allowRuntimeFetching = true;
  FlutterError.onError = (FlutterErrorDetails details) {
    final str = details.exception.toString();
    if (str.contains('google_fonts') || str.contains('AssetManifest')) {
      debugPrint('[GoogleFonts] Using bundled DMSans font.');
      return;
    }
    FlutterError.presentError(details);
  };
  // initialize hive
  await Hive.initFlutter();
  // open the hive box
  await Hive.openBox('foam');

  await SystemChrome.setPreferredOrientations(
    [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown],
  );

  runApp(
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
        ),
        ChangeNotifierProvider(
          create: (_) => BasketProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => VendorProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => SchedulePickupProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => WalletProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => RiderProvider(),
        ),
      ],
      child: const MyApp(),
    ),
  );

  // Initialize OneSignal Push Notifications asynchronously after first frame
  WidgetsBinding.instance.addPostFrameCallback((_) {
    NotificationService.initOneSignal(Constants.oneSignalAppId);
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
      home: HiveClass.tokenExist()
          ? const SplashScreen()
          : const OnBoardingScreen(),
    );
  }
}
