import 'package:flutter/material.dart';
import 'package:foam_mobile/utils/values.dart';

class CustomTextButton extends StatelessWidget {
  const CustomTextButton(
      {super.key,
      required this.text,
      this.fontsize,
      required this.onPressed,
      this.minWidth = 40,
      this.color});

  final String text;
  final double? fontsize;
  final VoidCallback onPressed;
  final double? minWidth;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return MaterialButton(
      minWidth: minWidth,
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: Text(
        text,
        style: Constants.textStyle.copyWith(
          color: color ?? AppColors.primaryAccentColor,
          fontSize: fontsize,
        ),
      ),
    );
  }
}
