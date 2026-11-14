import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class HiveClass {
  static var foamBox = Hive.box('foam');

////////////TOKEN/////////////////////////

  // inserting the token
  static void insertToken(String token) {
    debugPrint(token);
    foamBox.put('token', token);
  }

  // getting the token
  static String getToken() {
    final token = foamBox.get('token');
    return (token is String) ? token : '';
  }

  // deleting the token
  static void deleteToken() {
    foamBox.delete('token');
  }

  // check if token exist
  static bool tokenExist() {
    final token = foamBox.get('token');
    return token is String && token.trim().isNotEmpty;
  }

  /////////////////PROFILE PIC///////////////////

  // inserting the token
  static void insertPic(String picture) {
    debugPrint(picture);
    foamBox.put('picture', picture);
  }

  // getting the token
  static String getPic() {
    final pic = foamBox.get('picture');
    return (pic is String) ? pic : '';
  }

  // deleting the token
  static void deletePic() {
    foamBox.delete('picture');
  }

  // check if token exist
  static bool pictureExists() {
    final pic = foamBox.get('picture');
    return pic is String && pic.trim().isNotEmpty;
  }

  /////////////////ADDRESS///////////////////
  // static void updateAddress(List<Map<String, String>> addresses, int main) {
  //   foamBox.put('addresses', addresses);
  //   foamBox.put('main', main);
  // }
  //
  // static int getMain() {
  //   return foamBox.get("main") ?? 0;
  // }
  //
  // static List<Map<String, String>> getAddresses() {
  //   List<dynamic> add = foamBox.get("addresses") ?? [];
  //   List<Map<String, String>> adds = [];
  //   for (var element in add) {
  //     Map<dynamic, dynamic> e = element;
  //
  //     Map<String, String> stringQueryParameters = Map.fromEntries(
  //       e.entries.map(
  //         (entry) => MapEntry(
  //           entry.key.toString(),
  //           entry.value.toString(),
  //         ),
  //       ),
  //     );
  //     adds.add(stringQueryParameters);
  //   }
  //
  //   return adds;
  // }
  //
  // static void deleteAddresses() {
  //   foamBox.delete("addresses");
  //   foamBox.put("main", 0);
  // }

  /////////////////DELIVERY & PICKUP DETAILS///////////////////
  static void saveDeliveryDetails({
    String? address,
    String? pickupDate,
    String? fromTime,
    String? toTime,
    String? deliveryDate,
  }) {
    if (address != null && address.trim().isNotEmpty) {
      foamBox.put('delivery_address', address.trim());
    }
    if (pickupDate != null && pickupDate.isNotEmpty) {
      foamBox.put('delivery_pickup_date', pickupDate);
    }
    if (fromTime != null && fromTime.isNotEmpty) {
      foamBox.put('delivery_from_time', fromTime);
    }
    if (toTime != null && toTime.isNotEmpty) {
      foamBox.put('delivery_to_time', toTime);
    }
    if (deliveryDate != null && deliveryDate.isNotEmpty) {
      foamBox.put('delivery_delivery_date', deliveryDate);
    }
  }

  static Map<String, String?> getDeliveryDetails() {
    return {
      'address': foamBox.get('delivery_address') as String?,
      'pickupDate': foamBox.get('delivery_pickup_date') as String?,
      'fromTime': foamBox.get('delivery_from_time') as String?,
      'toTime': foamBox.get('delivery_to_time') as String?,
      'deliveryDate': foamBox.get('delivery_delivery_date') as String?,
    };
  }

  ///////////////////////////////////
  static void clearHive() {
    deleteToken();
    deletePic();
  }
}
