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

  int get totalItems =>
      _basketItems.fold(0, (sum, item) => sum + item.quantity);
  int get totalAmount =>
      _currentQuote?.subtotal ??
      _basketItems.fold(0, (sum, item) => sum + (item.price * item.quantity));
  int get foldingSurchargeTotal => _currentQuote?.foldingSurchargeTotal ?? 0;
  int get deliveryFee => _currentQuote?.deliveryFee ?? 3000;
  int get serviceFee => _currentQuote?.serviceFee ?? 300;
  int get totalPrice =>
      _currentQuote?.totalPrice ??
      (totalAmount +
          deliveryFee +
          serviceFee +
          (_isNoFolding ? foldingSurchargeTotal : 0));

  int getQuantity(String categoryId) {
    final item = _basketItems.firstWhere(
      (element) => element.categoryId == categoryId,
      orElse: () => BasketList(
          categoryId: categoryId,
          quantity: 0,
          name: '',
          price: 0,
          imageUrl: null),
    );
    return item.quantity;
  }

  Future<void> fetchQuote(
      {bool? noFolding, GlobalKey<ScaffoldMessengerState>? scaffoldKey}) async {
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

  Future<void> setNoFolding(bool value,
      {GlobalKey<ScaffoldMessengerState>? scaffoldKey}) async {
    _isNoFolding = value;
    notifyListeners();
    await fetchQuote(noFolding: value, scaffoldKey: scaffoldKey);
  }

  Future<void> fetchBasket(GlobalKey<ScaffoldMessengerState> scaffoldKey,
      {bool showLoading = true, bool refreshQuote = true}) async {
    if (showLoading) {
      _isLoading = true;
      notifyListeners();
    }

    final result = await BasketClass.getServices(scaffoldKey);
    if (result != null) {
      if (_basketItems.isNotEmpty) {
        final existingOrder = {
          for (var i = 0; i < _basketItems.length; i++)
            _basketItems[i].categoryId: i
        };
        result.sort((a, b) {
          final orderA = existingOrder[a.categoryId] ?? 999999;
          final orderB = existingOrder[b.categoryId] ?? 999999;
          return orderA.compareTo(orderB);
        });
      }
      _basketItems = result;
      if (refreshQuote) {
        if (_basketItems.isNotEmpty) {
          await fetchQuote(noFolding: _isNoFolding, scaffoldKey: scaffoldKey);
        } else {
          _currentQuote = BasketQuote.empty();
        }
      } else {
        _currentQuote = null;
      }
    }

    if (showLoading) {
      _isLoading = false;
    }
    notifyListeners();
  }

  Future<void> addToBasket(
    BuildContext context,
    String serviceId,
    String categoryId,
    int quantity,
    GlobalKey<ScaffoldMessengerState> scaffoldKey, {
    String? itemName,
    int? itemPrice,
    String? itemImageUrl,
    bool refreshQuote = false,
  }) async {
    // Optimistic local update for instant UI responsiveness
    final index =
        _basketItems.indexWhere((item) => item.categoryId == categoryId);
    if (index != -1) {
      final current = _basketItems[index];
      _basketItems[index] = BasketList(
        categoryId: current.categoryId,
        quantity: current.quantity + quantity,
        name: current.name,
        price: current.price,
        imageUrl: current.imageUrl,
      );
      notifyListeners();
    } else if (itemName != null) {
      _basketItems.add(BasketList(
        categoryId: categoryId,
        quantity: quantity,
        name: itemName,
        price: itemPrice ?? 0,
        imageUrl: itemImageUrl,
      ));
      notifyListeners();
    }

    await ServicesClass.addToBasket(
        context, serviceId, categoryId, quantity, scaffoldKey);
    await fetchBasket(scaffoldKey,
        showLoading: false, refreshQuote: refreshQuote);
  }

  Future<void> updateQuantity(
    String categoryId,
    int quantity,
    GlobalKey<ScaffoldMessengerState> scaffoldKey, {
    bool refreshQuote = true,
  }) async {
    // Optimistic local update for instant UI responsiveness
    final index =
        _basketItems.indexWhere((item) => item.categoryId == categoryId);
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
      if (refreshQuote) {
        _isQuoteLoading = true;
      }
      notifyListeners();
    }

    final res = await BasketClass.updateQuantity(
      categoryId,
      quantity,
      scaffoldKey,
      noFolding: _isNoFolding,
    );

    if (res != null) {
      if (refreshQuote && res['quote'] != null) {
        _currentQuote = BasketQuote.fromJson(res['quote']);
      }
      if (res['basket'] != null && res['basket']['items'] != null) {
        final existingOrder = {
          for (var i = 0; i < _basketItems.length; i++)
            _basketItems[i].categoryId: i
        };
        final updatedItems = List<BasketList>.from(
          (res['basket']['items'] as List).map((x) => BasketList.fromJson(x)),
        );
        updatedItems.sort((a, b) {
          final orderA = existingOrder[a.categoryId] ?? 999999;
          final orderB = existingOrder[b.categoryId] ?? 999999;
          return orderA.compareTo(orderB);
        });
        _basketItems = updatedItems;
      }
      if (_basketItems.isEmpty) {
        _currentQuote = BasketQuote.empty();
      }
      _isQuoteLoading = false;
      notifyListeners();
    } else {
      _isQuoteLoading = false;
      await fetchBasket(scaffoldKey,
          showLoading: false, refreshQuote: refreshQuote);
    }
  }

  Future<void> removeFromBasket(
    String categoryId,
    GlobalKey<ScaffoldMessengerState> scaffoldKey, {
    bool refreshQuote = true,
  }) async {
    // Optimistic local removal
    _basketItems.removeWhere((item) => item.categoryId == categoryId);
    if (refreshQuote) {
      _isQuoteLoading = true;
    }
    notifyListeners();

    final res = await BasketClass.removeItemByCategory(
      categoryId,
      scaffoldKey,
      noFolding: _isNoFolding,
    );

    if (res != null) {
      if (refreshQuote && res['quote'] != null) {
        _currentQuote = BasketQuote.fromJson(res['quote']);
      }
      if (res['basket'] != null && res['basket']['items'] != null) {
        final existingOrder = {
          for (var i = 0; i < _basketItems.length; i++)
            _basketItems[i].categoryId: i
        };
        final updatedItems = List<BasketList>.from(
          (res['basket']['items'] as List).map((x) => BasketList.fromJson(x)),
        );
        updatedItems.sort((a, b) {
          final orderA = existingOrder[a.categoryId] ?? 999999;
          final orderB = existingOrder[b.categoryId] ?? 999999;
          return orderA.compareTo(orderB);
        });
        _basketItems = updatedItems;
      }
      if (_basketItems.isEmpty) {
        _currentQuote = BasketQuote.empty();
      }
      _isQuoteLoading = false;
      notifyListeners();
    } else {
      _isQuoteLoading = false;
      await fetchBasket(scaffoldKey,
          showLoading: false, refreshQuote: refreshQuote);
    }
  }

  Future<void> clearBasket(
      GlobalKey<ScaffoldMessengerState> scaffoldKey) async {
    await BasketClass.clearBasket(scaffoldKey);
    _basketItems = [];
    _currentQuote = BasketQuote.empty();
    notifyListeners();
  }
}
