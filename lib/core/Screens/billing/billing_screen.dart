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
                          title: 'Basic Plan (Heavy Users)',
                          subtitle: 'Perfect for users with regular laundry needs twice monthly.',
                          price: '54,000',
                          services: const [
                            '35 items for laundry, 2X monthly',
                            'Standard wash, iron & fold',
                            '3–4 days turnaround',
                            'One free pickup & delivery per month',
                          ],
                          additionalBenefits: const [
                            '10% discount on extra laundry beyond the limit',
                          ],
                          isComingSoon: true,
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
                          title: 'Basic Plan B (Light Users)',
                          subtitle: 'Ideal for lighter laundry needs with more item flexibility.',
                          price: '44,000',
                          services: const [
                            '50 items for laundry monthly',
                            'Standard wash, iron & fold',
                            '3–4 days turnaround',
                          ],
                          additionalBenefits: const [
                            '10% discount on extra laundry beyond the limit',
                          ],
                          isComingSoon: true,
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
                          title: 'Standard Plan (Regular Users)',
                          subtitle: 'Balanced plan with added value for regular laundry needs.',
                          price: '74,000',
                          services: const [
                            '100 items for laundry monthly',
                            'Wash & fold + ironing',
                            '3–4 days turnaround',
                            'Two free pickups & deliveries per month',
                          ],
                          additionalBenefits: const [
                            'Free fabric softener or detergent upgrade',
                            'Priority customer support',
                            '10–15% discount on dry cleaning services',
                          ],
                          isComingSoon: true,
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
                          titleColor: AppColors.blackAccentColor,
                          title: 'Premium Plan (Heavy Users & Businesses)',
                          subtitle: 'All-inclusive service for bulk laundry and business needs.',
                          price: '199,000',
                          services: const [
                            'Unlimited laundry, 2X monthly',
                            'Wash & fold + ironing for all items',
                            '3–4 days service',
                            'Free pickups & deliveries',
                          ],
                          additionalBenefits: const [
                            'Free eco-friendly detergent upgrade',
                            '20% discount on special treatments (dry cleaning, stain removal, alterations)',
                          ],
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
