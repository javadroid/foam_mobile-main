part of '../values.dart';

class Constants {
  // URL
  static String url = "https://foamlaundryapp.com";

  // PayStack public key
  static String payStackPublicKey =
      "pk_live_1ed764614ba0e2993ae08d6312e2cccb9a5e6c69";

  // PayStack secret key
  static String payStackSecretKey =
      "sk_live_c922bedfe508ed1cb6d0760c1abbd86064ff155e";

  // Google API key
  static const String googleAPIKey = 'AIzaSyA7hyiwzU6LHTHhtntU36tAPRi46DXrygo';
  static const String googleMapsApiKey =
      "AIzaSyB5O_2oARf0lU5YlGfDsxgeEj_l_HxOjNY";

  static TextStyle headingStyle = GoogleFonts.dmSans(
    color: AppColors.blackAccentColor,
    fontSize: 25,
    fontWeight: FontWeight.w500,
    textStyle: const TextStyle(
      textBaseline: TextBaseline.ideographic,
    ),
  );

  static TextStyle subHeadingStyle = GoogleFonts.dmSans(
    color: AppColors.blackAccentColor,
    fontSize: 18,
    fontWeight: FontWeight.w300,
    textStyle: const TextStyle(
      textBaseline: TextBaseline.alphabetic,
    ),
  );

  static TextStyle textStyle = const TextStyle(
    fontWeight: FontWeight.w300,
    fontSize: 18,
    textBaseline: TextBaseline.alphabetic,
  );

  static IndicatorEffect slideEffect1 = SlideEffect(
    spacing: 14,
    dotWidth: 10.0,
    dotHeight: 10.0,
    paintStyle: PaintingStyle.fill,
    dotColor: AppColors.fadeBlueAccentColor,
    activeDotColor: AppColors.secondaryBackgroundColor,
  );

  static IndicatorEffect slideEffect2 = SlideEffect(
    spacing: 14,
    dotWidth: 10.0,
    dotHeight: 10.0,
    paintStyle: PaintingStyle.fill,
    dotColor: AppColors.fadeBlueAccentColor,
    activeDotColor: AppColors.primaryAccentColor,
  );

  String currencyFormat(int totalAmount) {
    // Convert the money to a string and use RegExp for formatting
    return totalAmount.toString().replaceAllMapped(
          RegExp(r'\B(?=(\d{3})+(?!\d))'),
          // Matches positions before groups of 3 digits
          (match) => ',',
        );
  }

  String formatDate(DateTime date) {
    // Get the day with the appropriate ordinal suffix
    String dayWithSuffix(int day) {
      if (day >= 11 && day <= 13) {
        return '${day}th'; // Special case for 11th, 12th, 13th
      }
      switch (day % 10) {
        case 1:
          return '${day}st';
        case 2:
          return '${day}nd';
        case 3:
          return '${day}rd';
        default:
          return '${day}th';
      }
    }

    // Format the month and year
    String month =
        DateFormat('MMMM').format(date); // Full month name (e.g., August)
    String year = DateFormat('y').format(date); // Year (e.g., 2024)

    return '${dayWithSuffix(date.day)} $month $year';
  }

  String formatTime(DateTime time) {
    // Use DateFormat to format time in the desired format
    return DateFormat('h:mm a')
        .format(time); // 'h' for hour, 'mm' for minutes, 'a' for AM/PM
  }
}

class DrawerProvider with ChangeNotifier {
  //initially drawer isn't called
  bool _isDrawer = false;

  //getter method to access the value from other parts of the code
  bool get isDrawer => _isDrawer;

  //getter method to see if the dark is turned on or not
  bool get drawerUse => _isDrawer == true;

  //setter method to set the value of the drawer being used
  set isDrawer(bool drawer) {
    _isDrawer = drawer;
    notifyListeners();
  }

  //this enables the switching of drawer
  //from either use or not
  void toggleDrawer() {
    if (_isDrawer == false) {
      isDrawer = drawerUse;
    } else {
      isDrawer = false;
    }
  }
}
