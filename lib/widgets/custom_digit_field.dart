import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:foam_mobile/utils/values.dart';

class CustomDigitField extends StatefulWidget {
  const CustomDigitField({
    super.key,
    required this.controllers,
    required this.hintText,
  });

  final List<TextEditingController> controllers;
  final String hintText;

  @override
  State<CustomDigitField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomDigitField> {
  @override
  Widget build(BuildContext context) {
    return Form(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double itemWidth =
                (constraints.maxWidth / (widget.controllers.length + 0.8))
                    .clamp(32.0, 52.0);
            final double itemHeight =
                (MediaQuery.sizeOf(context).height / 13).clamp(48.0, 60.0);
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(
                widget.controllers.length,
                (index) => SizedBox(
                  height: itemHeight,
                  width: itemWidth,
                  child: TextField(
                    controller: widget.controllers[index],
                    onChanged: (value) {
                      if (value.length == 1 &&
                          index < widget.controllers.length - 1) {
                        FocusScope.of(context).nextFocus();
                      } else if (value.isEmpty && index > 0) {
                        FocusScope.of(context).previousFocus();
                      }
                    },
                    decoration: InputDecoration(
                      contentPadding: EdgeInsets.zero,
                      hintText: widget.hintText,
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.transparent),
                        borderRadius: BorderRadius.all(
                          Radius.circular(itemWidth / 4),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: AppColors.primaryAccentColor,
                        ),
                        borderRadius: BorderRadius.all(
                          Radius.circular(itemWidth / 4),
                        ),
                      ),
                      fillColor: AppColors.fadeBlueAccentColor,
                      filled: true,
                    ),
                    style: Constants.headingStyle.copyWith(fontSize: 20),
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(1),
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
