import 'package:flutter/material.dart';
import 'package:foam_mobile/utils/values.dart';

class NotificationWidget extends StatelessWidget {
  const NotificationWidget({
    required this.text,
    required this.time,
    super.key,
  });

  final String text;
  final int? time;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          flex: 1,
          child: GestureDetector(
            onTap: () {},
            child: Container(
              height: MediaQuery.sizeOf(context).height / 29,
              width: MediaQuery.sizeOf(context).width / 12,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: AppColors.fadeBlueAccentColor,
              ),
              child: Icon(
                Icons.notifications,
                color: AppColors.primaryAccentColor,
              ),
            ),
          ),
        ),
        AppSpaces.horizontalSpace10,
        Expanded(
          flex: 8,
          child: Text(
            text,
            style: Constants.subHeadingStyle.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            '$time mins ago',
            style: Constants.textStyle.copyWith(
              fontSize: 15,
              color: AppColors.blackAccentColor,
            ),
          ),
        )
      ],
    );
  }
}
