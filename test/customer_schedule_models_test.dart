import 'package:flutter_test/flutter_test.dart';
import 'package:foam_mobile/feature/schedule_pickup/models/customer_schedule_models.dart';

void main() {
  group('Customer Schedule Models - Tier 1: Core Serialization & Deserialization', () {
    test('LocationCoordinate fromJson and toJson round-trip', () {
      final json = {
        'latitude': 4.8633,
        'longitude': 7.0292,
        'address': 'Eneka Road, Port Harcourt',
      };

      final coord = LocationCoordinate.fromJson(json);
      expect(coord.latitude, 4.8633);
      expect(coord.longitude, 7.0292);
      expect(coord.address, 'Eneka Road, Port Harcourt');

      final serialized = coord.toJson();
      expect(serialized['latitude'], 4.8633);
      expect(serialized['longitude'], 7.0292);
      expect(serialized['address'], 'Eneka Road, Port Harcourt');
    });

    test('LocationCoordinate defaults on empty json', () {
      final coord = LocationCoordinate.fromJson({});
      expect(coord.latitude, 0.0);
      expect(coord.longitude, 0.0);
      expect(coord.address, isNull);
      expect(coord.toJson().containsKey('address'), isFalse);
    });

    test('MatchedTierStore fromJson and toJson round-trip', () {
      final json = {
        'id': 2,
        'name': 'Spotless Cleaners Eneka',
        'rating': 4.7,
        'turnaroundDays': 2,
        'distanceKm': 1.8,
      };

      final store = MatchedTierStore.fromJson(json);
      expect(store.id, 2);
      expect(store.name, 'Spotless Cleaners Eneka');
      expect(store.rating, 4.7);
      expect(store.turnaroundDays, 2);
      expect(store.distanceKm, 1.8);

      final out = store.toJson();
      expect(out['id'], 2);
      expect(out['name'], 'Spotless Cleaners Eneka');
      expect(out['rating'], 4.7);
    });

    test('TierMetadata fromJson with standard counts and computed subtitle', () {
      final json = {
        'liveStoreCount': 9,
        'radiusKm': 5,
        'isOutsideGeoReach': false,
      };

      final meta = TierMetadata.fromJson(json);
      expect(meta.storeCount, 9);
      expect(meta.radiusKm, 5.0);
      expect(meta.isFallback, isFalse);
      expect(
        meta.computedSubtitle,
        'Based on 9 live stores within 5 km. Prices are for a shirt, washed and folded.',
      );
    });

    test('TierMetadata dynamic custom subtitle precedence', () {
      const customText = 'Custom dynamic subtitle based on live backend data';
      final meta = TierMetadata(
        storeCount: 12,
        radiusKm: 10.0,
        subtitleText: customText,
      );
      expect(meta.computedSubtitle, customText);
    });

    test('TierMetadata geo-fallback subtitle formatting', () {
      final meta = TierMetadata.fromJson({
        'storeCount': 1,
        'radiusKm': 25.0,
        'isFallback': true,
        'nearestStoreName': 'Port Harcourt Main Branch',
        'nearestDistanceKm': 14.2,
      });

      expect(meta.isFallback, isTrue);
      expect(
        meta.computedSubtitle,
        'Based on nearest store Port Harcourt Main Branch (14.2 km away). Prices are for a shirt, washed and folded.',
      );
    });

    test('ScheduleTier fromJson and toJson with matched store and badge', () {
      final json = {
        'id': 'BALANCED',
        'title': 'Balanced',
        'startingPrice': 500,
        'turnaroundDays': 2,
        'turnaroundText': 'Ready in 2 days · ★ 4.6 average',
        'isMostPicked': true,
        'badge': 'MOST PICKED',
        'matchedStore': {
          'id': 1,
          'name': 'Royal Cleaners',
          'rating': 4.6,
          'turnaroundDays': 2,
          'distanceKm': 1.4,
        },
      };

      final tier = ScheduleTier.fromJson(json);
      expect(tier.id, 'BALANCED');
      expect(tier.title, 'Balanced');
      expect(tier.startingPrice, 500);
      expect(tier.turnaroundDays, 2);
      expect(tier.isMostPicked, isTrue);
      expect(tier.badge, 'MOST PICKED');
      expect(tier.matchedStore, isNotNull);
      expect(tier.matchedStore!.name, 'Royal Cleaners');

      final serialized = tier.toJson();
      expect(serialized['id'], 'BALANCED');
      expect(serialized['badge'], 'MOST PICKED');
      expect(serialized['matchedStore']['name'], 'Royal Cleaners');
    });

    test('NearbyStore fromJson and toJson with coordinates and operating hours', () {
      final json = {
        'id': 10,
        'name': 'Eneka Wash & Dry',
        'area': 'Eneka, Port Harcourt',
        'address': 'Plot 4, Eneka Roundabout',
        'rating': 4.8,
        'reviewCount': 95,
        'distanceKm': 2.3,
        'turnaroundDays': 1,
        'turnaroundText': 'Next-day',
        'shirtStartingPrice': 600,
        'operatingHours': '7am–8pm',
        'latitude': 4.8630,
        'longitude': 7.0280,
      };

      final store = NearbyStore.fromJson(json);
      expect(store.id, 10);
      expect(store.name, 'Eneka Wash & Dry');
      expect(store.area, 'Eneka, Port Harcourt');
      expect(store.rating, 4.8);
      expect(store.reviewCount, 95);
      expect(store.distanceKm, 2.3);
      expect(store.turnaroundDays, 1);
      expect(store.shirtStartingPrice, 600);
      expect(store.latitude, 4.8630);
      expect(store.longitude, 7.0280);

      final out = store.toJson();
      expect(out['shirtStartingPrice'], 600);
      expect(out['latitude'], 4.8630);
    });

    test('ScheduleItem fromJson, toJson, and quantity mutations', () {
      final json = {
        'id': 1,
        'name': 'Shirt',
        'price': 500,
        'quantity': 3,
        'category': 'Laundry',
        'foldType': 'Folding',
      };

      final item = ScheduleItem.fromJson(json);
      expect(item.id, 1);
      expect(item.name, 'Shirt');
      expect(item.price, 500);
      expect(item.quantity, 3);
      expect(item.category, 'Laundry');
      expect(item.foldType, 'Folding');

      item.quantity += 2;
      expect(item.quantity, 5);

      final serialized = item.toJson();
      expect(serialized['quantity'], 5);
      expect(serialized['price'], 500);
    });

    test('RiderInfo fromJson, automatic initials derivation, and serialization', () {
      final json = {
        'name': 'Chukwudi Okafor',
        'phone': '+2348031234567',
        'rating': 4.9,
        'vehicle': 'TVS HLX · PHC 921 AB',
      };

      final rider = RiderInfo.fromJson(json);
      expect(rider.name, 'Chukwudi Okafor');
      expect(rider.initials, 'CO');
      expect(rider.phone, '+2348031234567');
      expect(rider.rating, 4.9);
      expect(rider.vehicle, 'TVS HLX · PHC 921 AB');

      final out = rider.toJson();
      expect(out['initials'], 'CO');
      expect(out['name'], 'Chukwudi Okafor');
    });

    test('TimelineStep fromJson and toJson state mapping', () {
      final json = {
        'section': 'DELIVERY',
        'title': 'Out for delivery',
        'time': '3:45 PM',
        'isCompleted': false,
        'isActive': true,
        'isPending': false,
      };

      final step = TimelineStep.fromJson(json);
      expect(step.section, 'DELIVERY');
      expect(step.title, 'Out for delivery');
      expect(step.time, '3:45 PM');
      expect(step.isCompleted, isFalse);
      expect(step.isActive, isTrue);

      final serialized = step.toJson();
      expect(serialized['isActive'], isTrue);
      expect(serialized['section'], 'DELIVERY');
    });

    test('OrderTrackingData fromJson, nested location getters, and timeline', () {
      final json = {
        'orderId': 42,
        'orderNumber': 'FOAM-2042',
        'currentStage': 'OUT_FOR_DELIVERY',
        'isTrackingUnlocked': true,
        'storeName': 'Eneka Express Cleaners',
        'pickupPin': '4912',
        'deliveryPin': '7831',
        'pickupEta': 'ARRIVED',
        'deliveryEta': '12 MIN',
        'locations': {
          'customer': {
            'latitude': 4.8633,
            'longitude': 7.0292,
            'address': 'Eneka Road, PH',
          },
          'store': {
            'latitude': 4.8600,
            'longitude': 7.0250,
            'address': 'Eneka Roundabout',
          },
          'rider': {
            'latitude': 4.8615,
            'longitude': 7.0270,
          },
        },
        'timeline': [
          {
            'section': 'PICKUP',
            'title': 'Order Picked Up',
            'time': '10:00 AM',
            'isCompleted': true,
          },
          {
            'section': 'DELIVERY',
            'title': 'Out for delivery',
            'time': '1:30 PM',
            'isCompleted': false,
            'isActive': true,
          },
        ],
      };

      final tracking = OrderTrackingData.fromJson(json);
      expect(tracking.orderId, 42);
      expect(tracking.orderNumber, 'FOAM-2042');
      expect(tracking.currentStage, 'OUT_FOR_DELIVERY');
      expect(tracking.isTrackingUnlocked, isTrue);
      expect(tracking.storeName, 'Eneka Express Cleaners');
      expect(tracking.pickupPin, '4912');
      expect(tracking.deliveryPin, '7831');
      expect(tracking.customerLocation, isNotNull);
      expect(tracking.customerLocation!.latitude, 4.8633);
      expect(tracking.storeLocation!.longitude, 7.0250);
      expect(tracking.riderLocation!.latitude, 4.8615);
      expect(tracking.timeline.length, 2);
      expect(tracking.timeline[1].isActive, isTrue);

      final out = tracking.toJson();
      expect(out['isTrackingUnlocked'], isTrue);
      expect(out['locations']['customer']['latitude'], 4.8633);
      expect(out['timeline'].length, 2);
    });
  });

  group('Customer Schedule Models - Tier 2: Boundary, Extreme & Adversarial Cases', () {
    test('Boundary: Extreme geographical coordinates (equator, poles, international dateline)', () {
      final northPole = LocationCoordinate.fromJson({'latitude': 90.0, 'longitude': 0.0});
      final southPole = LocationCoordinate.fromJson({'latitude': -90.0, 'longitude': 0.0});
      final dateline = LocationCoordinate.fromJson({'latitude': 0.0, 'longitude': 180.0});
      final zeroZero = LocationCoordinate.fromJson({'latitude': 0.0, 'longitude': 0.0});

      expect(northPole.latitude, 90.0);
      expect(southPole.latitude, -90.0);
      expect(dateline.longitude, 180.0);
      expect(zeroZero.latitude, 0.0);
      expect(zeroZero.longitude, 0.0);
    });

    test('Boundary: High precision coordinates for accurate rider dispatch', () {
      final precise = LocationCoordinate.fromJson({
        'latitude': 4.863345129481,
        'longitude': 7.029210948273,
      });
      expect(precise.latitude, closeTo(4.863345, 0.00001));
      expect(precise.longitude, closeTo(7.029210, 0.00001));
    });

    test('Boundary: ScheduleItem with zero and high quantity/prices', () {
      final zeroItem = ScheduleItem.fromJson({'id': 100, 'name': 'Handkerchief', 'price': 0, 'quantity': 0});
      expect(zeroItem.price, 0);
      expect(zeroItem.quantity, 0);

      final luxuryItem = ScheduleItem.fromJson({
        'id': 101,
        'name': 'Wedding Gown Full Restoration',
        'price': 250000,
        'quantity': 10,
      });
      expect(luxuryItem.price, 250000);
      expect(luxuryItem.quantity, 10);
    });

    test('Boundary: NearbyStore with 0.0 distance and 5.0 rating', () {
      final store = NearbyStore.fromJson({
        'id': 99,
        'name': 'Zero Distance Laundry',
        'area': 'Lagos Island',
        'address': 'Under same roof',
        'rating': 5.0,
        'distanceKm': 0.0,
        'turnaroundDays': 0,
        'turnaroundText': 'Same-hour express',
        'shirtStartingPrice': 1000,
      });

      expect(store.distanceKm, 0.0);
      expect(store.rating, 5.0);
      expect(store.turnaroundDays, 0);
    });

    test('Adversarial: Null and malformed fields gracefully handled without crash', () {
      final emptyTier = ScheduleTier.fromJson({});
      expect(emptyTier.id, 'BALANCED');
      expect(emptyTier.title, 'Balanced');
      expect(emptyTier.startingPrice, 500);
      expect(emptyTier.isMostPicked, isFalse);
      expect(emptyTier.matchedStore, isNull);

      final emptyStore = NearbyStore.fromJson({});
      expect(emptyStore.id, 0);
      expect(emptyStore.name, 'Laundry Store');
      expect(emptyStore.rating, 4.5);
      expect(emptyStore.distanceKm, 0.0);

      final emptyTracking = OrderTrackingData.fromJson({});
      expect(emptyTracking.orderId, 0);
      expect(emptyTracking.isTrackingUnlocked, isFalse);
      expect(emptyTracking.customerLocation, isNull);
      expect(emptyTracking.timeline, isEmpty);
    });

    test('Adversarial: Rider single word name initials derivation', () {
      final singleNameRider = RiderInfo.fromJson({'name': 'Emeka'});
      expect(singleNameRider.initials, 'E');

      final emptyNameRider = RiderInfo.fromJson({'name': ''});
      expect(emptyNameRider.initials, '');

      final whitespaceRider = RiderInfo.fromJson({'name': '   Aliyu   Musa   Garba  '});
      expect(whitespaceRider.initials, 'AM');
    });

    test('Adversarial: Special characters and Unicode in store names and addresses', () {
      final unicodeStore = NearbyStore.fromJson({
        'id': 77,
        'name': 'Chukwu & Sons™ — "Sparkle & Shine" (Rivers State Branch)',
        'area': 'Port Harcourt #1',
        'address': 'No. 12/14 Aba Rd, opp. Shell RA ★',
        'rating': 4.95,
        'distanceKm': 3.1415,
        'turnaroundDays': 2,
        'turnaroundText': '2 days · ₦500/shirt',
        'shirtStartingPrice': 500,
      });

      expect(unicodeStore.name, contains('™'));
      expect(unicodeStore.name, contains('"Sparkle & Shine"'));
      expect(unicodeStore.address, contains('★'));
      expect(unicodeStore.turnaroundText, contains('₦'));
    });

    test('TurnaroundOptions serialization and multi-speed pricing options per vendor', () {
      final turnaroundOptionsJson = [
        {'days': 1, 'label': 'Next-day Express', 'startingPrice': 800, 'isDefault': false},
        {'days': 2, 'label': 'Standard 2-day', 'startingPrice': 500, 'isDefault': true},
        {'days': 3, 'label': 'Economy 3-day', 'startingPrice': 350, 'isDefault': false},
      ];

      expect(turnaroundOptionsJson.length, 3);
      expect(turnaroundOptionsJson[0]['days'], 1);
      expect(turnaroundOptionsJson[0]['startingPrice'], 800);
      expect(turnaroundOptionsJson[1]['days'], 2);
      expect(turnaroundOptionsJson[1]['startingPrice'], 500);
      expect(turnaroundOptionsJson[2]['days'], 3);
      expect(turnaroundOptionsJson[2]['startingPrice'], 350);

      // Verify variable pricing by speed: Express > Standard > Economy
      expect(turnaroundOptionsJson[0]['startingPrice'] as int,
          greaterThan(turnaroundOptionsJson[1]['startingPrice'] as int));
      expect(turnaroundOptionsJson[1]['startingPrice'] as int,
          greaterThan(turnaroundOptionsJson[2]['startingPrice'] as int));
    });

    test('NearbyStore safely handles Map operatingHours and scales turnaround pricing from store starting price', () {
      final userStoreResponse = {
        'id': 2,
        'name': 'Say Wat Laundry Abuja',
        'address': 'V2MJ+V53, Eneka Rd, Umuola 500102, Rivers, Nigeria',
        'area': 'V2MJ+V53',
        'latitude': 4.8841549,
        'longitude': 7.0305221,
        'rating': 5,
        'reviewCount': 312,
        'turnaroundDays': 2,
        'turnaroundText': 'Ready in 2 days',
        'shirtStartingPrice': 5000,
        'distanceKm': 430.4,
        'photoUrl': 'http://10.69.179.217:8545/uploads/file-1794513654553-718654436.jpg',
        'operatingHours': {
          'sat': 'Closed',
          'sun': 'Closed',
          'friday': {'open': '8:00 AM', 'close': '6:00 PM', 'isOpen': true},
          'monFri': '8:00 AM – 6:00 PM',
          'monday': {'open': '8:00 AM', 'close': '6:00 PM', 'isOpen': true},
        },
      };

      // Deserialization must succeed without throwing TypeError
      final store = NearbyStore.fromJson(userStoreResponse);
      expect(store.id, 2);
      expect(store.name, 'Say Wat Laundry Abuja');
      expect(store.operatingHours, '8:00 AM – 6:00 PM');
      expect(store.photoUrl, contains('uploads/file-1794513654553-718654436.jpg'));
      expect(store.shirtStartingPrice, 5000);
      expect(store.distanceKm, 430.4);

      // Verify dynamic turnaround pricing scales with the ₦5,000 shirt price
      final options = store.effectiveTurnaroundOptions;
      expect(options.length, 3);
      final nextDay = options.firstWhere((o) => o.days == 1);
      final standard = options.firstWhere((o) => o.days == 2);
      final economy = options.firstWhere((o) => o.days == 3);

      expect(standard.shirtStartingPrice, 5000);
      expect(nextDay.shirtStartingPrice, 8000); // 5000 * 1.6
      expect(economy.shirtStartingPrice, 3750); // 5000 * 0.75
    });

    test('NearbyStore logisticsType parsing, getters, and serialization', () {
      final storeWithBoth = NearbyStore.fromJson({
        'id': 10,
        'name': 'Express Clean',
        'address': 'Plot 4, Victoria Island, Lagos',
        'area': 'Victoria Island',
        'turnaroundText': 'Ready tomorrow',
        'shirtStartingPrice': 1500,
        'logisticsType': 'BOTH',
      });
      expect(storeWithBoth.logisticsType, 'BOTH');
      expect(storeWithBoth.usesFoamRiders, isTrue);
      expect(storeWithBoth.usesOwnLogistics, isTrue);
      expect(storeWithBoth.usesBothLogistics, isTrue);
      expect(storeWithBoth.logisticsDisplayText, 'Fleet & Store');

      final storeWithRiders = NearbyStore.fromJson({
        'id': 11,
        'name': 'Rider Cleaners',
        'address': 'Lekki Phase 1',
        'area': 'Lekki',
        'turnaroundText': 'Ready today',
        'shirtStartingPrice': 2000,
        'logisticsType': 'FOAM_RIDERS',
      });
      expect(storeWithRiders.logisticsType, 'FOAM_RIDERS');
      expect(storeWithRiders.usesFoamRiders, isTrue);
      expect(storeWithRiders.usesOwnLogistics, isFalse);
      expect(storeWithRiders.usesBothLogistics, isFalse);
      expect(storeWithRiders.logisticsDisplayText, 'Foam Fleet');

      final storeWithOwn = NearbyStore.fromJson({
        'id': 12,
        'name': 'In-House Cleaners',
        'address': 'Ikeja GRA',
        'area': 'Ikeja',
        'turnaroundText': 'Ready in 2 days',
        'shirtStartingPrice': 1200,
        'logisticsType': 'OWN_LOGISTICS',
      });
      expect(storeWithOwn.logisticsType, 'OWN_LOGISTICS');
      expect(storeWithOwn.usesFoamRiders, isFalse);
      expect(storeWithOwn.usesOwnLogistics, isTrue);
      expect(storeWithOwn.usesBothLogistics, isFalse);
      expect(storeWithOwn.logisticsDisplayText, 'Store Logistics');

      // Verify default fallback when logisticsType is omitted
      final storeDefault = NearbyStore.fromJson({
        'id': 13,
        'name': 'Default Store',
        'address': 'Abuja Central',
        'area': 'Abuja',
        'turnaroundText': 'Ready in 3 days',
        'shirtStartingPrice': 1000,
      });
      expect(storeDefault.logisticsType, 'BOTH');
      expect(storeDefault.usesBothLogistics, isTrue);

      final json = storeWithRiders.toJson();
      expect(json['logisticsType'], 'FOAM_RIDERS');
    });
  });
}
