import 'package:flutter/material.dart';
import 'package:foam_mobile/core/Screens/billing/billing_screen.dart';
import 'package:foam_mobile/core/Screens/help/help_screen.dart';
import 'package:foam_mobile/core/Screens/home/services_screen/views/services_screen.dart';
import 'package:foam_mobile/core/Screens/profile/profile_screen.dart';
import 'package:foam_mobile/feature/authentication/model/log_out_model.dart';
import 'package:foam_mobile/utils/values.dart';
import 'package:foam_mobile/widgets/drawer_tile.dart';
import 'package:google_fonts/google_fonts.dart';

class MyDrawer extends StatelessWidget {
  final String firstName;
  final GlobalKey<ScaffoldMessengerState> scaffoldKey;

  const MyDrawer({
    required this.firstName,
    required this.scaffoldKey,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    void showLogOutMessage(String message) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            backgroundColor: AppColors.primaryBackgroundColor,
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  message,
                  style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.bold,
                    fontSize: 25,
                    color: Colors.black,
                  ),
                ),
                AppSpaces.verticalSpace40,
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    DecisionButton(
                      text: 'Cancel',
                      color: AppColors.primaryBackgroundColor,
                      fontSize: 17,
                      border: false,
                      onPressed: () => Navigator.pop(context),
                    ),
                    DecisionButton(
                      text: 'Log Out',
                      color: AppColors.blackAccentColor,
                      fontSize: 17,
                      border: true,
                      onPressed: () {
                        LogoutClass.logOut(
                          context,
                          scaffoldKey,
                        );
                      },
                    ),
                  ],
                )
              ],
            ),
          );
        },
      );
    }

    return Drawer(
      backgroundColor: AppColors.primaryBackgroundColor,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 100.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Column(
                children: [
                  AppSpaces.verticalSpace100,
                  //header sec
                  Padding(
                    padding: const EdgeInsets.only(left: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Hello $firstName',
                          style: const TextStyle(
                            fontSize: 25,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(
                            Icons.close,
                            size: 30,
                          ),
                        ),
                      ],
                    ),
                  ),

                  AppSpaces.verticalSpace40,

                  //Profile tile sec
                  DrawerTile(
                    tile: 'Profile',
                    leading: const Icon(Icons.person),
                    onTap: () => Navigator.pushReplacementNamed(
                        context, ProfileScreen.id),
                  ),

                  //settings tile sec
                  DrawerTile(
                    tile: 'Services',
                    leading: const Icon(Icons.discount),
                    onTap: () => Navigator.of(context)
                        .popAndPushNamed(ServicesScreen.id),
                  ),

                  DrawerTile(
                    tile: 'Billing & Subscription',
                    leading: const Icon(Icons.credit_card_rounded),
                    onTap: () =>
                        Navigator.popAndPushNamed(context, BillingScreen.id),
                  ),

                  DrawerTile(
                    tile: 'Setting',
                    leading: const Icon(Icons.settings_outlined),
                    onTap: () => Navigator.pop(context),
                  ),

                  DrawerTile(
                    tile: 'Help',
                    leading: const Icon(Icons.help_outline_sharp),
                    onTap: () =>
                        Navigator.popAndPushNamed(context, HelpScreen.id),
                  ),
                ],
              ),
              SizedBox(
                height: MediaQuery.sizeOf(context).height / 7,
              ),
         Padding(
  padding: const EdgeInsets.symmetric(horizontal: 25.0),
  child: Material(
    color: AppColors.secondaryBackgroundColor,
    borderRadius: BorderRadius.circular(8),
    child: InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () {
        showLogOutMessage('Are you Sure?');
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 12.0,
          horizontal: 24.0,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Log Out',
              style: GoogleFonts.dmSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.logout,
              size: 18,
              color: AppColors.primaryBackgroundColor,
            ),
          ],
        ),
      ),
    ),
  ),
) ],
          ),
        ),
      ),
    );
  }
}

class DecisionButton extends StatelessWidget {
  final String text;
  final Color color;
  final double fontSize;
  final bool border;
  final Function()? onPressed;

  const DecisionButton({
    super.key,
    required this.text,
    required this.color,
    required this.fontSize,
    required this.onPressed,
    required this.border,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: 18.0,
          horizontal: 20.0,
        ),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.blackAccentColor, width: 2.0),
          color: color,
          borderRadius: const BorderRadius.all(
            Radius.circular(
              8.0,
            ),
          ),
        ),
        child: Text(
          text,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: GoogleFonts.dmSans(
            fontSize: fontSize,
            fontWeight: FontWeight.w500,
            color: border == true ? Colors.white : AppColors.blackAccentColor,
          ),
        ),
      ),
    );
  }
}
