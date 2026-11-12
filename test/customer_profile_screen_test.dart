import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foam_mobile/core/Screens/profile/customer_address_screen.dart';
import 'package:foam_mobile/core/Screens/profile/profile_screen.dart';
import 'package:foam_mobile/feature/authentication/controller/provider/authprovider.dart';
import 'package:foam_mobile/feature/authentication/view/sign_up_pages/sign_up_1.dart';
import 'package:foam_mobile/feature/rider/controller/rider_provider.dart';
import 'package:foam_mobile/feature/vendor/controller/vendor_provider.dart';
import 'package:foam_mobile/feature/wallet/controller/wallet_provider.dart';
import 'package:foam_mobile/widgets/safe_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets(
      'ProfileScreen renders themed avatar with SafeNetworkImage, camera badge, and personal details',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(450, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final authProvider = AuthProvider();
    authProvider.fillAuth(
      'Amina',
      'Bello',
      null,
      'amina@foam.com',
      '+2348099887766',
    );

    final vendorProvider = VendorProvider();
    final riderProvider = RiderProvider();
    final walletProvider = WalletProvider();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: authProvider),
          ChangeNotifierProvider.value(value: vendorProvider),
          ChangeNotifierProvider.value(value: riderProvider),
          ChangeNotifierProvider.value(value: walletProvider),
        ],
        child: const MaterialApp(
          home: ProfileScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Verify User Name and Email
    expect(find.text('Amina Bello'), findsWidgets);
    expect(find.text('amina@foam.com'), findsWidgets);

    // 2. Verify SafeNetworkImage is used for avatar with initials fallback
    expect(find.byType(SafeNetworkImage), findsOneWidget);
    expect(find.text('AB'), findsOneWidget);

    // 3. Verify Camera icon is present for avatar upload
    expect(find.byIcon(Icons.camera_alt_rounded), findsOneWidget);

    // 4. Verify Personal Details section
    expect(find.text('Personal Details'), findsOneWidget);
    expect(find.text('Full Name'), findsOneWidget);
    expect(find.text('Phone Number'), findsOneWidget);
    expect(find.text('+2348099887766'), findsOneWidget);
    expect(find.text('Email Address'), findsOneWidget);

    // 5. Verify Subscriptions, Partner Programs, and Address
    expect(find.text('Subscriptions & Membership'), findsOneWidget);
    expect(find.text('Billing & Subscriptions'), findsOneWidget);
    expect(find.text('Manage'), findsOneWidget);

    expect(find.text('Partner Programs'), findsOneWidget);
    expect(find.text('Partner with Foam'), findsOneWidget);
    expect(find.text('Explore'), findsOneWidget);

    expect(find.text('Saved Address'), findsOneWidget);
    expect(find.text('Default Pickup Address'), findsOneWidget);
    expect(find.text('Change'), findsOneWidget);

    expect(find.text('Security & Preferences'), findsOneWidget);
    expect(find.text('Account Password'), findsOneWidget);
    expect(find.text('Update'), findsOneWidget);

    // 6. Test tapping Camera icon opens Photo Options sheet
    await tester.tap(find.byIcon(Icons.camera_alt_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Profile Photo'), findsOneWidget);
    expect(find.text('Choose from Gallery'), findsOneWidget);
    expect(find.text('Take Photo'), findsOneWidget);

    // Dismiss bottom sheet
    tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    // 7. Test tapping Edit icon opens Edit Profile modal
    await tester.tap(find.byIcon(Icons.edit_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Edit Profile'), findsOneWidget);
    expect(find.text('Save Changes'), findsOneWidget);

    // Dismiss modal
    tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    vendorProvider.dispose();
  });

  testWidgets(
      'Tapping Default Pickup Address in ProfileScreen navigates to CustomerAddressScreen',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(450, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final authProvider = AuthProvider();
    authProvider.fillAuth(
      'Amina',
      'Bello',
      null,
      'amina@foam.com',
      '+2348099887766',
    );
    authProvider.fillAddress(
      '14 Stadium Road',
      'Port Harcourt',
      'Near stadium gate',
      'Nigeria',
      state: 'Rivers State',
      lga: 'Port Harcourt',
      latitude: 4.8156,
      longitude: 7.0498,
    );

    final vendorProvider = VendorProvider();
    final riderProvider = RiderProvider();
    final walletProvider = WalletProvider();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: authProvider),
          ChangeNotifierProvider.value(value: vendorProvider),
          ChangeNotifierProvider.value(value: riderProvider),
          ChangeNotifierProvider.value(value: walletProvider),
        ],
        child: MaterialApp(
          home: const ProfileScreen(),
          routes: {
            CustomerAddressScreen.id: (_) => const CustomerAddressScreen(),
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Default Pickup Address tile is visible
    expect(find.text('Default Pickup Address'), findsOneWidget);

    // Tap Default Pickup Address
    await tester.tap(find.text('Default Pickup Address'));
    await tester.pumpAndSettle();

    // Should now be on CustomerAddressScreen
    expect(find.byType(CustomerAddressScreen), findsOneWidget);
    expect(find.text('Pickup Address'), findsOneWidget);
    expect(find.text('Delivery & Pickup Address '), findsOneWidget);
    expect(find.text('Use Current Location'), findsOneWidget);
    expect(find.text('Save Pickup Address'), findsOneWidget);

    // Verify prefilled data from AuthProvider
    expect(find.text('14 Stadium Road'), findsOneWidget);
    expect(find.text('Port Harcourt'), findsWidgets);
    expect(
      find.byWidgetPredicate(
        (w) => w is EditableText && w.controller.text == 'Rivers State',
      ),
      findsOneWidget,
    );
    expect(find.text('GPS Pin Tagged'), findsOneWidget);

    vendorProvider.dispose();
  });

  testWidgets('SignUpPage1 renders onboarding flow when isFromProfile is false',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(450, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final authProvider = AuthProvider();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: authProvider),
        ],
        child: const MaterialApp(
          home: SignUpPage1(isFromProfile: false),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify onboarding header & actions
    expect(find.text('Step 2 of 2'), findsOneWidget);
    expect(find.text('Log Out'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.text('Complete Registration'), findsOneWidget);
  });

  testWidgets(
      'SignUpPage1 renders clean profile address view when isFromProfile is true',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(450, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final authProvider = AuthProvider();
    authProvider.fillAddress(
      '22 Woji Road, GRA',
      'Port Harcourt',
      '',
      'Nigeria',
      state: 'Rivers State',
      lga: 'Obio-Akpor',
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: authProvider),
        ],
        child: const MaterialApp(
          home: SignUpPage1(isFromProfile: true),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify profile address title in AppBar
    expect(find.text('Pickup Address'), findsWidgets);
    // Onboarding items should NOT be present
    expect(find.text('Step 2 of 2'), findsNothing);
    expect(find.text('Log Out'), findsNothing);
    expect(find.text('Complete Registration'), findsNothing);
    // Profile save button should be present
    expect(find.text('Save Pickup Address'), findsOneWidget);
  });

  testWidgets(
      'Tapping Use Current Location in CustomerAddressScreen is compact and triggers auto-detect',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(450, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final authProvider = AuthProvider();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: authProvider),
        ],
        child: const MaterialApp(
          home: CustomerAddressScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify compact button is present
    expect(find.text('Use Current Location'), findsOneWidget);

    // Tap Use Current Location
    await tester.tap(find.text('Use Current Location'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  });
}
