class OrderResponse {
  final List<Order> orders;

  OrderResponse({required this.orders});

  factory OrderResponse.fromJson(Map<String, dynamic> json) {
    var ordersList = json['orders'] as List;
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
    required this.paymentType,
    required this.paymentId,
    required this.paymentStatus,
    required this.createdAt,
    this.orderHistoryId,
    this.riderId,
    required this.items,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    var itemsList = json['items'] as List;
    List<OrderItem> items = itemsList.map((i) => OrderItem.fromJson(i)).toList();

    return Order(
      id: json['id'],
      userId: json['userId'],
      status: json['status'],
      pickupDate: json['pickupDate'] != null ? DateTime.parse(json['pickupDate']) : null,
      deliveryDate: json['deliveryDate'] != null ? DateTime.parse(json['deliveryDate']) : null,
      totalPrice: json['totalPrice'],
      paymentType: json['paymentType'],
      paymentId: json['paymentId'],
      paymentStatus: json['paymentStatus'],
      createdAt: DateTime.parse(json['createdAt']),
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
  final DateTime createdAt;
  final DateTime updatedAt;
  final OrderItemCategory category;

  OrderItem({
    required this.id,
    this.basketId,
    required this.orderId,
    required this.categoryId,
    required this.quantity,
    required this.createdAt,
    required this.updatedAt,
    required this.category,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'],
      basketId: json['basketId'],
      orderId: json['orderId'],
      categoryId: json['categoryId'],
      quantity: json['quantity'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      category: OrderItemCategory.fromJson(json['category']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'basketId': basketId,
      'orderId': orderId,
      'categoryId': categoryId,
      'quantity': quantity,
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

  OrderItemCategory({
    required this.id,
    this.imageUrl,
    required this.name,
    required this.description,
    required this.price,
  });

  factory OrderItemCategory.fromJson(Map<String, dynamic> json) {
    return OrderItemCategory(
      id: json['id'],
      imageUrl: json['imageUrl'],
      name: json['name'],
      description: json['description'],
      price: json['price'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'imageUrl': imageUrl,
      'name': name,
      'description': description,
      'price': price,
    };
  }
}
