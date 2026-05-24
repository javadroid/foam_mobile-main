import 'package:flutter/material.dart';
import 'package:foam_mobile/theme/theme_main_provider.dart';
import 'package:foam_mobile/utils/values.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class CustomButton extends StatefulWidget {
  const CustomButton({
    super.key,
    required this.loading,
    required this.mainProvider,
    required this.onTap,
    required this.title,
  });

  final bool loading;
  final ThemeProvider mainProvider;
  final VoidCallback onTap;
  final String title;

  @override
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton> {
  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: widget.loading ? 0.5 : 1,
      child: MaterialButton(
        padding: EdgeInsets.zero,
        onPressed: widget.loading ? () {} : widget.onTap,
        child: Container(
          width: widget.mainProvider.width * 0.9,
          height: 50,
          decoration: BoxDecoration(
            color: AppColors.primaryAccentColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Stack(
            children: [
              Center(
                child: Text(
                  widget.title,
                  style: Constants.textStyle.copyWith(
                    color: AppColors.primaryBackgroundColor,
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
              ),
              if (widget.loading)
                Positioned(
                  right: 10,
                  top: 56 / 4,
                  child: LoadingAnimationWidget.fourRotatingDots(
                    color: Colors.white,
                    // rightDotColor: Constant.generalColor,
                    size: 20,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
