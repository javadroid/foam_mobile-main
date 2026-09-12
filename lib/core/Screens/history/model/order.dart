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
  final int id;
  final int userId;
  final String status;
  final DateTime? pickupDate;
  final DateTime? deliveryDate;
  final int totalPrice;
  final bool noFolding;
  final String paymentType;
  final String paymentId;
  final String paymentStatus;
  final DateTime createdAt;
  final int? orderHistoryId;
  final int? riderId;
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
    required this.items,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    var itemsList = (json['items'] as List?) ?? [];
    List<OrderItem> items =
        itemsList.map((i) => OrderItem.fromJson(i)).toList();

    return Order(
      id: json['id'] ?? 0,
      userId: json['userId'] ?? 0,
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
      orderHistoryId: json['orderHistoryId'],
      riderId: json['riderId'],
      items: items,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'status': status,
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
  final int id;
  final int? basketId;
  final int orderId;
  final int categoryId;
  final int quantity;
  final int foldingSurcharge;
  final DateTime createdAt;
  final DateTime updatedAt;
  final OrderItemCategory category;

  OrderItem({
    required this.id,
    this.basketId,
    required this.orderId,
    required this.categoryId,
    required this.quantity,
    this.foldingSurcharge = 0,
    required this.createdAt,
    required this.updatedAt,
    required this.category,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'] ?? 0,
      basketId: json['basketId'],
      orderId: json['orderId'] ?? 0,
      categoryId: json['categoryId'] ?? 0,
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      foldingSurcharge:
          (json['foldingSurcharge'] as num?)?.toInt() ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt']) ?? DateTime.now()
          : DateTime.now(),
      category: json['category'] != null
          ? OrderItemCategory.fromJson(json['category'])
          : OrderItemCategory(
              id: 0,
              name: '',
              description: '',
              price: 0,
            ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'basketId': basketId,
      'orderId': orderId,
      'categoryId': categoryId,
      'quantity': quantity,
      'foldingSurcharge': foldingSurcharge,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'category': category.toJson(),
    };
  }
}

class OrderItemCategory {
  final int id;
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
      id: json['id'] ?? 0,
      imageUrl: json['imageUrl'],
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] as num?)?.toInt() ?? 0,
      foldingSurchargeRate:
          (json['foldingSurchargeRate'] as num?)?.toDouble(),
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
