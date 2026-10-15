import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:foam_mobile/core/Screens/profile/profile_image/controller/profile_pic_auth.dart';
import 'package:foam_mobile/core/hive/hive.dart';
import 'package:foam_mobile/core/intro_screens/onboarding_screen.dart';
import 'package:foam_mobile/core/routes/app_router.dart';
import 'package:foam_mobile/core/splash_screen.dart';
import 'package:foam_mobile/core/services/notification_service.dart';
import 'package:foam_mobile/core/services/onesignal_service.dart';
import 'package:foam_mobile/utils/values.dart';
import 'package:foam_mobile/core/provider/basket_provider.dart';
import 'package:foam_mobile/feature/authentication/controller/provider/authprovider.dart';
import 'package:foam_mobile/feature/vendor/controller/vendor_provider.dart';
import 'package:foam_mobile/feature/wallet/controller/wallet_provider.dart';
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

  // Initialize OneSignal Push Notifications
  await NotificationService.initOneSignal(Constants.oneSignalAppId);

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
          ),
          ChangeNotifierProvider(
            create: (_) => BasketProvider(),
          ),
          ChangeNotifierProvider(
            create: (_) => VendorProvider(),
          ),
          ChangeNotifierProvider(
            create: (_) => WalletProvider(),
          ),
        ],
        child: const MyApp(),
      ),
    ),

    // ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // Retained observer reference to prevent garbage collection
  void Function(OSPushSubscriptionChangedState)? _pushSubscriptionObserver;
  bool _dialogShown = false;

  @override
  void initState() {
    super.initState();
    _setupPushSubscriptionObserver();
  }

  // A real, server-assigned subscription ID is non-empty and not the local- placeholder
  bool _isRegistered(String? id) =>
      id != null && id.isNotEmpty && !id.startsWith('local-');

  void _maybeShowIntegrationCompleteDialog(String? subscriptionId) {
    if (_isRegistered(subscriptionId) && !_dialogShown) {
      _dialogShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showIntegrationCompleteDialog();
      });
    }
  }

  void _setupPushSubscriptionObserver() {
    _pushSubscriptionObserver = (state) {
      _maybeShowIntegrationCompleteDialog(state.current.id);
    };
    OneSignalService().addPushSubscriptionObserver(_pushSubscriptionObserver!);

    // The ID may already be assigned before the observer attaches,
    // so evaluate the current value immediately as well.
    _maybeShowIntegrationCompleteDialog(OneSignalService().pushSubscriptionId);
  }

  void _showIntegrationCompleteDialog() {
    final context = AppRouter.navigatorKey.currentContext;
    if (context == null || !context.mounted) {
      // If navigator context is not mounted yet, retry shortly
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) _showIntegrationCompleteDialog();
      });
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Your OneSignal SDK integration is complete!'),
        content: const Text(
          'You can now send Push Notifications & In-App Messages through OneSignal. Tap below to enable push notifications.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              OneSignalService().requestPermission();
            },
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    if (_pushSubscriptionObserver != null) {
      OneSignalService().removePushSubscriptionObserver(_pushSubscriptionObserver!);
    }
    super.dispose();
  }

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
