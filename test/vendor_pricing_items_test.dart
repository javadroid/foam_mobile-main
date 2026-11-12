import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foam_mobile/feature/authentication/controller/provider/authprovider.dart';
import 'package:foam_mobile/feature/vendor/controller/vendor_provider.dart';
import 'package:foam_mobile/feature/vendor/models/vendor_models.dart';
import 'package:foam_mobile/feature/vendor/store_setup/vendor_pricing_items_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Widget createTestWidget({
    required VendorProvider vendorProvider,
    String serviceType = 'Laundry',
  }) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider.value(value: vendorProvider),
      ],
      child: MaterialApp(
        home: VendorPricingItemsScreen(serviceType: serviceType),
      ),
    );
  }

  testWidgets(
      'VendorPricingItemsScreen renders default items, per-item folding toggled ON by default, and admin commission',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(450, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final provider = VendorProvider();

    provider.addStore(VendorStore(
      id: 'store_1',
      name: 'Bright Wash Central',
      address: '12 Marina Road, Lagos',
      status: 'ACTIVE',
      turnaroundDays: 2,
    ));

    await tester.pumpWidget(createTestWidget(vendorProvider: provider));
    await tester.pumpAndSettle();

    // 1. Verify header and dynamic admin commission
    expect(find.text('Laundry'), findsOneWidget);
    expect(find.text('Foam: 15% fee'), findsOneWidget);

    // 2. Verify default laundry items are present
    expect(find.text('Shirt'), findsOneWidget);
    expect(find.text('T-shirt'), findsOneWidget);
    expect(find.text('Trouser'), findsOneWidget);
    expect(find.text('Jeans'), findsOneWidget);

    // 3. Verify Folding Service is per-item and ON by default
    expect(find.text('Folding included'), findsWidgets);
    expect(find.text('Included for customer without extra cost'), findsWidgets);

    // 4. Verify we can enter price for Shirt
    final shirtFieldFinder = find.byType(TextField).first;
    await tester.enterText(shirtFieldFinder, '500');
    await tester.pumpAndSettle();

    expect(find.text('1 of 8 items priced'), findsOneWidget);

    provider.dispose();
  });

  testWidgets(
      'Vendor can toggle off folding for an item and it shows folding optional',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(450, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final provider = VendorProvider();

    provider.addStore(VendorStore(
      id: 'store_1',
      name: 'Bright Wash Central',
      address: '12 Marina Road, Lagos',
      status: 'ACTIVE',
      turnaroundDays: 2,
    ));

    await tester.pumpWidget(createTestWidget(vendorProvider: provider));
    await tester.pumpAndSettle();

    // Toggle the first item's folding switch off
    final switchFinder = find.byType(Switch).first;
    expect(tester.widget<Switch>(switchFinder).value, isTrue);

    await tester.tap(switchFinder);
    await tester.pumpAndSettle();

    expect(tester.widget<Switch>(switchFinder).value, isFalse);
    expect(find.text('Folding optional'), findsOneWidget);
    expect(find.text('Customer can choose to add folding'), findsOneWidget);

    provider.dispose();
  });

  testWidgets('Vendor can add a custom item with price and folding',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(450, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final provider = VendorProvider();

    provider.addStore(VendorStore(
      id: 'store_1',
      name: 'Bright Wash Central',
      address: '12 Marina Road, Lagos',
      status: 'ACTIVE',
      turnaroundDays: 2,
    ));

    await tester.pumpWidget(createTestWidget(vendorProvider: provider));
    await tester.pumpAndSettle();

    // Tap "+ Add custom item"
    final addItemBtn = find.text('Add custom item');
    expect(addItemBtn, findsOneWidget);
    await tester.tap(addItemBtn);
    await tester.pumpAndSettle();

    // Dialog should appear
    expect(find.text('Add Item with Price'), findsOneWidget);

    // Enter name & price
    final textFields = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(TextField),
    );
    expect(textFields, findsNWidgets(2));

    await tester.enterText(textFields.at(0), 'Curtains (Large)');
    await tester.enterText(textFields.at(1), '2500');

    // Tap "Add Item" elevated button in dialog
    await tester.tap(find.widgetWithText(ElevatedButton, 'Add Item'));
    await tester.pumpAndSettle();

    // Verify custom item was saved in provider
    expect(provider.getCustomItems('store_1', 'Laundry'), contains('Curtains (Large)'));
    expect(find.text('1 of 9 items priced'), findsOneWidget);

    // Verify newly added item is in the list
    expect(find.text('Curtains (Large)'), findsOneWidget);
    expect(find.text('Custom'), findsOneWidget);
    expect(find.text('2500'), findsOneWidget);

    provider.dispose();
  });
}
