import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foam_mobile/widgets/foam_payment_sheet.dart';
import 'package:foam_mobile/core/services/foam_payment_service.dart';

void main() {
  testWidgets('FoamPaymentSheet renders brand-compliant Google Pay Mark and button',
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

    expect(find.text('Google Pay'), findsOneWidget);
    expect(find.text('Choose Payment Method'), findsOneWidget);
    expect(find.text('Pay with '), findsOneWidget);
  });
}
