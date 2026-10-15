import 'dart:async';
import 'package:flutter/material.dart';
import 'package:foam_mobile/feature/vendor/models/vendor_models.dart';

class VendorProvider extends ChangeNotifier {
  Timer? _countdownTimer;

  // Active Store and Stores List
  String? _selectedStoreId;
  final List<VendorStore> _stores = [
    VendorStore(
      id: 'store_1',
      name: 'Lekki Phase 1',
      address: '14 Admiralty Way, Lekki Phase 1',
      status: 'LIVE',
      rating: 4.7,
      itemsPricedCount: 28,
      totalItems: 28,
      hoursMonFri: '7:00 AM – 7:00 PM',
      hoursSat: '8:00 AM – 5:00 PM',
      hoursSun: 'Closed',
      latitude: 6.4474,
      longitude: 3.4723,
    ),
    VendorStore(
      id: 'store_2',
      name: 'Yaba',
      address: '22 Herbert Macaulay Way',
      status: 'PAUSED',
      rating: 4.5,
      itemsPricedCount: 28,
      totalItems: 28,
      hoursMonFri: '7:30 AM – 6:30 PM',
      hoursSat: '8:00 AM – 4:00 PM',
      hoursSun: 'Closed',
      latitude: 6.5059,
      longitude: 3.3782,
    ),
    VendorStore(
      id: 'store_3',
      name: 'Ikeja GRA',
      address: '5 Isaac John St',
      status: 'DRAFT',
      rating: 5.0,
      itemsPricedCount: 12,
      totalItems: 28,
      hoursMonFri: '8:00 AM – 7:00 PM',
      hoursSat: '9:00 AM – 5:00 PM',
      hoursSun: 'Closed',
      latitude: 6.5905,
      longitude: 3.3587,
    ),
  ];

  // KYC Onboarding state
  final VendorKycStatus _kycStatus = VendorKycStatus(
    cacUploaded: true,
    cacFileName: 'cac-certificate.pdf · 1.2 MB',
    ownerIdUploaded: true,
    ownerIdFileName: 'NIN slip · front.jpg',
    proofOfAddressUploaded: false,
    proofOfAddressFileName: '',
    bankName: 'GTBank',
    accountNumber: '0123454821',
    accountName: 'BRIGHT WASH LIMITED',
    reviewStatus: 'APPROVED',
  );

  // Orders List
  final List<VendorOrder> _orders = [
    VendorOrder(
      id: '#FM-2041',
      storeId: 'store_1',
      customerName: 'Tunde Bakare',
      serviceType: 'Laundry · Folding',
      itemCount: 7,
      pickupSlot: 'Pickup today, 3:00 PM',
      subtotal: 6900.0,
      commission: 1035.0,
      vendorEarnings: 5865.0,
      status: 'NEW',
      secondsRemaining: 522, // 08:42
      items: [
        VendorOrderItem(name: 'Shirt', quantity: 4, totalPrice: 2000),
        VendorOrderItem(name: 'Trouser', quantity: 2, totalPrice: 1400),
        VendorOrderItem(name: 'Duvet', quantity: 1, totalPrice: 3500),
      ],
    ),
    VendorOrder(
      id: '#FM-2043',
      storeId: 'store_1',
      customerName: 'Amina Bello',
      serviceType: 'Dry cleaning · 3 items',
      itemCount: 3,
      pickupSlot: 'Pickup today, 4:30 PM',
      subtotal: 11000.0,
      commission: 1650.0,
      vendorEarnings: 9350.0,
      status: 'NEW',
      secondsRemaining: 595, // 09:55
      items: [
        VendorOrderItem(name: 'Suit 2-Piece', quantity: 1, totalPrice: 5000),
        VendorOrderItem(name: 'Silk Dress', quantity: 2, totalPrice: 6000),
      ],
    ),
    VendorOrder(
      id: '#FM-2038',
      storeId: 'store_1',
      customerName: 'Chioma O.',
      serviceType: 'Laundry · Non-folding',
      itemCount: 6,
      pickupSlot: 'Dropped off by rider · 10:20 AM',
      subtotal: 5200.0,
      commission: 780.0,
      vendorEarnings: 4420.0,
      status: 'WASHING',
      receivedAt: '10:20 AM',
      washingStartedAt: '10:45 AM',
      items: [
        VendorOrderItem(name: 'Shirt', quantity: 3, totalPrice: 1350),
        VendorOrderItem(name: 'T-shirt', quantity: 2, totalPrice: 700),
        VendorOrderItem(name: 'Jeans', quantity: 1, totalPrice: 700),
      ],
    ),
    VendorOrder(
      id: '#FM-2036',
      storeId: 'store_1',
      customerName: 'Emeka N.',
      serviceType: 'Laundry · Folding',
      itemCount: 8,
      pickupSlot: 'Completed · Today 11:30 AM',
      subtotal: 6165.0,
      commission: 925.0,
      vendorEarnings: 5240.0,
      status: 'COMPLETED',
      items: [
        VendorOrderItem(name: 'Shirt', quantity: 4, totalPrice: 2000),
        VendorOrderItem(name: 'Trouser', quantity: 4, totalPrice: 2800),
      ],
    ),
  ];

