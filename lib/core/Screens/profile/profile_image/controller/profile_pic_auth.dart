import 'dart:io';
import 'package:flutter/material.dart';
import 'package:foam_mobile/core/hive/hive.dart';

class ProfilePicAuth extends ChangeNotifier {
  //Profile picture empty
  File _image = File(HiveClass.getPic());

  File get image => _image;

  void updateFile(File file, String filePath) {
    _image = file;
    HiveClass.insertPic(filePath);
    notifyListeners();
  }

  void clearFile(File file) {
    _image = File(HiveClass.getPic());
    notifyListeners();
  }
}
