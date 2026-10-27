import 'package:flutter/material.dart';
import 'package:foam_mobile/core/Screens/basket/view/basket_screen.dart';
import 'package:foam_mobile/core/Screens/billing/billing_screen.dart';
import 'package:foam_mobile/core/Screens/help/help_screen.dart';
import 'package:foam_mobile/core/Screens/history/history_screen.dart';
import 'package:foam_mobile/core/Screens/home/home_screen.dart';
import 'package:foam_mobile/core/Screens/home/notifications/notification_screen.dart';
import 'package:foam_mobile/core/Screens/home/services_screen/views/pickup_details_screen.dart';
import 'package:foam_mobile/core/Screens/home/services_screen/views/add_to_basket_screen.dart';
import 'package:foam_mobile/core/Screens/home/services_screen/views/service_details.dart';
import 'package:foam_mobile/core/Screens/home/services_screen/views/services_screen.dart';
import 'package:foam_mobile/core/Screens/main_screen.dart';
import 'package:foam_mobile/core/Screens/profile/profile_screen.dart';
import 'package:foam_mobile/core/intro_screens/onboarding_screen.dart';
import 'package:foam_mobile/core/splash_screen.dart';
import 'package:foam_mobile/feature/authentication/view/auth_pages/login_or_register_page.dart';
import 'package:foam_mobile/feature/authentication/view/forgot_password_pages/create_new_password.dart';
import 'package:foam_mobile/feature/authentication/view/forgot_password_pages/forgot_email_page.dart';
import 'package:foam_mobile/feature/authentication/view/forgot_password_pages/forgot_number_page.dart';
import 'package:foam_mobile/feature/authentication/view/sign_up_pages/sign_up_0.dart';
import 'package:foam_mobile/feature/authentication/view/verify_pages/verification_screen.dart';
import 'package:foam_mobile/feature/vendor/onboarding/vendor_approved_screen.dart';
import 'package:foam_mobile/feature/vendor/onboarding/vendor_documents_screen.dart';
import 'package:foam_mobile/feature/vendor/onboarding/vendor_payout_bank_screen.dart';
import 'package:foam_mobile/feature/vendor/onboarding/vendor_pending_verification_screen.dart';
import 'package:foam_mobile/feature/vendor/onboarding/vendor_rejected_screen.dart';
import 'package:foam_mobile/feature/vendor/onboarding/vendor_sign_up_screen.dart';
import 'package:foam_mobile/feature/vendor/onboarding/vendor_onboarding_stepper_screen.dart';
import 'package:foam_mobile/feature/vendor/store_setup/vendor_pricing_service_screen.dart';
import 'package:foam_mobile/feature/vendor/store_setup/vendor_review_live_screen.dart';
import 'package:foam_mobile/feature/vendor/store_setup/vendor_store_details_screen.dart';
import 'package:foam_mobile/feature/vendor/vendor_main_screen.dart';

class AppRouter {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case OnBoardingScreen.id:
        return MaterialPageRoute(
          builder: (_) => const OnBoardingScreen(),
          settings: settings,
        );

      case SplashScreen.id:
        return MaterialPageRoute(
          builder: (_) => const SplashScreen(),
          settings: settings,
        );

      case MainScreen.id:
        return MaterialPageRoute(
          builder: (_) => const MainScreen(),
          settings: settings,
        );

      case HomePage.id: // Home screen route
        return MaterialPageRoute(
          builder: (_) => const HomePage(),
          settings: settings,
        );

      case HistoryScreen.id: // History screen route
        return MaterialPageRoute(
          builder: (_) => const HistoryScreen(),
          settings: settings,
        );

      case HelpScreen.id: // Help screen route
        return MaterialPageRoute(
          builder: (_) => const HelpScreen(),
          settings: settings,
        );

      case BillingScreen.id:
        return MaterialPageRoute(
          builder: (_) => const BillingScreen(),
          settings: settings,
        );

      case BasketScreen.id: // Basket screen route
        return MaterialPageRoute(
          builder: (_) => const BasketScreen(),
          settings: settings,
        );

