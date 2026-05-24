import 'package:flutter/material.dart';
import 'package:foam_mobile/utils/values.dart';

//light mode
ThemeData lightMode = ThemeData(
  colorSchemeSeed: AppColors.primaryAccentColor,
  useMaterial3: true,
  brightness: Brightness.light,
  // colorScheme: ColorScheme.light(
  //   background: AppColors.primaryBackgroundColor,
  //   primary: AppColors.primaryAccentColor,
  //   secondary: AppColors.secondaryAccentColor,
  //   inversePrimary: AppColors.secondaryBackgroundColor,
  // ),
);

//dark mode
ThemeData darkMode = ThemeData(
  colorSchemeSeed: AppColors.primaryAccentColor,
  useMaterial3: true,
  brightness: Brightness.dark,
  // colorScheme: ColorScheme.light(
  //   background: AppColors.primaryBackgroundColor,
  //   primary: AppColors.primaryAccentColor,
  //   secondary: AppColors.secondaryAccentColor,
  //   inversePrimary: AppColors.secondaryBackgroundColor,
  // ),
);
