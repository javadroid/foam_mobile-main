class RiderProfile {
  final String id;
  final String name;
  final String phone;
  final String? email;
  final String? profileImageUrl;
  final String? driverLicenseUrl;
  final String vehicleType;
  final String? vehiclePlate;
  final String? licenseNumber;
  final double? coverageLatitude;
  final double? coverageLongitude;
  final double coverageRadiusKm;
  final String? coverageRoute;
  final String approvalStatus; // "PENDING", "APPROVED", "REJECTED"
  final bool isOnline;
  final double rating;
  final int totalRides;
  final double walletBalance;

  RiderProfile({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    this.profileImageUrl,
    this.driverLicenseUrl,
    this.vehicleType = 'MOTORCYCLE',
    this.vehiclePlate,
    this.licenseNumber,
    this.coverageLatitude,
    this.coverageLongitude,
    this.coverageRadiusKm = 10.0,
    this.coverageRoute,
    this.approvalStatus = 'PENDING',
    this.isOnline = false,
    this.rating = 5.0,
    this.totalRides = 0,
    this.walletBalance = 0.0,
  });

  factory RiderProfile.fromJson(Map<String, dynamic> json) {
    return RiderProfile(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      email: json['email']?.toString(),
      profileImageUrl: json['profileImageUrl']?.toString() ?? json['avatarUrl']?.toString(),
      driverLicenseUrl: json['driverLicenseUrl']?.toString(),
      vehicleType: json['vehicleType']?.toString() ?? 'MOTORCYCLE',
      vehiclePlate: json['vehiclePlate']?.toString(),
      licenseNumber: json['licenseNumber']?.toString(),
      coverageLatitude: json['coverageLatitude'] != null
          ? double.tryParse(json['coverageLatitude'].toString())
          : null,
      coverageLongitude: json['coverageLongitude'] != null
          ? double.tryParse(json['coverageLongitude'].toString())
          : null,
      coverageRadiusKm: json['coverageRadiusKm'] != null
          ? (double.tryParse(json['coverageRadiusKm'].toString()) ?? 10.0)
          : 10.0,
      coverageRoute: json['coverageRoute']?.toString(),
      approvalStatus: json['approvalStatus']?.toString() ?? 'PENDING',
      isOnline: json['isOnline'] == true,
      rating: json['rating'] != null
          ? (double.tryParse(json['rating'].toString()) ?? 5.0)
          : 5.0,
      totalRides: json['totalRides'] is int
          ? json['totalRides']
          : (int.tryParse(json['totalRides'].toString()) ?? 0),
      walletBalance: json['walletBalance'] != null
          ? (double.tryParse(json['walletBalance'].toString()) ?? 0.0)
          : 0.0,
    );
  }

  bool get isApproved => approvalStatus == 'APPROVED';
}

class AvailableRide {
  final String id;
  final String orderNumber;
  final String storeName;
  final String storeAddress;
  final String pickupAddress;
  final String deliveryAddress;
  final String customerName;
  final String customerPhone;
  final double totalPrice;
  final double earnings;
  final double deliveryFee;
  final double distanceKm;
  final String? scheduledPickupTime;
  final String? pickupTime;
  final String? pickupDate;
  final String? pin;
  final DateTime createdAt;

  AvailableRide({
    required this.id,
    required this.orderNumber,
    required this.storeName,
    required this.storeAddress,
    required this.pickupAddress,
    required this.deliveryAddress,
    required this.customerName,
    required this.customerPhone,
    required this.totalPrice,
    required this.earnings,
    required this.deliveryFee,
    this.distanceKm = 4.2,
    this.scheduledPickupTime,
    this.pickupTime,
    this.pickupDate,
    this.pin,
    required this.createdAt,
  });

