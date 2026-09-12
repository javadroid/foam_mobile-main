import 'dart:convert';

BasketQuote basketQuoteFromJson(String str) =>
    BasketQuote.fromJson(json.decode(str));

String basketQuoteToJson(BasketQuote data) => json.encode(data.toJson());

class BasketQuote {
  final List<BasketQuoteItem> items;
  final int subtotal;
  final int foldingSurchargeTotal;
  final int deliveryFee;
  final int totalPrice;

  BasketQuote({
    required this.items,
    required this.subtotal,
    required this.foldingSurchargeTotal,
    required this.deliveryFee,
    required this.totalPrice,
  });

  factory BasketQuote.empty() => BasketQuote(
        items: [],
        subtotal: 0,
        foldingSurchargeTotal: 0,
        deliveryFee: 0,
        totalPrice: 0,
      );

  factory BasketQuote.fromJson(Map<String, dynamic> json) => BasketQuote(
        items: json["items"] == null
            ? []
            : List<BasketQuoteItem>.from(
                json["items"].map((x) => BasketQuoteItem.fromJson(x))),
        subtotal: (json["subtotal"] as num?)?.toInt() ?? 0,
        foldingSurchargeTotal:
            (json["foldingSurchargeTotal"] as num?)?.toInt() ?? 0,
        deliveryFee: (json["deliveryFee"] as num?)?.toInt() ?? 0,
        totalPrice: (json["totalPrice"] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toJson() => {
        "items": List<dynamic>.from(items.map((x) => x.toJson())),
        "subtotal": subtotal,
        "foldingSurchargeTotal": foldingSurchargeTotal,
        "deliveryFee": deliveryFee,
        "totalPrice": totalPrice,
      };
}

class BasketQuoteItem {
  final int? itemId;
  final int? categoryId;
  final String? name;
  final int quantity;
  final int unitPrice;
  final int foldingSurcharge;
  final int lineTotal;

  BasketQuoteItem({
    this.itemId,
    this.categoryId,
    this.name,
    required this.quantity,
    required this.unitPrice,
    required this.foldingSurcharge,
    required this.lineTotal,
  });

  factory BasketQuoteItem.fromJson(Map<String, dynamic> json) =>
      BasketQuoteItem(
        itemId: json["itemId"],
        categoryId: json["categoryId"],
        name: json["name"],
        quantity: (json["quantity"] as num?)?.toInt() ?? 0,
        unitPrice: (json["unitPrice"] as num?)?.toInt() ?? 0,
        foldingSurcharge: (json["foldingSurcharge"] as num?)?.toInt() ?? 0,
        lineTotal: (json["lineTotal"] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toJson() => {
        "itemId": itemId,
        "categoryId": categoryId,
        "name": name,
        "quantity": quantity,
        "unitPrice": unitPrice,
        "foldingSurcharge": foldingSurcharge,
        "lineTotal": lineTotal,
      };
}
