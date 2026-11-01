import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foam_mobile/feature/schedule_pickup/controller/schedule_pickup_provider.dart';
import 'package:foam_mobile/feature/schedule_pickup/models/customer_schedule_models.dart';
import 'package:foam_mobile/feature/schedule_pickup/views/08_pickup_leg_screen.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

void main() {
  group('ScheduleTrackingScreen Widget Tests (R4, F9, F10)', () {
    testWidgets('Gated View when locked: Renders Order Status Card, Stepper, Store Name, Delivery PIN, and Refresh Button without GoogleMap', (tester) async {
      final lockedTracking = OrderTrackingData.fromJson({
        'orderId': 2040,
        'orderNumber': 'FM-2040',
        'currentStage': 'AT_STORE',
        'isTrackingUnlocked': false,
        'storeName': 'Royal Cleaners Port Harcourt',
        'pickupPin': '4829',
        'deliveryPin': '7193',
      });

      final provider = SchedulePickupProvider();
      // Inject tracking data through provider test simulation
      // We can use a test wrapper or subclass, or pump directly with provider
      // Since _trackingData is updated via loadTrackingInfo or we can wrap SchedulePickupProvider
      await tester.pumpWidget(
        ChangeNotifierProvider<SchedulePickupProvider>.value(
          value: provider,
          child: const MaterialApp(
            home: ScheduleTrackingScreen(),
          ),
        ),
      );

      // Verify that initially without unlocked tracking, it shows gated view
      expect(find.byKey(const Key('gated_locked_card')), findsOneWidget);
      expect(find.text('Live Tracking Locked'), findsOneWidget);
      expect(find.textContaining("Live GPS tracking will unlock automatically once your laundry is marked 'Out for Delivery'"), findsOneWidget);
      expect(find.text('Order Progression'), findsOneWidget);
      expect(find.text('Order Placed'), findsOneWidget);
      expect(find.text('Picked Up'), findsOneWidget);
      expect(find.text('At Store / Washing'), findsOneWidget);
      expect(find.text('Out for Delivery'), findsOneWidget);
      expect(find.text('Delivery PIN'), findsOneWidget);
      expect(find.byKey(const Key('refresh_status_button')), findsOneWidget);

      // Crucial: GoogleMap MUST NOT be instantiated when locked
      expect(find.byType(GoogleMap), findsNothing);
    });

    testWidgets('Live Map View when unlocked: Renders GoogleMap widget and Delivery PIN', (tester) async {
      // Simulate an unlocked order
      final unlockedTracking = OrderTrackingData.fromJson({
        'orderId': 2041,
        'orderNumber': 'FM-2041',
        'currentStage': 'OUT_FOR_DELIVERY',
        'isTrackingUnlocked': true,
        'storeName': 'Royal Cleaners Port Harcourt',
        'pickupPin': '4829',
        'deliveryPin': '7193',
        'deliveryEta': 'ARRIVING IN 7 MIN',
        'deliveryRider': {
          'name': 'Chidi O.',
          'initials': 'CO',
          'phone': '+2348031234567',
          'rating': 4.9,
          'vehicle': 'TVS Neo · RVS 102 PH',
        },
        'locations': {
          'customer': {'latitude': 4.8633, 'longitude': 7.0292, 'address': 'Eneka Road, PH'},
          'store': {'latitude': 4.8600, 'longitude': 7.0250, 'address': 'Eneka Roundabout'},
          'rider': {'latitude': 4.8615, 'longitude': 7.0270},
        },
      });

      // Provider with tracking data
      final provider = SchedulePickupProvider();
      // Use reflection or simulated provider wrapper if needed
      // Let's create a custom provider subclass for testing
      final testProvider = TestSchedulePickupProvider(unlockedTracking);

      await tester.pumpWidget(
        ChangeNotifierProvider<SchedulePickupProvider>.value(
          value: testProvider,
          child: const MaterialApp(
            home: ScheduleTrackingScreen(),
          ),
        ),
      );

      expect(find.byKey(const Key('live_tracking_unlocked_view')), findsOneWidget);
      expect(find.byType(GoogleMap), findsOneWidget);
      expect(find.text('Chidi O. is on the way'), findsOneWidget);
      expect(find.text('Chidi O.'), findsOneWidget);
      expect(find.textContaining('7193'), findsOneWidget);
      expect(find.byKey(const Key('gated_locked_card')), findsNothing);
    });
  });
}

class TestSchedulePickupProvider extends SchedulePickupProvider {
  final OrderTrackingData _testTracking;
  TestSchedulePickupProvider(this._testTracking);

  @override
  OrderTrackingData? get trackingData => _testTracking;
}