      case LoginOrRegisterPage
            .id: // Login screen route (with optional parameter)
        return MaterialPageRoute(
          builder: (_) => const LoginOrRegisterPage(),
          settings: settings,
        );

      case SignUpPage0.id: // Sign up screen route (with optional parameter)
        return MaterialPageRoute(
          builder: (_) => const SignUpPage0(),
          settings: settings,
        );

      case ForgotPasswordEmail
            .id: // Forgot email screen route (with optional parameter)
        return MaterialPageRoute(
          builder: (_) => const ForgotPasswordEmail(),
          settings: settings,
        );

      case ForgotPasswordNumber
            .id: // Forgot number screen route (with optional parameter)
        return MaterialPageRoute(
          builder: (_) => const ForgotPasswordNumber(),
          settings: settings,
        );

      case CreateNewPassword
            .id: // Create New Password screen route (with optional parameter)
        return MaterialPageRoute(
          builder: (_) => const CreateNewPassword(),
          settings: settings,
        );

      case VerificationScreen
            .id: // Verification screen route (with optional parameter)
        return MaterialPageRoute(
          builder: (_) => const VerificationScreen(),
          settings: settings,
        );

      case ProfileScreen.id: // Profile screen route (with optional parameter)
        return MaterialPageRoute(
          builder: (_) => const ProfileScreen(),
          settings: settings,
        );

      case ServicesScreen.id: // Services screen route (with optional parameter)
        return MaterialPageRoute(
          builder: (_) => const ServicesScreen(),
          settings: settings,
        );

      case ServiceDetails
            .id: // Service Details screen route (with optional parameter)
        return MaterialPageRoute(
          builder: (_) => const ServiceDetails(),
          settings: settings,
        );

      case NotificationScreen
            .id: // Notification screen route (with optional parameter)
        return MaterialPageRoute(
          builder: (_) => const NotificationScreen(),
          settings: settings,
        );

      case AddToBasket
            .id: // Notification screen route (with optional parameter)
        return MaterialPageRoute(
          builder: (_) => const AddToBasket(),
          settings: settings,
        );

      case PickupDetailsScreen
            .id: // Notification screen route (with optional parameter)
        return MaterialPageRoute(
          builder: (_) => const PickupDetailsScreen(),
          settings: settings,
        );

      case VendorOnboardingStepperScreen.id:
        return MaterialPageRoute(
          builder: (_) => const VendorOnboardingStepperScreen(),
          settings: settings,
        );

      case VendorSignUpScreen.id:
        return MaterialPageRoute(
          builder: (_) => const VendorOnboardingStepperScreen(),
          settings: settings,
        );

      case VendorDocumentsScreen.id:
        return MaterialPageRoute(
          builder: (_) => const VendorDocumentsScreen(),
          settings: settings,
        );

      case VendorPayoutBankScreen.id:
        return MaterialPageRoute(
          builder: (_) => const VendorPayoutBankScreen(),
          settings: settings,
        );

      case VendorPendingVerificationScreen.id:
        return MaterialPageRoute(
          builder: (_) => const VendorPendingVerificationScreen(),
          settings: settings,
        );

      case VendorRejectedScreen.id:
        return MaterialPageRoute(
          builder: (_) => const VendorRejectedScreen(),
          settings: settings,
        );

      case VendorApprovedScreen.id:
        return MaterialPageRoute(
          builder: (_) => const VendorApprovedScreen(),
          settings: settings,
        );

      case VendorStoreDetailsScreen.id:
        return MaterialPageRoute(
          builder: (_) => const VendorStoreDetailsScreen(),
          settings: settings,
        );

      case VendorPricingServiceScreen.id:
        return MaterialPageRoute(
          builder: (_) => const VendorPricingServiceScreen(),
          settings: settings,
        );

      case VendorReviewLiveScreen.id:
        return MaterialPageRoute(
          builder: (_) => const VendorReviewLiveScreen(),
          settings: settings,
        );

      case VendorMainScreen.id:
        return MaterialPageRoute(
          builder: (_) => const VendorMainScreen(),
          settings: settings,
        );

      // Add more routes for other screens as needed
      default:
        return MaterialPageRoute(
          builder: (_) => const Text('Error: Route not found'),
        );
    }
  }
}

