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
  double latitude;
  double longitude;

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
    this.latitude = 6.4474,
    this.longitude = 3.4723,
  });

  bool get isLive => status.toUpperCase() == 'LIVE';
  bool get isPaused => status.toUpperCase() == 'PAUSED';
  bool get isDraft => status.toUpperCase() == 'DRAFT';
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
  String status; // 'NEW', 'ACCEPTED', 'RECEIVED_AT_STORE', 'WASHING', 'READY', 'OUT_FOR_DELIVERY', 'COMPLETED'
  int secondsRemaining;
  String? receivedAt;
  String? washingStartedAt;
  String? readyAt;
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
    required this.items,
  });

  bool get isNew => status == 'NEW';
  bool get isActive =>
      ['ACCEPTED', 'RECEIVED_AT_STORE', 'WASHING', 'READY', 'OUT_FOR_DELIVERY'].contains(status);
  bool get isDone => status == 'COMPLETED';

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
  String accountNumber;
  String accountName;

  String reviewStatus; // 'NOT_STARTED', 'PENDING', 'APPROVED', 'REJECTED'
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
    this.accountNumber = '',
    this.accountName = '',
    this.reviewStatus = 'PENDING',
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
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      name: json['name'] ?? '',
      code: json['code']?.toString() ?? '',
      slug: json['slug'] ?? '',
    );
  }
}
