import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:foam_mobile/core/Screens/basket/model/basket.dart';
import 'package:foam_mobile/core/Screens/basket/model/basket_quote.dart';
import 'package:foam_mobile/core/hive/hive.dart';
import 'package:foam_mobile/core/intro_screens/onboarding_screen.dart';
import 'package:foam_mobile/feature/authentication/controller/provider/authprovider.dart';
import 'package:foam_mobile/feature/authentication/model/log_out_model.dart';
import 'package:foam_mobile/utils/values.dart';
import 'package:foam_mobile/widgets/message_handler.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

class BasketClass {
  static Future<BasketQuote?> getQuote(
    bool noFolding, {
    GlobalKey<ScaffoldMessengerState>? scaffoldKey,
    BuildContext? context,
  }) async {
    try {
      final res = await http.post(
        Uri.parse("${Constants.url}/api/user/basket/quote"),
        headers: {
          "Authorization": "Bearer ${HiveClass.getToken()}",
          "Accept": "application/json",
          "Content-Type": "application/json",
        },
        body: jsonEncode({"noFolding": noFolding}),
      );

      if (res.statusCode == 401 && context != null) {
        LogoutClass.logOut2(context);
        return null;
      }

      if (res.statusCode == 200 || res.statusCode == 201) {
        debugPrint("Basket quote: ${res.body}");
        return basketQuoteFromJson(res.body);
      } else {
        debugPrint("Failed to get quote: ${res.statusCode} ${res.body}");
        if (scaffoldKey != null) {
          MyMessageHandler.showSnackBar(
              scaffoldKey, "Failed to calculate quote");
        }
        return null;
      }
    } catch (e) {
      debugPrint("Error fetching quote: $e");
      if (scaffoldKey != null) {
        MyMessageHandler.showSnackBar(scaffoldKey, "Failed to calculate quote");
      }
      return null;
    }
  }

  static Future<List<BasketList>?> getServices(
      GlobalKey<ScaffoldMessengerState> scaffoldKey,
      [BuildContext? context]) async {
    try {
      final res = await http.get(
        Uri.parse(
          "${Constants.url}/api/user/basket",
        ),
        headers: {
          // here you get authorize by adding the token like a key to the header to have answers
          "Authorization": "Bearer ${HiveClass.getToken()}",
          "Accept": "application/json",
          'Content-Type': 'application/json'
        },
      );

      if (res.statusCode == 401 && context != null) {
        LogoutClass.logOut2(context);
        return null;
      }

      var response = res.body;
      if (res.statusCode == 200 || res.statusCode == 201) {
        // MyMessageHandler.showSnackBar(scaffoldKey, "Basket loaded");
        debugPrint(response.toString());
        return basketListFromJson(response);
      } else {
        debugPrint(res.reasonPhrase.toString());
        debugPrint(res.statusCode.toString());
        debugPrint(res.headers.toString());
        debugPrint(res.body);
        MyMessageHandler.showSnackBar(scaffoldKey, "Failed to load Basket");
        return null;
      }
    } catch (e) {
      debugPrint(e.toString());
      MyMessageHandler.showSnackBar(scaffoldKey, "Failed to load Basket");
      return [];
    }
  }

  static Future<Map<String, dynamic>?> updateQuantity(
    int categoryId,
    int quantity,
    GlobalKey<ScaffoldMessengerState> scaffoldKey, {
    bool noFolding = false,
    BuildContext? context,
  }) async {
    try {
      final res = await http.put(
        Uri.parse("${Constants.url}/api/user/basket/category/$categoryId"),
        headers: {
          "Authorization": "Bearer ${HiveClass.getToken()}",
          "Accept": "application/json",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "quantity": quantity,
          "noFolding": noFolding,
        }),
      );

      if (res.statusCode == 401 && context != null) {
        LogoutClass.logOut2(context);
        return null;
      }

      if (res.statusCode == 200 || res.statusCode == 201) {
        debugPrint("Quantity updated: ${res.body}");
        final data = jsonDecode(res.body);
        return data is Map<String, dynamic> ? data : null;
      } else {
        debugPrint("Failed to update quantity: ${res.statusCode}");
        MyMessageHandler.showSnackBar(scaffoldKey, "Failed to update quantity");
        return null;
      }
    } catch (e) {
      debugPrint("Error updating quantity: $e");
      MyMessageHandler.showSnackBar(scaffoldKey, "Error updating quantity");
      return null;
    }
  }

  static Future<Map<String, dynamic>?> removeItemByCategory(
    int categoryId,
    GlobalKey<ScaffoldMessengerState> scaffoldKey, {
    bool noFolding = false,
    BuildContext? context,
  }) async {
    try {
      final res = await http.delete(
        Uri.parse("${Constants.url}/api/user/basket/category/$categoryId"),
        headers: {
          "Authorization": "Bearer ${HiveClass.getToken()}",
          "Accept": "application/json",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "noFolding": noFolding,
        }),
      );

      if (res.statusCode == 401 && context != null) {
        LogoutClass.logOut2(context);
        return null;
      }

      if (res.statusCode == 200 || res.statusCode == 201) {
        debugPrint("Item removed: ${res.body}");
        final data = jsonDecode(res.body);
        return data is Map<String, dynamic> ? data : null;
      } else {
        debugPrint("Failed to remove item: ${res.statusCode}");
        MyMessageHandler.showSnackBar(scaffoldKey, "Failed to remove item");
        return null;
      }
    } catch (e) {
      debugPrint("Error removing item: $e");
      MyMessageHandler.showSnackBar(scaffoldKey, "Error removing item");
      return null;
    }
  }

  static Future<void> clearBasket(GlobalKey<ScaffoldMessengerState> scaffoldKey,
      [BuildContext? context]) async {
    try {
      final res = await http.delete(
        Uri.parse("${Constants.url}/api/user/basket/"),
        headers: {
          "Authorization": "Bearer ${HiveClass.getToken()}",
          "Accept": "application/json",
          "Content-Type": "application/json",
        },
      );

      if (res.statusCode == 401 && context != null) {
        LogoutClass.logOut2(context);
        return;
      }

      if (res.statusCode == 200 || res.statusCode == 201) {
        MyMessageHandler.showSnackBar(scaffoldKey, "Basket cleared");
      } else {
        debugPrint("Failed to clear basket: ${res.statusCode}");
        MyMessageHandler.showSnackBar(scaffoldKey, "Failed to clear basket");
      }
    } catch (e) {
      debugPrint("Error clearing basket: $e");
      MyMessageHandler.showSnackBar(scaffoldKey, "Error clearing basket");
    }
  }
}
