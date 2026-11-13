import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foam_mobile/core/Screens/history/history_screen.dart';
import 'package:foam_mobile/feature/schedule_pickup/controller/schedule_pickup_provider.dart';
import 'package:foam_mobile/feature/schedule_pickup/models/customer_schedule_models.dart';
import 'package:foam_mobile/feature/schedule_pickup/views/05_items_screen.dart';
import 'package:foam_mobile/feature/schedule_pickup/views/06_checkout_screen.dart';
import 'package:foam_mobile/feature/schedule_pickup/views/07_order_placed_screen.dart';
import 'package:foam_mobile/feature/vendor/controller/vendor_provider.dart';
import 'package:foam_mobile/feature/vendor/models/vendor_models.dart';
import 'package:foam_mobile/feature/vendor/store_setup/vendor_store_details_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('Turnaround, Store Folding Price & Checkout Order Flow Tests', () {
    test(
        'Turnaround multiplier dynamically alters item prices in SchedulePickupProvider',
        () {
      final provider = SchedulePickupProvider();
      final testStore = NearbyStore(
        id: '10',
        name: 'Express Cleaners',
        area: 'Lekki Phase 1',
        address: 'Admiralty Way, Lekki',
        rating: 4.9,
        distanceKm: 2.1,
        turnaroundDays: 2,
        turnaroundText: 'Ready in 2 days',
        shirtStartingPrice: 500,
        foldingPrice: 150.0,
        turnaroundOptions: const [
          TurnaroundOption(
            days: 3,
            name: 'Basic',
            priceMultiplier: 1.0,
            shirtStartingPrice: 500,
          ),
          TurnaroundOption(
            days: 2,
            name: 'Balance',
            priceMultiplier: 1.2,
            shirtStartingPrice: 600,
          ),
          TurnaroundOption(
            days: 1,
            name: 'Premium',
            priceMultiplier: 1.5,
            shirtStartingPrice: 750,
          ),
        ],
      );

      provider.selectStore(testStore);
      provider.selectTurnaroundDays(3); // Basic (1.0x)

      // Find shirt (base 500)
      final shirt = provider.items.firstWhere((i) => i.id == 1);
      // basePrice = round(500 * 1.0) = 500 + folding (150) = 650
      expect(provider.getItemPrice(shirt), 650);

      // Switch to Premium (1.5x)
      provider.selectTurnaroundDays(1);
      // basePrice = round(500 * 1.5) = 750 + folding (150) = 900
      expect(provider.getItemPrice(shirt), 900);

      // Verify store folding total
      // Shirt qty: 4, T-shirt qty: 2 (both foldType == 'Folding') -> 6 * 150 = 900
      expect(provider.storeFoldingTotal, 6 * 150);
    });

    test(
        'Store folding price per store affects all folded items and itemSubtotal',
        () {
      final provider = SchedulePickupProvider();
      // Store with custom 250 folding price per item
      final storeWithFolding = const NearbyStore(
        id: '11',
        name: 'Prime Wash Hub',
        area: 'Victoria Island',
        address: 'Ahmadu Bello Way',
        rating: 4.8,
        distanceKm: 1.5,
        turnaroundDays: 2,
        turnaroundText: 'Ready in 2 days',
        shirtStartingPrice: 500,
        foldingPrice: 250.0,
      );

      provider.selectStore(storeWithFolding);
      provider.selectTurnaroundDays(2); // Balance default (1.15x multiplier)

      expect(storeWithFolding.hasFoldingFee, isTrue);
      expect(storeWithFolding.foldingPrice, 250.0);

      // Total folding care fee for 6 initial basket items (4 shirts + 2 t-shirts) = 6 * 250 = 1500
      expect(provider.storeFoldingTotal, 1500);

      // Base items subtotal + store folding total == itemSubtotal
      expect(provider.baseItemSubtotal + provider.storeFoldingTotal,
          provider.itemSubtotal);
      expect(provider.grandTotal,
          provider.itemSubtotal + provider.deliveryFee + provider.serviceFee);
    });

    testWidgets(
        '05_items_screen renders turnaround chips and store folding banner',
        (WidgetTester tester) async {
      final provider = SchedulePickupProvider();
      final store = const NearbyStore(
        id: '15',
        name: 'Sparkle Fresh Wash',
        area: 'Ikeja GRA',
        address: 'Isaac John St',
        rating: 4.7,
        distanceKm: 4.0,
        turnaroundDays: 2,
        turnaroundText: 'Ready in 2 days',
        shirtStartingPrice: 500,
        foldingPrice: 200.0,
      );

      provider.selectStore(store);

      await tester.pumpWidget(
        ChangeNotifierProvider<SchedulePickupProvider>.value(
          value: provider,
          child: const MaterialApp(
            home: ScheduleItemsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Turnaround speed chips are rendered
      expect(find.text('Turnaround Speed'), findsOneWidget);
      expect(find.textContaining('3d Economy'), findsOneWidget);
      expect(find.textContaining('2d Standard'), findsOneWidget);
      expect(find.textContaining('1d Next-day'), findsOneWidget);

      // Verify folding banner
      expect(find.textContaining('Store folding care: +₦200 per item'),
          findsOneWidget);
    });

    testWidgets(
        '06_checkout_screen displays turnaround speed and folding care breakdown',
        (WidgetTester tester) async {
      final provider = SchedulePickupProvider();
      final store = const NearbyStore(
        id: '20',
        name: 'Deluxe Laundry Studio',
        area: 'Maitama',
        address: 'Gana Street',
        rating: 4.9,
        distanceKm: 3.5,
        turnaroundDays: 2,
        turnaroundText: 'Ready in 2 days',
        shirtStartingPrice: 600,
        foldingPrice: 300.0,
      );

      provider.selectStore(store);

      await tester.pumpWidget(
        ChangeNotifierProvider<SchedulePickupProvider>.value(
          value: provider,
          child: const MaterialApp(
            home: ScheduleCheckoutScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify matched store speed pill
      expect(find.textContaining('Standard · 2d'), findsOneWidget);

      // Verify folding care row in calculation card
      expect(find.text('Store folding care'), findsOneWidget);
      expect(find.textContaining('₦300/item'), findsOneWidget);

      // Verify items subtotal, delivery fee, service fee, total
      expect(find.text('Item subtotal'), findsOneWidget);
      expect(find.text('Delivery fee'), findsOneWidget);
      expect(find.text('Service fee'), findsOneWidget);
      expect(find.text('Total'), findsOneWidget);
      expect(find.text('Secure payment by Paystack'), findsOneWidget);
    });

    testWidgets(
        '07_order_placed_screen provides Track order and View in Order History actions',
        (WidgetTester tester) async {
      final provider = SchedulePickupProvider();
      provider.setLastCreatedOrderForTest({
        'id': 3045,
        'orderNumber': 'FM-3045',
        'storeName': 'Say Wat Laundry Abuja',
        'pickupPin': '8421',
        'deliveryPin': '1932',
        'totalPrice': 7500,
        'pickupTime': 'Today, 3:00 – 4:00 PM',
      });

      await tester.pumpWidget(
        ChangeNotifierProvider<SchedulePickupProvider>.value(
          value: provider,
          child: MaterialApp(
            routes: {
              HistoryScreen.id: (_) =>
                  const Scaffold(body: Text('Customer Order History Screen')),
            },
            home: const ScheduleOrderPlacedScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // PIN and store message
      expect(find.text('8421'), findsOneWidget);
      expect(find.text('Order placed'), findsOneWidget);
      expect(
          find.textContaining('Say Wat Laundry Abuja has your order #FM-3045'),
          findsOneWidget);

      // Track order button
      expect(find.text('Track order'), findsOneWidget);

      // View in Order History button
      final historyBtn = find.text('View in Order History');
      expect(historyBtn, findsOneWidget);

      // Tap View in Order History and verify navigation
      await tester.tap(historyBtn);
      await tester.pumpAndSettle();

      expect(find.text('Customer Order History Screen'), findsOneWidget);
    });

    test('VendorStore model supports foldingPrice and hasFoldingFee', () {
      final store = VendorStore(
        id: '2',
        name: 'Say Wat Laundry Abuja',
        address: 'V2MJ+V53, Rivers',
        status: 'LIVE',
        rating: 5.0,
        itemsPricedCount: 4,
        totalItems: 4,
        hoursMonFri: '8:00 AM – 6:00 PM',
        hoursSat: '8:00 AM – 5:00 PM',
        hoursSun: 'Closed',
        foldingPrice: 250.0,
      );

      expect(store.foldingPrice, 250.0);
      expect(store.hasFoldingFee, isTrue);

      final freeStore = store.copyWith(foldingPrice: 0.0);
      expect(freeStore.foldingPrice, 0.0);
      expect(freeStore.hasFoldingFee, isFalse);
    });
  });
}
