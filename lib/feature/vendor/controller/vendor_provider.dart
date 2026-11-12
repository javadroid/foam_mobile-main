import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:foam_mobile/core/hive/hive.dart';
import 'package:foam_mobile/feature/authentication/controller/provider/authprovider.dart';
import 'package:foam_mobile/feature/vendor/models/vendor_models.dart';
import 'package:foam_mobile/utils/values.dart';
import 'package:http/http.dart' as http;
import 'package:foam_mobile/feature/vendor/onboarding/vendor_approved_screen.dart';
import 'package:foam_mobile/feature/vendor/vendor_main_screen.dart';
import 'package:foam_mobile/feature/vendor/onboarding/vendor_pending_verification_screen.dart';
import 'package:foam_mobile/feature/vendor/onboarding/vendor_rejected_screen.dart';
import 'package:foam_mobile/feature/vendor/onboarding/vendor_onboarding_stepper_screen.dart';
import 'package:provider/provider.dart';

class VendorProvider extends ChangeNotifier {
  Timer? _countdownTimer;

  bool _isLoading = false;
  bool get isLoading => _isLoading;
  void setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }

  // Paystack Banks
  List<PaystackBankModel> _paystackBanks = [];
  bool _isLoadingBanks = false;
  List<PaystackBankModel> get paystackBanks => _paystackBanks;
  bool get isLoadingBanks => _isLoadingBanks;

  // Active Store and Stores List (Max stores default 10, configurable by admin)
  int _maxStores = 10;
  int get maxStores => _maxStores;
  bool get canAddStore => _stores.length < _maxStores;

  String? _selectedStoreId;
  final List<VendorStore> _stores = [];

  // KYC Onboarding state

  int _onboardingStep = 0;
  int get onboardingStep => _onboardingStep;
  void setOnboardingStep(int step) {
    _onboardingStep = step;
    notifyListeners();
  }

  String _draftBusinessName = '';
  String get draftBusinessName => _draftBusinessName;
  void setDraftBusinessName(String val) {
    _draftBusinessName = val;
    notifyListeners();
  }

  String _draftOwnerName = '';
  String get draftOwnerName => _draftOwnerName;
  void setDraftOwnerName(String val) {
    _draftOwnerName = val;
    notifyListeners();
  }

  String _draftPhone = '';
  String get draftPhone => _draftPhone;
  void setDraftPhone(String val) {
    _draftPhone = val;
    notifyListeners();
  }

  String _draftEmail = '';
  String get draftEmail => _draftEmail;
  void setDraftEmail(String val) {
    _draftEmail = val;
    notifyListeners();
  }

  String? _lastError;
  String? get lastError => _lastError;

  String? _lastResolveError;
  String? get lastResolveError => _lastResolveError;

  String _parseApiError(http.Response res,
      {String fallback = 'An unexpected error occurred'}) {
    try {
      if (res.body.trim().isEmpty) {
        if (res.statusCode == 401)
          return 'Session expired. Please log in again.';
        if (res.statusCode == 403)
          return 'You do not have permission to perform this action.';
        if (res.statusCode == 404)
          return 'The requested resource was not found.';
        if (res.statusCode >= 500)
          return 'Server error (${res.statusCode}). Please try again shortly.';
        return fallback;
      }

      final body = res.body.trim();
      if (body.startsWith('<html') || body.startsWith('<!DOCTYPE')) {
        return 'Server error (${res.statusCode}). Please try again shortly.';
      }

      final dynamic data = jsonDecode(body);
      if (data is Map) {
        if (data['errors'] != null) {
          if (data['errors'] is List) {
            final list = (data['errors'] as List)
                .map((e) => e is Map
                    ? (e['message'] ?? e['msg'] ?? e['error'] ?? '').toString()
                    : e.toString())
                .where((s) => s.isNotEmpty)
                .toList();
            if (list.isNotEmpty) return list.join('\n');
          } else if (data['errors'] is String) {
            return data['errors'].toString();
          }
        }
        if (data['error'] != null) {
          if (data['error'] is String &&
              (data['error'] as String).trim().isNotEmpty) {
            return data['error'] as String;
          } else if (data['error'] is Map && data['error']['message'] != null) {
            return data['error']['message'].toString();
          }
        }
        if (data['message'] != null) {
          if (data['message'] is String &&
              (data['message'] as String).trim().isNotEmpty) {
            return data['message'] as String;
          } else if (data['message'] is List) {
            final list = (data['message'] as List)
                .map((e) => e.toString())
                .where((s) => s.isNotEmpty)
                .toList();
            if (list.isNotEmpty) return list.join('\n');
          }
        }
        if (data['msg'] != null && data['msg'].toString().trim().isNotEmpty) {
          return data['msg'].toString();
        }
      } else if (data is String && data.trim().isNotEmpty) {
        return data.trim();
      }
    } catch (_) {}
    if (res.statusCode == 401) return 'Session expired. Please log in again.';
    if (res.statusCode >= 500)
      return 'Server error (${res.statusCode}). Please try again shortly.';
    return fallback;
  }

  final VendorKycStatus _kycStatus = VendorKycStatus(
    cacUploaded: false,
    cacFileName: '',
    ownerIdUploaded: false,
    ownerIdFileName: '',
    proofOfAddressUploaded: false,
    proofOfAddressFileName: '',
    bankName: '',
    accountNumber: '',
    accountName: '',
    reviewStatus: 'NOT_STARTED',
  );

  // Orders List
  final List<VendorOrder> _orders = [];

  // Pricing Matrix: StoreId -> ServiceType -> FoldType -> ItemName -> Price
  final Map<String, Map<String, double>> _pricingMap = {};
  final Map<String, bool> _storeFoldingSetting = {};

  // Per-Item Folding Status: StoreId_ServiceType_ItemName -> bool (default: true)
  final Map<String, bool> _itemFoldingMap = {};

  bool isItemFoldingIncluded(String storeId, String service, String item) {
    final key = '${storeId}_${service}_$item';
    return _itemFoldingMap[key] ?? true;
  }

  void setItemFoldingIncluded(String storeId, String service, String item, bool included) {
    final key = '${storeId}_${service}_$item';
    _itemFoldingMap[key] = included;
    notifyListeners();
  }

  // Custom Items added by vendor: StoreId_ServiceType -> List<String>
  final Map<String, List<String>> _customItemsMap = {};

  List<String> getCustomItems(String storeId, String service) {
    final key = '${storeId}_$service';
    return List<String>.from(_customItemsMap[key] ?? []);
  }

  void addCustomItem(String storeId, String service, String item) {
    final key = '${storeId}_$service';
    _customItemsMap.putIfAbsent(key, () => []);
    if (!_customItemsMap[key]!.contains(item)) {
      _customItemsMap[key]!.add(item);
      final itemKey = '${storeId}_${service}_$item';
      _itemFoldingMap[itemKey] = true;
      notifyListeners();
    }
  }

  void removeCustomItem(String storeId, String service, String item) {
    final key = '${storeId}_$service';
    _customItemsMap[key]?.remove(item);
    final itemKey = '${storeId}_${service}_$item';
    _itemFoldingMap.remove(itemKey);
    for (final k in _pricingMap.keys) {
      if (k.startsWith('${storeId}_${service}_')) {
        _pricingMap[k]?.remove(item);
      }
    }
    notifyListeners();
  }

  bool getStoreIncludeFolding(String storeId) {
    return _storeFoldingSetting[storeId] ?? true;
  }

  void setStoreIncludeFolding(String storeId, bool value) {
    _storeFoldingSetting[storeId] = value;
    notifyListeners();
  }

  // Foam Commission Percentage configured by Admin (defaults to 15%)
  double _foamCommissionPercentage = 15.0;
  double get foamCommissionPercentage => _foamCommissionPercentage;

  Future<double> fetchFoamCommission() async {
    try {
      final token = HiveClass.getToken();
      final headers = <String, String>{
        'Accept': 'application/json',
      };
      if (token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
      final res = await http.get(
        Uri.parse('${Constants.url}/api/vendor/commission'),
        headers: headers,
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['commissionPercentage'] != null) {
          _foamCommissionPercentage =
              (data['commissionPercentage'] as num).toDouble();
          notifyListeners();
          return _foamCommissionPercentage;
        }
      }
    } catch (e) {
      debugPrint('Error fetching admin commission: $e');
    }
    return _foamCommissionPercentage;
  }

  // Wallet
  double _availableBalance = 0.0;
  final double _onHoldBalance = 0.0;
  final List<VendorTransactionItem> _transactions = [];

  String? _vendorAvatarUrl;
  String? get vendorAvatarUrl => _vendorAvatarUrl;

  Future<bool> updateVendorProfileImage(String photoUrl) async {
    try {
      final token = HiveClass.getToken();
      if (token.isEmpty) return false;
      final res = await http.put(
        Uri.parse('${Constants.url}/api/user/profile'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'avatarUrl': photoUrl}),
      );
      if (res.statusCode == 200 || res.statusCode == 201) {
        _vendorAvatarUrl = photoUrl;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Error updating vendor profile image: $e');
    }
    return false;
  }

  VendorProvider() {
    _selectedStoreId = _stores.isNotEmpty ? _stores.first.id : null;
    _startCountdownTimer();
    fetchStores();
  }

  void _startCountdownTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      bool changed = false;
      for (final order in _orders) {
        if (order.isNew && order.secondsRemaining > 0) {
          order.secondsRemaining--;
          changed = true;
        }
      }
      if (changed) {
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  // Getters
  List<VendorStore> get stores => _stores;

  void addStore(VendorStore store) {
    _stores.add(store);
    if (_selectedStoreId == null) {
      _selectedStoreId = store.id;
    }
    notifyListeners();
  }

  VendorKycStatus get kycStatus => _kycStatus;
  double get availableBalance => _availableBalance;
  double get onHoldBalance => _onHoldBalance;
  List<VendorTransactionItem> get transactions => _transactions;

  VendorStore get currentStore {
    if (_stores.isEmpty) {
      return VendorStore(
        id: 'store_default',
        name: 'My Store',
        address: 'No address set',
        status: 'DRAFT',
        rating: 0.0,
        itemsPricedCount: 0,
        totalItems: 0,
        hoursMonFri: '8:00 AM – 6:00 PM',
        hoursSat: '9:00 AM – 5:00 PM',
        hoursSun: 'Closed',
      );
    }
    if (_selectedStoreId == null) return _stores.first;
    return _stores.firstWhere(
      (s) => s.id == _selectedStoreId,
      orElse: () => _stores.first,
    );
  }

  int getNewOrdersCount(String storeId) {
    return _orders.where((o) => o.isNew && o.storeId == storeId).length;
  }

  int getActiveOrdersCount(String storeId) {
    return _orders.where((o) => o.isActive && o.storeId == storeId).length;
  }

  List<VendorOrder> get newOrders =>
      _orders.where((o) => o.isNew && o.storeId == currentStore.id).toList();

  List<VendorOrder> get activeOrders =>
      _orders.where((o) => o.isActive && o.storeId == currentStore.id).toList();

  List<VendorOrder> get doneOrders =>
      _orders.where((o) => o.isDone && o.storeId == currentStore.id).toList();

  double get todayNetEarnings {
    return _orders
        .where((o) => o.storeId == currentStore.id && (o.isActive || o.isDone))
        .fold(0.0, (sum, o) => sum + o.vendorEarnings);
  }

  int get inProgressOrdersCount => activeOrders.length;

  // Actions
  void switchStore(String storeId) {
    _selectedStoreId = storeId;
    notifyListeners();
  }

  void toggleStoreLive(String storeId) {
    final idx = _stores.indexWhere((s) => s.id == storeId);
    if (idx != -1) {
      final store = _stores[idx];
      store.status = store.isLive ? 'PAUSED' : 'LIVE';
    } else {
      _stores.add(VendorStore(
        id: storeId,
        name: 'Main Store',
        address: 'No address set',
        status: 'LIVE',
        rating: 0.0,
        itemsPricedCount: 0,
        totalItems: 0,
        hoursMonFri: '8:00 AM – 6:00 PM',
        hoursSat: '9:00 AM – 5:00 PM',
        hoursSun: 'Closed',
      ));
      _selectedStoreId = storeId;
    }
    notifyListeners();
  }

  void updateStoreHours({
    required String storeId,
    required String monFri,
    required String sat,
    required String sun,
  }) {
    final idx = _stores.indexWhere((s) => s.id == storeId);
    if (idx != -1) {
      _stores[idx].hoursMonFri = monFri;
      _stores[idx].hoursSat = sat;
      _stores[idx].hoursSun = sun;
    } else {
      _stores.add(VendorStore(
        id: storeId,
        name: 'Main Store',
        address: 'No address set',
        status: 'DRAFT',
        rating: 0.0,
        itemsPricedCount: 0,
        totalItems: 0,
        hoursMonFri: monFri,
        hoursSat: sat,
        hoursSun: sun,
      ));
      _selectedStoreId = storeId;
    }
    notifyListeners();
  }

  void updateStoreAddress({
    required String storeId,
    required String address,
    required double lat,
    required double lng,
    String? name,
    String? photoUrl,
  }) {
    final idx = _stores.indexWhere((s) => s.id == storeId);
    if (idx != -1) {
      _stores[idx] = VendorStore(
        id: _stores[idx].id,
        name: name ?? _stores[idx].name,
        address: address,
        status: _stores[idx].status,
        rating: _stores[idx].rating,
        itemsPricedCount: _stores[idx].itemsPricedCount,
        totalItems: _stores[idx].totalItems,
        hoursMonFri: _stores[idx].hoursMonFri,
        hoursSat: _stores[idx].hoursSat,
        hoursSun: _stores[idx].hoursSun,
        latitude: lat,
        longitude: lng,
        photoUrl: photoUrl ?? _stores[idx].photoUrl,
      );
    } else {
      _stores.add(VendorStore(
        id: storeId,
        name: name ?? 'Main Store',
        address: address,
        status: 'DRAFT',
        rating: 0.0,
        itemsPricedCount: 0,
        totalItems: 0,
        hoursMonFri: '8:00 AM – 6:00 PM',
        hoursSat: '9:00 AM – 5:00 PM',
        hoursSun: 'Closed',
        latitude: lat,
        longitude: lng,
        photoUrl: photoUrl,
      ));
      _selectedStoreId = storeId;
    }
    notifyListeners();
  }

  void acceptOrder(String orderId) {
    final idx = _orders.indexWhere((o) => o.id == orderId);
    if (idx != -1) {
      _orders[idx].status = 'ACCEPTED';
      notifyListeners();
    }
  }

  void declineOrder(String orderId, String reason) {
    final idx = _orders.indexWhere((o) => o.id == orderId);
    if (idx != -1) {
      _orders.removeAt(idx);
      notifyListeners();
    }
  }

  void updateOrderStatus(String orderId, String nextStatus) {
    final idx = _orders.indexWhere((o) => o.id == orderId);
    if (idx != -1) {
      _orders[idx].status = nextStatus;
      if (nextStatus == 'READY') {
        _orders[idx].readyAt = 'Just now';
      } else if (nextStatus == 'COMPLETED') {
        _availableBalance += _orders[idx].vendorEarnings;
        _transactions.insert(
          0,
          VendorTransactionItem(
            id: 'tx_${DateTime.now().millisecondsSinceEpoch}',
            title: 'Order ${_orders[idx].id}',
            subtitle: '${currentStore.name} · Today',
            amount: _orders[idx].vendorEarnings,
            isCredit: true,
            dateString: 'Today',
          ),
        );
      }
      notifyListeners();
    }
  }

  Map<String, double> getItemPrices(
      String storeId, String service, String foldType) {
    final key = '${storeId}_${service}_$foldType';
    if (_pricingMap.containsKey(key) && _pricingMap[key]!.isNotEmpty) {
      return _pricingMap[key]!;
    }
    final foldKey = '${storeId}_${service}_Folding';
    if (_pricingMap.containsKey(foldKey) && _pricingMap[foldKey]!.isNotEmpty) {
      return _pricingMap[foldKey]!;
    }
    final nonFoldKey = '${storeId}_${service}_Non-folding';
    if (_pricingMap.containsKey(nonFoldKey) && _pricingMap[nonFoldKey]!.isNotEmpty) {
      return _pricingMap[nonFoldKey]!;
    }
    final stdKey = '${storeId}_${service}_Standard';
    if (_pricingMap.containsKey(stdKey) && _pricingMap[stdKey]!.isNotEmpty) {
      return _pricingMap[stdKey]!;
    }
    return {};
  }

  void setItemPrice(String storeId, String service, String foldType,
      String item, double price) {
    final key = '${storeId}_${service}_$foldType';
    if (!_pricingMap.containsKey(key)) {
      _pricingMap[key] = {};
    }
    _pricingMap[key]![item] = price;

    // Recalculate total items priced for this store
    int totalPriced = 0;
    for (final k in _pricingMap.keys) {
      if (k.startsWith('${storeId}_')) {
        totalPriced += _pricingMap[k]!.length;
      }
    }
    final idx = _stores.indexWhere((s) => s.id == storeId);
    if (idx != -1) {
      _stores[idx].itemsPricedCount = totalPriced;
    }

    notifyListeners();
  }

  Future<bool> saveStorePricing({
    required String storeId,
    required String serviceType,
    required Map<String, double> itemPrices,
    required Map<String, bool> itemFolding,
  }) async {
    // 1. Update local cache
    for (final entry in itemPrices.entries) {
      final item = entry.key;
      final price = entry.value;
      final isFolding = itemFolding[item] ?? true;

      setItemPrice(storeId, serviceType, 'Folding', item, price);
      setItemPrice(storeId, serviceType, 'Non-folding', item, price);
      setItemPrice(storeId, serviceType, 'Standard', item, price);
      setItemFoldingIncluded(storeId, serviceType, item, isFolding);
    }

    // 2. Sync to Backend if connected
    try {
      final token = HiveClass.getToken();
      if (token.isNotEmpty && int.tryParse(storeId) != null) {
        final backendServiceType =
            serviceType == 'Dry cleaning' ? 'DRY_CLEANING' : 'LAUNDRY';
        final itemsPayload = itemPrices.entries.map((entry) {
          final isFolding = itemFolding[entry.key] ?? true;
          return {
            'serviceType': backendServiceType,
            'foldType': isFolding ? 'FOLDING' : 'NON_FOLDING',
            'itemName': entry.key,
            'price': entry.value,
          };
        }).toList();

        final res = await http.put(
          Uri.parse('${Constants.url}/api/vendor/stores/$storeId/pricing'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({'items': itemsPayload}),
        );
        return res.statusCode == 200;
      }
    } catch (e) {
      debugPrint('Error syncing store pricing to backend: $e');
    }
    return true;
  }

  bool withdraw(double amount, String ref) {
    if (amount > 0 && amount <= _availableBalance) {
      _availableBalance -= amount;
      final bank =
          _kycStatus.bankName.isNotEmpty ? _kycStatus.bankName : 'Bank';
      final acc = _kycStatus.accountNumber;
      final last4 = acc.length >= 4 ? acc.substring(acc.length - 4) : '••••';
      _transactions.insert(
        0,
        VendorTransactionItem(
          id: ref,
          title: 'Withdrawal',
          subtitle: '$bank •••• $last4 · Today',
          amount: amount,
          isCredit: false,
          dateString: 'Today',
        ),
      );
      notifyListeners();
      return true;
    }
    return false;
  }

  void setKycDocument(String docType, String fileName, {String? url}) {
    if (docType == 'CAC') {
      _kycStatus.cacUploaded = true;
      _kycStatus.cacFileName = fileName;
      if (url != null) _kycStatus.cacUrl = url;
    } else if (docType == 'OWNER_ID') {
      _kycStatus.ownerIdUploaded = true;
      _kycStatus.ownerIdFileName = fileName;
      if (url != null) _kycStatus.ownerIdUrl = url;
    } else if (docType == 'ADDRESS') {
      _kycStatus.proofOfAddressUploaded = true;
      _kycStatus.proofOfAddressFileName = fileName;
      if (url != null) _kycStatus.proofOfAddressUrl = url;
    }
    notifyListeners();
  }

  void removeKycDocument(String docType) {
    if (docType == 'CAC') {
      _kycStatus.cacUploaded = false;
      _kycStatus.cacFileName = '';
      _kycStatus.cacUrl = null;
    } else if (docType == 'OWNER_ID') {
      _kycStatus.ownerIdUploaded = false;
      _kycStatus.ownerIdFileName = '';
      _kycStatus.ownerIdUrl = null;
    } else if (docType == 'ADDRESS') {
      _kycStatus.proofOfAddressUploaded = false;
      _kycStatus.proofOfAddressFileName = '';
      _kycStatus.proofOfAddressUrl = null;
    }
    notifyListeners();
  }

  /// Submit KYC documents to backend
  Future<bool> submitKyc({String? businessName}) async {
    try {
      final token = HiveClass.getToken();
      final res = await http.post(
        Uri.parse('${Constants.url}/api/vendor/kyc'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'businessName': businessName,
          'cacDocUrl': _kycStatus.cacUrl,
          'ownerIdDocUrl': _kycStatus.ownerIdUrl,
          'proofOfAddressDocUrl': _kycStatus.proofOfAddressUrl,
        }),
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        _kycStatus.reviewStatus = 'PENDING';
        notifyListeners();
        return true;
      } else {
        debugPrint('Submit KYC failed (${res.statusCode}): ${res.body}');
      }
    } catch (e) {
      debugPrint('Error submitting KYC: $e');
    }
    return false;
  }

  void setKycBank({
    required String bankName,
    required String accountNumber,
    required String accountName,
  }) {
    _kycStatus.bankName = bankName;
    _kycStatus.accountNumber = accountNumber;
    _kycStatus.accountName = accountName;
    _kycStatus.reviewStatus = 'PENDING';
    notifyListeners();
  }

  /// Fetch Nigerian banks from Paystack API
  Future<List<PaystackBankModel>> fetchPaystackBanks() async {
    if (_paystackBanks.isNotEmpty) return _paystackBanks;
    _isLoadingBanks = true;
    notifyListeners();

    try {
      final res = await http.get(
        Uri.parse('${Constants.url}/api/payment/banks'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['banks'] is List) {
          _paystackBanks = (data['banks'] as List)
              .map((b) => PaystackBankModel.fromJson(b))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('Error fetching Paystack banks: $e');
    } finally {
      _isLoadingBanks = false;
      notifyListeners();
    }
    return _paystackBanks;
  }

  /// Resolve and verify account number with bank code via Paystack
  Future<String?> resolvePaystackAccount({
    required String accountNumber,
    required String bankCode,
  }) async {
    _lastResolveError = null;
    try {
      final uri = Uri.parse(
        '${Constants.url}/api/payment/resolve-account?account_number=${accountNumber.trim()}&bank_code=${bankCode.trim()}',
      );
      final res = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));

      final data = jsonDecode(res.body);
      if (res.statusCode == 200 && data['status'] == true) {
        return data['accountName'] as String?;
      } else {
        _lastResolveError = data['error']?.toString() ??
            data['message']?.toString() ??
            'Could not verify account details with Paystack.';
        debugPrint('Paystack resolve response: $_lastResolveError');
      }
    } catch (e) {
      debugPrint('Error resolving Paystack account: $e');
      final str = e.toString().toLowerCase();
      if (str.contains('socketexception')) {
        _lastResolveError = 'Network error: please check your connection.';
      } else if (str.contains('timeoutexception')) {
        _lastResolveError = 'Verification timed out. Please retry.';
      } else {
        _lastResolveError = 'Could not verify account details with Paystack.';
      }
    }
    return null;
  }

  /// Persist payout bank to backend database
  Future<bool> savePayoutBank({
    required String bankName,
    required String bankCode,
    required String accountNumber,
    required String accountName,
  }) async {
    try {
      final token = HiveClass.getToken();
      final res = await http.patch(
        Uri.parse('${Constants.url}/api/vendor/payout-bank'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'bankName': bankName,
          'bankCode': bankCode,
          'bankAccountNumber': accountNumber,
          'bankAccountName': accountName,
        }),
      );

      if (res.statusCode == 200) {
        _kycStatus.bankName = bankName;
        _kycStatus.accountNumber = accountNumber;
        _kycStatus.accountName = accountName;
        _kycStatus.reviewStatus = 'PENDING';
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Error saving payout bank: $e');
    }
    return false;
  }

  VendorStore _parseStoreJson(Map<String, dynamic> json) {
    String monFri = '8:00 AM – 6:00 PM';
    String sat = '9:00 AM – 5:00 PM';
    String sun = 'Closed';

    Map<String, dynamic>? hoursMap;
    if (json['operatingHours'] != null) {
      if (json['operatingHours'] is Map<String, dynamic>) {
        hoursMap = json['operatingHours'] as Map<String, dynamic>;
        monFri = hoursMap['monFri']?.toString() ?? monFri;
        sat = hoursMap['sat']?.toString() ?? sat;
        sun = hoursMap['sun']?.toString() ?? sun;
      } else if (json['operatingHours'] is Map) {
        hoursMap = Map<String, dynamic>.from(json['operatingHours'] as Map);
        monFri = hoursMap['monFri']?.toString() ?? monFri;
        sat = hoursMap['sat']?.toString() ?? sat;
        sun = hoursMap['sun']?.toString() ?? sun;
      } else if (json['operatingHours'] is String) {
        monFri = json['operatingHours'].toString();
      }
    }

    int pricedCount = 0;
    if (json['pricing'] is List) {
      pricedCount = (json['pricing'] as List).length;
    }

    double basicPct = 0;
    double balancePct = 15;
    double premiumPct = 35;
    List<dynamic>? turnaroundOptions;

    if (json['turnaroundOptions'] is List) {
      turnaroundOptions = json['turnaroundOptions'] as List;
      for (final opt in turnaroundOptions) {
        if (opt is Map) {
          final pkg = (opt['package'] ?? opt['name'])?.toString().toUpperCase();
          final pct = (opt['percentage'] is num) ? (opt['percentage'] as num).toDouble() : null;
          if (pct != null) {
            if (pkg == 'BASIC') basicPct = pct;
            if (pkg == 'BALANCE') balancePct = pct;
            if (pkg == 'PREMIUM') premiumPct = pct;
          }
        }
      }
    }

    return VendorStore(
      id: json['id']?.toString() ??
          'store_${DateTime.now().millisecondsSinceEpoch}',
      name: json['name']?.toString() ?? 'Branch Store',
      address: json['address']?.toString() ?? 'No address set',
      status: json['status']?.toString() ?? 'LIVE',
      rating:
          (json['rating'] is num) ? (json['rating'] as num).toDouble() : 4.8,
      itemsPricedCount: pricedCount,
      totalItems: 28,
      hoursMonFri: monFri,
      hoursSat: sat,
      hoursSun: sun,
      operatingHoursMap: hoursMap,
      latitude: (json['latitude'] is num)
          ? (json['latitude'] as num).toDouble()
          : null,
      longitude: (json['longitude'] is num)
          ? (json['longitude'] as num).toDouble()
          : null,
      photoUrl: json['photoUrl']?.toString(),
      turnaroundDays: (json['turnaroundDays'] is num)
          ? (json['turnaroundDays'] as num).toInt()
          : 2,
      turnaroundOptions: turnaroundOptions,
      basicPercentage: basicPct,
      balancePercentage: balancePct,
      premiumPercentage: premiumPct,
    );
  }

  /// Fetch stores belonging to vendor from backend, including maxStores limit
  Future<void> fetchStores() async {
    try {
      final token = HiveClass.getToken();
      if (token.isEmpty) return;

      final res = await http.get(
        Uri.parse('${Constants.url}/api/vendor/stores'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['maxStores'] is num) {
          _maxStores = (data['maxStores'] as num).toInt();
        }
        if (data['stores'] is List) {
          final List<dynamic> list = data['stores'];
          _stores.clear();
          for (final item in list) {
            if (item is Map<String, dynamic>) {
              _stores.add(_parseStoreJson(item));
            }
          }
          if (_stores.isNotEmpty &&
              (_selectedStoreId == null ||
                  !_stores.any((s) => s.id == _selectedStoreId))) {
            _selectedStoreId = _stores.first.id;
          }
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Error fetching stores: $e');
    }
  }

  /// Create a new store (validating maxStores limit)
  Future<Map<String, dynamic>> createStore({
    required String name,
    required String address,
    required double lat,
    required double lng,
    String? photoUrl,
    String monFri = '8:00 AM – 6:00 PM',
    String sat = '9:00 AM – 5:00 PM',
    String sun = 'Closed',
    int turnaroundDays = 2,
    Map<String, dynamic>? operatingHours,
    List<Map<String, dynamic>>? turnaroundOptions,
  }) async {
    if (!canAddStore) {
      return {
        'success': false,
        'message':
            'Store limit reached. You can have a maximum of $_maxStores stores. Contact admin to increase your store capacity.',
      };
    }

    _isLoading = true;
    notifyListeners();

    try {
      final token = HiveClass.getToken();
      final res = await http.post(
        Uri.parse('${Constants.url}/api/vendor/stores'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'name': name,
          'address': address,
          'latitude': lat,
          'longitude': lng,
          'photoUrl': photoUrl,
          'turnaroundDays': turnaroundDays,
          'operatingHours': operatingHours ?? {
            'monFri': monFri,
            'sat': sat,
            'sun': sun,
          },
          if (turnaroundOptions != null) 'turnaroundOptions': turnaroundOptions,
        }),
      );

      final data = jsonDecode(res.body);
      if (res.statusCode == 201 && data['store'] != null) {
        final newStore = _parseStoreJson(data['store'] as Map<String, dynamic>);
        _stores.add(newStore);
        _selectedStoreId = newStore.id;
        _isLoading = false;
        notifyListeners();
        return {'success': true, 'store': newStore};
      } else {
        _isLoading = false;
        notifyListeners();
        return {
          'success': false,
          'message':
              data['error'] ?? data['message'] ?? 'Failed to create store',
        };
      }
    } catch (e) {
      // Local fallback
      final newStore = VendorStore(
        id: 'store_${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        address: address,
        status: 'LIVE',
        latitude: lat,
        longitude: lng,
        photoUrl: photoUrl,
        hoursMonFri: monFri,
        hoursSat: sat,
        hoursSun: sun,
        operatingHoursMap: operatingHours,
        turnaroundDays: turnaroundDays,
        turnaroundOptions: turnaroundOptions,
      );
      _stores.add(newStore);
      _selectedStoreId = newStore.id;
      _isLoading = false;
      notifyListeners();
      return {'success': true, 'store': newStore};
    }
  }

  /// Update an existing store branch profile
  Future<Map<String, dynamic>> updateStoreDetails({
    required String storeId,
    required String name,
    required String address,
    required double lat,
    required double lng,
    String? photoUrl,
    String monFri = '8:00 AM – 6:00 PM',
    String sat = '9:00 AM – 5:00 PM',
    String sun = 'Closed',
    int turnaroundDays = 2,
    Map<String, dynamic>? operatingHours,
    List<Map<String, dynamic>>? turnaroundOptions,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final token = HiveClass.getToken();
      final res = await http.put(
        Uri.parse('${Constants.url}/api/vendor/stores/$storeId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'name': name,
          'address': address,
          'latitude': lat,
          'longitude': lng,
          'photoUrl': photoUrl,
          'turnaroundDays': turnaroundDays,
          'operatingHours': operatingHours ?? {
            'monFri': monFri,
            'sat': sat,
            'sun': sun,
          },
          if (turnaroundOptions != null) 'turnaroundOptions': turnaroundOptions,
        }),
      );

      final data = jsonDecode(res.body);
      if (res.statusCode == 200 && data['store'] != null) {
        final updatedStore =
            _parseStoreJson(data['store'] as Map<String, dynamic>);
        final idx = _stores.indexWhere((s) => s.id == storeId);
        if (idx != -1) {
          _stores[idx] = updatedStore;
        } else {
          _stores.add(updatedStore);
        }
        _isLoading = false;
        notifyListeners();
        return {'success': true, 'store': updatedStore};
      }
    } catch (e) {
      debugPrint('Error updating store via API: $e');
    }

    // Local update
    updateStoreAddress(
      storeId: storeId,
      name: name,
      address: address,
      lat: lat,
      lng: lng,
      photoUrl: photoUrl,
    );
    updateStoreHours(
      storeId: storeId,
      monFri: monFri,
      sat: sat,
      sun: sun,
    );
    _isLoading = false;
    notifyListeners();
    return {'success': true, 'store': currentStore};
  }

  /// Fetch vendor profile from backend, including onboarding and KYC progress
  Future<Map<String, dynamic>?> fetchVendorProfile() async {
    try {
      final token = HiveClass.getToken();
      if (token.isEmpty) return null;

      final res = await http.get(
        Uri.parse('${Constants.url}/api/vendor/profile'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);

        _draftBusinessName = data['businessName']?.toString() ?? '';
        _vendorAvatarUrl = data['avatarUrl']?.toString();
        final firstName = data['firstName']?.toString() ?? '';
        final lastName = data['lastName']?.toString() ?? '';
        _draftOwnerName = '$firstName $lastName'.trim();
        _draftPhone = data['phone']?.toString() ?? '';
        _draftEmail = data['email']?.toString() ?? '';

        final rawStatus =
            data['vendorStatus']?.toString().toUpperCase() ?? 'NOT_STARTED';
        final role = data['role']?.toString().toUpperCase() ?? 'USER';
        final bool hasDocs = (data['documents'] is Map &&
            ((data['documents']['cacDocUrl']?.toString().isNotEmpty ?? false) ||
                (data['documents']['ownerIdDocUrl']?.toString().isNotEmpty ??
                    false)));
        final bool hasBank = (data['bankDetails'] is Map &&
            (data['bankDetails']['accountNumber']?.toString().isNotEmpty ??
                false));

        String vendorStatus = rawStatus;
        if (role != 'VENDOR' &&
            rawStatus != 'APPROVED' &&
            rawStatus != 'REJECTED' &&
            !hasDocs &&
            !hasBank) {
          vendorStatus = 'NOT_STARTED';
        }
        _kycStatus.reviewStatus = vendorStatus;
        _kycStatus.rejectionReason = data['rejectionReason']?.toString();

        if (data['documents'] is Map) {
          final docs = data['documents'];
          if (docs['cacDocUrl'] != null &&
              docs['cacDocUrl'].toString().isNotEmpty) {
            _kycStatus.cacUploaded = true;
            _kycStatus.cacUrl = docs['cacDocUrl'].toString();
            _kycStatus.cacFileName = 'CAC_Certificate.pdf';
          }
          if (docs['ownerIdDocUrl'] != null &&
              docs['ownerIdDocUrl'].toString().isNotEmpty) {
            _kycStatus.ownerIdUploaded = true;
            _kycStatus.ownerIdUrl = docs['ownerIdDocUrl'].toString();
            _kycStatus.ownerIdFileName = 'Owner_ID.pdf';
          }
          if (docs['proofOfAddressDocUrl'] != null &&
              docs['proofOfAddressDocUrl'].toString().isNotEmpty) {
            _kycStatus.proofOfAddressUploaded = true;
            _kycStatus.proofOfAddressUrl =
                docs['proofOfAddressDocUrl'].toString();
            _kycStatus.proofOfAddressFileName = 'Proof_Of_Address.pdf';
          }
        }

        if (data['bankDetails'] is Map) {
          final bank = data['bankDetails'];
          if (bank['bankName'] != null &&
              bank['bankName'].toString().isNotEmpty) {
            _kycStatus.bankName = bank['bankName'].toString();
            _kycStatus.bankCode = bank['bankCode']?.toString() ?? '';
            _kycStatus.accountNumber = bank['accountNumber']?.toString() ?? '';
            _kycStatus.accountName = bank['accountName']?.toString() ?? '';
          }
        }

        // Determine resume step based on completed sections
        if (_kycStatus.bankName.isNotEmpty &&
            _kycStatus.accountNumber.isNotEmpty) {
          _onboardingStep = 2;
        } else if (_kycStatus.cacUploaded ||
            _kycStatus.ownerIdUploaded ||
            _kycStatus.proofOfAddressUploaded) {
          _onboardingStep = 1;
        } else {
          _onboardingStep = 0;
        }

        notifyListeners();
        return data;
      }
    } catch (e) {
      debugPrint('Error fetching vendor profile: $e');
    }
    return null;
  }

  /// Save onboarding draft to backend
  Future<bool> saveOnboardingDraft({
    String? businessName,
    String? ownerName,
    String? phone,
    bool isFinalSubmit = false,
  }) async {
    _lastError = null;
    try {
      final token = HiveClass.getToken();
      if (token.isEmpty) {
        _lastError = 'You must be logged in to save onboarding draft.';
        return false;
      }

      String? firstName;
      String? lastName;
      final resolvedOwnerName = ownerName ?? _draftOwnerName;
      if (resolvedOwnerName.isNotEmpty) {
        final parts = resolvedOwnerName.trim().split(' ');
        firstName = parts.first;
        lastName = parts.length > 1 ? parts.sublist(1).join(' ') : 'Vendor';
      }

      final payload = <String, dynamic>{
        'businessName': businessName ?? _draftBusinessName,
        if (firstName != null) 'firstName': firstName,
        if (lastName != null) 'lastName': lastName,
        if (phone != null || _draftPhone.isNotEmpty)
          'phone': phone ?? _draftPhone,
        if (_kycStatus.cacUrl != null) 'cacDocUrl': _kycStatus.cacUrl,
        if (_kycStatus.ownerIdUrl != null)
          'ownerIdDocUrl': _kycStatus.ownerIdUrl,
        if (_kycStatus.proofOfAddressUrl != null)
          'proofOfAddressDocUrl': _kycStatus.proofOfAddressUrl,
        if (_kycStatus.bankName.isNotEmpty) 'bankName': _kycStatus.bankName,
        if (_kycStatus.bankCode.isNotEmpty) 'bankCode': _kycStatus.bankCode,
        if (_kycStatus.accountNumber.isNotEmpty)
          'bankAccountNumber': _kycStatus.accountNumber,
        if (_kycStatus.accountName.isNotEmpty)
          'bankAccountName': _kycStatus.accountName,
        'isFinalSubmit': isFinalSubmit,
      };

      final res = await http
          .post(
            Uri.parse('${Constants.url}/api/vendor/onboarding/draft'),
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 20));

      if (res.statusCode == 200 || res.statusCode == 201) {
        if (businessName != null) _draftBusinessName = businessName;
        if (ownerName != null) _draftOwnerName = ownerName;
        if (phone != null) _draftPhone = phone;
        if (isFinalSubmit) {
          _kycStatus.reviewStatus = 'PENDING';
        }
        notifyListeners();
        return true;
      } else {
        _lastError =
            _parseApiError(res, fallback: 'Failed to save onboarding draft.');
      }
    } catch (e) {
      debugPrint('Error saving onboarding draft: $e');
      final str = e.toString().toLowerCase();
      if (str.contains('socketexception') ||
          str.contains('network is unreachable')) {
        _lastError =
            'Unable to connect. Please check your internet connection.';
      } else if (str.contains('timeoutexception')) {
        _lastError = 'Connection timed out. Please try again.';
      } else {
        _lastError =
            'Error: ${e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '')}';
      }
    }
    return false;
  }

  /// Check verification status and navigate appropriately
  Future<void> checkAndNavigateToVendor(BuildContext context) async {
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
        child: CircularProgressIndicator(),
      ),
    );

    await fetchVendorProfile();
    await fetchStores();

    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pop(); // dismiss loader

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final status = _kycStatus.reviewStatus.toUpperCase();

    // Check if the vendor is approved, actively in review, or starting onboarding
    if (status == 'APPROVED') {
      if (_stores.isEmpty) {
        Navigator.pushNamed(context, VendorApprovedScreen.id);
      } else {
        Navigator.pushNamed(context, VendorMainScreen.id);
      }
    } else if (status == 'PENDING' &&
        (auth.isVendor ||
            _kycStatus.cacUploaded ||
            _kycStatus.ownerIdUploaded ||
            _kycStatus.accountNumber.isNotEmpty)) {
      Navigator.pushNamed(context, VendorPendingVerificationScreen.id);
    } else if (status == 'REJECTED') {
      Navigator.pushNamed(context, VendorRejectedScreen.id);
    } else {
      // NOT_STARTED, DRAFT, or customer applying for vendor
      Navigator.pushNamed(context, VendorOnboardingStepperScreen.id);
    }
  }
}
