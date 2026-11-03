import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:foam_mobile/core/hive/hive.dart';
import 'package:foam_mobile/feature/rider/models/rider_models.dart';
import 'package:foam_mobile/feature/rider/views/rider_dashboard_screen.dart';
import 'package:foam_mobile/feature/rider/views/rider_registration_screen.dart';
import 'package:foam_mobile/utils/values.dart';

class RiderProvider extends ChangeNotifier {
  RiderProfile? _currentRider;
  String? _token;
  bool _isLoading = false;
  String? _errorMessage;

  List<AvailableRide> _availableRides = [];
  ActiveRide? _currentActiveRide;
  List<RiderDeliveryHistoryItem> _history = [];
  List<RiderTransactionItem> _transactions = [];
  double _walletBalance = 0.0;

  RiderProfile? get currentRider => _currentRider;
  String? get token => _token;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<AvailableRide> get availableRides => _availableRides;
  ActiveRide? get currentActiveRide => _currentActiveRide;
  List<RiderDeliveryHistoryItem> get history => _history;
  List<RiderTransactionItem> get transactions => _transactions;
  double get walletBalance => _walletBalance;

  bool get isRegistered => _currentRider != null;
  bool get isApproved => _currentRider?.isApproved ?? false;
  bool get isPending => _currentRider?.approvalStatus == 'PENDING';
  bool get isOnline => _currentRider?.isOnline ?? false;

  String get _baseUrl {
    String url = Constants.url;
    // Replace localhost with 10.0.2.2 on Android emulator if needed, or keep standard
    if (kIsWeb) return 'http://127.0.0.1:8545';
    return url;
  }

  Map<String, String> get _authHeaders {
    final activeToken = (_token != null && _token!.isNotEmpty) ? _token! : HiveClass.getToken();
    return {
      'Content-Type': 'application/json',
      if (activeToken.isNotEmpty) 'Authorization': 'Bearer $activeToken',
    };
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void setCurrentRiderForTesting(RiderProfile profile, {String? token}) {
    _currentRider = profile;
    _token = token ?? 'mock_rider_token';
    _walletBalance = profile.walletBalance;
    notifyListeners();
  }

  void setActiveRideForTesting(ActiveRide ride) {
    _currentActiveRide = ride;
    notifyListeners();
  }

  /// Fetch rider profile using active rider or user token
  Future<RiderProfile?> fetchRiderProfile() async {
    try {
      final activeToken = (_token != null && _token!.isNotEmpty) ? _token! : HiveClass.getToken();
      if (activeToken.isEmpty) return null;

      final response = await http
          .get(
            Uri.parse('$_baseUrl/api/rider/profile'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $activeToken',
            },
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['rider'] != null) {
          _currentRider = RiderProfile.fromJson(data['rider']);
          _walletBalance = _currentRider!.walletBalance;
          notifyListeners();
          return _currentRider;
        }
      } else if (response.statusCode == 404) {
        // User is not registered as a rider yet
        _currentRider = null;
        notifyListeners();
        return null;
      }
    } catch (_) {}
    return _currentRider;
  }

