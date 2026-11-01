import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foam_mobile/feature/schedule_pickup/controller/schedule_pickup_provider.dart';
import 'package:foam_mobile/feature/schedule_pickup/models/customer_schedule_models.dart';
import 'package:foam_mobile/feature/schedule_pickup/views/01_how_to_choose_screen.dart';
import 'package:foam_mobile/feature/schedule_pickup/views/02_tiers_screen.dart';
import 'package:foam_mobile/feature/schedule_pickup/views/03_nearby_stores_screen.dart';
import 'package:foam_mobile/feature/schedule_pickup/views/04_store_page_screen.dart';
import 'package:foam_mobile/feature/schedule_pickup/views/05_items_screen.dart';
import 'package:foam_mobile/feature/schedule_pickup/views/06_checkout_screen.dart';
import 'package:foam_mobile/feature/schedule_pickup/views/07_order_placed_screen.dart';
import 'package:foam_mobile/feature/schedule_pickup/views/09_at_store_screen.dart';
import 'package:foam_mobile/feature/schedule_pickup/views/11_delivered_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

const String kAdversarialStoreName =
    'Spotless Deluxe Laundry & Dry Cleaning Hub International Limited - Eneka Junction Branch';

const String kAdversarialAddress =
    'Suite 402, Block B, Mega Commercial Plaza, Plot 1482 Trans-Amadi Industrial Layout, Near Slaughter Roundabout, Port Harcourt, Rivers State, Nigeria';

