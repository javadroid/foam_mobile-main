import 'dart:convert';

List<BasketList> basketListFromJson(dynamic str) {
  var decodedJson = json.decode(str);

  if (decodedJson['basket'] == null || decodedJson['basket']['items'] == null) {
    return [];
  }

  return List<BasketList>.from(
    decodedJson['basket']['items'].map(
      (x) => BasketList.fromJson(x),
    ),
  );
}

String basketListToJson(List<BasketList> data) => json.encode(
      List<dynamic>.from(
        data.map(
          (x) => x.toJson(),
        ),
      ),
    );

class BasketList {
  BasketList({
    required this.categoryId,
    required this.quantity,
    required this.name,
    required this.price,
  });

  int categoryId;
  int quantity;
  String name;
  int price;

  factory BasketList.fromJson(Map<String, dynamic> json) {
    return BasketList(
        categoryId: json["categoryId"],
        quantity: json["quantity"],
        name: json["category"]["name"],
        price: json["category"]["price"]);
  }

  Map<String, dynamic> toJson() => {
        "categoryId": categoryId,
        "quantity": quantity,
        "name": name,
        "price": price,
      };
}
