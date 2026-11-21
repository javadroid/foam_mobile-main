import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:foam_mobile/widgets/foam_payment_sheet.dart';
import 'package:foam_mobile/core/services/foam_payment_service.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets(
      'FoamPaymentSheet renders brand-compliant Google Pay Mark and navigates to summary',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: FoamPaymentSheet(
            title: 'Subscribe to Plan',
            itemTitle: 'Standard Plan (Pro)',
            itemSubtitle: 'Complete all-in-one recurring laundry care',
            amount: 74000,
            cycleLabel: '/ month',
            purpose: FoamPaymentPurpose.subscription,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Step 1: Payment Method selection view
    expect(find.text('Choose Payment Method'), findsOneWidget);
    expect(find.text('Google Pay'), findsOneWidget);
    expect(find.text('Apple Pay'), findsOneWidget);
    expect(find.text('Paystack Checkout'), findsOneWidget);

    // Verify marked items are NOT on the methods view
    expect(find.text('Total Payable'), findsNothing);

    // Step 2: Tap Google Pay to navigate to Order Summary
    await tester.tap(find.text('Google Pay'));
    await tester.pumpAndSettle();

    // Verify Order Summary screen
    expect(find.text('Order Summary'), findsOneWidget);
    expect(find.text('Standard Plan (Pro)'), findsOneWidget);
    expect(find.text('Total Payable'), findsOneWidget);
    expect(find.text('CHANGE'), findsOneWidget);
    expect(find.text('Pay with '), findsOneWidget);

    // Step 3: Tap CHANGE to go back to methods view
    await tester.tap(find.text('CHANGE'));
    await tester.pumpAndSettle();

    expect(find.text('Choose Payment Method'), findsOneWidget);
  });
}
