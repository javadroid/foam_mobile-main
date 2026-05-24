part of '../values.dart';

class AppColors {
  static final Color primaryBackgroundColor = HexColor.fromHex("FFFFFFF");
  static final Color secondaryBackgroundColor = HexColor.fromHex("001C1F");
  static final Color primaryAccentColor = HexColor.fromHex("00AABC");
  static final Color secondaryAccentColor = HexColor.fromHex("C5EFF3");
  static final Color blackAccentColor = HexColor.fromHex("212828");
  static final Color shadeGreyAccentColor = HexColor.fromHex("E4E4E4");
  static final Color fadeBlueAccentColor = HexColor.fromHex("E5F7F8");
  static final Color navyBlueAccent = HexColor.fromHex("1D1F2C");
  static final Color trueBlueAccent = HexColor.fromHex("3250FF");
  static final Color oceanBlueColor = HexColor.fromHex("2AB2FE");
  static final Color greenTaleColor = HexColor.fromHex("21CAAD");
  static final Color yellowAccentColor = HexColor.fromHex("FFE554");

  static final List<Color> gradientColor = <Color>[
    // gradient for linear blue
    // blue
    AppColors.secondaryAccentColor,
    // white
    AppColors.primaryAccentColor,
  ];
}

extension HexColor on Color {
  /// String is in the format "aabbcc" or "ffaabbcc" with an optional leading "#".
  static Color fromHex(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  /// Prefixes a hash sign if [leadingHashSign] is set to `true` (default is `true`).
  String toHex({bool leadingHashSign = true}) => '${leadingHashSign ? '#' : ''}'
      '${alpha.toRadixString(16).padLeft(2, '0')}'
      '${red.toRadixString(16).padLeft(2, '0')}'
      '${green.toRadixString(16).padLeft(2, '0')}'
      '${blue.toRadixString(16).padLeft(2, '0')}';
}
