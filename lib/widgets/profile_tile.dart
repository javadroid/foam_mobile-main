import 'package:flutter/material.dart';
import 'package:foam_mobile/utils/values.dart';

class ProfileTile extends StatelessWidget {
  final String title;
  final String label;

  const ProfileTile({
    super.key,
    required this.title,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title),
          AppSpaces.verticalSpace10,
          Row(
            children: [
              Expanded(
                flex: 1,
                child: Container(
                  padding: const EdgeInsets.only(
                    top: 22.5,
                    right: 22.0,
                    bottom: 22.5,
                    left: 15.0,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.all(
                      Radius.circular(12.0),
                    ),
                    color: AppColors.shadeGreyAccentColor,
                  ),
                  child: Text(
                    label,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
