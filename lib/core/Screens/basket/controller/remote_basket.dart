import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:foam_mobile/core/Screens/basket/model/basket.dart';
import 'package:foam_mobile/core/hive/hive.dart';
import 'package:foam_mobile/utils/values.dart';
import 'package:foam_mobile/widgets/message_handler.dart';
import 'package:http/http.dart' as http;

class BasketClass {
  static Future<List<BasketList>?> getServices(
      GlobalKey<ScaffoldMessengerState> scaffoldKey) async {
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
      var response = res.body;
      if (res.statusCode == 200 || res.statusCode == 201) {
        MyMessageHandler.showSnackBar(scaffoldKey, "Basket loaded");
        log(response.toString());
        return basketListFromJson(response);
      } else {
        log(res.reasonPhrase.toString());
        log(res.statusCode.toString());
        log(res.headers.toString());
        log(res.body);
        MyMessageHandler.showSnackBar(scaffoldKey, "Failed to load Basket");
        return null;
      }
    } catch (e) {
      log(e.toString());
      MyMessageHandler.showSnackBar(scaffoldKey, "Failed to load Basket");
      return [];
    }
  }

  static Future<void> updateQuantity(
    int categoryId,
    int quantity,
    GlobalKey<ScaffoldMessengerState> scaffoldKey,
  ) async {
    try {
      final res = await http.put(
        Uri.parse("${Constants.url}/api/user/basket/category/$categoryId"),
        headers: {
          "Authorization": "Bearer ${HiveClass.getToken()}",
          "Accept": "application/json",
          "Content-Type": "application/json",
        },
        body: jsonEncode({"quantity": quantity}),
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        log("Quantity updated: ${res.body}");
      } else {
        log("Failed to update quantity: ${res.statusCode}");
        MyMessageHandler.showSnackBar(scaffoldKey, "Failed to update quantity");
      }
    } catch (e) {
      log("Error updating quantity: $e");
      MyMessageHandler.showSnackBar(scaffoldKey, "Error updating quantity");
    }
  }

  static Future<void> clearBasket(
    GlobalKey<ScaffoldMessengerState> scaffoldKey,
  ) async {
    try {
      final res = await http.delete(
        Uri.parse("${Constants.url}/api/user/basket/"),
        headers: {
          "Authorization": "Bearer ${HiveClass.getToken()}",
          "Accept": "application/json",
          "Content-Type": "application/json",
        },
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        MyMessageHandler.showSnackBar(scaffoldKey, "Basket cleared");
      } else {
        log("Failed to clear basket: ${res.statusCode}");
        MyMessageHandler.showSnackBar(scaffoldKey, "Failed to clear basket");
      }
    } catch (e) {
      log("Error clearing basket: $e");
      MyMessageHandler.showSnackBar(scaffoldKey, "Error clearing basket");
    }
  }
}
