import 'package:flutter_test/flutter_test.dart';
import 'package:foam_mobile/feature/schedule_pickup/controller/schedule_pickup_provider.dart';
import 'package:foam_mobile/feature/schedule_pickup/models/customer_schedule_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // =========================================================================
  // Category 1: Geolocation Coordinates & Boundary Stress
  // =========================================================================
  group('Category 1: Geolocation Coordinates & Boundary Stress', () {
    test('LocationCoordinate: Null fields and default coordinate fallbacks', () {
      final json = <String, dynamic>{
        'latitude': null,
        'longitude': null,
        'address': null,
      };
      final coord = LocationCoordinate.fromJson(json);
      expect(coord.latitude, 0.0);
      expect(coord.longitude, 0.0);
      expect(coord.address, isNull);

      final out = coord.toJson();
      expect(out['latitude'], 0.0);
      expect(out['longitude'], 0.0);
      expect(out.containsKey('address'), isFalse);
    });

    test('LocationCoordinate: Extreme boundary points (Poles, Equator, Dateline)', () {
      final northPole = LocationCoordinate.fromJson({'latitude': 90.0, 'longitude': 0.0});
      final southPole = LocationCoordinate.fromJson({'latitude': -90.0, 'longitude': 0.0});
      final eastDateline = LocationCoordinate.fromJson({'latitude': 0.0, 'longitude': 180.0});
      final westDateline = LocationCoordinate.fromJson({'latitude': 0.0, 'longitude': -180.0});
      final equatorPrime = LocationCoordinate.fromJson({'latitude': 0.0, 'longitude': 0.0});

      expect(northPole.latitude, 90.0);
      expect(northPole.longitude, 0.0);
      expect(southPole.latitude, -90.0);
      expect(southPole.longitude, 0.0);
      expect(eastDateline.latitude, 0.0);
      expect(eastDateline.longitude, 180.0);
      expect(westDateline.latitude, 0.0);
      expect(westDateline.longitude, -180.0);
      expect(equatorPrime.latitude, 0.0);
      expect(equatorPrime.longitude, 0.0);
    });

    test('LocationCoordinate: Southern & Western hemisphere negative coordinates', () {
      final rioCoord = LocationCoordinate.fromJson({
        'latitude': -22.9068,
        'longitude': -43.1729,
        'address': 'Rio de Janeiro, Brazil',
      });
      expect(rioCoord.latitude, closeTo(-22.9068, 0.0001));
      expect(rioCoord.longitude, closeTo(-43.1729, 0.0001));
      expect(rioCoord.address, 'Rio de Janeiro, Brazil');

      final serialized = rioCoord.toJson();
      expect(serialized['latitude'], -22.9068);
      expect(serialized['longitude'], -43.1729);
    });

    test('LocationCoordinate: High floating-point precision coordinates', () {
      final microCoord = LocationCoordinate.fromJson({
        'latitude': 4.863345129481234,
        'longitude': 7.029210948273651,
        'address': 'Sub-meter accurate pickup pin',
      });
      expect(microCoord.latitude, closeTo(4.863345129, 0.000000001));
      expect(microCoord.longitude, closeTo(7.029210948, 0.000000001));
    });

    test('LocationCoordinate: Coordinates with integers instead of doubles', () {
      final intCoord = LocationCoordinate.fromJson({
        'latitude': 5,
        'longitude': 7,
      });
      expect(intCoord.latitude, 5.0);
      expect(intCoord.longitude, 7.0);
    });

    test('Provider: Null coordinates preserve previous valid location', () {
      final provider = SchedulePickupProvider();
      provider.setPickupLocation(
        address: 'Initial Safe Address',
        lat: 4.8156,
        lng: 7.0498,
      );
      expect(provider.pickupLat, 4.8156);
      expect(provider.pickupLng, 7.0498);

      // Pass null coordinates with new address
      provider.setPickupLocation(address: 'Updated Address Text Only', lat: null, lng: null);
      expect(provider.pickupAddress, 'Updated Address Text Only');
      expect(provider.pickupLat, 4.8156);
      expect(provider.pickupLng, 7.0498);

      // Pass only one coordinate as null
      provider.setPickupLocation(address: 'Half-Null Location', lat: 9.0765, lng: null);
      expect(provider.pickupAddress, 'Half-Null Location');
      expect(provider.pickupLat, 4.8156); // Must not update with partial lat
      expect(provider.pickupLng, 7.0498);
    });

    test('Provider: Extreme coordinates handling in provider state', () {
      final provider = SchedulePickupProvider();

      provider.setPickupLocation(address: 'North Pole HQ', lat: 90.0, lng: 0.0);
      expect(provider.pickupLat, 90.0);
      expect(provider.pickupLng, 0.0);

      provider.setPickupLocation(address: 'Dateline Edge', lat: 0.0, lng: 180.0);
      expect(provider.pickupLat, 0.0);
      expect(provider.pickupLng, 180.0);

      provider.setPickupLocation(address: 'Zero Island', lat: 0.0, lng: 0.0);
      expect(provider.pickupLat, 0.0);
      expect(provider.pickupLng, 0.0);

      provider.setPickupLocation(address: 'Negative Coords', lat: -4.8633, lng: -7.0292);
      expect(provider.pickupLat, -4.8633);
      expect(provider.pickupLng, -7.0292);
    });
  });

  // =========================================================================
  // Category 2: Data Corruption, Missing Fields & Unexpected Types
  // =========================================================================
  group('Category 2: Data Corruption, Missing Fields & Unexpected Types in Models', () {
    test('All 10 models safely instantiate from completely empty JSON maps', () {
      expect(() => LocationCoordinate.fromJson({}), returnsNormally);
      expect(() => MatchedTierStore.fromJson({}), returnsNormally);
      expect(() => TierMetadata.fromJson({}), returnsNormally);
      expect(() => ScheduleTier.fromJson({}), returnsNormally);
      expect(() => TurnaroundOption.fromJson({}), returnsNormally);
      expect(() => NearbyStore.fromJson({}), returnsNormally);
      expect(() => ScheduleItem.fromJson({}), returnsNormally);
      expect(() => RiderInfo.fromJson({}), returnsNormally);
      expect(() => TimelineStep.fromJson({}), returnsNormally);
      expect(() => OrderTrackingData.fromJson({}), returnsNormally);

      final loc = LocationCoordinate.fromJson({});
      expect(loc.latitude, 0.0);
      expect(loc.longitude, 0.0);

      final store = MatchedTierStore.fromJson({});
      expect(store.id, 0);
      expect(store.name, 'Nearby Store');
      expect(store.rating, 4.5);

      final meta = TierMetadata.fromJson({});
      expect(meta.storeCount, 9);
      expect(meta.radiusKm, 5.0);
      expect(meta.isFallback, isFalse);

      final tier = ScheduleTier.fromJson({});
      expect(tier.id, 'BALANCED');
      expect(tier.startingPrice, 500);
      expect(tier.matchedStore, isNull);

      final opt = TurnaroundOption.fromJson({});
      expect(opt.days, 2);
      expect(opt.name, 'Standard');
      expect(opt.priceMultiplier, 1.0);
      expect(opt.shirtStartingPrice, 500);

      final nearby = NearbyStore.fromJson({});
      expect(nearby.id, 0);
      expect(nearby.turnaroundOptions, isEmpty);
      expect(nearby.effectiveTurnaroundOptions.length, 3);

      final item = ScheduleItem.fromJson({});
      expect(item.id, 0);
      expect(item.name, 'Item');
      expect(item.price, 0);
      expect(item.quantity, 0);

      final rider = RiderInfo.fromJson({});
      expect(rider.name, 'Rider');
      expect(rider.initials, 'R');
      expect(rider.rating, 5.0);

      final step = TimelineStep.fromJson({});
      expect(step.section, '');
      expect(step.title, '');
      expect(step.isCompleted, isFalse);

      final tracking = OrderTrackingData.fromJson({});
      expect(tracking.orderId, 0);
      expect(tracking.locations, isEmpty);
      expect(tracking.timeline, isEmpty);
      expect(tracking.customerLocation, isNull);
      expect(tracking.storeLocation, isNull);
      expect(tracking.riderLocation, isNull);
    });

    test('OrderTrackingData: Malformed and partial locations map', () {
      final tracking = OrderTrackingData.fromJson({
        'orderId': 100,
        'orderNumber': 'FM-100',
        'currentStage': 'AT_STORE',
        'locations': <String, dynamic>{
          'customer': <String, dynamic>{'latitude': 4.86, 'longitude': 7.02},
          'store': null, // null value in map
          'rider': <String, dynamic>{'latitude': 0.0, 'longitude': 0.0},
          'unrecognized_actor': <String, dynamic>{'latitude': 1.0, 'longitude': 2.0},
          'corrupted_field': 'not_a_map',
        },
      });

      expect(tracking.customerLocation, isNotNull);
      expect(tracking.customerLocation!.latitude, 4.86);
      expect(tracking.storeLocation, isNull);
      expect(tracking.riderLocation, isNotNull);
      expect(tracking.riderLocation!.latitude, 0.0);
      expect(tracking.locations.containsKey('unrecognized_actor'), isTrue);
      expect(tracking.locations.containsKey('corrupted_field'), isFalse);
    });

    test('OrderTrackingData: Corrupted timeline list containing nulls and non-map elements', () {
      final tracking = OrderTrackingData.fromJson({
        'orderId': 200,
        'timeline': [
          null,
          'not_a_map',
          42,
          <String, dynamic>{'section': 'PICKUP', 'title': 'Valid Step', 'isCompleted': true},
          <String, dynamic>{},
        ],
      });

      // Valid Map<String, dynamic> items should be safely parsed into TimelineStep
      expect(tracking.timeline.length, 2);
      expect(tracking.timeline[0].title, 'Valid Step');
      expect(tracking.timeline[0].isCompleted, isTrue);
      expect(tracking.timeline[1].title, '');
    });

    test('NearbyStore: turnaroundOptions with nulls and non-map elements', () {
      final store = NearbyStore.fromJson({
        'id': 15,
        'name': 'Resilient Store',
        'turnaroundOptions': [
          null,
          123,
          'unexpected_string',
          {'days': 1, 'name': 'Express', 'priceMultiplier': 1.5, 'shirtStartingPrice': 750},
        ],
      });

      expect(store.turnaroundOptions.length, 1);
      expect(store.turnaroundOptions.first.days, 1);
      expect(store.turnaroundOptions.first.name, 'Express');
      expect(store.effectiveTurnaroundOptions.length, 1);
    });

    test('NearbyStore: fallback effectiveTurnaroundOptions when turnaroundOptions is empty', () {
      final store = NearbyStore.fromJson({
        'id': 20,
        'name': 'No Options Store',
        'shirtStartingPrice': 1000,
        'turnaroundOptions': [],
      });

      expect(store.turnaroundOptions, isEmpty);
      final options = store.effectiveTurnaroundOptions;
      expect(options.length, 3);

      final nextDay = options.firstWhere((o) => o.days == 1);
      expect(nextDay.name, 'Next-day');
      expect(nextDay.priceMultiplier, 1.6);
      expect(nextDay.shirtStartingPrice, 1600);

      final standard = options.firstWhere((o) => o.days == 2);
      expect(standard.name, 'Standard');
      expect(standard.priceMultiplier, 1.0);
      expect(standard.shirtStartingPrice, 1000);

      final economy = options.firstWhere((o) => o.days == 3);
      expect(economy.name, 'Economy');
      expect(economy.priceMultiplier, 0.75);
      expect(economy.shirtStartingPrice, 750);
    });

    test('ScheduleTier: matchedStore malformed types', () {
      final tierWithStringStore = ScheduleTier.fromJson({
        'id': 'PREMIUM',
        'matchedStore': 'not_a_map_should_be_null',
      });
      expect(tierWithStringStore.matchedStore, isNull);

      final tierWithIntStore = ScheduleTier.fromJson({
        'id': 'PREMIUM',
        'matchedStore': 999,
      });
      expect(tierWithIntStore.matchedStore, isNull);

      final tierWithValidStore = ScheduleTier.fromJson({
        'id': 'PREMIUM',
        'matchedStore': {
          'id': 5,
          'name': 'Lekki Whites',
          'rating': 4.9,
          'turnaroundDays': 1,
          'distanceKm': 3.2,
        },
      });
      expect(tierWithValidStore.matchedStore, isNotNull);
      expect(tierWithValidStore.matchedStore!.name, 'Lekki Whites');
    });

    test('RiderInfo: Standard initials derivation (single name, multi-word, extra spaces)', () {
      expect(RiderInfo.fromJson({'name': ''}).initials, '');
      expect(RiderInfo.fromJson({'name': '   '}).initials, '');
      expect(RiderInfo.fromJson({'name': 'A'}).initials, 'A');
      expect(RiderInfo.fromJson({'name': '  John   Doe  '}).initials, 'JD');
      expect(RiderInfo.fromJson({'name': 'First Middle Last Extra'}).initials, 'FM');
    });

    test('RiderInfo: Unicode surrogate pair split observation on emoji / non-BMP characters', () {
      // Dart strings are UTF-16 code units. Emojis like 🌟 (U+1F31F) are surrogate pairs.
      // String[0] truncates the surrogate pair to high surrogate \uD83C.
      final rider = RiderInfo.fromJson({'name': '🌟 Star Rider'});
      // The initials will receive the high surrogate '\uD83C' + 'S'
      expect(rider.initials.length, 2);
      expect(rider.initials.codeUnitAt(0), 0xD83C); // Demonstrates UTF-16 code unit truncation
      expect(rider.initials[1], 'S');
    });

    test('Adversarial: Massive strings and special characters in store names', () {
      final massiveName = 'A' * 2000;
      final store = NearbyStore.fromJson({
        'id': 999,
        'name': massiveName,
        'address': 'Special ₦ \$ € & < > " \' chars',
      });
      expect(store.name.length, 2000);
      expect(store.address, contains('₦'));
      expect(store.toJson()['name'].length, 2000);
    });

    test('Adversarial: Integer vs Double flexibility in numeric fields', () {
      // API may return ints for double fields (e.g. rating: 5, radiusKm: 10)
      final store = NearbyStore.fromJson({
        'rating': 5,
        'distanceKm': 3,
        'latitude': 4,
        'longitude': 7,
      });
      expect(store.rating, 5.0);
      expect(store.distanceKm, 3.0);
      expect(store.latitude, 4.0);
      expect(store.longitude, 7.0);

      // API may return doubles for int fields (startingPrice: 500.0)
      final tier = ScheduleTier.fromJson({
        'startingPrice': 500.0,
        'turnaroundDays': 3.0,
      });
      expect(tier.startingPrice, 500);
      expect(tier.turnaroundDays, 3);
    });

    test('Adversarial Type Cast Vulnerability: String instead of number in LocationCoordinate', () {
      // Testing whether passing String "4.8633" instead of num throws TypeError
      expect(
        () => LocationCoordinate.fromJson({'latitude': '4.8633', 'longitude': '7.0292'}),
        throwsA(isA<TypeError>()),
        reason: 'LocationCoordinate relies on (json["latitude"] as num?), which throws TypeError on String',
      );
    });

    test('Adversarial Type Cast Vulnerability: Double instead of int in TierMetadata storeCount', () {
      // (json['storeCount'] as int) throws TypeError if a backend returns 9.0 (double)
      expect(
        () => TierMetadata.fromJson({'storeCount': 9.0}),
        throwsA(isA<TypeError>()),
        reason: 'TierMetadata directly casts storeCount to int, failing if backend returns double 9.0',
      );
    });

    test('Adversarial Type Cast Vulnerability: Integer or String in TierMetadata isFallback', () {
      // (json['isFallback'] as bool) throws TypeError if backend returns 1 or "true"
      expect(
        () => TierMetadata.fromJson({'isFallback': 1}),
        throwsA(isA<TypeError>()),
        reason: 'TierMetadata directly casts isFallback to bool, failing if backend returns 1 (truthy int)',
      );
    });
  });

  // =========================================================================
  // Category 3: Dynamic Tier Metadata & Subtitle Formatting Stress
  // =========================================================================
  group('Category 3: Dynamic Tier Metadata & Subtitle Formatting Stress', () {
    test('TierMetadata: storeCount = 0 and large radius handling', () {
      final meta = TierMetadata.fromJson({
        'storeCount': 0,
        'radiusKm': 15000.0,
        'isFallback': false,
      });

      expect(meta.storeCount, 0);
      expect(meta.radiusKm, 15000.0);
      expect(meta.isFallback, isFalse);
      expect(
        meta.computedSubtitle,
        'Based on 0 live stores within 15000 km. Prices are for a shirt, washed and folded.',
      );
    });

    test('TierMetadata: Explicit subtitleText overrides all dynamic formatting', () {
      const explicitText = 'Exclusive partner tier pricing for VIP corporate customers';
      final meta = TierMetadata.fromJson({
        'storeCount': 0,
        'radiusKm': 0.0,
        'isFallback': true,
        'nearestStoreName': 'Some Store',
        'nearestDistanceKm': 50.0,
        'subtitleText': explicitText,
      });

      expect(meta.computedSubtitle, explicitText);
    });

    test('TierMetadata: Whitespace-only subtitleText is ignored in favor of dynamic fallback', () {
      final meta = TierMetadata.fromJson({
        'storeCount': 7,
        'radiusKm': 10.0,
        'isFallback': false,
        'subtitleText': '    \n  \t  ',
      });

      expect(
        meta.computedSubtitle,
        'Based on 7 live stores within 10 km. Prices are for a shirt, washed and folded.',
      );
    });

    test('TierMetadata: Fallback mode with complete nearest store details', () {
      final meta = TierMetadata.fromJson({
        'storeCount': 1,
        'radiusKm': 30.0,
        'isFallback': true,
        'nearestStoreName': 'Royal Cleaners Eneka Hub',
        'nearestDistanceKm': 18.73,
      });

      expect(meta.isFallback, isTrue);
      expect(
        meta.computedSubtitle,
        'Based on nearest store Royal Cleaners Eneka Hub (18.7 km away). Prices are for a shirt, washed and folded.',
      );
    });

    test('TierMetadata: Degraded fallback (isFallback true but nearest store name or distance is null)', () {
      final missingName = TierMetadata.fromJson({
        'storeCount': 3,
        'radiusKm': 25.0,
        'isFallback': true,
        'nearestStoreName': null,
        'nearestDistanceKm': 22.0,
      });
      // Should cleanly fall back to live stores reach string
      expect(
        missingName.computedSubtitle,
        'Based on 3 live stores within 25 km. Prices are for a shirt, washed and folded.',
      );

      final missingDistance = TierMetadata.fromJson({
        'storeCount': 2,
        'radiusKm': 20.0,
        'isFallback': true,
        'nearestStoreName': 'Clean Express',
        'nearestDistanceKm': null,
      });
      expect(
        missingDistance.computedSubtitle,
        'Based on 2 live stores within 20 km. Prices are for a shirt, washed and folded.',
      );
    });

    test('TierMetadata: Alternate legacy property keys (liveStoreCount & isOutsideGeoReach)', () {
      final meta = TierMetadata.fromJson({
        'liveStoreCount': 14,
        'radiusKm': 8,
        'isOutsideGeoReach': true,
        'nearestStoreName': 'Abuja Central Cleaners',
        'nearestDistanceKm': 6.2,
      });

      expect(meta.storeCount, 14);
      expect(meta.radiusKm, 8.0);
      expect(meta.isFallback, isTrue);
      expect(
        meta.computedSubtitle,
        'Based on nearest store Abuja Central Cleaners (6.2 km away). Prices are for a shirt, washed and folded.',
      );
    });
  });

  // =========================================================================
  // Category 4: SchedulePickupProvider Concurrency, Latency & State Invariants
  // =========================================================================
  group('Category 4: SchedulePickupProvider Concurrency & State Invariants', () {
    late SchedulePickupProvider provider;

    setUp(() {
      provider = SchedulePickupProvider();
    });

    test('Rapid sequential setPickupLocation calls update coordinates synchronously', () {
      final locations = [
        {'addr': 'Port Harcourt Town', 'lat': 4.8156, 'lng': 7.0498},
        {'addr': 'Eneka Roundabout', 'lat': 4.8633, 'lng': 7.0292},
        {'addr': 'Victoria Island, Lagos', 'lat': 6.4281, 'lng': 3.4219},
        {'addr': 'Maitama, Abuja', 'lat': 9.0882, 'lng': 7.4934},
      ];

      for (final loc in locations) {
        provider.setPickupLocation(
          address: loc['addr'] as String,
          lat: loc['lat'] as double,
          lng: loc['lng'] as double,
        );
      }

      expect(provider.pickupAddress, 'Maitama, Abuja');
      expect(provider.pickupLat, 9.0882);
      expect(provider.pickupLng, 7.4934);
    });

    test('Network latency simulation: Places selection interleaving with GPS auto-detect', () async {
      // Simulate GPS auto-detect in flight
      expect(provider.isDetectingLocation, isFalse);

      int listenerNotifications = 0;
      provider.addListener(() {
        listenerNotifications++;
      });

      // Emulate autoDetectLocation starting
      // When LocationService.autoDetectLocation runs, it catches platform missing channel in test
      // and returns false without throwing unhandled exception.
      final autoDetectFuture = provider.autoDetectLocation();

      // Interleaved: While autoDetect is resolving, user selects a place via Google Places
      provider.setPickupLocation(
        address: 'Google Places: 14 Admiralty Way, Lekki',
        lat: 6.4474,
        lng: 3.4723,
      );

      expect(provider.pickupAddress, 'Google Places: 14 Admiralty Way, Lekki');
      expect(provider.pickupLat, 6.4474);
      expect(provider.pickupLng, 3.4723);

      final result = await autoDetectFuture;
      // In headless unit test environment without GPS sensor, autoDetectLocation returns false safely
      expect(result, isFalse);
      expect(provider.isDetectingLocation, isFalse);
      expect(listenerNotifications, greaterThan(0));

      // User's manual selection remains intact
      expect(provider.pickupAddress, 'Google Places: 14 Admiralty Way, Lekki');
    });

    test('Turnaround speed multiplier and pricing across schedule methods', () {
      // Under letFoamChoose (default), turnaroundMultiplier is always 1.0
      expect(provider.selectedMethod, ScheduleMethod.letFoamChoose);
      expect(provider.turnaroundMultiplier, 1.0);

      final testShirt = ScheduleItem(id: 1, name: 'Shirt', price: 500, quantity: 1);
      expect(provider.getItemPrice(testShirt), 500);

      // Switch to pickStore
      provider.selectMethod(ScheduleMethod.pickStore);
      expect(provider.selectedMethod, ScheduleMethod.pickStore);

      // Select standard (2 days -> 1.0x)
      provider.selectTurnaroundDays(2);
      expect(provider.selectedTurnaroundDays, 2);
      expect(provider.turnaroundMultiplier, 1.0);
      expect(provider.getItemPrice(testShirt), 500);

      // Select next-day (1 day -> 1.6x)
      provider.selectTurnaroundDays(1);
      expect(provider.selectedTurnaroundDays, 1);
      expect(provider.turnaroundMultiplier, 1.6);
      expect(provider.getItemPrice(testShirt), 800); // 500 * 1.6 = 800

      // Select economy (3 days -> 0.75x)
      provider.selectTurnaroundDays(3);
      expect(provider.selectedTurnaroundDays, 3);
      expect(provider.turnaroundMultiplier, 0.75);
      expect(provider.getItemPrice(testShirt), 375); // 500 * 0.75 = 375

      // Select invalid day (e.g. 99 days) - safely defaults to first available option
      provider.selectTurnaroundDays(99);
      expect(provider.selectedTurnaroundOption, isNotNull);
      expect(() => provider.turnaroundMultiplier, returnsNormally);
    });

    test('Basket totals and grand totals dynamically adapt to turnaround multiplier', () {
      provider.selectMethod(ScheduleMethod.pickStore);

      // Baseline items: 4 shirts (500) + 2 t-shirts (400) = 2800 at 1.0x
      provider.selectTurnaroundDays(2); // 1.0x
      expect(provider.itemSubtotal, 2800);
      expect(provider.grandTotal, 2800 + 1500 + 300); // 4600

      // Express 1-day: 1.6x multiplier
      provider.selectTurnaroundDays(1); // 1.6x
      // Shirt: (500 * 1.6) = 800 * 4 = 3200
      // T-shirt: (400 * 1.6) = 640 * 2 = 1280
      // Subtotal = 3200 + 1280 = 4480
      expect(provider.itemSubtotal, 4480);
      expect(provider.grandTotal, 4480 + 1500 + 300); // 6280

      // Economy 3-day: 0.75x multiplier
      provider.selectTurnaroundDays(3); // 0.75x
      // Shirt: (500 * 0.75) = 375 * 4 = 1500
      // T-shirt: (400 * 0.75) = 300 * 2 = 600
      // Subtotal = 1500 + 600 = 2100
      expect(provider.itemSubtotal, 2100);
      expect(provider.grandTotal, 2100 + 1500 + 300); // 3900
    });

    test('Basket zero quantity edge case: basket count and subtotal zero when all items decremented', () {
      // Decrement all default quantities to 0
      for (int i = 0; i < 4; i++) {
        provider.decrementItem(1); // Shirt
      }
      for (int i = 0; i < 2; i++) {
        provider.decrementItem(2); // T-shirt
      }

      expect(provider.totalBasketCount, 0);
      expect(provider.itemSubtotal, 0);
      expect(provider.grandTotal, 1500 + 300); // Only delivery and service fee
    });

    test('Order processing fallback on network failure maintains valid state', () async {
      // processPaystackOrder should not crash when network fails
      final success = await provider.processPaystackOrder(paystackRef: 'TEST-REF-999');
      expect(success, isTrue);
      expect(provider.lastCreatedOrder, isNotNull);
      expect(provider.lastCreatedOrder!['orderNumber'], isNotEmpty);
      expect(provider.lastCreatedOrder!['pickupPin'], isNotEmpty);
      expect(provider.lastCreatedOrder!['deliveryPin'], isNotEmpty);
      expect(provider.isLoading, isFalse);
    });

    test('Review submission handles extreme ratings (1 to 5) without exception', () async {
      provider.setRatingStore(1);
      provider.setRatingRider(1);
      expect(provider.ratingStore, 1);
      expect(provider.ratingRider, 1);

      final minRes = await provider.submitReview(999, comments: 'Extremely poor service');
      expect(minRes, isTrue);

      provider.setRatingStore(5);
      provider.setRatingRider(5);
      expect(provider.ratingStore, 5);
      expect(provider.ratingRider, 5);

      final maxRes = await provider.submitReview(999, comments: 'Flawless 5-star service');
      expect(maxRes, isTrue);
    });
  });
}
