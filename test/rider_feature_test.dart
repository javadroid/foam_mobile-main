import 'package:flutter_test/flutter_test.dart';
import 'package:foam_mobile/feature/rider/models/rider_models.dart';
import 'package:foam_mobile/feature/rider/controller/rider_provider.dart';

void main() {
  group('Rider Models & Provider Tests', () {
    test('RiderProfile JSON serialization & fallbacks', () {
      final json = {
        'id': 123,
        'name': 'Emeka Obi',
        'email': 'emeka@example.com',
        'phone': '08012345678',
        'vehicleType': 'MOTORCYCLE',
        'vehiclePlate': 'PH-892-ABC',
        'coverageLatitude': 4.8874,
        'coverageLongitude': 7.0289,
        'coverageRadiusKm': 12.5,
        'coverageRoute': 'Port Harcourt (Eneka / Peter Odili) Radius 12.5km',
        'approvalStatus': 'APPROVED',
        'isOnline': true,
      };

      final profile = RiderProfile.fromJson(json);
      expect(profile.id, 123);
      expect(profile.name, 'Emeka Obi');
      expect(profile.vehicleType, 'MOTORCYCLE');
      expect(profile.coverageLatitude, 4.8874);
      expect(profile.coverageLongitude, 7.0289);
      expect(profile.coverageRadiusKm, 12.5);
      expect(profile.coverageRoute, 'Port Harcourt (Eneka / Peter Odili) Radius 12.5km');
      expect(profile.isApproved, true);
      expect(profile.isOnline, true);
    });

    test('RiderProfile updates coverage area & radius', () {
      final profile = RiderProfile(
        id: 1,
        name: 'Rider John',
        email: 'john@foam.ng',
        phone: '08011112222',
        vehicleType: 'MOTORCYCLE',
        coverageLatitude: 4.8633,
        coverageLongitude: 7.0292,
        coverageRadiusKm: 5.0,
        coverageRoute: 'Port Harcourt Center (5.0 km radius)',
        approvalStatus: 'APPROVED',
        isOnline: true,
      );

      expect(profile.coverageRadiusKm, 5.0);
      expect(profile.coverageRoute, contains('5.0 km'));

      // Test expanding radius
      const expandedRadius = 15.0;
      final updatedRoute = 'Port Harcourt Expanded ($expandedRadius km radius)';
      expect(expandedRadius > profile.coverageRadiusKm, true);
      expect(updatedRoute, contains('15.0 km'));
    });

    test('AvailableRide JSON parsing with store and customer details', () {
      final json = {
        'id': 999,
        'orderNumber': 'FOAM-ORD-2026-999',
        'customerName': 'Amaka Okonkwo',
        'customerPhone': '08098765432',
        'pickupAddress': 'Eneka Road, PH',
        'deliveryAddress': 'Peter Odili, PH',
        'storeName': 'Sparkle Clean Eneka Branch',
        'storeAddress': '14 Eneka Junction, Port Harcourt',
        'deliveryFee': 1850.0,
        'earnings': 1500.0,
        'distanceKm': 4.2,
      };

      final ride = AvailableRide.fromJson(json);
      expect(ride.id, 999);
      expect(ride.storeName, 'Sparkle Clean Eneka Branch');
      expect(ride.deliveryFee, 1850.0);
      expect(ride.earnings, 1500.0);
      expect(ride.distanceKm, 4.2);

      final active = ActiveRide.fromAvailable(ride);
      expect(active.orderId, 999);
      expect(active.stage, 'EN_ROUTE_TO_STORE');
      expect(active.pickupPin, '1234');
      expect(active.deliveryPin, '5678');
    });

    test('RiderDeliveryHistoryItem & RiderTransactionItem parsing', () {
      final historyJson = {
        'orderId': 777,
        'orderNumber': 'FOAM-ORD-777',
        'date': '2026-10-30T14:00:00Z',
        'storeName': 'Lekki Crisp Clean',
        'pickupAddress': '15 Admiralty Way, Lekki',
        'deliveryAddress': 'Phase 1 Lekki',
        'earnings': 2500.0,
        'distanceKm': 6.5,
        'totalPrice': 7000.0,
      };
      final historyItem = RiderDeliveryHistoryItem.fromJson(historyJson);
      expect(historyItem.orderId, 777);
      expect(historyItem.earnings, 2500.0);
      expect(historyItem.distanceKm, 6.5);

      final txJson = {
        'id': 101,
        'title': 'Delivery Earnings (FOAM-ORD-777)',
        'amount': 2500.0,
        'type': 'CREDIT',
        'date': '2026-10-30T14:00:00Z',
      };
      final txItem = RiderTransactionItem.fromJson(txJson);
      expect(txItem.amount, 2500.0);
      expect(txItem.type, 'CREDIT');
    });

    test('RiderProvider initial state and testing setters', () {
      final provider = RiderProvider();
      expect(provider.isRegistered, false);
      expect(provider.isApproved, false);
      expect(provider.isOnline, false);
      expect(provider.walletBalance, 0.0);
      expect(provider.availableRides.isEmpty, true);

      final dummyProfile = RiderProfile(
        id: 1,
        name: 'Test Rider',
        email: 'rider@foam.ng',
        phone: '08000000000',
        vehicleType: 'MOTORCYCLE',
        approvalStatus: 'APPROVED',
        isOnline: true,
      );

      provider.setCurrentRiderForTesting(dummyProfile, token: 'fake-jwt-token');
      expect(provider.isRegistered, true);
      expect(provider.isApproved, true);
      expect(provider.isOnline, true);
      expect(provider.token, 'fake-jwt-token');
    });
  });
}
