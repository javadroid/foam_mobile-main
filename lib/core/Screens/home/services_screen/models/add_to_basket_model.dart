class AddToBasketModel {
  List<Items>? items = [
    Items(
      id: 1,
      name: 'Shirts',
      image: 'assets/images/shirt.png',
      price: 'N500',
      oldPrice: 'N850',
      quantity: 0,
    ),
    Items(
      id: 2,
      name: 'T-Shirts',
      image: 'assets/images/basket2.png',
      price: 'N500',
      oldPrice: 'N850',
      quantity: 0,
    ),
    Items(
      id: 3,
      name: 'Polo',
      image: 'assets/images/polo.png',
      price: 'N500',
      oldPrice: 'N850',
      quantity: 0,
    ),
    Items(
      id: 4,
      name: 'Female Tops',
      image: 'assets/images/female_tops.png',
      price: 'N500',
      oldPrice: 'N850',
      quantity: 0,
    ),
    Items(
      id: 5,
      name: 'Singlets',
      image: 'assets/images/singlet.png',
      price: 'N500',
      oldPrice: 'N850',
      quantity: 0,
    ),
    Items(
      id: 6,
      name: 'Caps/Hats',
      image: 'assets/images/shirt.png', // Fallback image
      price: 'N400',
      oldPrice: 'N600',
      quantity: 0,
    ),
  ];
}

class Items {
  Items({
    this.id,
    this.name,
    this.image,
    this.price,
    this.oldPrice,
    this.quantity,
  });

  int? id;
  String? name;
  String? image;
  String? price;
  String? oldPrice;
  int? quantity;
}
