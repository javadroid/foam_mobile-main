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

    // 3. Check Hive stored delivery address if available
    try {
      if (!_isLocationLoaded || _pickupAddress.isEmpty) {
        final savedDelivery = HiveClass.getDeliveryDetails();
        final hiveAddress = savedDelivery['address'];
        if (hiveAddress != null && hiveAddress.trim().isNotEmpty) {
          _pickupAddress = hiveAddress.trim();
          _isLocationLoaded = true;
          notifyListeners();
        }
      }
    } catch (_) {}

    // 4. If address is present but coordinates are default placeholder, geocode the address
    final isLagosPlaceholder = (_pickupLat == 6.4474 && _pickupLng == 3.4723);
    if ((isLagosPlaceholder || _pickupLat == 0.0) &&
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

    // 5. If still no saved location, attempt to auto-detect device position
    if (!_isLocationLoaded) {
      try {
        final pos = await LocationService.getCurrentPosition();
        if (pos != null) {
          _pickupLat = pos.latitude;
          _pickupLng = pos.longitude;
          try {
            final details = await LocationService.autoDetectLocation();
            if (details != null && details.formattedAddress.isNotEmpty) {
              _pickupAddress = details.formattedAddress;
            }
          } catch (_) {}
          _isLocationLoaded = true;
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
  bool _isTiersLoading = false;
  bool get isTiersLoading => _isTiersLoading;
  bool _hasTiersLoaded = false;
  bool get hasTiersLoaded => _hasTiersLoaded;

  Future<void> loadTiersAndNearbyStores({bool silent = false}) async {
    if (!silent || !_hasTiersLoaded) {
      _isTiersLoading = true;
      notifyListeners();
    }

    try {
      final fetchedTiers = await CustomerScheduleService.fetchTiers(
        lat: _pickupLat,
        lng: _pickupLng,
      );
      final fetchedStores = await CustomerScheduleService.fetchNearbyStores(
        lat: _pickupLat,
        lng: _pickupLng,
        filter: _storeFilter,
      );

      _tierMetadata = CustomerScheduleService.latestTierMetadata;
      _maxRadiusKm = CustomerScheduleService.latestMaxRadiusKm;
      if (CustomerScheduleService.latestPricingConfig != null) {
        _pricingConfig = CustomerScheduleService.latestPricingConfig!;
      }
      if (fetchedTiers.isNotEmpty) {
        _tiers = fetchedTiers;
      }
      if (fetchedStores.isNotEmpty) {
        _nearbyStores = fetchedStores;
        final validStores =
            _nearbyStores.where((s) => s.distanceKm <= _maxRadiusKm);
        if (validStores.isNotEmpty) {
          if (_selectedStore == null ||
              !validStores.any((s) => s.id == _selectedStore?.id)) {
            _selectedStore = validStores.first;
            _selectedTurnaroundDays = _selectedStore!.turnaroundDays;
          }
        } else {
          _selectedStore = _nearbyStores.first;
          _selectedTurnaroundDays = _selectedStore!.turnaroundDays;
        }
      }
      _hasTiersLoaded = true;
    } catch (e) {
      debugPrint('Error loading tiers and stores: $e');
    } finally {
      _isTiersLoading = false;
      notifyListeners();
    }
  }

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
    if (tierId == 'BEST_VALUE') {
      _selectedTurnaroundDays = 3;
    } else if (tierId == 'BALANCED') {
      _selectedTurnaroundDays = 2;
    } else if (tierId == 'PREMIUM') {
      _selectedTurnaroundDays = 1;
    }

    final matched = currentTier.matchedStore;
    if (matched != null) {
      final found = _nearbyStores.firstWhere(
        (s) => s.id == matched.id.toString(),
        orElse: () => NearbyStore(
          id: matched.id.toString(),
          name: matched.name,
          area: '',
          address: '',
          rating: matched.rating,
          distanceKm: matched.distanceKm,
          turnaroundDays: matched.turnaroundDays,
          turnaroundText: 'Ready in ${matched.turnaroundDays} days',
          shirtStartingPrice: currentTier.startingPrice,
        ),
      );
      _selectedStore = found;
      _selectedTurnaroundDays = found.turnaroundDays;
    } else if (_nearbyStores.isNotEmpty && _selectedStore == null) {
      _selectedStore = _nearbyStores.first;
    }
    notifyListeners();
  }

  // Nearby Stores for "Pick a store"
  List<NearbyStore> _nearbyStores = [];
  List<NearbyStore> get nearbyStores => _nearbyStores;

  String _storeFilter = 'closest'; // closest | top_rated | fastest
  String get storeFilter => _storeFilter;

  NearbyStore? _selectedStore;
  NearbyStore? get selectedStore => _selectedStore;
  bool get hasSelectedStore =>
      _selectedStore != null || _nearbyStores.isNotEmpty;

  NearbyStore get currentStore {
    if (_selectedStore != null) return _selectedStore!;
    if (_nearbyStores.isNotEmpty) return _nearbyStores.first;
    return const NearbyStore(
      id: '',
      name: 'Laundry Store',
      area: '',
      address: '',
      rating: 0.0,
      distanceKm: 0.0,
      turnaroundDays: 2,
      turnaroundText: '',
      shirtStartingPrice: 0,
    );
  }

  Future<void> selectStore(NearbyStore store) async {
    _selectedMethod = ScheduleMethod.pickStore;
    _selectedStore = store;
    _selectedTurnaroundDays = store.turnaroundDays;
    notifyListeners();

    try {
      final catalog = await CustomerScheduleService.fetchStoreCatalog(store.id);
      if (catalog.isNotEmpty) {
        _items.clear();
        _items.addAll(catalog);
        _loadedCatalogStoreIds.add(store.id);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading store catalog: $e');
    }
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
    // Tier mode ("Let Foam choose")
    if (_selectedTierId == 'PREMIUM') return 1.6;
    if (_selectedTierId == 'BEST_VALUE') return 0.75;
    return 1.0;
  }

  PricingConfig _pricingConfig = const PricingConfig();
  PricingConfig get pricingConfig => _pricingConfig;

  int getItemPrice(ScheduleItem item) {
    final basePrice = (item.price * turnaroundMultiplier).round();
    if (item.storeIncludesFolding) {
      // Store includes folding automatically; user is not charged extra
      return basePrice;
    }
    // Store does not include folding for this item; user can choose to add folding
    final foldingExtra =
        (item.userWantsFolding && currentStore.foldingPrice > 0)
            ? currentStore.foldingPrice.round()
            : 0;
    return basePrice + foldingExtra;
  }

  int get storeFoldingTotal {
    return _items.fold(
      0,
      (sum, i) {
        if (!i.storeIncludesFolding &&
            i.userWantsFolding &&
            currentStore.foldingPrice > 0) {
          return sum + (currentStore.foldingPrice.round() * i.quantity);
        }
        return sum;
      },
    );
  }

  void toggleItemFolding(int itemId) {
    final idx = _items.indexWhere((i) => i.id == itemId);
    if (idx != -1) {
      _items[idx].userWantsFolding = !_items[idx].userWantsFolding;
      notifyListeners();
    }
  }

  int get baseItemSubtotal {
    return _items.fold(
      0,
      (sum, i) => sum + ((i.price * turnaroundMultiplier).round() * i.quantity),
    );
  }

  // Service selection: 'Laundry' vs 'Dry cleaning'
  String _selectedService = 'Laundry';
  String get selectedService => _selectedService;

  void selectService(String service) {
    _selectedService = service;
    notifyListeners();
  }

  bool isDryCleaningItem(ScheduleItem item) {
    final cat = item.category.trim().toLowerCase();
    debugPrint('Category: $cat');
    debugPrint('Laundry items: ${item.toJson()}');

    // 1. Direct match on category from store.items[i].category
    if (cat.contains('dry') ||
        cat.contains('dryclean') ||
        cat.contains('dry-clean')) {
      return true;
    }
    return false;
  }

  List<ScheduleItem> get laundryItems => _items.where((i) {
        final check = i.category.toLowerCase().contains('laundry');
        debugPrint('Category12: $check');
        debugPrint('Category122: ${i.category}');
        return check;
      }).toList();

  List<ScheduleItem> get dryCleaningItems => _items
      .where((i) => i.category.toLowerCase().contains('dry cleaning'))
      .toList();

  /// Starting (lowest) price for Laundry items taking the current turnaround multiplier into account
  int get lowestLaundryStartingPrice {
    final list = laundryItems;
    if (list.isNotEmpty) {
      final minBase = list.map((i) => i.price).reduce((a, b) => a < b ? a : b);
      return (minBase * turnaroundMultiplier).round();
    }
    // Fallback to store shirt starting price if catalog items not yet loaded
    final options = currentStore.effectiveTurnaroundOptions;
    final opt = options.firstWhere(
      (o) => o.days == _selectedTurnaroundDays,
      orElse: () => options.first,
    );
    return opt.shirtStartingPrice;
  }

  /// Starting (lowest) price for Dry cleaning items taking the current turnaround multiplier into account
  int get lowestDryCleaningStartingPrice {
    final list = dryCleaningItems;
    if (list.isNotEmpty) {
      final minBase = list.map((i) => i.price).reduce((a, b) => a < b ? a : b);
      return (minBase * turnaroundMultiplier).round();
    }
    // Fallback default for dry cleaning
    return (1500 * turnaroundMultiplier).round();
  }

  bool isDryCleaningService(String service) {
    final s = service.trim().toLowerCase();
    return s.startsWith('dry') ||
        s.contains('dry clean') ||
        s.contains('dryclean');
  }

  List<ScheduleItem> get filteredItems {
    final isDryCleaning = isDryCleaningService(_selectedService);
    return isDryCleaning ? dryCleaningItems : laundryItems;
  }

  // Items & Quantities
  final List<ScheduleItem> _items = [];
  List<ScheduleItem> get items => _items;

  bool _isItemsLoading = false;
  bool get isItemsLoading => _isItemsLoading;
  final Set<String> _loadedCatalogStoreIds = {};

  bool hasCatalogLoaded(String storeId) =>
      _loadedCatalogStoreIds.contains(storeId);

  Future<void> loadStoreCatalog({String? storeId, bool silent = false}) async {
    final targetStoreId = storeId ?? currentStore.id;
    if (targetStoreId.isEmpty) return;

    final hasLoadedBefore = _loadedCatalogStoreIds.contains(targetStoreId);
    if (!silent || !hasLoadedBefore) {
      _isItemsLoading = true;
      notifyListeners();
    }

    try {
      final catalog =
          await CustomerScheduleService.fetchStoreCatalog(targetStoreId);

      if (catalog.isNotEmpty) {
        // Preserve any quantities user already selected
        final existingQuantities = {
          for (final item in _items) item.id: item.quantity
        };
        for (final catItem in catalog) {
          if (existingQuantities.containsKey(catItem.id)) {
            catItem.quantity = existingQuantities[catItem.id]!;
          }
        }
        _items.clear();
        _items.addAll(catalog);
        _loadedCatalogStoreIds.add(targetStoreId);
      }
    } catch (e) {
      debugPrint('Error loading store catalog: $e');
    } finally {
      _isItemsLoading = false;
      notifyListeners();
    }
  }

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

  int get deliveryFee {
    final distance = currentStore.distanceKm;
    final perKm = _pricingConfig.deliveryFeePerKm;
    final base = _pricingConfig.baseDeliveryFee;
    return (base + (distance * perKm)).round();
  }

  int get serviceFee {
    final subtotal = itemSubtotal;
    if (subtotal == 0 || subtotal >= _pricingConfig.serviceFeeThreshold) {
      return _pricingConfig.serviceFeeFixed;
    } else {
      return ((subtotal * _pricingConfig.serviceFeePercentage) / 100).round();
    }
  }

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

  // Admin max search radius (default 21 km)
  double _maxRadiusKm = 21.0;
  double get maxRadiusKm => _maxRadiusKm;

  /// Returns true if at least one store is within admin max radius (default 21km)
  bool get hasStoresWithinMaxRadius =>
      _nearbyStores.any((s) => s.distanceKm <= _maxRadiusKm);

  /// Stores strictly within the admin max radius
  List<NearbyStore> get storesWithinMaxRadius =>
      _nearbyStores.where((s) => s.distanceKm <= _maxRadiusKm).toList();

  /// Stores that are outside the admin max radius (far stores)
  List<NearbyStore> get storesOutsideMaxRadius =>
      _nearbyStores.where((s) => s.distanceKm > _maxRadiusKm).toList();

  /// Check whether a specific store is beyond the max allowed radius
  bool isStoreFar(NearbyStore store) => store.distanceKm > _maxRadiusKm;

  // Tier metadata from dynamic backend calculation
  TierMetadata? _tierMetadata;
  TierMetadata? get tierMetadata => _tierMetadata;
  String get tierSubtitle =>
      _tierMetadata?.computedSubtitle ??
      'Based on live stores within ${_maxRadiusKm.toInt()} km. Prices are for a shirt, washed and folded.';

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
      _maxRadiusKm = CustomerScheduleService.latestMaxRadiusKm;
      _tiers = fetchedTiers;
      _hasTiersLoaded = true;
      _nearbyStores = fetchedStores;
      if (_nearbyStores.isNotEmpty) {
        final validStores =
            _nearbyStores.where((s) => s.distanceKm <= _maxRadiusKm);
        _selectedStore =
            validStores.isNotEmpty ? validStores.first : _nearbyStores.first;
        _selectedTurnaroundDays = _selectedStore!.turnaroundDays;
        try {
          final catalog = await CustomerScheduleService.fetchStoreCatalog(
              _selectedStore!.id);
          if (catalog.isNotEmpty) {
            _items.clear();
            _items.addAll(catalog);
            _loadedCatalogStoreIds.add(_selectedStore!.id);
          }
        } catch (_) {}
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

  /// Create order via verified Paystack payment
  Future<bool> processPaystackOrder({required String paystackRef}) async {
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

      final res = await CustomerScheduleService.createScheduleOrder(
        storeId: currentStore.id,
        tier: _selectedTierId,
        items: orderItems,
        pickupAddress: _pickupAddress,
        pickupTime: _pickupSlot,
        paymentMethod: 'PAYSTACK',
        paystackRef: paystackRef,
        totalPrice: grandTotal,
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

    _lastCreatedOrder = null;
    _isLoading = false;
    notifyListeners();
    return false;
  }

  /// Create order via native Apple Pay (NOT Paystack)
  Future<bool> processApplePayOrder({
    required String token,
    String? reference,
  }) async {
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

      final res = await CustomerScheduleService.createScheduleOrder(
        storeId: currentStore.id,
        tier: _selectedTierId,
        items: orderItems,
        pickupAddress: _pickupAddress,
        pickupTime: _pickupSlot,
        paymentMethod: 'APPLE_PAY',
        token: token,
        reference: reference,
        totalPrice: grandTotal,
      );

      if (res['status'] == true && res['order'] != null) {
        _lastCreatedOrder = res['order'] as Map<String, dynamic>;
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Error placing Apple Pay schedule order: $e');
    }

    _lastCreatedOrder = null;
    _isLoading = false;
    notifyListeners();
    return false;
  }

  /// Create order via native Google Pay
  Future<bool> processGooglePayOrder({
    required String token,
    String? reference,
  }) async {
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

      final res = await CustomerScheduleService.createScheduleOrder(
        storeId: currentStore.id,
        tier: _selectedTierId,
        items: orderItems,
        pickupAddress: _pickupAddress,
        pickupTime: _pickupSlot,
        paymentMethod: 'GOOGLE_PAY',
        token: token,
        reference: reference,
        totalPrice: grandTotal,
      );

      if (res['status'] == true && res['order'] != null) {
        _lastCreatedOrder = res['order'] as Map<String, dynamic>;
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Error placing Google Pay schedule order: $e');
    }

    _lastCreatedOrder = null;
    _isLoading = false;
    notifyListeners();
    return false;
  }

  @visibleForTesting
  void setLastCreatedOrderForTest(Map<String, dynamic> order) {
    _lastCreatedOrder = order;
  }

  Future<void> loadTrackingInfo(String orderId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final tracking =
          await CustomerScheduleService.fetchOrderTracking(orderId);
      if (tracking != null) {
        _trackingData = tracking;
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> submitReview(String orderId, {String? comments}) async {
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
