import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:foam_mobile/core/hive/hive.dart';
import 'package:foam_mobile/feature/vendor/models/vendor_models.dart';
import 'package:foam_mobile/utils/values.dart';
import 'package:http/http.dart' as http;

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

  // Active Store and Stores List
  String? _selectedStoreId;
  final List<VendorStore> _stores = [];

  // KYC Onboarding state
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

  // Wallet
  double _availableBalance = 0.0;
  final double _onHoldBalance = 0.0;
  final List<VendorTransactionItem> _transactions = [];

  VendorProvider() {
    _selectedStoreId = _stores.isNotEmpty ? _stores.first.id : null;
    _startCountdownTimer();
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

  Map<String, double> getItemPrices(String storeId, String service, String foldType) {
    final key = '${storeId}_${service}_$foldType';
    return _pricingMap[key] ?? {};
  }

  void setItemPrice(String storeId, String service, String foldType, String item, double price) {
    final key = '${storeId}_${service}_$foldType';
    if (!_pricingMap.containsKey(key)) {
      _pricingMap[key] = {};
    }
    _pricingMap[key]![item] = price;
    notifyListeners();
  }

  bool withdraw(double amount, String ref) {
    if (amount > 0 && amount <= _availableBalance) {
      _availableBalance -= amount;
      final bank = _kycStatus.bankName.isNotEmpty ? _kycStatus.bankName : 'Bank';
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
      );

      final data = jsonDecode(res.body);
      if (res.statusCode == 200 && data['status'] == true) {
        return data['accountName'] as String?;
      } else {
        debugPrint('Paystack resolve response: ${data['error'] ?? data['message']}');
      }
    } catch (e) {
      debugPrint('Error resolving Paystack account: $e');
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
}
