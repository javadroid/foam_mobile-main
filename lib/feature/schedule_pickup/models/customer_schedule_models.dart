import 'package:flutter/foundation.dart';

/// Geographical coordinate representation
@immutable
class LocationCoordinate {
  final double latitude;
  final double longitude;
  final String? address;

  const LocationCoordinate({
    required this.latitude,
    required this.longitude,
    this.address,
  });

  factory LocationCoordinate.fromJson(Map<String, dynamic> json) {
    return LocationCoordinate(
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      address: json['address'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        if (address != null) 'address': address,
      };
}

/// Store metadata matched for a specific pricing tier
@immutable
class MatchedTierStore {
  final String id;
  final String name;
  final double rating;
  final int turnaroundDays;
  final double distanceKm;

  const MatchedTierStore({
    required this.id,
    required this.name,
    required this.rating,
    required this.turnaroundDays,
    required this.distanceKm,
  });

  factory MatchedTierStore.fromJson(Map<String, dynamic> json) {
    return MatchedTierStore(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? 'Nearby Store',
      rating: (json['rating'] as num?)?.toDouble() ?? 4.5,
      turnaroundDays: (json['turnaroundDays'] as num?)?.toInt() ?? 2,
      distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'rating': rating,
        'turnaroundDays': turnaroundDays,
        'distanceKm': distanceKm,
      };
}

/// Metadata returned from dynamic tiers calculation
@immutable
class TierMetadata {
  final int storeCount;
  final double radiusKm;
  final bool isFallback;
  final String? nearestStoreName;
  final double? nearestDistanceKm;
  final String? subtitleText;

  const TierMetadata({
    this.storeCount = 9,
    this.radiusKm = 5.0,
    this.isFallback = false,
    this.nearestStoreName,
    this.nearestDistanceKm,
    this.subtitleText,
  });

  String get computedSubtitle {
    if (subtitleText != null && subtitleText!.trim().isNotEmpty) {
      return subtitleText!;
    }
    if (isFallback && nearestStoreName != null && nearestDistanceKm != null) {
      return 'Based on nearest store $nearestStoreName (${nearestDistanceKm!.toStringAsFixed(1)} km away). Prices are for a shirt, washed and folded.';
    }
    return 'Based on $storeCount live stores within ${radiusKm.toInt()} km. Prices are for a shirt, washed and folded.';
  }

  factory TierMetadata.fromJson(Map<String, dynamic> json) {
    return TierMetadata(
      storeCount: (json['storeCount'] ?? json['liveStoreCount'] ?? 9) as int,
      radiusKm: (json['radiusKm'] is num)
          ? (json['radiusKm'] as num).toDouble()
          : 5.0,
      isFallback:
          (json['isFallback'] ?? json['isOutsideGeoReach'] ?? false) as bool,
      nearestStoreName: json['nearestStoreName'] as String?,
      nearestDistanceKm: (json['nearestDistanceKm'] is num)
          ? (json['nearestDistanceKm'] as num).toDouble()
          : null,
      subtitleText: json['subtitleText'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'storeCount': storeCount,
        'radiusKm': radiusKm,
        'isFallback': isFallback,
        'nearestStoreName': nearestStoreName,
        'nearestDistanceKm': nearestDistanceKm,
        'subtitleText': subtitleText,
      };
}

/// Customer schedule pricing tier
@immutable
class ScheduleTier {
  final String id;
  final String title;
  final int startingPrice;
  final int turnaroundDays;
  final String turnaroundText;
  final bool isMostPicked;
  final String? badge;
  final MatchedTierStore? matchedStore;

  const ScheduleTier({
    required this.id,
    required this.title,
    required this.startingPrice,
    required this.turnaroundDays,
    required this.turnaroundText,
    this.isMostPicked = false,
    this.badge,
    this.matchedStore,
  });

  factory ScheduleTier.fromJson(Map<String, dynamic> json) {
    return ScheduleTier(
      id: json['id'] as String? ?? 'BALANCED',
      title: json['title'] as String? ?? 'Balanced',
      startingPrice: (json['startingPrice'] as num?)?.toInt() ?? 500,
      turnaroundDays: (json['turnaroundDays'] as num?)?.toInt() ?? 2,
      turnaroundText: json['turnaroundText'] as String? ?? 'Ready in 2 days',
      isMostPicked: json['isMostPicked'] as bool? ?? false,
      badge: json['badge'] as String?,
      matchedStore: json['matchedStore'] is Map<String, dynamic>
          ? MatchedTierStore.fromJson(
              json['matchedStore'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'startingPrice': startingPrice,
        'turnaroundDays': turnaroundDays,
        'turnaroundText': turnaroundText,
        'isMostPicked': isMostPicked,
        if (badge != null) 'badge': badge,
        if (matchedStore != null) 'matchedStore': matchedStore!.toJson(),
      };
}

/// Turnaround speed option offered by a vendor
@immutable
class TurnaroundOption {
  final int days;
  final String name;
  final double priceMultiplier;
  final int shirtStartingPrice;

  const TurnaroundOption({
    required this.days,
    required this.name,
    this.priceMultiplier = 1.0,
    required this.shirtStartingPrice,
  });

  int get surchargePercent =>
      priceMultiplier > 1.0 ? ((priceMultiplier - 1.0) * 100).round() : 0;

  factory TurnaroundOption.fromJson(Map<String, dynamic> json) {
    double mult = 1.0;
    if (json['priceMultiplier'] is num) {
      mult = (json['priceMultiplier'] as num).toDouble();
    } else if (json['multiplier'] is num) {
      mult = (json['multiplier'] as num).toDouble();
    } else if (json['percentage'] is num) {
      mult = 1.0 + ((json['percentage'] as num).toDouble() / 100.0);
    }

    return TurnaroundOption(
      days: (json['days'] as num?)?.toInt() ?? 2,
      name: json['name'] as String? ?? (json['package'] as String? ?? 'Standard'),
      priceMultiplier: mult,
      shirtStartingPrice: (json['shirtStartingPrice'] as num?)?.toInt() ??
          (json['startingPrice'] as num?)?.toInt() ??
          500,
    );
  }

  Map<String, dynamic> toJson() => {
        'days': days,
        'name': name,
        'priceMultiplier': priceMultiplier,
        'shirtStartingPrice': shirtStartingPrice,
      };
}

/// Nearby store model
@immutable
class NearbyStore {
  final String id;
  final String name;
  final String area;
  final String address;
  final double rating;
  final int reviewCount;
  final double distanceKm;
  final int turnaroundDays;
  final String turnaroundText;
  final int shirtStartingPrice;
  final String operatingHours;
  final String? photoUrl;
  final String logisticsType;
  final double foldingPrice;
  final double? latitude;
  final double? longitude;
  final List<TurnaroundOption> turnaroundOptions;

  const NearbyStore({
    required this.id,
    required this.name,
    required this.area,
    required this.address,
    required this.rating,
    this.reviewCount = 0,
    required this.distanceKm,
    required this.turnaroundDays,
    required this.turnaroundText,
    required this.shirtStartingPrice,
    this.operatingHours = '8am–8pm',
    this.photoUrl,
    this.logisticsType = 'BOTH',
    this.foldingPrice = 0.0,
    this.latitude,
    this.longitude,
    this.turnaroundOptions = const [],
  });

  bool get hasFoldingFee => foldingPrice > 0;

  bool get usesFoamRiders =>
      logisticsType == 'FOAM_RIDERS' || logisticsType == 'BOTH';
  bool get usesOwnLogistics =>
      logisticsType == 'OWN_LOGISTICS' || logisticsType == 'BOTH';
  bool get usesBothLogistics => logisticsType == 'BOTH';

  String get logisticsDisplayText {
    switch (logisticsType.toUpperCase()) {
      case 'FOAM_RIDERS':
        return 'Foam Fleet';
      case 'OWN_LOGISTICS':
        return 'Store Logistics';
      case 'BOTH':
      default:
        return 'Fleet & Store';
    }
  }

  List<TurnaroundOption> get effectiveTurnaroundOptions {
    if (turnaroundOptions.isNotEmpty) {
      return turnaroundOptions.map((opt) {
        if (opt.shirtStartingPrice == 500 && shirtStartingPrice != 500) {
          return TurnaroundOption(
            days: opt.days,
            name: opt.name,
            priceMultiplier: opt.priceMultiplier,
            shirtStartingPrice: (shirtStartingPrice * opt.priceMultiplier).round(),
          );
        }
        return opt;
      }).toList();
    }
    return [
      TurnaroundOption(
        days: 1,
        name: 'Next-day',
        priceMultiplier: 1.6,
        shirtStartingPrice: (shirtStartingPrice * 1.6).round(),
      ),
      TurnaroundOption(
        days: 2,
        name: 'Standard',
        priceMultiplier: 1.0,
        shirtStartingPrice: shirtStartingPrice,
      ),
      TurnaroundOption(
        days: 3,
        name: 'Economy',
        priceMultiplier: 0.75,
        shirtStartingPrice: (shirtStartingPrice * 0.75).round(),
      ),
    ];
  }

  factory NearbyStore.fromJson(Map<String, dynamic> json) {
    final rawOptions = json['turnaroundOptions'];
    final parsedOptions = <TurnaroundOption>[];
    if (rawOptions is List) {
      for (final opt in rawOptions) {
        if (opt is Map<String, dynamic>) {
          parsedOptions.add(TurnaroundOption.fromJson(opt));
        }
      }
    }

    // Safely parse operatingHours whether it is String, Map, or null
    String parsedHours = '8am–8pm';
    final rawHours = json['operatingHours'];
    if (rawHours is String && rawHours.trim().isNotEmpty) {
      parsedHours = rawHours;
    } else if (rawHours is Map) {
      if (rawHours['monFri'] != null && rawHours['monFri'].toString().trim().isNotEmpty) {
        parsedHours = rawHours['monFri'].toString();
      } else if (rawHours['monday'] is Map && rawHours['monday']['open'] != null) {
        parsedHours = '${rawHours['monday']['open']} – ${rawHours['monday']['close']}';
      } else {
        parsedHours = '8:00 AM – 6:00 PM';
      }
    }

    return NearbyStore(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? 'Laundry Store',
      area: json['area'] as String? ?? (json['city'] as String? ?? 'Area'),
      address: json['address'] as String? ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 4.5,
      reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
      distanceKm: (json['distanceKm'] ?? json['distance'] as num?)?.toDouble() ?? 0.0,
      turnaroundDays: (json['turnaroundDays'] as num?)?.toInt() ?? 2,
      turnaroundText: json['turnaroundText'] as String? ??
          'Ready in ${(json['turnaroundDays'] as num?)?.toInt() ?? 2} days',
      shirtStartingPrice: (json['shirtStartingPrice'] as num?)?.toInt() ??
          (json['startingPrice'] as num?)?.toInt() ??
          500,
      operatingHours: parsedHours,
      photoUrl: json['photoUrl'] as String?,
      logisticsType: json['logisticsType'] as String? ?? 'BOTH',
      foldingPrice: (json['foldingPrice'] as num?)?.toDouble() ?? 0.0,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      turnaroundOptions: parsedOptions,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'area': area,
        'address': address,
        'rating': rating,
        'reviewCount': reviewCount,
        'distanceKm': distanceKm,
        'turnaroundDays': turnaroundDays,
        'turnaroundText': turnaroundText,
        'shirtStartingPrice': shirtStartingPrice,
        'operatingHours': operatingHours,
        'logisticsType': logisticsType,
        'foldingPrice': foldingPrice,
        if (photoUrl != null) 'photoUrl': photoUrl,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (turnaroundOptions.isNotEmpty)
          'turnaroundOptions': turnaroundOptions.map((o) => o.toJson()).toList(),
      };
}

/// Item selectable in laundry basket
class ScheduleItem {
  final int id;
  final String name;
  final int price;
  int quantity;
  final String category;
  final String foldType;
  final String? imageUrl;
  bool userWantsFolding;

  ScheduleItem({
    required this.id,
    required this.name,
    required this.price,
    this.quantity = 0,
    this.category = 'Laundry',
    this.foldType = 'Folding',
    this.imageUrl,
    this.userWantsFolding = false,
  });

  bool get storeIncludesFolding =>
      !foldType.toUpperCase().contains('NON') &&
      foldType.toUpperCase().contains('FOLD');

  factory ScheduleItem.fromJson(Map<String, dynamic> json) {
    String parsedCategory = 'Laundry';
    final rawCat = json['category'];
    if (rawCat is String && rawCat.trim().isNotEmpty) {
      parsedCategory = rawCat.trim();
    } else if (rawCat is Map && rawCat['name'] != null) {
      parsedCategory = rawCat['name'].toString().trim();
    } else if (json['serviceType'] is String) {
      parsedCategory = (json['serviceType'] as String).trim();
    } else if (json['service'] is String) {
      parsedCategory = (json['service'] as String).trim();
    }

    return ScheduleItem(
      id: (json['id'] ?? json['categoryId'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? 'Item',
      price: (json['price'] as num?)?.toInt() ?? 0,
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      category: parsedCategory,
      foldType: json['foldType'] as String? ?? 'Folding',
      imageUrl: json['imageUrl'] as String?,
      userWantsFolding: json['userWantsFolding'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'price': price,
        'quantity': quantity,
        'category': category,
        'foldType': foldType,
        'userWantsFolding': userWantsFolding,
        'storeIncludesFolding': storeIncludesFolding,
        if (imageUrl != null) 'imageUrl': imageUrl,
      };
}

/// Rider info attached to order tracking
@immutable
class RiderInfo {
  final String name;
  final String initials;
  final String? phone;
  final double rating;
  final String? vehicle;
  final String? subtitle;

  const RiderInfo({
    required this.name,
    this.initials = '',
    this.phone,
    this.rating = 5.0,
    this.vehicle,
    this.subtitle,
  });

  factory RiderInfo.fromJson(Map<String, dynamic> json) {
    final name = json['name'] as String? ?? 'Rider';
    String derivedInitials = json['initials'] as String? ?? '';
    if (derivedInitials.isEmpty && name.isNotEmpty) {
      final parts = name.trim().split(RegExp(r'\s+'));
      derivedInitials = parts.map((p) => p.isNotEmpty ? p[0] : '').take(2).join().toUpperCase();
    }
    return RiderInfo(
      name: name,
      initials: derivedInitials,
      phone: json['phone'] as String?,
      rating: (json['rating'] as num?)?.toDouble() ?? 5.0,
      vehicle: json['vehicle'] as String?,
      subtitle: json['subtitle'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'initials': initials,
        if (phone != null) 'phone': phone,
        'rating': rating,
        if (vehicle != null) 'vehicle': vehicle,
        if (subtitle != null) 'subtitle': subtitle,
      };
}

/// Timeline step in tracking progression
@immutable
class TimelineStep {
  final String section;
  final String title;
  final String time;
  final bool isCompleted;
  final bool isActive;
  final bool isPending;

  const TimelineStep({
    required this.section,
    required this.title,
    this.time = '',
    this.isCompleted = false,
    this.isActive = false,
    this.isPending = false,
  });

  factory TimelineStep.fromJson(Map<String, dynamic> json) {
    return TimelineStep(
      section: json['section'] as String? ?? '',
      title: json['title'] as String? ?? '',
      time: json['time'] as String? ?? '',
      isCompleted: json['isCompleted'] as bool? ?? false,
      isActive: json['isActive'] as bool? ?? false,
      isPending: json['isPending'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'section': section,
        'title': title,
        'time': time,
        'isCompleted': isCompleted,
        'isActive': isActive,
        'isPending': isPending,
      };
}

/// Comprehensive order tracking data model
@immutable
class OrderTrackingData {
  final int orderId;
  final String orderNumber;
  final String currentStage;
  final bool isTrackingUnlocked;
  final String storeName;
  final String pickupPin;
  final String deliveryPin;
  final String? pickupEta;
  final String? deliveryEta;
  final String? readyEta;
  final RiderInfo? pickupRider;
  final RiderInfo? deliveryRider;
  final Map<String, LocationCoordinate> locations;
  final List<TimelineStep> timeline;

  const OrderTrackingData({
    required this.orderId,
    required this.orderNumber,
    required this.currentStage,
    this.isTrackingUnlocked = false,
    required this.storeName,
    required this.pickupPin,
    required this.deliveryPin,
    this.pickupEta,
    this.deliveryEta,
    this.readyEta,
    this.pickupRider,
    this.deliveryRider,
    this.locations = const {},
    this.timeline = const [],
  });

  LocationCoordinate? get customerLocation => locations['customer'];
  LocationCoordinate? get storeLocation => locations['store'];
  LocationCoordinate? get riderLocation => locations['rider'];

  factory OrderTrackingData.fromJson(Map<String, dynamic> json) {
    final rawLocations = json['locations'];
    final parsedLocations = <String, LocationCoordinate>{};
    if (rawLocations is Map<String, dynamic>) {
      rawLocations.forEach((key, value) {
        if (value is Map<String, dynamic>) {
          parsedLocations[key] = LocationCoordinate.fromJson(value);
        }
      });
    }

    final rawTimeline = json['timeline'];
    final parsedTimeline = <TimelineStep>[];
    if (rawTimeline is List) {
      for (final item in rawTimeline) {
        if (item is Map<String, dynamic>) {
          parsedTimeline.add(TimelineStep.fromJson(item));
        }
      }
    }

    return OrderTrackingData(
      orderId: (json['orderId'] as num?)?.toInt() ?? 0,
      orderNumber: json['orderNumber'] as String? ?? '',
      currentStage: json['currentStage'] as String? ?? 'PICKUP',
      isTrackingUnlocked: json['isTrackingUnlocked'] as bool? ?? false,
      storeName: json['storeName'] as String? ?? 'Laundry Store',
      pickupPin: json['pickupPin'] as String? ?? '',
      deliveryPin: json['deliveryPin'] as String? ?? '',
      pickupEta: json['pickupEta'] as String?,
      deliveryEta: json['deliveryEta'] as String?,
      readyEta: json['readyEta'] as String?,
      pickupRider: json['pickupRider'] is Map<String, dynamic>
          ? RiderInfo.fromJson(json['pickupRider'] as Map<String, dynamic>)
          : null,
      deliveryRider: json['deliveryRider'] is Map<String, dynamic>
          ? RiderInfo.fromJson(json['deliveryRider'] as Map<String, dynamic>)
          : null,
      locations: parsedLocations,
      timeline: parsedTimeline,
    );
  }

  Map<String, dynamic> toJson() => {
        'orderId': orderId,
        'orderNumber': orderNumber,
        'currentStage': currentStage,
        'isTrackingUnlocked': isTrackingUnlocked,
        'storeName': storeName,
        'pickupPin': pickupPin,
        'deliveryPin': deliveryPin,
        if (pickupEta != null) 'pickupEta': pickupEta,
        if (deliveryEta != null) 'deliveryEta': deliveryEta,
        if (readyEta != null) 'readyEta': readyEta,
        if (pickupRider != null) 'pickupRider': pickupRider!.toJson(),
        if (deliveryRider != null) 'deliveryRider': deliveryRider!.toJson(),
        'locations': locations.map((k, v) => MapEntry(k, v.toJson())),
        'timeline': timeline.map((s) => s.toJson()).toList(),
      };
}

/// Delivery & service fee pricing configuration set by Admin
@immutable
class PricingConfig {
  final int baseDeliveryFee;
  final int deliveryFeePerKm;
  final int serviceFeeThreshold;
  final int serviceFeeFixed;
  final double serviceFeePercentage;

  const PricingConfig({
    this.baseDeliveryFee = 1500,
    this.deliveryFeePerKm = 100,
    this.serviceFeeThreshold = 2000,
    this.serviceFeeFixed = 300,
    this.serviceFeePercentage = 5.0,
  });

  factory PricingConfig.fromJson(Map<String, dynamic> json) {
    return PricingConfig(
      baseDeliveryFee: (json['baseDeliveryFee'] as num?)?.toInt() ?? 1500,
      deliveryFeePerKm: (json['deliveryFeePerKm'] as num?)?.toInt() ?? 100,
      serviceFeeThreshold:
          (json['serviceFeeThreshold'] as num?)?.toInt() ?? 2000,
      serviceFeeFixed: (json['serviceFeeFixed'] as num?)?.toInt() ?? 300,
      serviceFeePercentage:
          (json['serviceFeePercentage'] as num?)?.toDouble() ?? 5.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'baseDeliveryFee': baseDeliveryFee,
        'deliveryFeePerKm': deliveryFeePerKm,
        'serviceFeeThreshold': serviceFeeThreshold,
        'serviceFeeFixed': serviceFeeFixed,
        'serviceFeePercentage': serviceFeePercentage,
      };
}
