import 'package:flutter/material.dart';
import 'package:foam_mobile/core/Screens/basket/controller/remote_basket.dart';
import 'package:foam_mobile/core/Screens/basket/model/basket.dart';
import 'package:foam_mobile/core/Screens/basket/model/basket_quote.dart';
import 'package:foam_mobile/core/Screens/home/services_screen/controllers/remote_services.dart';

class BasketProvider extends ChangeNotifier {
  List<BasketList> _basketItems = [];
  bool _isLoading = false;
  bool _isQuoteLoading = false;
  bool _isNoFolding = false;
  BasketQuote? _currentQuote;

  List<BasketList> get basketItems => _basketItems;
  bool get isLoading => _isLoading;
  bool get isQuoteLoading => _isQuoteLoading;
  bool get isNoFolding => _isNoFolding;
  BasketQuote? get currentQuote => _currentQuote;

  int get totalItems => _basketItems.fold(0, (sum, item) => sum + item.quantity);
  int get totalAmount => _currentQuote?.subtotal ?? _basketItems.fold(0, (sum, item) => sum + (item.price * item.quantity));
  int get foldingSurchargeTotal => _currentQuote?.foldingSurchargeTotal ?? 0;
  int get deliveryFee => _currentQuote?.deliveryFee ?? 3000;
  int get totalPrice => _currentQuote?.totalPrice ?? (totalAmount + deliveryFee + (_isNoFolding ? foldingSurchargeTotal : 0));

  int getQuantity(int categoryId) {
    final item = _basketItems.firstWhere(
      (element) => element.categoryId == categoryId,
      orElse: () => BasketList(categoryId: categoryId, quantity: 0, name: '', price: 0, imageUrl: null),
    );
    return item.quantity;
  }

  Future<void> fetchQuote({bool? noFolding, GlobalKey<ScaffoldMessengerState>? scaffoldKey}) async {
    final flag = noFolding ?? _isNoFolding;
    _isQuoteLoading = true;
    notifyListeners();

    final quote = await BasketClass.getQuote(flag, scaffoldKey: scaffoldKey);
    if (quote != null) {
      _currentQuote = quote;
    }
    _isQuoteLoading = false;
    notifyListeners();
  }

  Future<void> setNoFolding(bool value, {GlobalKey<ScaffoldMessengerState>? scaffoldKey}) async {
    _isNoFolding = value;
    notifyListeners();
    await fetchQuote(noFolding: value, scaffoldKey: scaffoldKey);
  }

  Future<void> fetchBasket(GlobalKey<ScaffoldMessengerState> scaffoldKey, {bool showLoading = true}) async {
    if (showLoading) {
      _isLoading = true;
      notifyListeners();
    }

    final result = await BasketClass.getServices(scaffoldKey);
    if (result != null) {
      _basketItems = result;
      if (_basketItems.isNotEmpty) {
        await fetchQuote(noFolding: _isNoFolding, scaffoldKey: scaffoldKey);
      } else {
        _currentQuote = BasketQuote.empty();
      }
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
    // Optimistic local update for instant UI responsiveness
    final index = _basketItems.indexWhere((item) => item.categoryId == categoryId);
    if (index != -1) {
      if (quantity <= 0) {
        _basketItems.removeAt(index);
      } else {
        final current = _basketItems[index];
        _basketItems[index] = BasketList(
          categoryId: current.categoryId,
          quantity: quantity,
          name: current.name,
          price: current.price,
          imageUrl: current.imageUrl,
        );
      }
      notifyListeners();
    }

    await BasketClass.updateQuantity(categoryId, quantity, scaffoldKey);
    await fetchBasket(scaffoldKey, showLoading: false);
  }

  Future<void> removeFromBasket(int categoryId, GlobalKey<ScaffoldMessengerState> scaffoldKey) async {
    // Optimistic local removal
    _basketItems.removeWhere((item) => item.categoryId == categoryId);
    notifyListeners();

    await ServicesClass.removeFromBasket(categoryId, scaffoldKey);
    await fetchBasket(scaffoldKey, showLoading: false);
  }

  Future<void> clearBasket(GlobalKey<ScaffoldMessengerState> scaffoldKey) async {
    await BasketClass.clearBasket(scaffoldKey);
    _basketItems = [];
    _currentQuote = BasketQuote.empty();
    notifyListeners();
  }
}
