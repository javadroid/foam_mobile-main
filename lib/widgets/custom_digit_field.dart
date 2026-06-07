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
          horizontal: 20,
          vertical: 20,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(
            widget.controllers.length,
            (index) => SizedBox(
              height: MediaQuery.sizeOf(context).height / 13,
              width: MediaQuery.sizeOf(context).width / (widget.controllers.length + 2),
              child: TextField(
                controller: widget.controllers[index],
                onChanged: (value) {
                  if (value.length == 1 && index < widget.controllers.length - 1) {
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
                      Radius.circular(MediaQuery.sizeOf(context).width / 25),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: AppColors.primaryAccentColor,
                    ),
                    borderRadius: BorderRadius.all(
                      Radius.circular(MediaQuery.sizeOf(context).width / 25),
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
        ),
      ),
    );
  }
}
