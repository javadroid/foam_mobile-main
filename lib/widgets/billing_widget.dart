import 'package:flutter/material.dart';
import 'package:foam_mobile/utils/values.dart';

class BillingWidget extends StatelessWidget {
  const BillingWidget({
    super.key,
    required this.backgroundColor,
    required this.titleColor,
    required this.title,
    required this.subtitle,
    required this.price,
    required this.services,
    required this.additionalBenefits,
    this.isComingSoon = false,
  });

  final Color backgroundColor;
  final Color titleColor;
  final String title;
  final String subtitle;
  final String price;
  final List<String> services;
  final List<String> additionalBenefits;
  final bool isComingSoon;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: backgroundColor,
        boxShadow: [
          const BoxShadow(
            spreadRadius: 1,
            blurRadius: 20,
            offset: Offset(4.0, 4.0),
            color: Colors.grey,
          ),
          BoxShadow(
            spreadRadius: 1,
            blurRadius: 20,
            offset: const Offset(-4.0, -4.0),
            color: AppColors.primaryBackgroundColor,
          )
        ],
      ),
      child: Stack(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    height: 40,
                    width: MediaQuery.sizeOf(context).width,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(
                          12.0,
                        ),
                      ),
                      color: titleColor,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(child: 
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Constants.subHeadingStyle.copyWith(
                            color: AppColors.primaryBackgroundColor,
                            fontSize: MediaQuery.sizeOf(context).height / 50,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                    )],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: MediaQuery.sizeOf(context).width / 30,
                      vertical: MediaQuery.sizeOf(context).width / 20,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          subtitle,
                          style: Constants.subHeadingStyle.copyWith(
                              fontWeight: FontWeight.w300, fontSize: 14),
                        ),
                        AppSpaces.verticalSpace10,
                        Text(
                          'As low as*',
                          style: Constants.subHeadingStyle.copyWith(
                            color: Colors.grey[500],
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                          ),
                        ),
                        AppSpaces.verticalSpace10,
                        Text(
                          'NGN $price',
                          style: Constants.headingStyle.copyWith(
                            color: AppColors.blackAccentColor,
                            fontWeight: FontWeight.w900,
                            fontSize: 24,
                          ),
                        ),
                        AppSpaces.verticalSpace10,
                        const Divider(thickness: 1),
                        AppSpaces.verticalSpace10,
                        Text(
                          'Services Included:',
                          style: Constants.subHeadingStyle.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        ...services.map((service) => Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('• ',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  Expanded(
                                    child: Text(
                                      service,
                                      style: Constants.subHeadingStyle.copyWith(
                                        color: AppColors.blackAccentColor,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )),
                        AppSpaces.verticalSpace10,
                        if (additionalBenefits.isNotEmpty) ...[
                          Text(
                            'Additional Benefits:',
                            style: Constants.subHeadingStyle.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          ...additionalBenefits.map((benefit) => Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('• ',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold)),
                                    Expanded(
                                      child: Text(
                                        benefit,
                                        style:
                                            Constants.subHeadingStyle.copyWith(
                                          color: AppColors.blackAccentColor,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: MediaQuery.sizeOf(context).width / 30,
                  vertical: MediaQuery.sizeOf(context).width / 20,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Opacity(
                      opacity: isComingSoon ? 0.5 : 1.0,
                      child: InkWell(
                        onTap: isComingSoon ? null : () {},
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            vertical: MediaQuery.sizeOf(context).height * 0.01,
                            horizontal: MediaQuery.sizeOf(context).width * 0.04,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: AppColors.blackAccentColor,
                              width: 2.0,
                            ),
                            color: Colors.transparent,
                            borderRadius: const BorderRadius.all(
                              Radius.circular(
                                8.0,
                              ),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                isComingSoon ? 'Coming Soon' : 'Get Started',
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: Constants.subHeadingStyle.copyWith(
                                  color: AppColors.blackAccentColor,
                                  fontSize: 18,
                                ),
                              ),
                              if (!isComingSoon) ...[
                                AppSpaces.horizontalSpace10,
                                Icon(
                                  Icons.arrow_forward_outlined,
                                  color: AppColors.blackAccentColor,
                                )
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
          if (isComingSoon)
            Positioned(
              top: 40,
              right: -25,
              child: Transform.rotate(
                angle: 0.785398, // 45 degrees
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 5),
                  color: Colors.orange,
                  child: const Text(
                    'COMING SOON',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