  factory AvailableRide.fromJson(Map<String, dynamic> json) {
    return AvailableRide(
      id: json['id']?.toString() ?? (json['orderId']?.toString() ?? ''),
      orderNumber: json['orderNumber']?.toString() ?? 'FOAM-0000',
      storeName: json['storeName']?.toString() ?? 'Foam Laundry Hub',
      storeAddress: json['storeAddress']?.toString() ?? '',
      pickupAddress: json['pickupAddress']?.toString() ?? '',
      deliveryAddress: json['deliveryAddress']?.toString() ?? '',
      customerName: json['customerName']?.toString() ?? 'Customer',
      customerPhone: json['customerPhone']?.toString() ?? '',
      totalPrice: json['totalPrice'] != null
          ? (double.tryParse(json['totalPrice'].toString()) ?? 0.0)
          : 0.0,
      earnings: json['earnings'] != null
          ? (double.tryParse(json['earnings'].toString()) ?? 1500.0)
          : 1500.0,
      deliveryFee: json['deliveryFee'] != null
          ? (double.tryParse(json['deliveryFee'].toString()) ?? 1500.0)
          : 1500.0,
      distanceKm: json['distanceKm'] != null
          ? (double.tryParse(json['distanceKm'].toString()) ?? 4.2)
          : 4.2,
      scheduledPickupTime: json['scheduledPickupTime']?.toString(),
      pickupTime: json['pickupTime']?.toString(),
      pickupDate: json['pickupDate']?.toString(),
      pin: json['pin']?.toString(),
      createdAt: json['createdAt'] != null
          ? (DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now())
          : DateTime.now(),
    );
  }
}

class ActiveRide {
  final String orderId;
  final String orderNumber;
  final String storeName;
  final String storeAddress;
  final String pickupAddress;
  final String deliveryAddress;
  final String customerName;
  final String customerPhone;
  String stage; // EN_ROUTE_TO_STORE, PICKED_UP, OUT_FOR_DELIVERY, DELIVERED
  final String? pickupPin;
  final String? deliveryPin;
  final double earnings;
  final String? scheduledPickupTime;
  final String? pickupTime;
  final String? pickupDate;

  String get id => orderId;

  ActiveRide({
    required this.orderId,
    required this.orderNumber,
    required this.storeName,
    required this.storeAddress,
    required this.pickupAddress,
    required this.deliveryAddress,
    required this.customerName,
    required this.customerPhone,
    required this.stage,
    this.pickupPin,
    this.deliveryPin,
    required this.earnings,
    this.scheduledPickupTime,
    this.pickupTime,
    this.pickupDate,
  });

  factory ActiveRide.fromAvailable(AvailableRide ride) {
    return ActiveRide(
      orderId: ride.id,
      orderNumber: ride.orderNumber,
      storeName: ride.storeName,
      storeAddress: ride.storeAddress,
      pickupAddress: ride.pickupAddress,
      deliveryAddress: ride.deliveryAddress,
      customerName: ride.customerName,
      customerPhone: ride.customerPhone,
      stage: 'EN_ROUTE_TO_STORE',
      pickupPin: ride.pin ?? '1234',
      deliveryPin: '5678',
      earnings: ride.earnings,
      scheduledPickupTime: ride.scheduledPickupTime,
      pickupTime: ride.pickupTime,
      pickupDate: ride.pickupDate,
    );
  }

