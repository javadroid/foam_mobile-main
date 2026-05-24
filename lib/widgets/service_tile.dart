import 'package:flutter/material.dart';
import 'package:foam_mobile/utils/values.dart';

class ServiceTile extends StatelessWidget {
  const ServiceTile({
    super.key,
    required this.imageAsset,
    this.label,
    this.onTap,
  });

  final String imageAsset;
  final String? label;
  final Function()? onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: MediaQuery.sizeOf(context).height * 0.09,
            width: MediaQuery.sizeOf(context).width * 0.20,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: AppColors.fadeBlueAccentColor,
            ),
            child: Image.asset(imageAsset),
          ),
        ),
        AppSpaces.verticalSpace5,
        Text(
          label ?? '',
          style: Constants.textStyle.copyWith(fontSize: 15),
        )
      ],
    );
  }
}
