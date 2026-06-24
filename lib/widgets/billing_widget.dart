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
    this.onGetStarted,
  });

  final Color backgroundColor;
  final Color titleColor;
  final String title;
  final String subtitle;
  final String price;
  final List<String> services;
  final List<String> additionalBenefits;
  final bool isComingSoon;
  final VoidCallback? onGetStarted;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
final isSmallScreen = MediaQuery.of(context).size.width < 360;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: backgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: 
Stack(
  clipBehavior: Clip.none,
  children: [
    Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: size.width / 30,
            vertical: size.width / 20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                subtitle,
                style: Constants.subHeadingStyle.copyWith(
                  fontWeight: FontWeight.w300,
                  fontSize: 14,
                ),
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
              ...services.map(
                (service) => Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '• ',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
                ),
              ),
              if (additionalBenefits.isNotEmpty) ...[
                AppSpaces.verticalSpace10,
                Text(
                  'Additional Benefits:',
                  style: Constants.subHeadingStyle.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                ...additionalBenefits.map(
                  (benefit) => Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '• ',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            benefit,
                            style: Constants.subHeadingStyle.copyWith(
                              color: AppColors.blackAccentColor,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),

        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: size.width / 30,
            vertical: size.width / 25,
          ),
          child: Opacity(
            opacity: isComingSoon ? 0.5 : 1.0,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: isComingSoon ? null : onGetStarted,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 20,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: AppColors.blackAccentColor,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isComingSoon
                            ? 'Coming Soon'
                            : 'Get Started',
                        style: Constants.subHeadingStyle.copyWith(
                          color: AppColors.blackAccentColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (!isComingSoon) ...[
                        const SizedBox(width: 8),
                        Icon(
                          Icons.arrow_forward_outlined,
                          size: 18,
                          color: AppColors.blackAccentColor,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    ),

    if (isComingSoon)
      Positioned(
        top: isSmallScreen ? 12 : 18,
        right: isSmallScreen ? -10 : -15,
        child: Transform.rotate(
          angle: 0.785398, // 45 degrees
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 22 : 32,
              vertical: 5,
            ),
            decoration: BoxDecoration(
              color: Colors.orange,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'COMING SOON',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: isSmallScreen ? 8 : 10,
              ),
            ),
          ),
        ),
      ),
  ],
)
    );
  }
}