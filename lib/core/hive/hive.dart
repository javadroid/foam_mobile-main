import 'dart:developer';
import 'package:hive/hive.dart';

class HiveClass {
  static var foamBox = Hive.box('foam');

////////////TOKEN/////////////////////////

  // inserting the token
  static void insertToken(String token) {
    log(token);
    foamBox.put('token', token);
  }

  // getting the token
  static String getToken() {
    return foamBox.get('token');
  }

  // deleting the token
  static void deleteToken() {
    foamBox.delete('token');
  }

  // check if token exist
  static bool tokenExist() {
    return foamBox.get('token') != null;
  }

  /////////////////PROFILE PIC///////////////////

  // inserting the token
  static void insertPic(String picture) {
    log(picture);
    foamBox.put('picture', picture);
  }

  // getting the token
  static String getPic() {
    return foamBox.get('picture') ?? '';
  }

  // deleting the token
  static void deletePic() {
    foamBox.delete('picture');
  }

  // check if token exist
  static bool pictureExists() {
    return foamBox.get('picture') != null;
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

  ///////////////////////////////////
  static void clearHive() {
    deleteToken();
    deletePic();
  }
}