Widget _buildTestApp({
  required Widget child,
  required SchedulePickupProvider provider,
  double textScale = 1.0,
  Size size = const Size(360, 640),
}) {
  return ChangeNotifierProvider<SchedulePickupProvider>.value(
    value: provider,
    child: MaterialApp(
      routes: {
        ScheduleTiersScreen.id: (_) => const ScheduleTiersScreen(),
        NearbyStoresScreen.id: (_) => const NearbyStoresScreen(),
        CustomerStorePageScreen.id: (_) => const CustomerStorePageScreen(),
        ScheduleItemsScreen.id: (_) => const ScheduleItemsScreen(),
        ScheduleCheckoutScreen.id: (_) => const ScheduleCheckoutScreen(),
        ScheduleOrderPlacedScreen.id: (_) => const ScheduleOrderPlacedScreen(),
        CustomerAtStoreScreen.id: (_) => const CustomerAtStoreScreen(),
        CustomerDeliveredScreen.id: (_) => const CustomerDeliveredScreen(),
      },
      home: MediaQuery(
        data: MediaQueryData(
          size: size,
          textScaler: TextScaler.linear(textScale),
        ),
        child: child,
      ),
    ),
  );
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('Adversarial Viewport & Overflow Tests (Challenger M1_1)', () {
    void setupViewport(WidgetTester tester, double width, double height, double textScale) {
      tester.view.physicalSize = Size(width, height);
      tester.view.devicePixelRatio = 1.0;
      tester.platformDispatcher.textScaleFactorTestValue = textScale;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        tester.platformDispatcher.clearTextScaleFactorTestValue();
      });
    }

    NearbyStore createAdversarialStore() {
      return const NearbyStore(
        id: 88,
        name: kAdversarialStoreName,
        area: 'Port Harcourt Trans-Amadi Industrial Layout Area',
        address: kAdversarialAddress,
        rating: 4.8,
        reviewCount: 1420,
        distanceKm: 3.2,
        turnaroundDays: 2,
        turnaroundText: 'Ready in 2 days (Standard delivery SLA guarantee)',
        shirtStartingPrice: 500,
        operatingHours: 'Monday - Saturday: 7:30 AM - 8:30 PM',
      );
    }

    // ==========================================
    // VIEW 01: HOW TO CHOOSE SCREEN
    // ==========================================
    testWidgets('View 01 (HowToChooseScreen) under 320dp width, long address, and 1.3x text zoom',
        (WidgetTester tester) async {
      setupViewport(tester, 320, 640, 1.3);

      final provider = SchedulePickupProvider();
      provider.setPickupAddress(kAdversarialAddress);

      await tester.pumpWidget(
        _buildTestApp(
          child: const HowToChooseScreen(),
          provider: provider,
          textScale: 1.3,
          size: const Size(320, 640),
        ),
      );
      await tester.pumpAndSettle();

      final exception = tester.takeException();
      expect(exception, isNull, reason: 'View 01 threw exception: $exception');
    });

    testWidgets('View 01 (HowToChooseScreen) under compact 320x568dp with 1.3x zoom',
        (WidgetTester tester) async {
      setupViewport(tester, 320, 568, 1.3);

      final provider = SchedulePickupProvider();
      provider.setPickupAddress(kAdversarialAddress);

      await tester.pumpWidget(
        _buildTestApp(
          child: const HowToChooseScreen(),
          provider: provider,
          textScale: 1.3,
          size: const Size(320, 568),
        ),
      );
      await tester.pumpAndSettle();

      final exception = tester.takeException();
      expect(exception, isNull, reason: 'View 01 vertical overflow on 320x568: $exception');
    });

    // ==========================================
    // VIEW 02: SCHEDULE TIERS SCREEN
    // ==========================================
    testWidgets('View 02 (ScheduleTiersScreen) under 320dp width and 1.3x text zoom',
        (WidgetTester tester) async {
      setupViewport(tester, 320, 640, 1.3);

      final provider = SchedulePickupProvider();

      await tester.pumpWidget(
        _buildTestApp(
          child: const ScheduleTiersScreen(),
          provider: provider,
          textScale: 1.3,
          size: const Size(320, 640),
        ),
      );
      await tester.pumpAndSettle();

      final exception = tester.takeException();
      expect(exception, isNull, reason: 'View 02 threw exception: $exception');
    });

    testWidgets('View 02 (ScheduleTiersScreen) under compact 320x568dp with 1.3x zoom',
        (WidgetTester tester) async {
      setupViewport(tester, 320, 568, 1.3);

      final provider = SchedulePickupProvider();

      await tester.pumpWidget(
        _buildTestApp(
          child: const ScheduleTiersScreen(),
          provider: provider,
          textScale: 1.3,
          size: const Size(320, 568),
        ),
      );
      await tester.pumpAndSettle();

      final exception = tester.takeException();
      expect(exception, isNull, reason: 'View 02 vertical overflow on 320x568: $exception');
    });

    // ==========================================
    // VIEW 03: NEARBY STORES SCREEN
    // ==========================================
    testWidgets('View 03 (NearbyStoresScreen) under 320dp width, 1.3x zoom, and 120-char store name',
        (WidgetTester tester) async {
      setupViewport(tester, 320, 640, 1.3);

      final provider = SchedulePickupProvider();
      provider.selectStore(createAdversarialStore());

      await tester.pumpWidget(
        _buildTestApp(
          child: const NearbyStoresScreen(),
          provider: provider,
          textScale: 1.3,
          size: const Size(320, 640),
        ),
      );
      await tester.pumpAndSettle();

      final exception = tester.takeException();
      expect(exception, isNull, reason: 'View 03 threw exception: $exception');
    });

    // ==========================================
    // VIEW 04: CUSTOMER STORE PAGE SCREEN
    // ==========================================
    testWidgets('View 04 (CustomerStorePageScreen) under 320dp width, 1.3x zoom, and long store stats',
        (WidgetTester tester) async {
      setupViewport(tester, 320, 640, 1.3);

      final provider = SchedulePickupProvider();
      provider.selectStore(createAdversarialStore());

      await tester.pumpWidget(
        _buildTestApp(
          child: const CustomerStorePageScreen(),
          provider: provider,
          textScale: 1.3,
          size: const Size(320, 640),
        ),
      );
      await tester.pumpAndSettle();

      final exception = tester.takeException();
      expect(exception, isNull, reason: 'View 04 threw exception: $exception');
    });

    testWidgets('View 04 (CustomerStorePageScreen) under 360dp width and 412dp width with long store name',
        (WidgetTester tester) async {
      setupViewport(tester, 360, 640, 1.3);

      final provider = SchedulePickupProvider();
      provider.selectStore(createAdversarialStore());

      await tester.pumpWidget(
        _buildTestApp(
          child: const CustomerStorePageScreen(),
          provider: provider,
          textScale: 1.3,
          size: const Size(360, 640),
        ),
      );
      await tester.pumpAndSettle();

      final exception = tester.takeException();
      expect(exception, isNull, reason: 'View 04 (360dp) threw exception: $exception');
    });

    // ==========================================
    // VIEW 05: SCHEDULE ITEMS SCREEN
    // ==========================================
    testWidgets('View 05 (ScheduleItemsScreen) under 320dp width, 1.3x zoom, 120-char store, 6-digit total',
        (WidgetTester tester) async {
      setupViewport(tester, 320, 640, 1.3);

      final provider = SchedulePickupProvider();
      provider.selectStore(createAdversarialStore());
      // Set quantities to produce 6-digit subtotal: 500 shirts * 500 = 250,000
      provider.items.firstWhere((i) => i.id == 1).quantity = 500;

      await tester.pumpWidget(
        _buildTestApp(
          child: const ScheduleItemsScreen(),
          provider: provider,
          textScale: 1.3,
          size: const Size(320, 640),
        ),
      );
      await tester.pumpAndSettle();

      final exception = tester.takeException();
      expect(exception, isNull, reason: 'View 05 threw exception: $exception');
    });

    // ==========================================
    // VIEW 06: SCHEDULE CHECKOUT SCREEN
    // ==========================================
    testWidgets('View 06 (ScheduleCheckoutScreen) under 320dp width, 1.3x zoom, 120-char store name',
        (WidgetTester tester) async {
      setupViewport(tester, 320, 640, 1.3);

      final provider = SchedulePickupProvider();
      provider.selectStore(createAdversarialStore());
      provider.items.firstWhere((i) => i.id == 1).quantity = 500;

      await tester.pumpWidget(
        _buildTestApp(
          child: const ScheduleCheckoutScreen(),
          provider: provider,
          textScale: 1.3,
          size: const Size(320, 640),
        ),
      );
      await tester.pumpAndSettle();

      final exception = tester.takeException();
      expect(exception, isNull, reason: 'View 06 (320dp) threw exception: $exception');
    });

    testWidgets('View 06 (ScheduleCheckoutScreen) under standard 360dp width with 120-char store name',
        (WidgetTester tester) async {
      setupViewport(tester, 360, 640, 1.0);

      final provider = SchedulePickupProvider();
      provider.selectStore(createAdversarialStore());

      await tester.pumpWidget(
        _buildTestApp(
          child: const ScheduleCheckoutScreen(),
          provider: provider,
          textScale: 1.0,
          size: const Size(360, 640),
        ),
      );
      await tester.pumpAndSettle();

      final exception = tester.takeException();
      expect(exception, isNull, reason: 'View 06 (360dp) threw exception: $exception');
    });

    testWidgets('View 06 (ScheduleCheckoutScreen) under 412dp width with 120-char store name and 1.3x zoom',
        (WidgetTester tester) async {
      setupViewport(tester, 412, 915, 1.3);

      final provider = SchedulePickupProvider();
      provider.selectStore(createAdversarialStore());

      await tester.pumpWidget(
        _buildTestApp(
          child: const ScheduleCheckoutScreen(),
          provider: provider,
          textScale: 1.3,
          size: const Size(412, 915),
        ),
      );
      await tester.pumpAndSettle();

      final exception = tester.takeException();
      expect(exception, isNull, reason: 'View 06 (412dp) threw exception: $exception');
    });

    // ==========================================
    // VIEW 07: ORDER PLACED SCREEN
    // ==========================================
    testWidgets('View 07 (ScheduleOrderPlacedScreen) under 320dp width, 1.3x zoom, 120-char store name',
        (WidgetTester tester) async {
      setupViewport(tester, 320, 640, 1.3);

      final provider = SchedulePickupProvider();
      provider.selectStore(createAdversarialStore());

      await tester.pumpWidget(
        _buildTestApp(
          child: const ScheduleOrderPlacedScreen(),
          provider: provider,
          textScale: 1.3,
          size: const Size(320, 640),
        ),
      );
      await tester.pumpAndSettle();

      final exception = tester.takeException();
      expect(exception, isNull, reason: 'View 07 threw exception: $exception');
    });

    testWidgets('View 07 (ScheduleOrderPlacedScreen) under compact 320x568dp with 1.3x zoom',
        (WidgetTester tester) async {
      setupViewport(tester, 320, 568, 1.3);

      final provider = SchedulePickupProvider();
      provider.selectStore(createAdversarialStore());

      await tester.pumpWidget(
        _buildTestApp(
          child: const ScheduleOrderPlacedScreen(),
          provider: provider,
          textScale: 1.3,
          size: const Size(320, 568),
        ),
      );
      await tester.pumpAndSettle();

      final exception = tester.takeException();
      expect(exception, isNull, reason: 'View 07 vertical overflow on 320x568: $exception');
    });

    // ==========================================
    // VIEW 09: CUSTOMER AT STORE SCREEN
    // ==========================================
    testWidgets('View 09 (CustomerAtStoreScreen) under 320dp width, 1.3x zoom, 120-char store name',
        (WidgetTester tester) async {
      setupViewport(tester, 320, 640, 1.3);

      final provider = SchedulePickupProvider();
      provider.selectStore(createAdversarialStore());

      await tester.pumpWidget(
        _buildTestApp(
          child: const CustomerAtStoreScreen(),
          provider: provider,
          textScale: 1.3,
          size: const Size(320, 640),
        ),
      );
      await tester.pumpAndSettle();

      final exception = tester.takeException();
      expect(exception, isNull, reason: 'View 09 threw exception: $exception');
    });

    // ==========================================
    // VIEW 11: CUSTOMER DELIVERED SCREEN
    // ==========================================
    testWidgets('View 11 (CustomerDeliveredScreen) under 320dp width, 1.3x zoom, 120-char store name',
        (WidgetTester tester) async {
      setupViewport(tester, 320, 640, 1.3);

      final provider = SchedulePickupProvider();
      provider.selectStore(createAdversarialStore());

      await tester.pumpWidget(
        _buildTestApp(
          child: const CustomerDeliveredScreen(),
          provider: provider,
          textScale: 1.3,
          size: const Size(320, 640),
        ),
      );
      await tester.pumpAndSettle();

      final exception = tester.takeException();
      expect(exception, isNull, reason: 'View 11 threw exception: $exception');
    });
  });
}
