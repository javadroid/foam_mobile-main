// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:foam_mobile/utils/values.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class CustomAPIButton extends StatefulWidget {
  final String text;
  final Function()? onPressed;
  final bool isLoading;
  final Color color;

  const CustomAPIButton({
    super.key,
    required this.text,
    required this.onPressed,
    required this.isLoading,
    required this.color,
  });

  @override
  State<CustomAPIButton> createState() => _CustomAPIButtonState();
}

class _CustomAPIButtonState extends State<CustomAPIButton> {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: widget.onPressed,
      child: Container(
        width: MediaQuery.sizeOf(context).width,
        padding: const EdgeInsets.symmetric(
          vertical: 18.0,
        ),
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(
            Radius.circular(
              8.0,
            ),
          ),
          color: widget.color,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              children: [
                Text(
                  widget.text,
                  style: GoogleFonts.dmSans(
                    fontSize: 20.0,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primaryBackgroundColor,
                  ),
                ),
                if (widget.isLoading)
                  Positioned(
                    top: 56 / 10,
                    child: LoadingAnimationWidget.fourRotatingDots(
                      color: AppColors.primaryAccentColor,
                      // rightDotColor: Constant.generalColor,
                      size: 20,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
