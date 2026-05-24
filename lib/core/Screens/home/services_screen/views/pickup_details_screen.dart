import 'package:flutter/material.dart';
import 'package:foam_mobile/core/Screens/main_screen.dart';
import 'package:foam_mobile/utils/values.dart';
import 'package:foam_mobile/widgets/click_button.dart';
import 'package:foam_mobile/widgets/pickup_dropdown.dart';
import 'package:foam_mobile/widgets/pickup_field.dart';

class PickupDetailsScreen extends StatefulWidget {
  const PickupDetailsScreen({
    super.key,
  });

  static const String id = '/pickup_details_page';

  @override
  State<PickupDetailsScreen> createState() => _PickupDetailsScreenState();
}

class _PickupDetailsScreenState extends State<PickupDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    final GlobalKey<ScaffoldMessengerState> scaffoldKey =
        GlobalKey<ScaffoldMessengerState>();

    return ScaffoldMessenger(
      key: scaffoldKey,
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          bottomOpacity: 6,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new,
              color: AppColors.blackAccentColor,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Pickup Details',
            overflow: TextOverflow.ellipsis,
            style: Constants.headingStyle,
          ),
        ),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding:
                    const EdgeInsets.only(left: 25.0, top: 15.0, bottom: 15.0),
                child: Text(
                  'Pickup/Delivery Address',
                  style: Constants.subHeadingStyle.copyWith(
                    fontSize: MediaQuery.sizeOf(context).height / 52,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const PickupDropdown(),
              AppSpaces.verticalSpace10,
              Padding(
                padding: const EdgeInsets.only(
                  left: 25.0,
                  top: 15.0,
                  bottom: 15.0,
                ),
                child: Text(
                  'Pickup Date',
                  style: Constants.subHeadingStyle.copyWith(
                    fontSize: MediaQuery.sizeOf(context).height / 52,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const PickupTextField(
                hinText: 'DD/MM/YY',
                isLink: true,
              ),
              AppSpaces.verticalSpace10,
              Padding(
                padding: const EdgeInsets.only(
                  left: 25.0,
                  top: 15.0,
                  bottom: 15.0,
                ),
                child: Text(
                  'Pickup Time',
                  style: Constants.subHeadingStyle.copyWith(
                    fontSize: MediaQuery.sizeOf(context).height / 52,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const PickupTextField(
                hinText: '00:00:00',
                isLink: true,
              ),
              AppSpaces.verticalSpace10,
              Padding(
                padding: const EdgeInsets.only(
                  left: 25.0,
                  top: 15.0,
                  bottom: 15.0,
                ),
                child: Text(
                  'Delivery Date',
                  style: Constants.subHeadingStyle.copyWith(
                    fontSize: MediaQuery.sizeOf(context).height / 52,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const PickupTextField(
                hinText: 'DD/MM/YY',
                isLink: true,
              ),
              AppSpaces.verticalSpace100,
              Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 15.0),
                      child: ClickButton(
                        text: 'Go to basket',
                        textColor: Colors.white,
                        onPressed: () {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const MainScreen(),
                            ),
                            (Route<dynamic> route) => false,
                          );
                        },
                        fontSize: MediaQuery.sizeOf(context).height / 53,
                        color: AppColors.secondaryBackgroundColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
