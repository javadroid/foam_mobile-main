import 'dart:convert';

List<CategoryItem> categoryListFromJson(dynamic str) => List<CategoryItem>.from(
      json.decode(str)['categories'].map(
            (x) => CategoryItem.fromJson(x),
          ),
    );

class CategoryItem {
  CategoryItem({
    required this.id,
    required this.imageUrl,
    required this.name,
    required this.description,
    required this.price,
    this.quantity = 0,
  });

  int id;
  String? imageUrl;
  String name;
  String description;
  int price;
  int quantity;

  factory CategoryItem.fromJson(Map<String, dynamic> response) {
    return CategoryItem(
      id: response["id"],
      imageUrl: response["imageUrl"],
      name: response["name"].toString().trim(),
      description: response["description"].toString().trim(),
      price: response["price"],
    );
  }

  Map<String, dynamic> toJson() => {
        "id": id,
        "imageUrl": imageUrl,
        "name": name,
        "description": description,
        "price": price,
      };
}
