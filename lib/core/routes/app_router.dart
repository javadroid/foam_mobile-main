import 'package:foam_mobile/feature/rider/views/rider_registration_screen.dart';
import 'package:foam_mobile/feature/rider/views/rider_dashboard_screen.dart';
import 'package:foam_mobile/feature/rider/views/rider_active_ride_screen.dart';
import 'package:foam_mobile/feature/rider/views/rider_history_screen.dart';
import 'package:foam_mobile/feature/rider/views/rider_wallet_screen.dart';
import 'package:foam_mobile/feature/rider/models/rider_models.dart';
import 'package:foam_mobile/feature/schedule_pickup/views/01_how_to_choose_screen.dart';
import 'package:foam_mobile/feature/schedule_pickup/views/02_tiers_screen.dart';
import 'package:foam_mobile/feature/schedule_pickup/views/03_nearby_stores_screen.dart';
import 'package:foam_mobile/feature/schedule_pickup/views/04_store_page_screen.dart';
import 'package:foam_mobile/feature/schedule_pickup/views/05_items_screen.dart';
import 'package:foam_mobile/feature/schedule_pickup/views/06_checkout_screen.dart';
import 'package:foam_mobile/feature/schedule_pickup/views/07_order_placed_screen.dart';
import 'package:foam_mobile/feature/schedule_pickup/views/08_pickup_leg_screen.dart';
import 'package:foam_mobile/feature/schedule_pickup/views/09_at_store_screen.dart';
import 'package:foam_mobile/feature/schedule_pickup/views/10_delivery_leg_screen.dart';
import 'package:foam_mobile/feature/schedule_pickup/views/11_delivered_screen.dart';
import 'package:flutter/material.dart';
import 'package:foam_mobile/core/Screens/basket/view/basket_screen.dart';
import 'package:foam_mobile/core/Screens/billing/billing_screen.dart';
import 'package:foam_mobile/core/Screens/billing/payment_success_screen.dart';
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
import 'package:foam_mobile/core/Screens/profile/customer_address_screen.dart';
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
import 'package:foam_mobile/feature/vendor/profile/vendor_bank_settings_screen.dart';
import 'package:foam_mobile/feature/vendor/store_setup/vendor_pricing_service_screen.dart';
import 'package:foam_mobile/feature/vendor/store_setup/vendor_review_live_screen.dart';
import 'package:foam_mobile/feature/vendor/store_setup/vendor_store_details_screen.dart';
import 'package:foam_mobile/feature/vendor/vendor_main_screen.dart';

class AppRouter {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case HowToChooseScreen.id:
        return MaterialPageRoute(
          builder: (_) => const HowToChooseScreen(),
          settings: settings,
        );

      case ScheduleTiersScreen.id:
        return MaterialPageRoute(
          builder: (_) => const ScheduleTiersScreen(),
          settings: settings,
        );

      case NearbyStoresScreen.id:
        return MaterialPageRoute(
          builder: (_) => const NearbyStoresScreen(),
          settings: settings,
        );

      case CustomerStorePageScreen.id:
        return MaterialPageRoute(
          builder: (_) => const CustomerStorePageScreen(),
          settings: settings,
        );

      case ScheduleItemsScreen.id:
        return MaterialPageRoute(
          builder: (_) => const ScheduleItemsScreen(),
          settings: settings,
        );

      case ScheduleCheckoutScreen.id:
        return MaterialPageRoute(
          builder: (_) => const ScheduleCheckoutScreen(),
          settings: settings,
        );

      case ScheduleOrderPlacedScreen.id:
        return MaterialPageRoute(
          builder: (_) => const ScheduleOrderPlacedScreen(),
          settings: settings,
        );

      case ScheduleTrackingScreen.id:
        return MaterialPageRoute(
          builder: (_) => const ScheduleTrackingScreen(),
          settings: settings,
        );

      case CustomerAtStoreScreen.id:
        return MaterialPageRoute(
          builder: (_) => const CustomerAtStoreScreen(),
          settings: settings,
        );

      case CustomerDeliveryLegScreen.id:
        return MaterialPageRoute(
          builder: (_) => const CustomerDeliveryLegScreen(),
          settings: settings,
        );

      case CustomerDeliveredScreen.id:
        return MaterialPageRoute(
          builder: (_) => const CustomerDeliveredScreen(),
          settings: settings,
        );

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

      case PaymentSuccessScreen.id:
        final args = settings.arguments as Map<String, dynamic>? ?? {};
        return MaterialPageRoute(
          builder: (_) => PaymentSuccessScreen(
            title: args['title'] ?? 'Payment Successful! 🎉',
            subtitle: args['subtitle'] ??
                'Your payment was processed and verified successfully.',
            itemTitle: args['itemTitle'] ?? 'Subscription',
            amount: (args['amount'] as num?)?.toDouble() ?? 0.0,
            paymentMethod: args['paymentMethod'],
            reference: args['reference'],
            details:
                (args['details'] as List<MapEntry<String, String>>?) ?? const [],
            primaryButtonLabel:
                args['primaryButtonLabel'] ?? 'View Subscription',
          ),
          settings: settings,
        );

      case BasketScreen.id: // Basket screen route
        return MaterialPageRoute(
          builder: (_) => const BasketScreen(),
          settings: settings,
        );

      case LoginOrRegisterPage.id:
      case '/log_in': // Fallback alias for login route
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

      case CustomerAddressScreen.id:
        return MaterialPageRoute(
          builder: (_) => const CustomerAddressScreen(),
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

      case VendorBankSettingsScreen.id:
        return MaterialPageRoute(
          builder: (_) => const VendorBankSettingsScreen(),
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

      case RiderRegistrationScreen.id:
        return MaterialPageRoute(
          builder: (_) => const RiderRegistrationScreen(),
          settings: settings,
        );

      case RiderDashboardScreen.id:
        return MaterialPageRoute(
          builder: (_) => const RiderDashboardScreen(),
          settings: settings,
        );

      case RiderHistoryScreen.id:
        return MaterialPageRoute(
          builder: (_) => const RiderHistoryScreen(),
          settings: settings,
        );

      case RiderWalletScreen.id:
        return MaterialPageRoute(
          builder: (_) => const RiderWalletScreen(),
          settings: settings,
        );

      case RiderActiveRideScreen.id:
        final activeRide = settings.arguments as ActiveRide?;
        if (activeRide != null) {
          return MaterialPageRoute(
            builder: (_) => RiderActiveRideScreen(ride: activeRide),
            settings: settings,
          );
        }
        return MaterialPageRoute(
          builder: (_) => const RiderDashboardScreen(),
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

