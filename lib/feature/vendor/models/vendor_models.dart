class VendorStore {
  final String id;
  final String name;
  final String address;
  String status; // 'LIVE', 'PAUSED', 'DRAFT'
  final double rating;
  int itemsPricedCount;
  final int totalItems;
  String hoursMonFri;
  String hoursSat;
  String hoursSun;
  Map<String, dynamic>? operatingHoursMap;
  double? latitude;
  double? longitude;
  String? photoUrl;
  int turnaroundDays;
  List<dynamic>? turnaroundOptions;
  double basicPercentage;
  double balancePercentage;
  double premiumPercentage;
  String logisticsType; // 'FOAM_RIDERS', 'OWN_LOGISTICS', 'BOTH'
  double foldingPrice;

  VendorStore({
    required this.id,
    required this.name,
    required this.address,
    this.status = 'DRAFT',
    this.rating = 4.8,
    this.itemsPricedCount = 0,
    this.totalItems = 28,
    this.hoursMonFri = '7:00 AM – 7:00 PM',
    this.hoursSat = '8:00 AM – 5:00 PM',
    this.hoursSun = 'Closed',
    this.operatingHoursMap,
    this.latitude,
    this.longitude,
    this.photoUrl,
    this.turnaroundDays = 2,
    this.turnaroundOptions,
    this.basicPercentage = 0,
    this.balancePercentage = 15,
    this.premiumPercentage = 35,
    this.logisticsType = 'BOTH',
    this.foldingPrice = 0.0,
  });

  String get turnaroundText => turnaroundDays <= 1 ? 'Next-day' : 'Ready in $turnaroundDays days';

  bool get isLive => status.toUpperCase() == 'LIVE';
  bool get isPaused => status.toUpperCase() == 'PAUSED';
  bool get isDraft => status.toUpperCase() == 'DRAFT';

  bool get hasFoldingFee => foldingPrice > 0;

  bool get usesFoamRiders => logisticsType == 'FOAM_RIDERS' || logisticsType == 'BOTH';
  bool get usesOwnLogistics => logisticsType == 'OWN_LOGISTICS' || logisticsType == 'BOTH';
  bool get usesBothLogistics => logisticsType == 'BOTH';

  String get logisticsDisplayText {
    switch (logisticsType.toUpperCase()) {
      case 'FOAM_RIDERS':
        return 'Foam Rider Service';
      case 'OWN_LOGISTICS':
        return 'Own Logistics';
      case 'BOTH':
      default:
        return 'Foam Riders & Own Logistics';
    }
  }

  VendorStore copyWith({
    String? id,
    String? name,
    String? address,
    String? status,
    double? rating,
    int? itemsPricedCount,
    int? totalItems,
    String? hoursMonFri,
    String? hoursSat,
    String? hoursSun,
    Map<String, dynamic>? operatingHoursMap,
    double? latitude,
    double? longitude,
    String? photoUrl,
    int? turnaroundDays,
    List<dynamic>? turnaroundOptions,
    double? basicPercentage,
    double? balancePercentage,
    double? premiumPercentage,
    String? logisticsType,
    double? foldingPrice,
  }) {
    return VendorStore(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      status: status ?? this.status,
      rating: rating ?? this.rating,
      itemsPricedCount: itemsPricedCount ?? this.itemsPricedCount,
      totalItems: totalItems ?? this.totalItems,
      hoursMonFri: hoursMonFri ?? this.hoursMonFri,
      hoursSat: hoursSat ?? this.hoursSat,
      hoursSun: hoursSun ?? this.hoursSun,
      operatingHoursMap: operatingHoursMap ?? this.operatingHoursMap,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      photoUrl: photoUrl ?? this.photoUrl,
      turnaroundDays: turnaroundDays ?? this.turnaroundDays,
      turnaroundOptions: turnaroundOptions ?? this.turnaroundOptions,
      basicPercentage: basicPercentage ?? this.basicPercentage,
      balancePercentage: balancePercentage ?? this.balancePercentage,
      premiumPercentage: premiumPercentage ?? this.premiumPercentage,
      logisticsType: logisticsType ?? this.logisticsType,
      foldingPrice: foldingPrice ?? this.foldingPrice,
    );
  }
}

class VendorOrderItem {
  final String name;
  final int quantity;
  final double totalPrice;

  VendorOrderItem({
    required this.name,
    required this.quantity,
    required this.totalPrice,
  });
}

class VendorOrder {
  final String id;
  final String storeId;
  final String customerName;
  final String serviceType;
  final int itemCount;
  final String pickupSlot;
  final double subtotal;
  final double commission;
  final double vendorEarnings;
  String
      status; // 'NEW', 'ACCEPTED', 'RECEIVED_AT_STORE', 'WASHING', 'READY', 'OUT_FOR_DELIVERY', 'COMPLETED'
  int secondsRemaining;
  String? receivedAt;
  String? washingStartedAt;
  String? readyAt;
  String? pickupPin;
  String? deliveryPin;
  final List<VendorOrderItem> items;