  /// Check verification status and navigate appropriately (mirroring checkAndNavigateToVendor)
  Future<void> checkAndNavigateToRider(BuildContext context) async {
    final token = HiveClass.getToken();
    if (token.isEmpty) {
      Navigator.pushNamed(context, '/log_in');
      return;
    }

    // Show lightweight loader
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF00AABC)),
      ),
    );

    await fetchRiderProfile();

    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pop(); // dismiss loader

    if (_currentRider != null) {
      final status = _currentRider!.approvalStatus.toUpperCase();
      if (status == 'APPROVED') {
        Navigator.pushNamed(context, RiderDashboardScreen.id);
      } else if (status == 'PENDING') {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                const Icon(Icons.hourglass_top_rounded, color: Color(0xFFFFA000), size: 28),
                const SizedBox(width: 8),
                Text(
                  'Application Pending',
                  style: GoogleFonts.dmSans(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your rider application has been received and is currently under administrative review.',
                  style: GoogleFonts.dmSans(fontSize: 14, color: const Color(0xFF212828)),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8E1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFFECB3)),
                  ),
                  child: Text(
                    'Once approved by Foam Administrators, dispatch broadcast rides will become available to accept.',
                    style: GoogleFonts.dmSans(fontSize: 12, color: const Color(0xFF795548)),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Dismiss', style: GoogleFonts.dmSans(color: Colors.black54)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00AABC),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pushNamed(context, RiderDashboardScreen.id);
                },
                child: Text(
                  'View Dashboard',
                  style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      } else if (status == 'REJECTED') {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                const Icon(Icons.cancel_rounded, color: Colors.redAccent, size: 28),
                const SizedBox(width: 8),
                Text(
                  'Application Declined',
                  style: GoogleFonts.dmSans(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ],
            ),
            content: Text(
              'Your rider application was not approved. You can review your details and re-apply.',
              style: GoogleFonts.dmSans(fontSize: 14, color: const Color(0xFF212828)),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Close', style: GoogleFonts.dmSans(color: Colors.black54)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00AABC),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pushNamed(context, RiderRegistrationScreen.id);
                },
                child: Text(
                  'Update & Reapply',
                  style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      } else {
        Navigator.pushNamed(context, RiderDashboardScreen.id);
      }
    } else {
      // User is not yet a rider -> Navigate to RiderRegistrationScreen
      Navigator.pushNamed(context, RiderRegistrationScreen.id);
    }
  }

  /// Register a new Rider (or register an existing user as a Rider)
  Future<bool> register({
    required String name,
    required String phone,
    String? email,
    String? password,
    required String vehicleType,
    required String vehiclePlate,
    String? licenseNumber,
    double? coverageLatitude,
    double? coverageLongitude,
    double coverageRadiusKm = 10.0,
    String? coverageRoute,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final headers = _authHeaders;
      final response = await http
          .post(
            Uri.parse('$_baseUrl/api/rider/register'),
            headers: headers,
            body: jsonEncode({
              'name': name.trim(),
              'phone': phone.trim(),
              'email': email?.trim(),
              if (password != null && password.isNotEmpty) 'password': password,
              'vehicleType': vehicleType.toUpperCase(),
              'vehiclePlate': vehiclePlate.trim(),
              'licenseNumber': licenseNumber?.trim(),
              'coverageLatitude': coverageLatitude ?? 4.8633,
              'coverageLongitude': coverageLongitude ?? 7.0292,
              'coverageRadiusKm': coverageRadiusKm,
              if (coverageRoute != null) 'coverageRoute': coverageRoute,
            }),
          )
          .timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        if (data['rider'] != null) {
          _currentRider = RiderProfile.fromJson(data['rider']);
          _token = data['token'];
        }
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = data['error'] ?? 'Registration failed';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      // Local fallback for offline mode
      _currentRider = RiderProfile(
        id: 101,
        name: name,
        phone: phone,
        email: email,
        vehicleType: vehicleType,
        vehiclePlate: vehiclePlate,
        licenseNumber: licenseNumber,
        coverageLatitude: coverageLatitude ?? 4.8633,
        coverageLongitude: coverageLongitude ?? 7.0292,
        coverageRadiusKm: coverageRadiusKm,
        approvalStatus: 'PENDING',
        isOnline: false,
      );
      _token = 'offline_token';
      _isLoading = false;
      notifyListeners();
      return true;
    }
  }

  /// Login Rider
  Future<bool> login(String identifier, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/api/rider/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'identifier': identifier.trim(),
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['status'] == true) {
        _token = data['token'];
        if (data['rider'] != null) {
          _currentRider = RiderProfile.fromJson(data['rider']);
          _walletBalance = _currentRider!.walletBalance;
        }
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = data['error'] ?? 'Invalid credentials';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Network connection failed: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Toggle Online/Offline Status
  Future<bool> toggleOnlineStatus(bool online) async {
    if (_currentRider == null) return false;

    try {
      final response = await http
          .patch(
            Uri.parse('$_baseUrl/api/rider/status'),
            headers: _authHeaders,
            body: jsonEncode({'isOnline': online}),
          )
          .timeout(const Duration(seconds: 6));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['rider'] != null) {
          _currentRider = RiderProfile.fromJson(data['rider']);
        }
      } else {
        // Fallback update
        _currentRider = RiderProfile(
          id: _currentRider!.id,
          name: _currentRider!.name,
          phone: _currentRider!.phone,
          email: _currentRider!.email,
          vehicleType: _currentRider!.vehicleType,
          vehiclePlate: _currentRider!.vehiclePlate,
          licenseNumber: _currentRider!.licenseNumber,
          coverageLatitude: _currentRider!.coverageLatitude,
          coverageLongitude: _currentRider!.coverageLongitude,
          coverageRadiusKm: _currentRider!.coverageRadiusKm,
          approvalStatus: _currentRider!.approvalStatus,
          isOnline: online,
          rating: _currentRider!.rating,
          totalRides: _currentRider!.totalRides,
          walletBalance: _currentRider!.walletBalance,
        );
      }
    } catch (_) {
      // Local offline state update
      _currentRider = RiderProfile(
        id: _currentRider!.id,
        name: _currentRider!.name,
        phone: _currentRider!.phone,
        email: _currentRider!.email,
        vehicleType: _currentRider!.vehicleType,
        vehiclePlate: _currentRider!.vehiclePlate,
        licenseNumber: _currentRider!.licenseNumber,
        coverageLatitude: _currentRider!.coverageLatitude,
        coverageLongitude: _currentRider!.coverageLongitude,
        coverageRadiusKm: _currentRider!.coverageRadiusKm,
        approvalStatus: _currentRider!.approvalStatus,
        isOnline: online,
        rating: _currentRider!.rating,
        totalRides: _currentRider!.totalRides,
        walletBalance: _currentRider!.walletBalance,
      );
    }
    notifyListeners();
    return true;
  }

  /// Update Rider Coverage Area & Radius
  Future<bool> updateCoverage({
    required double latitude,
    required double longitude,
    required double radiusKm,
    String? routeDescription,
  }) async {
    if (_currentRider == null) return false;

    try {
      final response = await http
          .patch(
            Uri.parse('$_baseUrl/api/rider/status'),
            headers: _authHeaders,
            body: jsonEncode({
              'coverageLatitude': latitude,
              'coverageLongitude': longitude,
              'coverageRadiusKm': radiusKm,
              if (routeDescription != null) 'coverageRoute': routeDescription,
            }),
          )
          .timeout(const Duration(seconds: 6));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['rider'] != null) {
          _currentRider = RiderProfile.fromJson(data['rider']);
        }
      } else {
        _currentRider = RiderProfile(
          id: _currentRider!.id,
          name: _currentRider!.name,
          phone: _currentRider!.phone,
          email: _currentRider!.email,
          vehicleType: _currentRider!.vehicleType,
          vehiclePlate: _currentRider!.vehiclePlate,
          licenseNumber: _currentRider!.licenseNumber,
          coverageLatitude: latitude,
          coverageLongitude: longitude,
          coverageRadiusKm: radiusKm,
          approvalStatus: _currentRider!.approvalStatus,
          isOnline: _currentRider!.isOnline,
          rating: _currentRider!.rating,
          totalRides: _currentRider!.totalRides,
          walletBalance: _currentRider!.walletBalance,
        );
      }
    } catch (_) {
      _currentRider = RiderProfile(
        id: _currentRider!.id,
        name: _currentRider!.name,
        phone: _currentRider!.phone,
        email: _currentRider!.email,
        vehicleType: _currentRider!.vehicleType,
        vehiclePlate: _currentRider!.vehiclePlate,
        licenseNumber: _currentRider!.licenseNumber,
        coverageLatitude: latitude,
        coverageLongitude: longitude,
        coverageRadiusKm: radiusKm,
        approvalStatus: _currentRider!.approvalStatus,
        isOnline: _currentRider!.isOnline,
        rating: _currentRider!.rating,
        totalRides: _currentRider!.totalRides,
        walletBalance: _currentRider!.walletBalance,
      );
    }
    notifyListeners();
    if (isApproved) {
      await fetchAvailableRides();
    }
    return true;
  }

  /// Fetch Available Broadcast Rides
  Future<void> fetchAvailableRides() async {
    if (_currentRider == null || !_currentRider!.isApproved) {
      _availableRides = [];
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/api/rider/rides/available'),
            headers: _authHeaders,
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['rides'] is List) {
          _availableRides = (data['rides'] as List)
              .map((r) => AvailableRide.fromJson(r))
              .toList();
        }
      } else {
        _setMockAvailableRides();
      }
    } catch (_) {
      _setMockAvailableRides();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _setMockAvailableRides() {
    _availableRides = [
      AvailableRide(
        id: 201,
        orderNumber: 'FOAM-8491',
        storeName: 'Royal Cleaners - Eneka Junction',
        storeAddress: 'Eneka Roundabout, Port Harcourt',
        pickupAddress: 'Plot 4, Eneka Road, Port Harcourt',
        deliveryAddress: 'Woji Estate Phase 2, Port Harcourt',
        customerName: 'Chidi Okafor',
        customerPhone: '+2348039988771',
        totalPrice: 4200,
        earnings: 2000,
        deliveryFee: 2000,
        distanceKm: 5.2,
        createdAt: DateTime.now(),
      ),
      AvailableRide(
        id: 202,
        orderNumber: 'FOAM-8492',
        storeName: 'Sparkle Fresh Wash',
        storeAddress: '12 Aba Road, Port Harcourt',
        pickupAddress: 'G.R.A Phase 2, Port Harcourt',
        deliveryAddress: 'Rumuola Road, Port Harcourt',
        customerName: 'Amina Mohammed',
        customerPhone: '+2348021122334',
        totalPrice: 3500,
        earnings: 1750,
        deliveryFee: 1750,
        distanceKm: 3.8,
        createdAt: DateTime.now(),
      ),
    ];
  }

  /// Accept an available ride (Atomic concurrency check)
  Future<bool> acceptRide(AvailableRide ride) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/api/rider/rides/${ride.id}/accept'),
            headers: _authHeaders,
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        _currentActiveRide = ActiveRide.fromAvailable(ride);
        _availableRides.removeWhere((r) => r.id == ride.id);
        _isLoading = false;
        notifyListeners();
        return true;
      } else if (response.statusCode == 409) {
        _errorMessage = 'Ride already accepted by another rider!';
        _availableRides.removeWhere((r) => r.id == ride.id);
        _isLoading = false;
        notifyListeners();
        return false;
      } else {
        final data = jsonDecode(response.body);
        _errorMessage = data['error'] ?? 'Failed to accept ride';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (_) {
      // Local fallback for offline demo
      _currentActiveRide = ActiveRide.fromAvailable(ride);
      _availableRides.removeWhere((r) => r.id == ride.id);
      _isLoading = false;
      notifyListeners();
      return true;
    }
  }

  /// Progress ride lifecycle
  /// Stages: EN_ROUTE_TO_STORE, PICKED_UP, OUT_FOR_DELIVERY, DELIVERED
  Future<bool> progressLifecycle(String nextStage, {String? pin}) async {
    if (_currentActiveRide == null) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await http
          .patch(
            Uri.parse(
                '$_baseUrl/api/rider/rides/${_currentActiveRide!.orderId}/lifecycle'),
            headers: _authHeaders,
            body: jsonEncode({
              'stage': nextStage,
              if (pin != null) 'pin': pin.trim(),
            }),
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _currentActiveRide!.stage = nextStage;

        if (nextStage == 'DELIVERED') {
          if (data['newWalletBalance'] != null) {
            _walletBalance = double.tryParse(data['newWalletBalance'].toString()) ?? _walletBalance;
          } else {
            _walletBalance += _currentActiveRide!.earnings;
          }
          // Add to local history
          _history.insert(
            0,
            RiderDeliveryHistoryItem(
              orderId: _currentActiveRide!.orderId,
              orderNumber: _currentActiveRide!.orderNumber,
              date: DateTime.now().toIso8601String(),
              storeName: _currentActiveRide!.storeName,
              pickupAddress: _currentActiveRide!.pickupAddress,
              deliveryAddress: _currentActiveRide!.deliveryAddress,
              distanceKm: 4.5,
              earnings: _currentActiveRide!.earnings,
              totalPrice: 4000,
            ),
          );
        }

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        final data = jsonDecode(response.body);
        _errorMessage = data['error'] ?? 'Failed to update lifecycle';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (_) {
      // Local fallback
      _currentActiveRide!.stage = nextStage;
      if (nextStage == 'DELIVERED') {
        _walletBalance += _currentActiveRide!.earnings;
        _history.insert(
          0,
          RiderDeliveryHistoryItem(
            orderId: _currentActiveRide!.orderId,
            orderNumber: _currentActiveRide!.orderNumber,
            date: DateTime.now().toIso8601String(),
            storeName: _currentActiveRide!.storeName,
            pickupAddress: _currentActiveRide!.pickupAddress,
            deliveryAddress: _currentActiveRide!.deliveryAddress,
            distanceKm: 4.5,
            earnings: _currentActiveRide!.earnings,
            totalPrice: 4000,
          ),
        );
      }
      _isLoading = false;
      notifyListeners();
      return true;
    }
  }

  void finishActiveRide() {
    _currentActiveRide = null;
    notifyListeners();
  }

  /// Fetch past delivery history
  Future<void> fetchHistory() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/api/rider/rides/history'),
            headers: _authHeaders,
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['history'] is List) {
          _history = (data['history'] as List)
              .map((h) => RiderDeliveryHistoryItem.fromJson(h))
              .toList();
        }
      } else {
        _populateMockHistoryIfEmpty();
      }
    } catch (_) {
      _populateMockHistoryIfEmpty();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _populateMockHistoryIfEmpty() {
    if (_history.isEmpty) {
      _history = [
        RiderDeliveryHistoryItem(
          orderId: 101,
          orderNumber: 'FOAM-8412',
          date: DateTime.now().subtract(const Duration(hours: 3)).toIso8601String(),
          storeName: 'Royal Cleaners - Eneka',
          pickupAddress: 'Eneka Roundabout',
          deliveryAddress: 'Plot 12 Eneka Link Road',
          distanceKm: 3.5,
          earnings: 1850,
          totalPrice: 3200,
        ),
        RiderDeliveryHistoryItem(
          orderId: 102,
          orderNumber: 'FOAM-8399',
          date: DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
          storeName: 'Sparkle Fresh Wash',
          pickupAddress: '14 Aba Road',
          deliveryAddress: 'Woji Estate',
          distanceKm: 6.0,
          earnings: 2100,
          totalPrice: 4500,
        ),
      ];
    }
  }

  /// Fetch Wallet balance & transaction history
  Future<void> fetchWallet() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/api/rider/wallet'),
            headers: _authHeaders,
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _walletBalance = (data['walletBalance'] != null)
            ? (double.tryParse(data['walletBalance'].toString()) ?? _walletBalance)
            : _walletBalance;

        if (data['transactions'] is List) {
          _transactions = (data['transactions'] as List)
              .map((t) => RiderTransactionItem.fromJson(t))
              .toList();
        }
      } else {
        _populateMockTransactionsIfEmpty();
      }
    } catch (_) {
      _populateMockTransactionsIfEmpty();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _populateMockTransactionsIfEmpty() {
    if (_walletBalance == 0.0) {
      _walletBalance = 15400.0;
    }
    if (_transactions.isEmpty) {
      _transactions = [
        RiderTransactionItem(
          id: 1,
          type: 'CREDIT',
          amount: 1850,
          description: 'Earnings for Order #FOAM-8412',
          status: 'COMPLETED',
          createdAt: DateTime.now().subtract(const Duration(hours: 3)),
        ),
        RiderTransactionItem(
          id: 2,
          type: 'CREDIT',
          amount: 2100,
          description: 'Earnings for Order #FOAM-8399',
          status: 'COMPLETED',
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
        RiderTransactionItem(
          id: 3,
          type: 'DEBIT',
          amount: 5000,
          description: 'Withdrawal to Access Bank (0123456789)',
          status: 'COMPLETED',
          createdAt: DateTime.now().subtract(const Duration(days: 3)),
        ),
      ];
    }
  }

  /// Request Bank Withdrawal
  Future<bool> requestWithdrawal({
    required double amount,
    required String bankName,
    required String accountNumber,
    required String accountName,
  }) async {
    if (amount <= 0 || amount > _walletBalance) {
      _errorMessage = 'Invalid withdrawal amount';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/api/rider/wallet/withdraw'),
            headers: _authHeaders,
            body: jsonEncode({
              'amount': amount,
              'bankName': bankName.trim(),
              'accountNumber': accountNumber.trim(),
              'accountName': accountName.trim(),
            }),
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['newBalance'] != null) {
          _walletBalance = double.tryParse(data['newBalance'].toString()) ?? (_walletBalance - amount);
        } else {
          _walletBalance -= amount;
        }

        _transactions.insert(
          0,
          RiderTransactionItem(
            id: DateTime.now().millisecondsSinceEpoch,
            type: 'DEBIT',
            amount: amount,
            description: 'Withdrawal to $bankName ($accountNumber)',
            status: 'PENDING',
            createdAt: DateTime.now(),
          ),
        );

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        final data = jsonDecode(response.body);
        _errorMessage = data['error'] ?? 'Withdrawal failed';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (_) {
      // Offline fallback
      _walletBalance -= amount;
      _transactions.insert(
        0,
        RiderTransactionItem(
          id: DateTime.now().millisecondsSinceEpoch,
          type: 'DEBIT',
          amount: amount,
          description: 'Withdrawal to $bankName ($accountNumber)',
          status: 'PENDING',
          createdAt: DateTime.now(),
        ),
      );
      _isLoading = false;
      notifyListeners();
      return true;
    }
  }
}
