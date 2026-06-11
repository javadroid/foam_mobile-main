import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:foam_mobile/core/Screens/home/services_screen/models/services.dart';
import 'package:foam_mobile/core/Screens/history/model/order.dart';
import 'package:foam_mobile/core/hive/hive.dart';
import 'package:foam_mobile/utils/values.dart';
import 'package:foam_mobile/widgets/message_handler.dart';
import 'package:http/http.dart' as http;

import 'package:foam_mobile/core/Screens/home/services_screen/models/add_to_basket_model.dart';

class ServicesClass {
  static Future<List<CategoryItem>?> getCategories(
      GlobalKey<ScaffoldMessengerState> scaffoldKey) async {
    try {
      final res = await http.get(
        Uri.parse("${Constants.url}/api/category/"),
        headers: {
          "Accept": "application/json",
          'Content-Type': 'application/json'
        },
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        log(jsonEncode(json.decode(res.body)));
        return categoryListFromJson(res.body);
      } else {
        MyMessageHandler.showSnackBar(scaffoldKey, "Failed to load Categories");
        return null;
      }
    } catch (e) {
      log("Exception: $e");
      MyMessageHandler.showSnackBar(scaffoldKey, "Failed to load Categories");
      return null;
    }
  }

  static Future<List<ServicesList>?> getServices(
      GlobalKey<ScaffoldMessengerState> scaffoldKey) async {
    try {
      final res = await http.get(
        Uri.parse("${Constants.url}/api/services"),
        headers: {
          "Accept": "application/json",
          'Content-Type': 'application/json'
        },
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        MyMessageHandler.showSnackBar(scaffoldKey, "Services loaded");
        log(jsonEncode(json.decode(res.body))); // Properly log response
        return servicesListFromJson(res.body);
      } else {
        log("Error: ${res.statusCode} - ${res.reasonPhrase}");
        log("Headers: ${jsonEncode(res.headers)}");
        log("Body: ${res.body}");
        MyMessageHandler.showSnackBar(scaffoldKey, "Failed to load Services");
        return null;
      }
    } catch (e) {
      log("Exception: $e");
      MyMessageHandler.showSnackBar(scaffoldKey, "Failed to load Services");
      return null; // Return null for consistency
    }
  }

  static Future<void> updateQuantity(
      int categoryId, int quantity, GlobalKey<ScaffoldMessengerState> scaffoldKey) async {
    try {
      final res = await http.put(
        Uri.parse("${Constants.url}/api/user/basket/category/$categoryId"),
        headers: {
          "Accept": "application/json",
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${HiveClass.getToken()}',
        },
        body: jsonEncode({"quantity": quantity}),
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        log("Item updated successfully");
      } else {
        MyMessageHandler.showSnackBar(scaffoldKey, "Failed to update quantity");
      }
    } catch (e) {
      log("Exception: $e");
    }
  }

  static Future<void> removeFromBasket(
      int categoryId, GlobalKey<ScaffoldMessengerState> scaffoldKey) async {
    try {
      final res = await http.delete(
        Uri.parse("${Constants.url}/api/user/basket/category/$categoryId"),
        headers: {
          "Accept": "application/json",
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${HiveClass.getToken()}',
        },
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        log("Item removed from basket successfully");
      } else {
        MyMessageHandler.showSnackBar(scaffoldKey, "Failed to remove item");
      }
    } catch (e) {
      log("Exception: $e");
    }
  }

  static Future<void> addToBasket(
      BuildContext context,
      int serviceId,
      int categoryId,
      int quantity,
      GlobalKey<ScaffoldMessengerState> scaffoldKey) async {
    try {
      final res = await http.post(
        Uri.parse("${Constants.url}/api/user/basket"),
        headers: {
          "Accept": "application/json",
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${HiveClass.getToken()}',
        },
        body: jsonEncode({
          "categoryId": categoryId,
          "quantity": quantity,
        }),
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        MyMessageHandler.showSnackBar(scaffoldKey, "Added to basket");
      } else {
        MyMessageHandler.showSnackBar(scaffoldKey, "Failed to add to basket");
      }
    } catch (e) {
      log("Exception: $e");
      MyMessageHandler.showSnackBar(scaffoldKey, "An error occurred");
    }
  }

  static Future<List<Order>?> getOrders(
      GlobalKey<ScaffoldMessengerState> scaffoldKey) async {
    try {
      final res = await http.get(
        Uri.parse("${Constants.url}/api/order/"),
        headers: {
          "Accept": "application/json",
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${HiveClass.getToken()}',
        },
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        log(jsonEncode(json.decode(res.body)));
        return OrderResponse.fromJson(json.decode(res.body)).orders;
      } else {
        MyMessageHandler.showSnackBar(scaffoldKey, "Failed to load Orders");
        return null;
      }
    } catch (e) {
      log("Exception: $e");
      MyMessageHandler.showSnackBar(scaffoldKey, "Failed to load Orders");
      return null;
    }
  }
}
