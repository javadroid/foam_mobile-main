import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foam_mobile/core/services/foam_payment_service.dart';
import 'package:foam_mobile/widgets/foam_payment_sheet.dart';

void main() {
  testWidgets(
      'FoamPaymentSheet displays official Google Pay Mark in payment option tile and CTA',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(450, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: FoamPaymentSheet(
            title: 'Complete Order Payment',
            itemTitle: 'Laundry & Folding Order',
            amount: 5000,
            purpose: FoamPaymentPurpose.order,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Verify "Google Pay" option tile is present
    expect(find.text('Google Pay'), findsOneWidget);
    expect(find.text('Fast 1-tap checkout via Google Wallet'), findsOneWidget);

    // 2. Verify official Google Pay mark asset is used in the UI
    final svgFinders = find.byType(SvgPicture);
    expect(svgFinders, findsWidgets);

    // Ensure the old generic search google.svg is NOT used for Google Pay
    bool foundOldGoogleSvg = false;
    bool foundOfficialGooglePayMark = false;

    for (final element in svgFinders.evaluate()) {
      final svgWidget = element.widget as SvgPicture;
      final bytesLoader = svgWidget.bytesLoader;
      final description = bytesLoader.toString();
      if (description.contains('google.svg')) {
        foundOldGoogleSvg = true;
      }
      if (description.contains('google_pay_mark.svg')) {
        foundOfficialGooglePayMark = true;
      }
    }

    expect(foundOldGoogleSvg, isFalse,
        reason: 'Generic google.svg should not be used for Google Pay');
    expect(foundOfficialGooglePayMark, isTrue,
        reason: 'Official Google Pay Mark SVG must be used');

    // 3. Tap Google Pay to select it and verify CTA button
    await tester.tap(find.text('Google Pay'));
    await tester.pumpAndSettle();

    expect(find.text('Pay with '), findsOneWidget);
  });
}
