import 'package:flutter/material.dart';
import 'package:foam_mobile/core/Screens/basket/view/basket_screen.dart';
import 'package:foam_mobile/core/Screens/history/history_screen.dart';
import 'package:foam_mobile/core/Screens/home/home_screen.dart';
import 'package:foam_mobile/core/Screens/profile/profile_screen.dart';
import 'package:foam_mobile/feature/authentication/controller/provider/authprovider.dart';
import 'package:foam_mobile/utils/values.dart';
import 'package:provider/provider.dart';
import 'package:foam_mobile/core/hive/hive.dart';
import 'package:foam_mobile/core/provider/basket_provider.dart';
import 'package:ultimate_bottom_navbar/ultimate_bottom_navbar.dart';

class MainScreen extends StatefulWidget {
  final int initialIndex;
  const MainScreen({
    super.key,
    this.initialIndex = 0,
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
    super.initState();
    currentIndex = widget.initialIndex;
    var authProvider = Provider.of<AuthProvider>(context, listen: false);
    var basketProvider = Provider.of<BasketProvider>(context, listen: false);

    setState(() {
      firstName = authProvider.firstName;
    });

    if (HiveClass.tokenExist()) {
      basketProvider.fetchBasket(scaffoldKey);
    }
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
        body: IndexedStack(
          index: currentIndex,
          children: screens,
        ),
        extendBody: true,
        //<------like this
        bottomNavigationBar: Consumer<BasketProvider>(
          builder: (context, basketProvider, child) {
            final int basketCount = basketProvider.basketItems.fold<int>(
              0,
              (sum, item) => sum + item.quantity,
            );

            final double bottomPadding = MediaQuery.of(context).padding.bottom;
            final double barHeight = 70.0 + (bottomPadding > 0 ? bottomPadding * 0.4 : 0.0);

            return Container(
              height: barHeight,
              padding: EdgeInsets.only(
                bottom: bottomPadding > 0 ? bottomPadding * 0.25 : 0.0,
              ),
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                color: AppColors.primaryAccentColor,
                gradient: LinearGradient(
                  begin: Alignment.bottomLeft,
                  end: Alignment.center,
                  colors: [
                    ...AppColors.gradientColor,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.12),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  UltimateBottomNavBar(
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
                    showForeGround: false,
                    animationType: Curves.easeOutCubic,
                    animationDuration: const Duration(milliseconds: 240),
                    unselectedIconColor: AppColors.primaryBackgroundColor,
                    selectedIconColor: AppColors.blackAccentColor,
                    unselectedTextColor: AppColors.primaryBackgroundColor,
                    selectedTextColor: AppColors.blackAccentColor,
                    selectedIconSize: 28,
                    selectedTextSize: 11.5,
                    unselectedIconSize: 26,
                    unselectedTextSize: 11,
                  ),
                  if (basketCount > 0)
                    Positioned(
                      top: 6,
                      left: (MediaQuery.of(context).size.width * 0.625) + 4,
                      child: IgnorePointer(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white, width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                          child: Center(
                            child: Text(
                              basketCount > 99 ? '99+' : basketCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                height: 1.1,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
