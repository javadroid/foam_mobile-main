import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foam_mobile/feature/authentication/controller/provider/authprovider.dart';
import 'package:foam_mobile/feature/schedule_pickup/controller/schedule_pickup_provider.dart';
import 'package:foam_mobile/feature/schedule_pickup/models/customer_schedule_models.dart';
import 'package:foam_mobile/feature/schedule_pickup/views/01_how_to_choose_screen.dart';
import 'package:foam_mobile/feature/schedule_pickup/views/02_tiers_screen.dart';
import 'package:foam_mobile/feature/schedule_pickup/views/03_nearby_stores_screen.dart';
import 'package:foam_mobile/feature/schedule_pickup/views/07_order_placed_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

Widget _buildTestApp(Widget child, SchedulePickupProvider provider,
    {AuthProvider? authProvider}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<SchedulePickupProvider>.value(value: provider),
      if (authProvider != null)
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
    ],
    child: MaterialApp(
      routes: {
        ScheduleTiersScreen.id: (_) => const ScheduleTiersScreen(),
        NearbyStoresScreen.id: (_) => const NearbyStoresScreen(),
      },
      home: child,
    ),
  );
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('Schedule Pickup Views UI Tests (Worker M1)', () {
    testWidgets('View 01: Address banner is tappable and opens location picker modal',
        (WidgetTester tester) async {
      final provider = SchedulePickupProvider();
      provider.setPickupAddress('3 Bisola Durosinmi-Etti Dr, Lekki');

      await tester.pumpWidget(_buildTestApp(const HowToChooseScreen(), provider));
      await tester.pumpAndSettle();

      // Find Pickup from banner
      expect(find.text('Pickup from'), findsOneWidget);
      expect(find.text('3 Bisola Durosinmi-Etti Dr, Lekki'), findsOneWidget);

      // Tap on the address banner
      await tester.tap(find.text('Pickup from'));
      await tester.pumpAndSettle();

      // Verify modal bottom sheet appears with location actions
      expect(find.text('Select pickup location'), findsOneWidget);
      expect(find.text('Auto-detect current location'), findsOneWidget);
      expect(find.text('Use device GPS coordinates'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Search address or landmark...'), findsOneWidget);
    });

    testWidgets('View 02: Renders dynamic tier subtitle from provider',
        (WidgetTester tester) async {
      final provider = SchedulePickupProvider();

      await tester.pumpWidget(_buildTestApp(const ScheduleTiersScreen(), provider));
      await tester.pumpAndSettle();

      // Verify dynamic subtitle is present
      expect(find.text(provider.tierSubtitle), findsOneWidget);

      // Verify tier options are rendered
      expect(find.text('Best value'), findsOneWidget);
      expect(find.text('Balanced'), findsOneWidget);
      expect(find.text('Premium'), findsOneWidget);
      expect(find.text('MOST PICKED'), findsOneWidget);
    });

    testWidgets('View 03: Renders stores with long names without RenderFlex overflow',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final provider = SchedulePickupProvider();
      const longStore = NearbyStore(
        id: 99,
        name: 'Extraordinarily Long Super Special Deluxe Dry Cleaning & Laundry Services Establishment',
        area: 'Port Harcourt Municipal Area',
        address: '100 Long Name Expressway',
        rating: 4.8,
        distanceKm: 3.5,
        turnaroundDays: 2,
        turnaroundText: 'Ready in 2 days',
        shirtStartingPrice: 500,
      );

      provider.selectStore(longStore);

      await tester.pumpWidget(_buildTestApp(const NearbyStoresScreen(), provider));
      await tester.pumpAndSettle();

      // Filter pills rendered
      expect(find.text('Closest'), findsOneWidget);
      expect(find.text('Top rated'), findsOneWidget);
      expect(find.text('Fastest'), findsOneWidget);

      // No RenderFlex overflow exception
      expect(tester.takeException(), isNull);
    });

    testWidgets('View 07: Renders pickup PIN inside FittedBox with proportional size',
        (WidgetTester tester) async {
      final provider = SchedulePickupProvider();
      provider.setLastCreatedOrderForTest({
        'id': 101,
        'orderNumber': 'FM-2101',
        'storeName': 'Lekki Whites',
        'pickupPin': '3921',
        'deliveryPin': '6604',
      });

      await tester.pumpWidget(_buildTestApp(const ScheduleOrderPlacedScreen(), provider));
      await tester.pumpAndSettle();

      // Verify Order placed and checkmark
      expect(find.text('Order placed'), findsOneWidget);
      expect(find.text('Your pickup PIN'), findsOneWidget);

      // Verify PIN text is rendered
      final pinFinder = find.text('3921');
      expect(pinFinder, findsOneWidget);

      // Verify the PIN Text is inside a FittedBox
      final fittedBoxFinder = find.ancestor(
        of: pinFinder,
        matching: find.byType(FittedBox),
      );
      expect(fittedBoxFinder, findsOneWidget);

      // Verify Track order button
      expect(find.text('Track order'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'View 01: On loading HowToChooseScreen uses saved location as pickup',
        (WidgetTester tester) async {
      final auth = AuthProvider();
      auth.fillAddress(
        '14 Stadium Road',
        'Port Harcourt',
        '',
        'Nigeria',
        state: 'Rivers State',
        lga: 'Port Harcourt',
        latitude: 4.8156,
        longitude: 7.0498,
      );

      final provider = SchedulePickupProvider();

      await tester.pumpWidget(
        _buildTestApp(const HowToChooseScreen(), provider, authProvider: auth),
      );
      await tester.pumpAndSettle();

      // Verify the banner automatically displays the saved pickup location
      expect(find.text('Pickup from'), findsOneWidget);
      expect(find.text('14 Stadium Road, Port Harcourt'), findsOneWidget);
      expect(provider.pickupAddress, '14 Stadium Road, Port Harcourt');
      expect(provider.pickupLat, 4.8156);
      expect(provider.pickupLng, 7.0498);

      // Tap on address banner to open modal
      await tester.tap(find.text('Pickup from'));
      await tester.pumpAndSettle();

      // Verify "Use Saved Pickup Address" option appears in modal
      expect(find.text('Use Saved Pickup Address'), findsOneWidget);
      expect(find.text('14 Stadium Road, Port Harcourt'), findsWidgets);
    });
  });
}
