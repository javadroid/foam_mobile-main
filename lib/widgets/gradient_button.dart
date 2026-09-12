import 'package:flutter/material.dart';
import 'package:foam_mobile/utils/values.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class GradientButton extends StatefulWidget {
  final String text;
  final Function()? onPressed;
  final bool isLoading;
  final double? width;
  final double? fontSize;
  final EdgeInsetsGeometry? padding;

  const GradientButton({
    super.key,
    required this.text,
    required this.onPressed,
    required this.isLoading,
    this.width,
    this.fontSize,
    this.padding,
  });

  @override
  State<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton> {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: widget.isLoading ? null : widget.onPressed,
      borderRadius: BorderRadius.circular(8.0),
      child: Container(
        width: widget.width ?? double.infinity,
        padding: widget.padding ??
            const EdgeInsets.symmetric(
              vertical: 16.0,
              horizontal: 16.0,
            ),
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(
            Radius.circular(8.0),
          ),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              ...AppColors.gradientColor,
            ],
          ),
        ),
        child: Center(
          child: widget.isLoading
              ? LoadingAnimationWidget.fourRotatingDots(
                  color: Colors.white,
                  size: 28,
                )
              : Text(
                  widget.text,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.dmSans(
                    fontSize: widget.fontSize ?? 18.0,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }
}