  // Pricing Matrix: StoreId -> ServiceType -> FoldType -> ItemName -> Price
  final Map<String, Map<String, double>> _pricingMap = {
    'store_1_Laundry_Non-folding': {
      'Shirt': 450.0,
      'T-shirt': 350.0,
      'Trouser': 600.0,
      'Jeans': 700.0,
      'Bedsheet': 1000.0,
      'Duvet': 3000.0,
      'Towel': 800.0,
      'Native (agbada)': 1500.0,
    },
    'store_1_Laundry_Folding': {
      'Shirt': 500.0,
      'T-shirt': 400.0,
      'Trouser': 700.0,
      'Jeans': 800.0,
      'Bedsheet': 1200.0,
      'Duvet': 3500.0,
      'Towel': 900.0,
      'Native (agbada)': 1800.0,
    },
  };

  // Wallet
  double _availableBalance = 112300.0;
  final double _onHoldBalance = 16150.0;
  final List<VendorTransactionItem> _transactions = [
    VendorTransactionItem(
      id: 'tx_1',
      title: 'Order #FM-2036',
      subtitle: 'Lekki Phase 1 · Today',
      amount: 5240.0,
      isCredit: true,
      dateString: 'Today',
    ),
    VendorTransactionItem(
      id: 'tx_2',
      title: 'Order #FM-2031',
      subtitle: 'Yaba · Today',
      amount: 3910.0,
      isCredit: true,
      dateString: 'Today',
    ),
    VendorTransactionItem(
      id: 'tx_3',
      title: 'Withdrawal',
      subtitle: 'GTBank •••• 4821 · Sep 28',
      amount: 150000.0,
      isCredit: false,
      dateString: 'Sep 28',
    ),
    VendorTransactionItem(
      id: 'tx_4',
      title: 'Order #FM-2024',
      subtitle: 'Lekki Phase 1 · Sep 27',
      amount: 7480.0,
      isCredit: true,
      dateString: 'Sep 27',
    ),
    VendorTransactionItem(
      id: 'tx_5',
      title: 'Order #FM-2019',
      subtitle: 'Lekki Phase 1 · Sep 27',
      amount: 2890.0,
      isCredit: true,
      dateString: 'Sep 27',
    ),
  ];

  VendorProvider() {
    _selectedStoreId = _stores.first.id;
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
    if (_selectedStoreId == null) return _stores.first;
    return _stores.firstWhere(
      (s) => s.id == _selectedStoreId,
      orElse: () => _stores.first,
    );
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
      notifyListeners();
    }
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
      notifyListeners();
    }
  }

  void updateStoreAddress({
    required String storeId,
    required String address,
    required double lat,
    required double lng,
  }) {
    final idx = _stores.indexWhere((s) => s.id == storeId);
    if (idx != -1) {
      _stores[idx] = VendorStore(
        id: _stores[idx].id,
        name: _stores[idx].name,
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
      notifyListeners();
    }
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
    if (amount <= _availableBalance) {
      _availableBalance -= amount;
      _transactions.insert(
        0,
        VendorTransactionItem(
          id: ref,
          title: 'Withdrawal',
          subtitle: '${_kycStatus.bankName} •••• ${_kycStatus.accountNumber.substring(_kycStatus.accountNumber.length - 4)} · Today',
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

  void setKycDocument(String docType, String fileName) {
    if (docType == 'CAC') {
      _kycStatus.cacUploaded = true;
      _kycStatus.cacFileName = fileName;
    } else if (docType == 'OWNER_ID') {
      _kycStatus.ownerIdUploaded = true;
      _kycStatus.ownerIdFileName = fileName;
    } else if (docType == 'ADDRESS') {
      _kycStatus.proofOfAddressUploaded = true;
      _kycStatus.proofOfAddressFileName = fileName;
    }
    notifyListeners();
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
}
