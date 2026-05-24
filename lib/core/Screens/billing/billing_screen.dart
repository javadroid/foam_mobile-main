import 'package:flutter/material.dart';
import 'package:foam_mobile/utils/values.dart';
import 'package:foam_mobile/widgets/billing_widget.dart';

class BillingScreen extends StatefulWidget {
  static const String id = '/billing_screen';

  const BillingScreen({super.key});

  @override
  State<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> {
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
            'Billing & Subscription',
            overflow: TextOverflow.ellipsis,
            style: Constants.headingStyle,
          ),
        ),
        body: ListView(
          children: [
            Container(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: BillingWidget(
                          backgroundColor: AppColors.primaryBackgroundColor,
                          titleColor: AppColors.navyBlueAccent,
                          title: 'Most Popular Plan',
                          description1: 'No upfront payment',
                          description2: 'Pay on order placement',
                          description3: 'We pick up and deliver your laundry ',
                          price: '14,700',
                        ),
                      ),
                    ],
                  ),
                  AppSpaces.verticalSpace20,
                  Row(
                    children: [
                      Expanded(
                        child: BillingWidget(
                          backgroundColor: AppColors.primaryBackgroundColor,
                          titleColor: AppColors.greenTaleColor,
                          title: 'Monthly Plan',
                          description1: 'Verified premium account',
                          description2: 'A month’s subscription',
                          description3: 'We pick up and deliver your laundry ',
                          price: '14,700',
                        ),
                      ),
                    ],
                  ),
                  AppSpaces.verticalSpace20,
                  Row(
                    children: [
                      Expanded(
                        child: BillingWidget(
                          backgroundColor: AppColors.primaryBackgroundColor,
                          titleColor: AppColors.oceanBlueColor,
                          title: 'Annual Plan',
                          description1: 'Verified premium account',
                          description2: 'A years’s subscription',
                          description3: 'We pick up and deliver your laundry ',
                          price: '54,700',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