  factory ActiveRide.fromJson(Map<String, dynamic> json) {
    final order = json['order'] is Map ? json['order'] as Map<String, dynamic> : json;
    final store = order['store'] is Map ? order['store'] as Map<String, dynamic> : null;
    final user = order['user'] is Map ? order['user'] as Map<String, dynamic> : null;

    final customerFirst = user?['firstName']?.toString() ?? '';
    final customerLast = user?['lastName']?.toString() ?? '';
    final custName = '$customerFirst $customerLast'.trim();

    return ActiveRide(
      orderId: order['id']?.toString() ?? (order['orderId']?.toString() ?? ''),
      orderNumber: order['orderNumber']?.toString() ?? 'FOAM-${order['id'] ?? ''}',
      storeName: store?['name']?.toString() ?? order['storeName']?.toString() ?? 'Foam Laundry Hub',
      storeAddress: store?['address']?.toString() ?? order['storeAddress']?.toString() ?? '',
      pickupAddress: order['pickupAddress']?.toString() ?? '',
      deliveryAddress: order['deliveryAddress']?.toString() ?? '',
      customerName: custName.isNotEmpty ? custName : (order['customerName']?.toString() ?? 'Customer'),
      customerPhone: user?['phone']?.toString() ?? order['customerPhone']?.toString() ?? '',
      stage: order['vendorStatus']?.toString() ?? json['stage']?.toString() ?? 'EN_ROUTE_TO_STORE',
      pickupPin: order['pickupPin']?.toString() ?? json['pin']?.toString(),
      deliveryPin: order['deliveryPin']?.toString(),
      earnings: (json['earnings'] != null)
          ? (double.tryParse(json['earnings'].toString()) ?? 1500.0)
          : (order['deliveryFee'] != null ? (double.tryParse(order['deliveryFee'].toString()) ?? 1500.0) : 1500.0),
      scheduledPickupTime: json['scheduledPickupTime']?.toString() ?? order['scheduledPickupTime']?.toString(),
      pickupTime: order['pickupTime']?.toString(),
      pickupDate: order['pickupDate']?.toString(),
    );
  }
}

class RiderDeliveryHistoryItem {
  final String orderId;
  final String orderNumber;
  final String date;
  final String storeName;
  final String pickupAddress;
  final String deliveryAddress;
  final double distanceKm;
  final double earnings;
  final double totalPrice;

  RiderDeliveryHistoryItem({
    required this.orderId,
    required this.orderNumber,
    required this.date,
    required this.storeName,
    required this.pickupAddress,
    required this.deliveryAddress,
    required this.distanceKm,
    required this.earnings,
    required this.totalPrice,
  });

  factory RiderDeliveryHistoryItem.fromJson(Map<String, dynamic> json) {
    return RiderDeliveryHistoryItem(
      orderId: json['orderId']?.toString() ?? (json['id']?.toString() ?? ''),
      orderNumber: json['orderNumber']?.toString() ?? 'FOAM-0000',
      date: json['date']?.toString() ?? '',
      storeName: json['storeName']?.toString() ?? 'Foam Hub',
      pickupAddress: json['pickupAddress']?.toString() ?? '',
      deliveryAddress: json['deliveryAddress']?.toString() ?? '',
      distanceKm: json['distanceKm'] != null
          ? (double.tryParse(json['distanceKm'].toString()) ?? 4.5)
          : 4.5,
      earnings: json['earnings'] != null
          ? (double.tryParse(json['earnings'].toString()) ?? 1500.0)
          : 1500.0,
      totalPrice: json['totalPrice'] != null
          ? (double.tryParse(json['totalPrice'].toString()) ?? 0.0)
          : 0.0,
    );
  }
}

class RiderTransactionItem {
  final String id;
  final String type; // CREDIT or DEBIT
  final double amount;
  final String description;
  final String status; // COMPLETED, PENDING, FAILED
  final DateTime createdAt;

  RiderTransactionItem({
    required this.id,
    required this.type,
    required this.amount,
    required this.description,
    required this.status,
    required this.createdAt,
  });

  factory RiderTransactionItem.fromJson(Map<String, dynamic> json) {
    return RiderTransactionItem(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? 'CREDIT',
      amount: json['amount'] != null
          ? (double.tryParse(json['amount'].toString()) ?? 0.0)
          : 0.0,
      description: json['description']?.toString() ?? '',
      status: json['status']?.toString() ?? 'COMPLETED',
      createdAt: json['createdAt'] != null
          ? (DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now())
          : DateTime.now(),
    );
  }
}
