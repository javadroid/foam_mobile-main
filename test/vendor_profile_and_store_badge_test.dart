import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foam_mobile/feature/authentication/controller/provider/authprovider.dart';
import 'package:foam_mobile/feature/vendor/controller/vendor_provider.dart';
import 'package:foam_mobile/feature/vendor/models/vendor_models.dart';
import 'package:foam_mobile/feature/vendor/profile/vendor_bank_settings_screen.dart';
import 'package:foam_mobile/feature/vendor/profile/vendor_profile_screen.dart';
import 'package:foam_mobile/feature/vendor/store_setup/vendor_store_details_screen.dart';
import 'package:foam_mobile/feature/vendor/stores/vendor_stores_list_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets(
      'VendorProfileScreen uses only theme, renders Verified Partner badge, and removes branch allocation',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(450, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final authProvider = AuthProvider();
    authProvider.fillAuth(
      'Bubble',
      'Owner',
      null,
      'bubble@express.com',
      '+2348012345678',
      businessName: 'Bubble Express Laundry',
    );

    final vendorProvider = VendorProvider();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: authProvider),
          ChangeNotifierProvider.value(value: vendorProvider),
        ],
        child: const MaterialApp(
          home: VendorProfileScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Verify business name, email, phone, and verified partner check icon
    expect(find.text('Bubble Express Laundry'), findsOneWidget);
    expect(find.text('bubble@express.com'), findsOneWidget);
    expect(find.text('+2348012345678'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_rounded), findsWidgets);

    // 2. Verify avatar has camera icon for photo update
    expect(find.byIcon(Icons.camera_alt_rounded), findsOneWidget);

    // 3. Verify Store Branches & Capacity and Branch Allocation are REMOVED
    expect(find.text('Store Branches & Capacity'), findsNothing);
    expect(find.text('Branch Allocation'), findsNothing);
    expect(find.text('Manage All Branches'), findsNothing);
    expect(find.text('Add New Store Branch'), findsNothing);

    // 4. Verify Payouts & Finance menu items are present
    expect(find.text('Payout Bank Account'), findsOneWidget);
    expect(find.text('Wallet & Withdrawals'), findsOneWidget);
    expect(find.text('Business KYC Documents'), findsOneWidget);

    // 5. Tapping Payout Bank Account opens dedicated VendorBankSettingsScreen
    await tester.tap(find.text('Payout Bank Account'));
    await tester.pumpAndSettle();

    expect(find.byType(VendorBankSettingsScreen), findsOneWidget);
    expect(find.text('Select Bank'), findsWidgets);
    expect(find.text('NUBAN Account Number'), findsOneWidget);

    // Verify it is NOT the onboarding screen (no Step 2 of 2)
    expect(find.text('Step 2 of 2'), findsNothing);

    vendorProvider.dispose();
  });

  testWidgets(
      'VendorBankSettingsScreen renders active verified bank when configured',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(450, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final authProvider = AuthProvider();
    final vendorProvider = VendorProvider();

    // Simulate verified bank already configured in kycStatus
    vendorProvider.setKycBank(
      bankName: 'Guaranty Trust Bank',
      accountNumber: '0123456789',
      accountName: 'BUBBLE LAUNDRY SERVICES',
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: authProvider),
          ChangeNotifierProvider.value(value: vendorProvider),
        ],
        child: const MaterialApp(
          home: VendorBankSettingsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Payout Bank Account'), findsOneWidget);
    expect(find.text('Guaranty Trust Bank'), findsWidgets);
    expect(find.text('•••• 6789'), findsOneWidget);
    expect(find.text('BUBBLE LAUNDRY SERVICES'), findsOneWidget);
    expect(find.text('Active'), findsOneWidget);
    expect(find.text('Update Payout Bank'), findsOneWidget);

    vendorProvider.dispose();
  });

  testWidgets(
      'VendorStoresListScreen renders Verified Partner badge on each store item',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(450, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final authProvider = AuthProvider();
    final vendorProvider = VendorProvider();
    vendorProvider.addStore(VendorStore(
      id: 'store_1',
      name: 'Branch Alpha',
      address: '1 Lekki Phase 1',
      status: 'ACTIVE',
      itemsPricedCount: 8,
    ));
    vendorProvider.addStore(VendorStore(
      id: 'store_2',
      name: 'Branch Beta',
      address: '50 Allen Avenue, Ikeja',
      status: 'ACTIVE',
      itemsPricedCount: 5,
    ));

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: authProvider),
          ChangeNotifierProvider.value(value: vendorProvider),
        ],
        child: const MaterialApp(
          home: VendorStoresListScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify both stores show Verified Partner badge
    expect(find.text('Branch Alpha'), findsOneWidget);
    expect(find.text('Branch Beta'), findsOneWidget);
    expect(find.text('Verified Partner'), findsNWidgets(2));

    vendorProvider.dispose();
  });

  testWidgets(
      'VendorStoreDetailsScreen does not have file upload for store photo (photo is handled in profile)',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(450, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final authProvider = AuthProvider();
    final vendorProvider = VendorProvider();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: authProvider),
          ChangeNotifierProvider.value(value: vendorProvider),
        ],
        child: const MaterialApp(
          home: VendorStoreDetailsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify file upload for store photo is completely removed
    expect(find.text('Store photo'), findsNothing);
    expect(find.text('Tap to upload store photo'), findsNothing);
    expect(find.text('Update Brand Photo'), findsNothing);

    // Verify core branch setup fields remain
    expect(find.text('Store name & branch'), findsOneWidget);
    expect(find.text('Physical address'), findsOneWidget);
    expect(find.text('Coordinates Required'), findsOneWidget);
    expect(find.text('Operating hours'), findsOneWidget);
    expect(find.text('TURNAROUND SPEED PACKAGES'), findsOneWidget);

    vendorProvider.dispose();
  });
}
