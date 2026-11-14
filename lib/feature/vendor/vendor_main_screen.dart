import 'package:flutter/material.dart';
import 'package:foam_mobile/feature/vendor/orders/vendor_orders_screen.dart';
import 'package:foam_mobile/feature/vendor/profile/vendor_profile_screen.dart';
import 'package:foam_mobile/feature/vendor/stores/vendor_stores_list_screen.dart';
import 'package:foam_mobile/feature/vendor/wallet/vendor_revenue_screen.dart';
import 'package:foam_mobile/feature/vendor/wallet/vendor_wallet_screen.dart';
import 'package:foam_mobile/feature/vendor/widgets/vendor_ui_components.dart';
import 'package:google_fonts/google_fonts.dart';

class VendorMainScreen extends StatefulWidget {
  static const String id = '/vendor_main';

  final int initialIndex;

  const VendorMainScreen({super.key, this.initialIndex = 0});

  @override
  State<VendorMainScreen> createState() => _VendorMainScreenState();
}

class _VendorMainScreenState extends State<VendorMainScreen> {
  late int _currentIndex;

  final List<Widget> _screens = const [
    VendorOrdersScreen(),
    VendorStoresListScreen(),
    VendorRevenueScreen(),
    VendorWalletScreen(),
    VendorProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_currentIndex != 0) {
          setState(() => _currentIndex = 0);
        }
      },
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
        bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: VendorColors.border, width: 1.0)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          backgroundColor: Colors.white,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: VendorColors.primary,
          unselectedItemColor: VendorColors.textMuted,
          selectedLabelStyle: GoogleFonts.dmSans(
            fontWeight: FontWeight.w700,
            fontSize: 11.5,
          ),
          unselectedLabelStyle: GoogleFonts.dmSans(
            fontWeight: FontWeight.w600,
            fontSize: 11.5,
          ),
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_outlined),
              activeIcon: Icon(Icons.receipt_long),
              label: 'Orders',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.storefront_outlined),
              activeIcon: Icon(Icons.storefront),
              label: 'Stores',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.trending_up_rounded),
              activeIcon: Icon(Icons.trending_up_rounded),
              label: 'Revenue',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_wallet_outlined),
              activeIcon: Icon(Icons.account_balance_wallet),
              label: 'Wallet',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              activeIcon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    ),
  );
  }
}
