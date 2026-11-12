import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:foam_mobile/core/hive/hive.dart';
import 'package:foam_mobile/core/services/location_service.dart';
import 'package:foam_mobile/feature/authentication/controller/provider/authprovider.dart';
import 'package:foam_mobile/feature/schedule_pickup/controller/customer_schedule_service.dart';
import 'package:foam_mobile/feature/schedule_pickup/models/customer_schedule_models.dart';
import 'package:foam_mobile/utils/values.dart';
import 'package:http/http.dart' as http;

enum ScheduleMethod { letFoamChoose, pickStore }

class SchedulePickupProvider extends ChangeNotifier {
  // Current pickup location
  String _pickupAddress = '3 Bisola Durosinmi-Etti Dr, Lekki';
  double _pickupLat = 6.4474;
  double _pickupLng = 3.4723;
  bool _isDetectingLocation = false;
  bool _isLocationLoaded = false;

  String get pickupAddress => _pickupAddress;
  double get pickupLat => _pickupLat;
  double get pickupLng => _pickupLng;
  bool get isDetectingLocation => _isDetectingLocation;
  bool get isLocationLoaded => _isLocationLoaded;

  /// Load the customer's saved location from AuthProvider / backend API / storage
  Future<void> loadSavedLocation({AuthProvider? authProvider}) async {
    // 1. Populate immediately from AuthProvider if available in memory
    if (authProvider != null && authProvider.addressStreet.isNotEmpty) {
      final street = authProvider.addressStreet;
      final city = authProvider.addressCity;
      _pickupAddress = city.isNotEmpty ? '$street, $city' : street;

      if (authProvider.addressLatitude != null &&
          authProvider.addressLongitude != null &&
          authProvider.addressLatitude != 0.0 &&
          authProvider.addressLongitude != 0.0) {
        _pickupLat = authProvider.addressLatitude!;
        _pickupLng = authProvider.addressLongitude!;
      }
      _isLocationLoaded = true;
      notifyListeners();
    }

    // 2. Fetch latest saved address from backend /api/user/address
    try {
      String token = '';
      try {
        if (HiveClass.tokenExist()) {
          token = HiveClass.getToken();
        }
      } catch (_) {}

      if (token.isNotEmpty) {
        final res = await http.get(
          Uri.parse('${Constants.url}/api/user/address'),
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        ).timeout(const Duration(seconds: 4));

        if (res.statusCode == 200 || res.statusCode == 201) {
          final data = json.decode(res.body);
          if (data['address'] != null && (data['address'] as List).isNotEmpty) {
            final addr = data['address'][0];
            final street = addr['street']?.toString() ?? '';
            final city = addr['city']?.toString() ?? '';
            final state = addr['state']?.toString() ?? '';
            final lga = addr['lga']?.toString() ?? '';
            final lat = double.tryParse(addr['latitude']?.toString() ?? '');
            final lng = double.tryParse(addr['longitude']?.toString() ?? '');

            if (street.isNotEmpty) {
              _pickupAddress = city.isNotEmpty ? '$street, $city' : street;
              _isLocationLoaded = true;
            }
            if (lat != null && lng != null && lat != 0.0 && lng != 0.0) {
              _pickupLat = lat;
              _pickupLng = lng;
            }

            if (authProvider != null && street.isNotEmpty) {
              authProvider.fillAddress(
                street,
                city,
                addr['postalCode']?.toString() ?? '',
                addr['country']?.toString() ?? 'Nigeria',
                state: state,
                lga: lga,
                latitude: lat,
                longitude: lng,
              );
            }
            notifyListeners();
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading saved location from backend: $e');
    }

    // 3. If address is present but coordinates are default placeholder, geocode the address
    final isLagosPlaceholder = (_pickupLat == 6.4474 && _pickupLng == 3.4723);
    if (isLagosPlaceholder &&
        _pickupAddress.isNotEmpty &&
        !_pickupAddress.contains('Lekki')) {
      try {
        final suggestions =
            await LocationService.searchAddressSuggestions(_pickupAddress);
        if (suggestions.isNotEmpty &&
            suggestions.first.details.latitude != 0.0) {
          _pickupLat = suggestions.first.details.latitude;
          _pickupLng = suggestions.first.details.longitude;
          notifyListeners();
        }
      } catch (_) {}
    }
  }

  void setPickupAddress(String address) {
    _pickupAddress = address;
    notifyListeners();
  }

  void setPickupLocation({
    required String address,
    double? lat,
    double? lng,
  }) {
    _pickupAddress = address;
    if (lat != null && lng != null) {
      _pickupLat = lat;
      _pickupLng = lng;
    }
    notifyListeners();
    initFlowData(lat: _pickupLat, lng: _pickupLng);
  }

  Future<bool> autoDetectLocation() async {
    _isDetectingLocation = true;
    notifyListeners();
    try {
      final details = await LocationService.autoDetectLocation();
      if (details != null) {
        setPickupLocation(
          address: details.formattedAddress,
          lat: details.latitude,
          lng: details.longitude,
        );
        return true;
      }
    } catch (e) {
      debugPrint('Auto-detect location error: $e');
    } finally {
      _isDetectingLocation = false;
      notifyListeners();
    }
    return false;
  }

  // Method Selection
  ScheduleMethod _selectedMethod = ScheduleMethod.letFoamChoose;
  ScheduleMethod get selectedMethod => _selectedMethod;
  void selectMethod(ScheduleMethod method) {
    _selectedMethod = method;
    notifyListeners();
  }

  // Tiers for "Let Foam choose"
  List<ScheduleTier> _tiers = [];
  List<ScheduleTier> get tiers => _tiers;

  String _selectedTierId = 'BALANCED';
  String get selectedTierId => _selectedTierId;
  ScheduleTier get currentTier {
    return _tiers.firstWhere(
      (t) => t.id == _selectedTierId,
      orElse: () => const ScheduleTier(
        id: 'BALANCED',
        title: 'Balanced',
        startingPrice: 500,
        turnaroundDays: 2,
        turnaroundText: 'Ready in 2 days · ★ 4.6 average',
        isMostPicked: true,
      ),
    );
  }

  void selectTier(String tierId) {
    _selectedTierId = tierId;
    notifyListeners();
  }

  // Nearby Stores for "Pick a store"
  List<NearbyStore> _nearbyStores = [];
  List<NearbyStore> get nearbyStores => _nearbyStores;

  String _storeFilter = 'closest'; // closest | top_rated | fastest
  String get storeFilter => _storeFilter;

  NearbyStore? _selectedStore;
  NearbyStore? get selectedStore => _selectedStore;
  bool get hasSelectedStore => _selectedStore != null || _nearbyStores.isNotEmpty;

  NearbyStore get currentStore {
    if (_selectedStore != null) return _selectedStore!;
    if (_nearbyStores.isNotEmpty) return _nearbyStores.first;
    return const NearbyStore(
      id: 0,
      name: 'Laundry Store',
      area: '',
      address: '',
      rating: 5.0,
      distanceKm: 0.0,
      turnaroundDays: 2,
      turnaroundText: '',
      shirtStartingPrice: 0,
    );
  }

  void selectStore(NearbyStore store) {
    _selectedStore = store;
    _selectedTurnaroundDays = store.turnaroundDays;
    notifyListeners();
  }

  // Vendor Turnaround Options & Price Multiplier
  int _selectedTurnaroundDays = 2;
  int get selectedTurnaroundDays => _selectedTurnaroundDays;

  TurnaroundOption? get selectedTurnaroundOption {
    final options = currentStore.effectiveTurnaroundOptions;
    return options.firstWhere(
      (o) => o.days == _selectedTurnaroundDays,
      orElse: () => options.first,
    );
  }

  void selectTurnaroundDays(int days) {
    _selectedTurnaroundDays = days;
    notifyListeners();
  }

  double get turnaroundMultiplier {
    if (_selectedMethod == ScheduleMethod.pickStore) {
      return selectedTurnaroundOption?.priceMultiplier ?? 1.0;
    }
    return 1.0;
  }

  int getItemPrice(ScheduleItem item) {
    if (_selectedMethod == ScheduleMethod.pickStore) {
      return (item.price * turnaroundMultiplier).round();
    }
    return item.price;
  }

  // Items & Quantities
  final List<ScheduleItem> _items = [
    ScheduleItem(id: 1, name: 'Shirt', price: 500, quantity: 4, category: 'Laundry', foldType: 'Folding'),
    ScheduleItem(id: 2, name: 'T-shirt', price: 400, quantity: 2, category: 'Laundry', foldType: 'Folding'),
    ScheduleItem(id: 3, name: 'Trousers', price: 600, quantity: 0, category: 'Laundry', foldType: 'Folding'),
    ScheduleItem(id: 4, name: 'Bedsheet', price: 900, quantity: 0, category: 'Laundry', foldType: 'Folding'),
  ];
  List<ScheduleItem> get items => _items;

  void incrementItem(int itemId) {
    final idx = _items.indexWhere((i) => i.id == itemId);
    if (idx != -1) {
      _items[idx].quantity++;
      notifyListeners();
    }
  }

  void decrementItem(int itemId) {
    final idx = _items.indexWhere((i) => i.id == itemId);
    if (idx != -1 && _items[idx].quantity > 0) {
      _items[idx].quantity--;
      notifyListeners();
    }
  }

  int get totalBasketCount => _items.fold(0, (sum, i) => sum + i.quantity);

  int get itemSubtotal =>
      _items.fold(0, (sum, i) => sum + (getItemPrice(i) * i.quantity));

  int get deliveryFee => 1500;
  int get serviceFee => 300;
  int get grandTotal => itemSubtotal + deliveryFee + serviceFee;

  // Pickup Slot
  String _pickupSlot = 'Today, 3:00 – 4:00 PM';
  String get pickupSlot => _pickupSlot;
  void setPickupSlot(String slot) {
    _pickupSlot = slot;
    notifyListeners();
  }

  // Order & Tracking State
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Map<String, dynamic>? _lastCreatedOrder;
  Map<String, dynamic>? get lastCreatedOrder => _lastCreatedOrder;

  OrderTrackingData? _trackingData;
  OrderTrackingData? get trackingData => _trackingData;

  int _ratingStore = 4;
  int get ratingStore => _ratingStore;
  void setRatingStore(int r) {
    _ratingStore = r;
    notifyListeners();
  }

  int _ratingRider = 5;
  int get ratingRider => _ratingRider;
  void setRatingRider(int r) {
    _ratingRider = r;
    notifyListeners();
  }

  // Tier metadata from dynamic backend calculation
  TierMetadata? _tierMetadata;
  TierMetadata? get tierMetadata => _tierMetadata;
  String get tierSubtitle =>
      _tierMetadata?.computedSubtitle ??
      'Based on 9 live stores within 5 km. Prices are for a shirt, washed and folded.';

  // Load Initial Tiers & Stores
  Future<void> initFlowData(
      {AuthProvider? authProvider, double? lat, double? lng}) async {
    _isLoading = true;
    notifyListeners();

    if (lat == null && lng == null) {
      await loadSavedLocation(authProvider: authProvider);
    }

    final targetLat = lat ?? _pickupLat;
    final targetLng = lng ?? _pickupLng;

    try {
      final fetchedTiers = await CustomerScheduleService.fetchTiers(
        lat: targetLat,
        lng: targetLng,
      );
      final fetchedStores = await CustomerScheduleService.fetchNearbyStores(
        lat: targetLat,
        lng: targetLng,
        filter: _storeFilter,
      );

      _tierMetadata = CustomerScheduleService.latestTierMetadata;
      _tiers = fetchedTiers;
      _nearbyStores = fetchedStores;
      if (_nearbyStores.isNotEmpty) {
        _selectedStore = _nearbyStores.first;
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setStoreFilter(String filter) async {
    _storeFilter = filter;
    _isLoading = true;
    notifyListeners();
    try {
      _nearbyStores = await CustomerScheduleService.fetchNearbyStores(
        lat: _pickupLat,
        lng: _pickupLng,
        filter: filter,
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Create order via Paystack only
  Future<bool> processPaystackOrder({String? paystackRef}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final orderItems = _items
          .map((i) => ScheduleItem(
                id: i.id,
                name: i.name,
                price: getItemPrice(i),
                quantity: i.quantity,
                category: i.category,
                foldType: i.foldType,
                imageUrl: i.imageUrl,
              ))
          .toList();

      final res = await CustomerScheduleService.createScheduleOrderPaystack(
        storeId: currentStore.id,
        tier: _selectedTierId,
        items: orderItems,
        pickupAddress: _pickupAddress,
        pickupTime: _pickupSlot,
        paystackRef: paystackRef,
      );

      if (res['status'] == true && res['order'] != null) {
        _lastCreatedOrder = res['order'] as Map<String, dynamic>;
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Error placing Paystack schedule order: $e');
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  @visibleForTesting
  void setLastCreatedOrderForTest(Map<String, dynamic> order) {
    _lastCreatedOrder = order;
  }

  Future<void> loadTrackingInfo(int orderId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final tracking = await CustomerScheduleService.fetchOrderTracking(orderId);
      if (tracking != null) {
        _trackingData = tracking;
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> submitReview(int orderId, {String? comments}) async {
    _isLoading = true;
    notifyListeners();
    try {
      return await CustomerScheduleService.submitReview(
        orderId: orderId,
        storeRating: _ratingStore,
        riderRating: _ratingRider,
        comments: comments,
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

