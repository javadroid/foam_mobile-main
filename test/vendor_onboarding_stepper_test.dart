import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foam_mobile/feature/authentication/controller/provider/authprovider.dart';
import 'package:foam_mobile/feature/vendor/controller/vendor_provider.dart';
import 'package:foam_mobile/feature/vendor/onboarding/vendor_onboarding_stepper_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Widget createTestWidget({VendorProvider? vendorProvider}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => vendorProvider ?? VendorProvider()),
      ],
      child: const MaterialApp(
        home: VendorOnboardingStepperScreen(),
      ),
    );
  }

  testWidgets('VendorOnboardingStepperScreen renders Figma Step 0 design correctly',
      (WidgetTester tester) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    // Verify brand tag, heading, and subtitle matching Figma
    expect(find.text('FOAM FOR BUSINESS'), findsOneWidget);
    expect(find.text('Create vendor account'), findsOneWidget);
    expect(
      find.text(
          "Run your laundry stores on Foam. We'll verify your business before you go live."),
      findsOneWidget,
    );

    // Verify input fields
    expect(find.text('Business name'), findsOneWidget);
    expect(find.text("Owner's full name"), findsOneWidget);
    expect(find.text('Email address'), findsOneWidget);
    expect(find.text('+234'), findsOneWidget);
    expect(find.text('Phone number'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);

    // Verify CTA button and draft button
    expect(find.text('Continue'), findsOneWidget);
    expect(find.text('Save Draft'), findsOneWidget);
    expect(find.text('Save as Draft & Finish Later'), findsOneWidget);

    // Verify footer login link
    expect(
      find.byWidgetPredicate((widget) =>
          widget is RichText &&
          widget.text.toPlainText().contains('Already a vendor? Log in')),
      findsOneWidget,
    );

    // Enter business name and verify text fields
    await tester.enterText(
        find.widgetWithText(TextField, 'Business name'), 'QuickWash Hub');
    expect(find.text('QuickWash Hub'), findsOneWidget);

    // Verify vertical alignment: fields with suffixIcon do not shift up
    final businessFieldFinder = find.widgetWithText(TextField, 'QuickWash Hub');
    final passwordFieldFinder = find.widgetWithText(TextField, 'Password');
    expect(businessFieldFinder, findsOneWidget);
    expect(passwordFieldFinder, findsOneWidget);

    final businessFieldBox = tester.getRect(businessFieldFinder);
    final passwordFieldBox = tester.getRect(passwordFieldFinder);
    expect(businessFieldBox.height, equals(passwordFieldBox.height));
  });

  testWidgets('VendorOnboardingStepperScreen renders Step 1 (Verify your business) when onboardingStep is 1',
      (WidgetTester tester) async {
    final vendor = VendorProvider();
    vendor.setOnboardingStep(1);

    await tester.pumpWidget(createTestWidget(vendorProvider: vendor));
    await tester.pumpAndSettle();

    expect(find.text('Step 1 of 2'), findsOneWidget);
    expect(find.text('Verify your business'), findsOneWidget);
    expect(
      find.text(
          'Upload clear photos or PDFs. Foam reviews every vendor before approval.'),
      findsOneWidget,
    );

    expect(find.text('CAC registration'), findsOneWidget);
    expect(find.text("Owner's ID"), findsOneWidget);
    expect(find.text('Proof of address'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
    expect(find.text('Save as Draft & Finish Later'), findsOneWidget);
  });

  testWidgets('VendorOnboardingStepperScreen renders Step 2 (Where should we pay you?) when onboardingStep is 2',
      (WidgetTester tester) async {
    final vendor = VendorProvider();
    vendor.setOnboardingStep(2);

    await tester.pumpWidget(createTestWidget(vendorProvider: vendor));
    await tester.pumpAndSettle();

    expect(find.text('Step 2 of 2'), findsOneWidget);
    expect(find.text('Where should we pay you?'), findsOneWidget);
    expect(
      find.text(
          "Your earnings are withdrawn to this account. It must be in your business or owner's name."),
      findsOneWidget,
    );

    expect(find.text('Select Bank'), findsOneWidget);
    expect(find.text('0123 454 821'), findsOneWidget);
    expect(
      find.text(
          "By submitting, you agree to Foam's vendor terms, including a 15% commission on item subtotals."),
      findsOneWidget,
    );
    expect(find.text('Submit for review'), findsOneWidget);
    expect(find.text('Save as Draft & Finish Later'), findsOneWidget);
  });
}
