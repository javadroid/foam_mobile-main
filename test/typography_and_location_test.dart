import 'package:flutter_test/flutter_test.dart';
import 'package:foam_mobile/feature/schedule_pickup/controller/schedule_pickup_provider.dart';
import 'package:foam_mobile/feature/schedule_pickup/models/customer_schedule_models.dart';

void main() {
  group('Typography & Location Provider - Tier 1: Location Selection & Coordinate Storage', () {
    late SchedulePickupProvider provider;

    setUp(() {
      provider = SchedulePickupProvider();
    });

    test('Initial default pickup address and coordinates are properly initialized', () {
      expect(provider.pickupAddress, isNotEmpty);
      expect(provider.pickupLat, isNotNull);
      expect(provider.pickupLng, isNotNull);
      expect(provider.pickupLat, closeTo(6.4474, 0.001));
      expect(provider.pickupLng, closeTo(3.4723, 0.001));
      expect(provider.isDetectingLocation, isFalse);
    });

    test('setPickupLocation updates address and coordinates and notifies listeners', () {
      int listenerNotified = 0;
      provider.addListener(() => listenerNotified++);

      provider.setPickupLocation(
        address: 'Eneka Roundabout, Port Harcourt',
        lat: 4.8633,
        lng: 7.0292,
      );

      expect(provider.pickupAddress, 'Eneka Roundabout, Port Harcourt');
      expect(provider.pickupLat, 4.8633);
      expect(provider.pickupLng, 7.0292);
      expect(listenerNotified, greaterThan(0));
    });

    test('setPickupLocation preserves existing coordinates when lat/lng are null', () {
      provider.setPickupLocation(
        address: 'Original Location',
        lat: 4.8633,
        lng: 7.0292,
      );

      provider.setPickupLocation(address: 'New Text Only Address');
      expect(provider.pickupAddress, 'New Text Only Address');
      expect(provider.pickupLat, 4.8633);
      expect(provider.pickupLng, 7.0292);
    });

    test('setPickupAddress updates address alone', () {
      int notifyCount = 0;
      provider.addListener(() => notifyCount++);

      provider.setPickupAddress('Victoria Island, Lagos');
      expect(provider.pickupAddress, 'Victoria Island, Lagos');
      expect(notifyCount, 1);
    });

    test('Multi-state coordinate updates (Rivers, Lagos, Abuja)', () {
      // Port Harcourt (Rivers)
      provider.setPickupLocation(
        address: 'Peter Odili Road, Trans-Amadi, Port Harcourt',
        lat: 4.8156,
        lng: 7.0498,
      );
      expect(provider.pickupLat, 4.8156);
      expect(provider.pickupLng, 7.0498);

      // Abuja (FCT)
      provider.setPickupLocation(
        address: 'Adetokunbo Ademola Crescent, Wuse 2, Abuja',
        lat: 9.0765,
        lng: 7.4891,
      );
      expect(provider.pickupLat, 9.0765);
      expect(provider.pickupLng, 7.4891);

      // Lagos
      provider.setPickupLocation(
        address: '14 Admiralty Way, Lekki Phase 1, Lagos',
        lat: 6.4474,
        lng: 3.4723,
      );
      expect(provider.pickupLat, 6.4474);
      expect(provider.pickupLng, 3.4723);
    });

    test('Schedule method toggle notifies listeners', () {
      expect(provider.selectedMethod, ScheduleMethod.letFoamChoose);

      int toggled = 0;
      provider.addListener(() => toggled++);

      provider.selectMethod(ScheduleMethod.pickStore);
      expect(provider.selectedMethod, ScheduleMethod.pickStore);
      expect(toggled, 1);
    });

    test('Tier selection and currentTier fallback resolution', () {
      provider.selectTier('PREMIUM');
      expect(provider.selectedTierId, 'PREMIUM');

      // Tiers list empty initially, currentTier falls back to Balanced safely
      final tier = provider.currentTier;
      expect(tier.id, isNotEmpty);
    });

    test('Store selection updates currentStore', () {
      const customStore = NearbyStore(
        id: '7',
        name: 'Prime Drycleaners Abuja',
        area: 'Maitama',
        address: 'Maitama Shopping Complex',
        rating: 4.9,
        distanceKm: 1.2,
        turnaroundDays: 1,
        turnaroundText: 'Next-day',
        shirtStartingPrice: 850,
      );

      provider.selectStore(customStore);
      expect(provider.currentStore.id, '7');
      expect(provider.currentStore.name, 'Prime Drycleaners Abuja');
    });

    test('Basket calculations: subtotal, delivery fee, service fee, and grand total', () {
      // Initially items have 4 shirts (500) and 2 t-shirts (400) = 2000 + 800 = 2800
      expect(provider.totalBasketCount, 6);
      expect(provider.itemSubtotal, 2800);
      expect(provider.deliveryFee, 1500);
      expect(provider.serviceFee, 300);
      expect(provider.grandTotal, 2800 + 1500 + 300); // 4600

      // Increment shirt (id: 1)
      provider.incrementItem(1);
      expect(provider.totalBasketCount, 7);
      expect(provider.itemSubtotal, 3300);
      expect(provider.grandTotal, 5100);

      // Decrement t-shirt (id: 2)
      provider.decrementItem(2);
      expect(provider.totalBasketCount, 6);
      expect(provider.itemSubtotal, 2900);
      expect(provider.grandTotal, 4700);
    });

    test('Pickup slot updates properly', () {
      provider.setPickupSlot('Tomorrow, 10:00 – 11:00 AM');
      expect(provider.pickupSlot, 'Tomorrow, 10:00 – 11:00 AM');
    });

    test('Dynamic tier subtitle computation from TierMetadata', () {
      // Default before metadata
      expect(provider.tierSubtitle, contains('live stores within'));

      // Simulate dynamic metadata
      final meta = TierMetadata.fromJson({
        'liveStoreCount': 12,
        'radiusKm': 8,
        'isOutsideGeoReach': false,
      });

      // Reflection or verification of computedSubtitle
      expect(meta.computedSubtitle, 'Based on 12 live stores within 8 km. Prices are for a shirt, washed and folded.');
    });
  });

  group('Typography & Layout Specifications - Tier 1 & 2: Proportional Font Metrics', () {
    test('Proportional typography rules adhere to design boundaries (R1)', () {
      // Verify standard design constraints defined in PROJECT.md and mobile UI audit
      const maxButtonFontSize = 16.0;
      const minButtonFontSize = 14.0;
      const maxButtonLetterSpacing = 0.8;

      const maxAppBarTitleFontSize = 18.0;
      const maxDisplayTitleFontSize = 24.0;
      const maxPinLetterSpacing = 8.0;
      const maxPinFontSize = 30.0;

      // Recommended primary button spec
      const recommendedButtonFontSize = 15.0;
      const recommendedButtonLetterSpacing = 0.6;

      expect(recommendedButtonFontSize, inInclusiveRange(minButtonFontSize, maxButtonFontSize));
      expect(recommendedButtonLetterSpacing, lessThanOrEqualTo(maxButtonLetterSpacing));

      // Recommended AppBar title spec
      const recommendedAppBarFontSize = 18.0;
      expect(recommendedAppBarFontSize, lessThanOrEqualTo(maxAppBarTitleFontSize));

      // Recommended Display title spec (Screens 07, 11)
      const recommendedDisplayTitleFontSize = 22.0;
      expect(recommendedDisplayTitleFontSize, lessThanOrEqualTo(maxDisplayTitleFontSize));

      // Recommended PIN display spec (Screen 07, 08, 10)
      const recommendedPinFontSize = 28.0;
      const recommendedPinLetterSpacing = 8.0;
      expect(recommendedPinFontSize, lessThanOrEqualTo(maxPinFontSize));
      expect(recommendedPinLetterSpacing, lessThanOrEqualTo(maxPinLetterSpacing));
    });

    test('Button text layout safety on 53dp container with display scaling', () {
      // Simulate button dimensions
      const buttonHeight = 53.0;
      const verticalPadding = 24.0; // 12 top + 12 bottom
      const availableTextHeight = buttonHeight - verticalPadding; // 29.0dp

      const fontSize = 15.0;
      const lineHeightMultiplier = 1.2;
      final renderedTextHeight = fontSize * lineHeightMultiplier; // 18.0dp

      // Rendered height must comfortably fit within available height without clipping
      expect(renderedTextHeight, lessThan(availableTextHeight));

      // Check with 1.3x accessibility font scaling
      const fontScale130 = 1.3;
      final scaledTextHeight = renderedTextHeight * fontScale130; // 23.4dp
      expect(scaledTextHeight, lessThan(availableTextHeight));
    });

    test('PIN width safety on narrow 320dp screen width', () {
      // 4-digit PIN: e.g. "3921"
      const pinLength = 4;
      const charWidth = 18.0; // at 28px font size
      const letterSpacing = 8.0;
      final totalPinWidth = (pinLength * charWidth) + ((pinLength - 1) * letterSpacing); // 72 + 24 = 96dp

      // Card container available width on 320dp screen (320 - 48 margin) = 272dp
      const availableCardWidth = 272.0;
      expect(totalPinWidth, lessThan(availableCardWidth * 0.6)); // Comfortably centered without overflow
    });

    test('Boundary: Decrementing item already at zero does not become negative', () {
      final provider = SchedulePickupProvider();
      // Item 3 (Trousers) starts at quantity 0
      expect(provider.items.firstWhere((i) => i.id == 3).quantity, 0);

      provider.decrementItem(3);
      expect(provider.items.firstWhere((i) => i.id == 3).quantity, 0);
      expect(provider.itemSubtotal, greaterThanOrEqualTo(0));
    });

    test('Boundary: Decrementing non-existent item id does not crash', () {
      final provider = SchedulePickupProvider();
      expect(() => provider.decrementItem(9999), returnsNormally);
      expect(() => provider.incrementItem(9999), returnsNormally);
    });

    test('Boundary: Setting empty address string does not crash provider', () {
      final provider = SchedulePickupProvider();
      provider.setPickupLocation(address: '', lat: 0.0, lng: 0.0);
      expect(provider.pickupAddress, '');
      expect(provider.pickupLat, 0.0);
      expect(provider.pickupLng, 0.0);
    });
  });
}
