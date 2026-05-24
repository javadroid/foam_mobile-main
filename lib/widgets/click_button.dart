import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class ClickButton extends StatelessWidget {
  final String text;
  final Color color;
  final double fontSize;
  final Function()? onPressed;
  final Color textColor;
  final bool? isLoading;

  const ClickButton({
    super.key,
    this.isLoading,
    required this.text,
    required this.color,
    required this.fontSize,
    required this.onPressed,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: 18.0,
          horizontal: 60.0,
        ),
        decoration: BoxDecoration(
          color: color,
          borderRadius: const BorderRadius.all(
            Radius.circular(
              8.0,
            ),
          ),
        ),
        child: (isLoading == false || isLoading == null)
            ? Text(
                text,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              )
            : LoadingAnimationWidget.fourRotatingDots(
                color: Colors.white,
                size: 30,
              ),
      ),
    );
  }
}
