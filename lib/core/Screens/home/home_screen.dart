import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:foam_mobile/core/Screens/basket/view/basket_screen.dart';
import 'package:foam_mobile/core/Screens/drawer.dart';
import 'package:foam_mobile/core/Screens/home/notifications/notification_screen.dart';
import 'package:foam_mobile/core/Screens/home/services_screen/views/services_screen.dart';
import 'package:foam_mobile/core/Screens/profile/profile_image/controller/profile_pic_auth.dart';
import 'package:foam_mobile/feature/authentication/controller/provider/authprovider.dart';
import 'package:foam_mobile/utils/values.dart';
import 'package:foam_mobile/widgets/billing_widget.dart';
import 'package:foam_mobile/widgets/click_button.dart';
import 'package:foam_mobile/widgets/discount_tile.dart';
import 'package:foam_mobile/widgets/service_tile.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class HomePage extends StatefulWidget {
  final VoidCallback? toProfile;

  const HomePage({
    super.key,
    this.toProfile,
  });

  static const String id = '/homepage';

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? fullName;
  String? addressStreet;
  String? firstName;
  File? image;

  // discount slider CONTROLLER
  int _currentDiscountController = 0;
  Timer? timer;
  final discountController = PageController(initialPage: 0);

  final List<Map<String, String>> discountDeals = [
    {
      'title': 'Discount Deals',
      'promoPrefix': 'up to',
      'promoValue': '30% off',
      'description': 'all laundry services available!',
      'imageAsset': 'assets/images/foam_discount.png',
    },
    {
      'title': 'Schedule Pickup',
      'promoPrefix': 'for as low as',
      'promoValue': '₦800',
      'description': 'for an item!',
      'imageAsset': 'assets/images/foam_discount2.png',
    },
    {
      'title': 'Referral Bonus',
      'promoPrefix': 'up to',
      'promoValue': '10% off',
      'description': 'on all referrals!',
      'imageAsset': 'assets/images/foam_discount3.png',
    },
  ];

  @override
  void initState() {
    var authProvider = Provider.of<AuthProvider>(context, listen: false);
    var profileAuth = Provider.of<ProfilePicAuth>(context, listen: false);
    setState(() {
      image = profileAuth.image;
    });
    setState(() {
      fullName = "${authProvider.firstName} ${authProvider.lastName}";
      addressStreet = authProvider.addressStreet;
      firstName = authProvider.firstName;
    });

    //discount tile controller
    timer = Timer.periodic(const Duration(seconds: 5), (Timer timer) {
      if (_currentDiscountController < discountDeals.length - 1) {
        _currentDiscountController++;
      } else {
        _currentDiscountController = 0;
      }

      discountController.animateToPage(
        _currentDiscountController,
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeIn,
      );
    });
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    // discount slider CONTROLLER
    timer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    final GlobalKey<ScaffoldMessengerState> scaffoldKey =
        GlobalKey<ScaffoldMessengerState>();

    return ScaffoldMessenger(
      key: scaffoldKey,
      child: Scaffold(
        backgroundColor: AppColors.primaryBackgroundColor,
        drawer: MyDrawer(
          firstName: firstName ?? 'error',
          scaffoldKey: scaffoldKey,
        ),
        body: SafeArea(
          child: ListView(
            scrollDirection: Axis.vertical,
            children: [
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 18.0,
                      right: 18.0,
                      top: 25.0,
                      bottom: 15.0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          flex: 3,
                          child: Row(
                            children: [
                              GestureDetector(
                                onTap: widget.toProfile,
                                child: Center(
                                  child: FittedBox(
                                    fit: BoxFit.contain,
                                    child: CircleAvatar(
                                      foregroundImage: image != null
                                          ? FileImage(image!)
                                          : null,
                                      radius: 25,
                                      child: image == null
                                          ? const Icon(Icons.person, size: 30)
                                          : null,
                                    ),
                                  ),
                                ),
                              ),
                              AppSpaces.horizontalSpace10,
                              Expanded(
                                // ✅ Prevents text overflow
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      fullName?.isNotEmpty == true
                                          ? fullName!
                                          : 'Unknown User',
                                      overflow: TextOverflow.ellipsis,
                                      maxLines:
                                          1, // ✅ Ensures text stays in one line
                                      style: GoogleFonts.dmSans(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    AppSpaces.verticalSpace5,
                                    Text(
                                      addressStreet?.isNotEmpty == true
                                          ? addressStreet!
                                          : 'No Address Provided',
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1, // ✅ Prevents text wrapping
                                      style: GoogleFonts.dmSans(fontSize: 16),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              InkWell(
                                onTap: () => Navigator.of(context)
                                    .pushNamed(NotificationScreen.id),
                                child: SvgPicture.asset(
                                    'assets/images/notification.svg'),
                              ),
                              Builder(
                                builder: (context) {
                                  return IconButton(
                                    onPressed: () {
                                      Scaffold.of(context).openDrawer();
                                    },
                                    icon: SvgPicture.asset(
                                        'assets/images/menu.svg'),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  AppSpaces.verticalSpace20,
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Container(
                          padding: const EdgeInsets.only(
                            left: 18,
                          ),
                          child: ClickButton(
                            text: 'Schedule Pickup',
                            textColor: Colors.white,
                            onPressed: () => Navigator.of(context)
                                .pushNamed(BasketScreen.id),
                            fontSize: MediaQuery.sizeOf(context).height / 60,
                            color: AppColors.secondaryBackgroundColor,
                          ),
                        ),
                      ),
                      const Expanded(
                        flex: 1,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [],
                        ),
                      ),
                    ],
                  ),
                  AppSpaces.verticalSpace20,
                  SizedBox(
                    height: MediaQuery.sizeOf(context).height * 0.21,
                    child: PageView(
                      scrollDirection: Axis.horizontal,
                      controller: discountController,
                      children: discountDeals.map<Widget>((deal) {
                        return DiscountSlider(
                          onPressed: () {},
                          isLoading: false,
                          imageAsset: deal['imageAsset']!,
                          title: deal['title']!,
                          promoPrefix: deal['promoPrefix']!,
                          promoValue: deal['promoValue']!,
                          description: deal['description']!,
                        );
                      }).toList(),
                    ),
                  ),
                  SmoothPageIndicator(
                    controller: discountController,
                    count: discountDeals.length,
                    effect: Constants.slideEffect2,
                  ),

                  //Choose a Service
                  AppSpaces.verticalSpace40,
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 22.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Choose a Service',
                          style: Constants.headingStyle.copyWith(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        InkWell(
                          onTap: () => Navigator.of(context)
                              .pushNamed(ServicesScreen.id),
                          child: Text(
                            'See All',
                            style: Constants.textStyle,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AppSpaces.verticalSpace20,
                  Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: MediaQuery.sizeOf(context).width * 0.030),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ServiceTile(
                          imageAsset: 'assets/images/washing-machine.png',
                          label: 'Laundry',
                          onTap: () => Navigator.of(context).pushNamed(
                            ServicesScreen.id,
                            arguments: 'laundry',
                          ),
                        ),
                        ServiceTile(
                          imageAsset: 'assets/images/iron.png',
                          label: 'Dry Cleaning',
                          onTap: () => Navigator.of(context).pushNamed(
                            ServicesScreen.id,
                            arguments: 'dry cleaning',
                          ),
                        ),
                        // ServiceTile(
                        //   imageAsset: 'assets/images/drycleaning.png',
                        //   label: 'Dry Cleaning',
                        //   onTap: () => Navigator.of(context).pushNamed(
                        //     ServicesScreen.id,
                        //   ),
                        // ),
                        // ServiceTile(
                        //   imageAsset: 'assets/images/folding.png',
                        //   label: 'Folding',
                        //   onTap: () => Navigator.of(context).pushNamed(
                        //     ServicesScreen.id,
                        //   ),
                        // ),
                      ],
                    ),
                  ),

                  //Product on sale
                  AppSpaces.verticalSpace50,
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 22.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          'Product on sale',
                          style: Constants.headingStyle.copyWith(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: MediaQuery.sizeOf(context).height / 5,
                    width: double.infinity,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(15.0),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              boxShadow: [
                                BoxShadow(
                                  spreadRadius: 1,
                                  blurRadius: 20,
                                  offset: const Offset(8.0, 4.0),
                                  color: AppColors.shadeGreyAccentColor,
                                ),
                                BoxShadow(
                                  spreadRadius: 1,
                                  blurRadius: 20,
                                  offset: const Offset(-4.0, -4.0),
                                  color: AppColors.primaryBackgroundColor,
                                )
                              ],
                            ),
                            child: Image.asset('assets/images/product0.jpg'),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(5.0),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              boxShadow: [
                                BoxShadow(
                                  spreadRadius: 1,
                                  blurRadius: 20,
                                  offset: const Offset(8.0, 4.0),
                                  color: AppColors.shadeGreyAccentColor,
                                ),
                                BoxShadow(
                                  spreadRadius: 1,
                                  blurRadius: 20,
                                  offset: const Offset(-4.0, -4.0),
                                  color: AppColors.primaryBackgroundColor,
                                )
                              ],
                            ),
                            child: Image.asset('assets/images/product1.jpg'),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(15.0),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              boxShadow: [
                                BoxShadow(
                                  spreadRadius: 1,
                                  blurRadius: 20,
                                  offset: const Offset(8.0, 4.0),
                                  color: AppColors.shadeGreyAccentColor,
                                ),
                                BoxShadow(
                                  spreadRadius: 1,
                                  blurRadius: 20,
                                  offset: const Offset(-4.0, -4.0),
                                  color: AppColors.primaryBackgroundColor,
                                )
                              ],
                            ),
                            child: Image.asset('assets/images/product2.jpg'),
                          ),
                        ),
                      ],
                    ),
                  ),

                  //Plans
                  AppSpaces.verticalSpace50,
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 22.0),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Text(
                              'Plans',
                              style: Constants.headingStyle.copyWith(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            Text(
                              'Get access to the more streamlined services with our plans',
                              style: Constants.subHeadingStyle,
                              softWrap: true,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 600,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20.0),
                          child: Row(
                            children: [
                              SizedBox(
                                width: MediaQuery.sizeOf(context).width / 1.3,
                                child: Column(
                                  children: [
                                    Expanded(
                                      child: BillingWidget(
                                        backgroundColor:
                                            AppColors.primaryBackgroundColor,
                                        titleColor: AppColors.navyBlueAccent,
                                        title: 'Basic Plan (Heavy Users)',
                                        subtitle:
                                            'Perfect for users with regular laundry needs twice monthly.',
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
                              ),
                              AppSpaces.horizontalSpace20,
                              SizedBox(
                                width: MediaQuery.sizeOf(context).width / 1.3,
                                child: Column(
                                  children: [
                                    Expanded(
                                      child: BillingWidget(
                                        backgroundColor:
                                            AppColors.primaryBackgroundColor,
                                        titleColor: AppColors.greenTaleColor,
                                        title: 'Basic Plan B (Light Users)',
                                        subtitle:
                                            'Ideal for lighter laundry needs with more item flexibility.',
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
                              ),
                              AppSpaces.horizontalSpace20,
                              SizedBox(
                                width: MediaQuery.sizeOf(context).width / 1.3,
                                child: Column(
                                  children: [
                                    Expanded(
                                      child: BillingWidget(
                                        backgroundColor:
                                            AppColors.primaryBackgroundColor,
                                        titleColor: AppColors.oceanBlueColor,
                                        title: 'Standard Plan (Regular Users)',
                                        subtitle:
                                            'Balanced plan with added value for regular laundry needs.',
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
                              ),
                              AppSpaces.horizontalSpace20,
                              SizedBox(
                                width: MediaQuery.sizeOf(context).width / 1.3,
                                child: Column(
                                  children: [
                                    Expanded(
                                      child: BillingWidget(
                                        backgroundColor:
                                            AppColors.primaryBackgroundColor,
                                        titleColor: AppColors.blackAccentColor,
                                        title:
                                            'Premium Plan (Heavy Users & Businesses)',
                                        subtitle:
                                            'All-inclusive service for bulk laundry and business needs.',
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
                              ),
                            ],
                          ),
                        ),
                      ],
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
