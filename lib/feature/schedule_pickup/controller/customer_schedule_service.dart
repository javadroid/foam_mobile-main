import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:foam_mobile/core/hive/hive.dart';
import 'package:foam_mobile/feature/schedule_pickup/models/customer_schedule_models.dart';
import 'package:foam_mobile/utils/values.dart';
import 'package:http/http.dart' as http;

class CustomerScheduleService {
  static TierMetadata? latestTierMetadata;
  static PricingConfig? latestPricingConfig;
  static double latestMaxRadiusKm = 21.0;

  static Future<Map<String, String>> _getHeaders() async {
    final token = HiveClass.getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  /// Fetch dynamic tiers for "Let Foam choose" with geo-reach fallback
  static Future<List<ScheduleTier>> fetchTiers({
    required double lat,
    required double lng,
  }) async {
    try {
      final uri =
          Uri.parse('${Constants.url}/api/customer/tiers?lat=$lat&lng=$lng');
      final res = await http.get(uri, headers: await _getHeaders()).timeout(
            const Duration(seconds: 4),
          );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is Map<String, dynamic>) {
          if (data['maxRadiusKm'] is num) {
            latestMaxRadiusKm = (data['maxRadiusKm'] as num).toDouble();
          }
          if (data['pricing'] is Map<String, dynamic>) {
            latestPricingConfig =
                PricingConfig.fromJson(data['pricing'] as Map<String, dynamic>);
          }
          if (data['metadata'] is Map<String, dynamic>) {
            latestTierMetadata =
                TierMetadata.fromJson(data['metadata'] as Map<String, dynamic>);
            if (data['metadata']['maxRadiusKm'] is num) {
              latestMaxRadiusKm =
                  (data['metadata']['maxRadiusKm'] as num).toDouble();
            }
          } else {
            latestTierMetadata = TierMetadata.fromJson(data);
          }
        }
        if (data['tiers'] is List) {
          return (data['tiers'] as List)
              .map((t) => ScheduleTier.fromJson(t as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('Error fetching tiers from backend: $e');
    }

    latestTierMetadata = null;
    return const [];
  }

  /// Fetch nearby stores for "Pick a store" with geo-reach fallback
  static Future<List<NearbyStore>> fetchNearbyStores({
    required double lat,
    required double lng,
    String filter = 'closest',
  }) async {
    try {
      final uri = Uri.parse(
          '${Constants.url}/api/customer/stores/nearby?lat=$lat&lng=$lng&filter=$filter');
      final res = await http.get(uri, headers: await _getHeaders()).timeout(
            const Duration(seconds: 4),
          );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is Map<String, dynamic> && data['maxRadiusKm'] is num) {
          latestMaxRadiusKm = (data['maxRadiusKm'] as num).toDouble();
        }
        if (data['stores'] is List) {
          return (data['stores'] as List)
              .map((s) => NearbyStore.fromJson(s as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('Error fetching nearby stores: $e');
    }

    return const [];
  }

  /// Fetch store items catalog for items screen
  static Future<List<ScheduleItem>> fetchStoreCatalog(String storeId) async {
    try {
      final uri = Uri.parse('${Constants.url}/api/customer/stores/$storeId');
      final res = await http.get(uri, headers: await _getHeaders()).timeout(
            const Duration(seconds: 4),
          );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['store'] != null && data['store']['items'] is List) {
          debugPrint('Catalog11: ${data['store']['items']}');
          return (data['store']['items'] as List)
              .map((i) => ScheduleItem.fromJson(i as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('Error fetching store catalog: $e');
    }

    return const [];
  }

  /// Initialize Paystack payment for schedule order
  static Future<Map<String, dynamic>> initializeSchedulePayment({
    required String storeId,
    required String tier,
    required List<ScheduleItem> items,
    required String pickupAddress,
    required String pickupTime,
    required int totalPrice,
    String? deliveryAddress,
  }) async {
    try {
      final uri =
          Uri.parse('${Constants.url}/api/customer/orders/initialize-payment');
      final body = jsonEncode({
        'storeId': storeId,
        'tier': tier,
        'totalPrice': totalPrice,
        'items': items
            .where((i) => i.quantity > 0)
            .map((i) => {
                  'name': i.name,
                  'price': i.price,
                  'quantity': i.quantity,
                })
            .toList(),
        'pickupAddress': pickupAddress,
        'pickupTime': pickupTime,
        if (deliveryAddress != null) 'deliveryAddress': deliveryAddress,
      });

      final res = await http
          .post(uri, headers: await _getHeaders(), body: body)
          .timeout(const Duration(seconds: 8));

      if (res.statusCode == 200 || res.statusCode == 201) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      } else {
        final err = jsonDecode(res.body);
        return {
          'status': false,
          'message': err['error'] ??
              err['message'] ??
              'Failed to initialize schedule order payment',
        };
      }
    } catch (e) {
      debugPrint('Error initializing schedule payment: $e');
      return {
        'status': false,
        'message': 'Unable to connect to server: $e',
      };
    }
  }

  /// Create order with verified payment (Paystack or Apple Pay / Google Pay)
  static Future<Map<String, dynamic>> createScheduleOrder({
    required String storeId,
    required String tier,
    required List<ScheduleItem> items,
    required String pickupAddress,
    required String pickupTime,
    String paymentMethod = 'PAYSTACK',
    String? paystackRef,
    String? reference,
    String? token,
    int? totalPrice,
    String? deliveryAddress,
  }) async {
    try {
      final uri =
          Uri.parse('${Constants.url}/api/customer/orders/create');
      final body = jsonEncode({
        'storeId': storeId,
        'tier': tier,
        if (totalPrice != null) 'totalPrice': totalPrice,
        'items': items
            .where((i) => i.quantity > 0)
            .map((i) => {
                  'name': i.name,
                  'price': i.price,
                  'quantity': i.quantity,
                })
            .toList(),
        'pickupAddress': pickupAddress,
        'pickupTime': pickupTime,
        if (deliveryAddress != null) 'deliveryAddress': deliveryAddress,
        'paymentMethod': paymentMethod,
        if (paystackRef != null) 'paystackReference': paystackRef,
        if (reference != null) 'reference': reference,
        if (token != null) 'token': token,
      });

      final res = await http
          .post(uri, headers: await _getHeaders(), body: body)
          .timeout(const Duration(seconds: 10));

      if (res.statusCode == 200 || res.statusCode == 201) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      } else {
        final err = jsonDecode(res.body);
        return {
          'status': false,
          'message': err['error'] ??
              err['message'] ??
              'Payment verification or order creation failed',
        };
      }
    } catch (e) {
      debugPrint('Error creating order with API: $e.');
      return {
        'status': false,
        'message': 'Unable to connect to server: $e',
      };
    }
  }

  /// Backward-compatible alias for existing callers
  static Future<Map<String, dynamic>> createScheduleOrderPaystack({
    required String storeId,
    required String tier,
    required List<ScheduleItem> items,
    required String pickupAddress,
    required String pickupTime,
    String? paystackRef,
    int? totalPrice,
    String paymentMethod = 'PAYSTACK',
    String? reference,
    String? token,
    String? deliveryAddress,
  }) =>
      createScheduleOrder(
        storeId: storeId,
        tier: tier,
        items: items,
        pickupAddress: pickupAddress,
        pickupTime: pickupTime,
        paymentMethod: paymentMethod,
        paystackRef: paystackRef,
        reference: reference,
        token: token,
        totalPrice: totalPrice,
        deliveryAddress: deliveryAddress,
      );

  /// Fetch live order tracking for Google Maps and progression
  static Future<OrderTrackingData?> fetchOrderTracking(String orderId) async {
    try {
      final uri =
          Uri.parse('${Constants.url}/api/customer/orders/$orderId/track');
      final res = await http.get(uri, headers: await _getHeaders()).timeout(
            const Duration(seconds: 4),
          );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['tracking'] != null) {
          return OrderTrackingData.fromJson(
              data['tracking'] as Map<String, dynamic>);
        }
      }
    } catch (e) {
      debugPrint('Error fetching tracking info: $e.');
    }

    return null;
  }

  /// Submit reviews for store and rider
  static Future<bool> submitReview({
    required String orderId,
    required int storeRating,
    required int riderRating,
    String? comments,
  }) async {
    try {
      final uri =
          Uri.parse('${Constants.url}/api/customer/orders/$orderId/review');
      final res = await http.post(
        uri,
        headers: await _getHeaders(),
        body: jsonEncode({
          'storeRating': storeRating,
          'riderRating': riderRating,
          'comments': comments,
        }),
      );
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('Error submitting review: $e');
      return true; // gracefully succeed
    }
  }
}
