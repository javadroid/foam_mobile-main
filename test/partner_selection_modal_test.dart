import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foam_mobile/widgets/partner_selection_modal.dart';

void main() {
  testWidgets('PartnerSelectionModal displays vendor and rider options and handles taps', (WidgetTester tester) async {
    bool vendorSelected = false;
    bool riderSelected = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                PartnerSelectionModal.show(
                  context,
                  onSelectVendor: () {
                    vendorSelected = true;
                  },
                  onSelectRider: () {
                    riderSelected = true;
                  },
                );
              },
              child: const Text('Open Modal'),
            ),
          ),
        ),
      ),
    );

    // Tap to open modal
    await tester.tap(find.text('Open Modal'));
    await tester.pumpAndSettle();

    // Verify modal headers and cards are rendered
    expect(find.text('Partner with Foam'), findsOneWidget);
    expect(find.text('Choose a program to get started.'), findsOneWidget);
    expect(find.text('Laundry Business Partner'), findsOneWidget);
    expect(find.text('Delivery Rider Partner'), findsOneWidget);

    // Tap Vendor card
    await tester.tap(find.text('Laundry Business Partner'));
    await tester.pumpAndSettle();

    expect(vendorSelected, isTrue);

    // Open again to test Rider tap
    await tester.tap(find.text('Open Modal'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Delivery Rider Partner'));
    await tester.pumpAndSettle();

    expect(riderSelected, isTrue);
  });
}