  VendorOrder({
    required this.id,
    required this.storeId,
    required this.customerName,
    required this.serviceType,
    required this.itemCount,
    required this.pickupSlot,
    required this.subtotal,
    required this.commission,
    required this.vendorEarnings,
    this.status = 'NEW',
    this.secondsRemaining = 522, // e.g. 08:42
    this.receivedAt,
    this.washingStartedAt,
    this.readyAt,
    this.pickupPin,
    this.deliveryPin,
    required this.items,
  });

  factory VendorOrder.fromJson(Map<String, dynamic> json) {
    final orderId = json['id'] != null ? json['id'].toString() : '0';
    final storeId = json['storeId'] != null ? json['storeId'].toString() : '';
    final user = json['user'] is Map<String, dynamic>
        ? json['user'] as Map<String, dynamic>
        : null;
    final userName = user != null
        ? '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}'.trim()
        : (json['customerName']?.toString() ?? 'Customer');
    final customerName = userName.isNotEmpty ? userName : 'Customer';

    final total = (json['totalPrice'] as num?)?.toDouble() ?? 0.0;
    final delivery = (json['deliveryFee'] as num?)?.toDouble() ?? 0.0;
    final service = (json['serviceFee'] as num?)?.toDouble() ?? 0.0;
    final subtotal =
        (total - delivery - service) > 0 ? (total - delivery - service) : total;
    final commission = subtotal * 0.15;
    final vendorEarnings = (json['vendorEarnings'] as num?)?.toDouble() ??
        (subtotal - commission);

    final rawItems = (json['items'] as List?) ?? [];
    final items = rawItems.map((it) {
      if (it is Map<String, dynamic>) {
        final cat = it['category'] is Map ? it['category'] as Map : null;
        final name = it['name'] ?? (cat != null ? cat['name'] : 'Item');
        final qty = (it['quantity'] as num?)?.toInt() ?? 1;
        final price = (it['price'] as num?)?.toDouble() ??
            (cat != null
                ? ((cat['price'] as num?)?.toDouble() ?? 500.0)
                : 500.0);
        return VendorOrderItem(
          name: name.toString(),
          quantity: qty,
          totalPrice: price * qty,
        );
      }
      return VendorOrderItem(name: 'Item', quantity: 1, totalPrice: 500.0);
    }).toList();

    return VendorOrder(
      id: orderId,
      storeId: storeId,
      customerName: customerName,
      serviceType: json['tier']?.toString() ?? 'Laundry',
      itemCount: items.fold(0, (sum, i) => sum + i.quantity),
      pickupSlot: json['pickupTime']?.toString() ?? 'Today, 3:00 – 4:00 PM',
      subtotal: subtotal,
      commission: commission,
      vendorEarnings: vendorEarnings,
      status: json['vendorStatus']?.toString() ??
          (json['status'] == 'ACCEPTED'
              ? 'ACCEPTED'
              : (json['status']?.toString() ?? 'ACCEPTED')),
      pickupPin: json['pickupPin']?.toString(),
      deliveryPin: json['deliveryPin']?.toString(),
      items: items,
    );
  }

  bool get isNew => status == 'NEW';
  bool get isActive => [
        'ACCEPTED',
        'RECEIVED_AT_STORE',
        'WASHING',
        'READY',
        'OUT_FOR_DELIVERY'
      ].contains(status);
  bool get isDone => [
        'COMPLETED',
        'DECLINED',
        'CANCELLED',
        'DELIVERED'
      ].contains(status);

  String get formattedCountdown {
    final mins = secondsRemaining ~/ 60;
    final secs = secondsRemaining % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}

class VendorTransactionItem {
  final String id;
  final String title;
  final String subtitle;
  final double amount;
  final bool isCredit;
  final String dateString;

  VendorTransactionItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.isCredit,
    required this.dateString,
  });
}

class VendorKycStatus {
  bool cacUploaded;
  String cacFileName;
  String? cacUrl;
  bool ownerIdUploaded;
  String ownerIdFileName;
  String? ownerIdUrl;
  bool proofOfAddressUploaded;
  String proofOfAddressFileName;
  String? proofOfAddressUrl;

    String bankName;
  String bankCode;
  String accountNumber;
  String accountName;

  String reviewStatus; // 'NOT_STARTED', 'DRAFT', 'PENDING', 'APPROVED', 'REJECTED'
  String? rejectionReason;

  VendorKycStatus({
    this.cacUploaded = false,
    this.cacFileName = '',
    this.cacUrl,
    this.ownerIdUploaded = false,
    this.ownerIdFileName = '',
    this.ownerIdUrl,
    this.proofOfAddressUploaded = false,
    this.proofOfAddressFileName = '',
    this.proofOfAddressUrl,
    this.bankName = '',
    this.bankCode = '',
    this.accountNumber = '',
    this.accountName = '',
    this.reviewStatus = 'NOT_STARTED',
    this.rejectionReason,
  });
}

class PaystackBankModel {
  final int id;
  final String name;
  final String code;
  final String slug;

  PaystackBankModel({
    required this.id,
    required this.name,
    required this.code,
    required this.slug,
  });

  factory PaystackBankModel.fromJson(Map<String, dynamic> json) {
    return PaystackBankModel(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id'].toString()) ?? 0,
      name: json['name'] ?? '',
      code: json['code']?.toString() ?? '',
      slug: json['slug'] ?? '',
    );
  }
}
