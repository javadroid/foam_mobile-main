import 'package:flutter/material.dart';
import 'package:foam_mobile/utils/values.dart';

class BillingWidget extends StatelessWidget {
  const BillingWidget({
    super.key,
    required this.backgroundColor,
    required this.titleColor,
    required this.title,
    this.description1,
    this.description2,
    this.description3,
    required this.price,
  });

  final Color backgroundColor;
  final Color titleColor;
  final String title;
  final String? description1;
  final String? description2;
  final String? description3;
  final String price;

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: MediaQuery.sizeOf(context).height / 22,
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
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: Constants.subHeadingStyle.copyWith(
                    color: AppColors.primaryBackgroundColor,
                    fontSize: MediaQuery.sizeOf(context).height / 50,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
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
                  'Our Most convenient plan. Enjoy next-day rush',
                  style: Constants.subHeadingStyle
                      .copyWith(fontWeight: FontWeight.w300),
                ),
                AppSpaces.verticalSpace10,
                Text(
                  'As low as*',
                  style: Constants.subHeadingStyle.copyWith(
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w900,
                  ),
                ),
                AppSpaces.verticalSpace10,
                Text(
                  'NGN $price',
                  style: Constants.headingStyle.copyWith(
                    color: AppColors.blackAccentColor,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                AppSpaces.verticalSpace10,
                (description1 != null)
                    ? Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: MediaQuery.sizeOf(context).width / 100,
                        ),
                        child: Divider(
                          color: AppColors.blackAccentColor,
                          thickness: 1.5,
                        ),
                      )
                    : const Padding(padding: EdgeInsets.zero),
                Padding(
                  padding: (description1 != null)
                      ? EdgeInsets.only(
                          left: MediaQuery.sizeOf(context).width / 26,
                          right: MediaQuery.sizeOf(context).width / 26,
                          top: MediaQuery.sizeOf(context).width / 26,
                        )
                      : EdgeInsets.zero,
                  child: Text(
                    (description1 == null)
                        ? ''
                        : (description2 == null)
                            ? '• $description1 \n '
                            : (description3 == null)
                                ? ' '
                                    '• $description1 \n '
                                    '• $description2 \n '
                                : ' '
                                    '• $description1 \n '
                                    '• $description2 \n '
                                    '• $description3 \n ',
                    style: Constants.subHeadingStyle.copyWith(
                      color: AppColors.blackAccentColor,
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    InkWell(
                      onTap: () {},
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
                              'Get Started',
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: Constants.subHeadingStyle.copyWith(
                                color: AppColors.blackAccentColor,
                                fontSize: 22,
                              ),
                            ),
                            AppSpaces.horizontalSpace10,
                            Icon(
                              Icons.arrow_forward_outlined,
                              color: AppColors.blackAccentColor,
                            )
                          ],
                        ),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
