import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:foam_mobile/core/Screens/home/services_screen/models/services.dart';
import 'package:foam_mobile/core/Screens/home/services_screen/views/pickup_details_screen.dart';
import 'package:foam_mobile/core/hive/hive.dart';
import 'package:foam_mobile/utils/values.dart';
import 'package:foam_mobile/widgets/message_handler.dart';
import 'package:http/http.dart' as http;

class ServicesClass {
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

  static Future<void> addToBasket(
    BuildContext context,
    int id,
    int quantity,
    GlobalKey<ScaffoldMessengerState> scaffoldKey,
  ) async {
    try {
      final adjustedQuantity =
          (quantity == 0) ? 1 : quantity; // Fix quantity increment

      final res = await http.post(
        Uri.parse("${Constants.url}/api/user/basket/"),
        headers: {
          "Accept": "application/json",
          "Content-Type": "application/json",
          "Authorization": "Bearer ${HiveClass.getToken()}",
        },
        body: jsonEncode({
          "categoryId": id,
          "quantity": adjustedQuantity,
        }),
      );

      var response = json.decode(res.body);
      log(jsonEncode(response)); // Fix logging of JSON response

      if (res.statusCode == 200 || res.statusCode == 201) {
        MyMessageHandler.showSnackBar(scaffoldKey, "Added to basket");
        Navigator.pushNamed(context, PickupDetailsScreen.id);
      } else {
        log("Error: ${res.statusCode} - ${res.reasonPhrase}");
        log("Headers: ${jsonEncode(res.headers)}");
        log("Body: ${res.body}");
        MyMessageHandler.showSnackBar(scaffoldKey, "Failed to add to basket");
      }
    } catch (e) {
      log("Exception: $e");
      MyMessageHandler.showSnackBar(scaffoldKey, "Failed to add to basket");
    }
  }
}
