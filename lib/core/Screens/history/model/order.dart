class OrderResponse {
  final List<Order> orders;

  OrderResponse({required this.orders});

  factory OrderResponse.fromJson(Map<String, dynamic> json) {
    var ordersList = (json['orders'] as List?) ?? [];
    List<Order> orders = ordersList.map((i) => Order.fromJson(i)).toList();
    return OrderResponse(orders: orders);
  }

  Map<String, dynamic> toJson() {
    return {
      'orders': orders.map((order) => order.toJson()).toList(),
    };
  }
}

class Order {
  final String id;
  final String userId;
  final String status;
  final DateTime? pickupDate;
  final DateTime? deliveryDate;
  final int totalPrice;
  final bool noFolding;
  final String paymentType;
  final String paymentId;
  final String paymentStatus;
  final DateTime createdAt;
  final String? orderHistoryId;
  final String? riderId;
  final String? pickupAddress;
  final String? deliveryAddress;
  final String? pickupTime;
  final String? deliveryTime;
  final String? storeName;
  final String? riderName;
  final String? riderPhone;
  final String? vendorStatus;
  final List<OrderItem> items;

  Order({
    required this.id,
    required this.userId,
    required this.status,
    this.pickupDate,
    this.deliveryDate,
    required this.totalPrice,
    this.noFolding = false,
    required this.paymentType,
    required this.paymentId,
    required this.paymentStatus,
    required this.createdAt,
    this.orderHistoryId,
    this.riderId,
    this.pickupAddress,
    this.deliveryAddress,
    this.pickupTime,
    this.deliveryTime,
    this.storeName,
    this.riderName,
    this.riderPhone,
    this.vendorStatus,
    required this.items,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    var itemsList = (json['items'] as List?) ?? [];
    List<OrderItem> items =
        itemsList.map((i) => OrderItem.fromJson(i)).toList();

    return Order(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      status: json['status'] ?? '',
      pickupDate: json['pickupDate'] != null
          ? DateTime.tryParse(json['pickupDate'])
          : null,
      deliveryDate: json['deliveryDate'] != null
          ? DateTime.tryParse(json['deliveryDate'])
          : null,
      totalPrice: (json['totalPrice'] as num?)?.toInt() ?? 0,
      noFolding: json['noFolding'] == true,
      paymentType: json['paymentType'] ?? '',
      paymentId: json['paymentId'] ?? '',
      paymentStatus: json['paymentStatus'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
          : DateTime.now(),
      orderHistoryId: json['orderHistoryId']?.toString(),
      riderId: json['riderId']?.toString(),
      pickupAddress: json['pickupAddress'],
      deliveryAddress: json['deliveryAddress'],
      pickupTime: json['pickupTime'],
      deliveryTime: json['deliveryTime'],
      storeName: json['store'] != null ? json['store']['name'] : null,
      riderName: json['rider'] != null ? json['rider']['name'] : null,
      riderPhone: json['rider'] != null ? json['rider']['phone'] : null,
      vendorStatus: json['vendorStatus']?.toString(),
      items: items,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'status': status,
      'vendorStatus': vendorStatus,
      'pickupDate': pickupDate?.toIso8601String(),
      'deliveryDate': deliveryDate?.toIso8601String(),
      'totalPrice': totalPrice,
      'noFolding': noFolding,
      'paymentType': paymentType,
      'paymentId': paymentId,
      'paymentStatus': paymentStatus,
      'createdAt': createdAt.toIso8601String(),
      'orderHistoryId': orderHistoryId,
      'riderId': riderId,
      'items': items.map((item) => item.toJson()).toList(),
    };
  }
}

class OrderItem {
  final String id;
  final String? basketId;
  final String orderId;
  final String? categoryId;
  final int quantity;
  final int foldingSurcharge;
  final DateTime createdAt;
  final DateTime updatedAt;
  final OrderItemCategory category;
  final String? name;
  final double? price;
  final String? imageUrl;

  OrderItem({
    required this.id,
    this.basketId,
    required this.orderId,
    this.categoryId,
    required this.quantity,
    this.foldingSurcharge = 0,
    required this.createdAt,
    required this.updatedAt,
    required this.category,
    this.name,
    this.price,
    this.imageUrl,
  });

  String get displayName => (name != null && name!.isNotEmpty)
      ? name!
      : (category.name.isNotEmpty ? category.name : 'Laundry Item');

  double get displayPrice => price != null ? price! : category.price.toDouble();

  String get displayImageUrl {
    if (imageUrl != null && imageUrl!.isNotEmpty) return imageUrl!;
    if (category.imageUrl != null && category.imageUrl!.isNotEmpty) {
      return category.imageUrl!;
    }
    return 'assets/images/folding.png';
  }

  String get displayDescription => category.description;

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    final catObj = json['category'] != null
        ? OrderItemCategory.fromJson(json['category'])
        : OrderItemCategory(
            id: '',
            name: json['name']?.toString() ?? '',
            description: '',
            price: (json['price'] as num?)?.toInt() ?? 0,
            imageUrl: json['imageUrl']?.toString(),
          );

    return OrderItem(
      id: json['id']?.toString() ?? '',
      basketId: json['basketId']?.toString(),
      orderId: json['orderId']?.toString() ?? '',
      categoryId: json['categoryId']?.toString(),
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      foldingSurcharge: (json['foldingSurcharge'] as num?)?.toInt() ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt']) ?? DateTime.now()
          : DateTime.now(),
      category: catObj,
      name: json['name']?.toString(),
      price: (json['price'] as num?)?.toDouble() ?? (catObj.price.toDouble()),
      imageUrl: json['imageUrl']?.toString() ?? catObj.imageUrl,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'basketId': basketId,
      'orderId': orderId,
      if (categoryId != null) 'categoryId': categoryId,
      'quantity': quantity,
      'foldingSurcharge': foldingSurcharge,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'category': category.toJson(),
      if (name != null) 'name': name,
      if (price != null) 'price': price,
      if (imageUrl != null) 'imageUrl': imageUrl,
    };
  }
}

class OrderItemCategory {
  final String id;
  final String? imageUrl;
  final String name;
  final String description;
  final int price;
  final double? foldingSurchargeRate;

  OrderItemCategory({
    required this.id,
    this.imageUrl,
    required this.name,
    required this.description,
    required this.price,
    this.foldingSurchargeRate,
  });

  factory OrderItemCategory.fromJson(Map<String, dynamic> json) {
    return OrderItemCategory(
      id: json['id']?.toString() ?? '',
      imageUrl: json['imageUrl'],
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] as num?)?.toInt() ?? 0,
      foldingSurchargeRate: (json['foldingSurchargeRate'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'imageUrl': imageUrl,
      'name': name,
      'description': description,
      'price': price,
      if (foldingSurchargeRate != null)
        'foldingSurchargeRate': foldingSurchargeRate,
    };
  }
}
