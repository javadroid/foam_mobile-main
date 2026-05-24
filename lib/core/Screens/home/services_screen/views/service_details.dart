import 'package:flutter/material.dart';
import 'package:foam_mobile/core/Screens/home/services_screen/views/add_to_basket_screen.dart';
import 'package:foam_mobile/utils/values.dart';
import 'package:foam_mobile/widgets/click_button.dart';

class ServiceDetails extends StatefulWidget {
  const ServiceDetails({super.key});

  static const String id = '/service_details_screen';

  @override
  State<ServiceDetails> createState() => _ServiceDetailsState();
}

class _ServiceDetailsState extends State<ServiceDetails> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        bottomOpacity: 200,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: AppColors.blackAccentColor,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Washing and Folding',
          overflow: TextOverflow.ellipsis,
          style: Constants.headingStyle,
        ),
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: MediaQuery.sizeOf(context).height * 0.22,
                      width: MediaQuery.sizeOf(context).width * 0.4,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: AppColors.primaryAccentColor,
                        image: const DecorationImage(
                          image: AssetImage(
                            'assets/images/services0.png',
                          ),
                          fit: BoxFit.fill,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              AppSpaces.verticalSpace40,
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'About',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Constants.headingStyle.copyWith(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  AppSpaces.verticalSpace10,
                  Text(
                    "The ultimate convenience for busy lifestyles. Let us handle your laundry, so you can focus on what matters most. Quality, efficiency, and convenience—all in one package.",
                    maxLines: 6,
                    overflow: TextOverflow.ellipsis,
                    style: Constants.subHeadingStyle.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              AppSpaces.verticalSpace40,
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Services Hours',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Constants.headingStyle.copyWith(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  AppSpaces.verticalSpace10,
                  Row(
                    children: [
                      const Icon(Icons.access_time),
                      AppSpaces.horizontalSpace10,
                      Text(
                        'Mon - Sat',
                        overflow: TextOverflow.ellipsis,
                        style: Constants.subHeadingStyle.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      AppSpaces.horizontalSpace5,
                      Text(
                        '|',
                        style: Constants.headingStyle,
                      ),
                      AppSpaces.horizontalSpace5,
                      Text(
                        '8am - 6pm',
                        overflow: TextOverflow.ellipsis,
                        style: Constants.subHeadingStyle.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              AppSpaces.verticalSpace50,
              Row(
                children: [
                  Expanded(
                    child: ClickButton(
                      text: 'Schedule Pickup',
                      textColor: Colors.white,
                      onPressed: () =>
                          Navigator.pushNamed(context, AddToBasket.id),
                      fontSize: MediaQuery.sizeOf(context).height / 53,
                      color: AppColors.secondaryBackgroundColor,
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
