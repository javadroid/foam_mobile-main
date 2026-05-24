import 'package:flutter/material.dart';
import 'package:foam_mobile/core/Screens/basket/view/basket_screen.dart';
import 'package:foam_mobile/core/Screens/history/history_screen.dart';
import 'package:foam_mobile/core/Screens/home/home_screen.dart';
import 'package:foam_mobile/core/Screens/profile/profile_screen.dart';
import 'package:foam_mobile/feature/authentication/controller/provider/authprovider.dart';
import 'package:foam_mobile/utils/values.dart';
import 'package:provider/provider.dart';
import 'package:ultimate_bottom_navbar/ultimate_bottom_navbar.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({
    super.key,
  });

  static const String id = '/main_screen';

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int currentIndex = 0;
  final GlobalKey<ScaffoldMessengerState> scaffoldKey =
      GlobalKey<ScaffoldMessengerState>();

  String? firstName;

  void logOutMessage(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                message,
                style: const TextStyle(
                  fontWeight: FontWeight.normal,
                  fontSize: 17,
                  color: Colors.black54,
                ),
              ),
              IconButton(
                onPressed: () {
                  //pop once to remove the dialog box
                  Navigator.pop(context);
                },
                icon: const Icon(
                  Icons.cancel,
                  color: Colors.red,
                  size: 40.0,
                ),
              )
            ],
          ),
        );
      },
    );
  }

  @override
  void initState() {
    var authProvider = Provider.of<AuthProvider>(context, listen: false);
    super.initState();
    setState(() {
      firstName = authProvider.firstName;
    });
  }

  void home() {
    setState(() {
      currentIndex = 0;
    });
  }

  void basket() {
    setState(() {
      currentIndex = 2;
    });
  }

  void profile() {
    setState(() {
      currentIndex = 3;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = <Widget>[
      HomePage(
        toProfile: profile,
      ),
      const HistoryScreen(),
      const BasketScreen(),
      ProfileScreen(toHome: home),
    ];
    return ScaffoldMessenger(
      key: scaffoldKey,
      child: Scaffold(
        body: screens[currentIndex],
        extendBody: true,
        //<------like this
        bottomNavigationBar: Container(
          height: MediaQuery.of(context).size.height * 0.11,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: AppColors.primaryAccentColor,
            gradient: LinearGradient(
              begin: Alignment.bottomLeft,
              end: Alignment.center,
              colors: [
                ...AppColors.gradientColor,
              ],
            ),
          ),
          child: UltimateBottomNavBar(
            icons: [
              currentIndex == 0 ? Icons.home : Icons.home_outlined,
              currentIndex == 1
                  ? Icons.access_time_filled
                  : Icons.access_time_outlined,
              currentIndex == 2
                  ? Icons.shopping_bag_rounded
                  : Icons.shopping_bag_outlined,
              currentIndex == 3 ? Icons.person : Icons.person_outline,
            ],
            titles: const [
              'Home',
              'History',
              'Basket',
              'Profile',
            ],
            currentIndex: currentIndex,
            onTap: (value) {
              setState(() {
                currentIndex = value;
              });
            },
            showBackGroundStrokeAllSide: false,
            backgroundStrokeBorderColor: Colors.transparent,
            //<--------this very important for good design looking
            showForeGround: false,
            //<------------this too
            animationType: Curves.elasticInOut,
            animationDuration: const Duration(seconds: 2),
            unselectedIconColor: AppColors.primaryBackgroundColor,
            selectedIconColor: AppColors.blackAccentColor,
            unselectedTextColor: AppColors.primaryBackgroundColor,
            selectedTextColor: AppColors.blackAccentColor,
            selectedIconSize: 30,
            selectedTextSize: 12,
            unselectedIconSize: 28,
            unselectedTextSize: 11,
          ),
        ),
      ),
    );
  }
}
