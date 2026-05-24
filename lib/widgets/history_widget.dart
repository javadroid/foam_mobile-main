import 'package:foam_mobile/utils/values.dart';
import 'package:flutter/material.dart';

class HistoryWidget extends StatelessWidget {
  const HistoryWidget({
    required this.date,
    required this.details,
    super.key,
  });

  final String date;
  final String details;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        date,
                        style: Constants.subHeadingStyle.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Text(
                        '${DateTime.timestamp().hour.toString()}:${DateTime.timestamp().minute.toString()}',
                        style: Constants.textStyle.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      )
                    ],
                  )
                ],
              ),
              Column(
                children: [
                  Row(
                    children: [
                      Text(
                        details,
                        style: Constants.textStyle.copyWith(
                          color: AppColors.primaryAccentColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ],
          ),
          AppSpaces.verticalSpace10,
          const Divider(),
        ],
      ),
    );
  }
}
