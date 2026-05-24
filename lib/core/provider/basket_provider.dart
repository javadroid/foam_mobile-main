import 'package:flutter/material.dart';
import 'package:foam_mobile/core/Screens/basket/controller/remote_basket.dart';
import 'package:foam_mobile/core/Screens/basket/model/basket.dart';
import 'package:foam_mobile/core/Screens/home/services_screen/controllers/remote_services.dart';

class BasketProvider extends ChangeNotifier {
  List<BasketList> _basketItems = [];
  bool _isLoading = false;

  List<BasketList> get basketItems => _basketItems;
  bool get isLoading => _isLoading;

  int get totalItems => _basketItems.fold(0, (sum, item) => sum + item.quantity);
  int get totalAmount => _basketItems.fold(0, (sum, item) => sum + (item.price * item.quantity));

  int getQuantity(int categoryId) {
    final item = _basketItems.firstWhere(
      (element) => element.categoryId == categoryId,
      orElse: () => BasketList(categoryId: categoryId, quantity: 0, name: '', price: 0, imageUrl: null),
    );
    return item.quantity;
  }

  Future<void> fetchBasket(GlobalKey<ScaffoldMessengerState> scaffoldKey, {bool showLoading = true}) async {
    if (showLoading) {
      _isLoading = true;
      notifyListeners();
    }

    final result = await BasketClass.getServices(scaffoldKey);
    if (result != null) {
      _basketItems = result;
    }
    
    if (showLoading) {
      _isLoading = false;
    }
    notifyListeners();
  }

  Future<void> addToBasket(BuildContext context, int serviceId, int categoryId, int quantity, GlobalKey<ScaffoldMessengerState> scaffoldKey) async {
    await ServicesClass.addToBasket(context, serviceId, categoryId, quantity, scaffoldKey);
    await fetchBasket(scaffoldKey, showLoading: false);
  }

  Future<void> updateQuantity(int categoryId, int quantity, GlobalKey<ScaffoldMessengerState> scaffoldKey) async {
    await BasketClass.updateQuantity(categoryId, quantity, scaffoldKey);
    await fetchBasket(scaffoldKey, showLoading: false);
  }

  Future<void> removeFromBasket(int categoryId, GlobalKey<ScaffoldMessengerState> scaffoldKey) async {
    await ServicesClass.removeFromBasket(categoryId, scaffoldKey);
    await fetchBasket(scaffoldKey, showLoading: false);
  }

  Future<void> clearBasket(GlobalKey<ScaffoldMessengerState> scaffoldKey) async {
    await BasketClass.clearBasket(scaffoldKey);
    _basketItems = [];
    notifyListeners();
  }
}
