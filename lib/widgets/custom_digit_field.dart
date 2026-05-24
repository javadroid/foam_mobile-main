import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:foam_mobile/utils/values.dart';

class CustomDigitField extends StatefulWidget {
  const CustomDigitField({
    super.key,
    required this.codeController0,
    required this.codeController1,
    required this.codeController2,
    required this.codeController3,
    required this.hintText,
  });

  final TextEditingController codeController0;
  final TextEditingController codeController1;
  final TextEditingController codeController2;
  final TextEditingController codeController3;
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
          horizontal: 40,
          vertical: 20,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            SizedBox(
              height: MediaQuery.sizeOf(context).height / 13,
              width: MediaQuery.sizeOf(context).width / 6,
              child: TextField(
                controller: widget.codeController0,
                onChanged: (value) {
                  if (value.length == 1) {
                    FocusScope.of(context).nextFocus();
                  }
                },
                decoration: InputDecoration(
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
                style: Constants.headingStyle,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(1),
                  FilteringTextInputFormatter.digitsOnly,
                ],
              ),
            ),
            SizedBox(
              height: MediaQuery.sizeOf(context).height / 13,
              width: MediaQuery.sizeOf(context).width / 6,
              child: TextField(
                controller: widget.codeController1,
                onChanged: (value) {
                  if (value.length == 1) {
                    FocusScope.of(context).nextFocus();
                  }
                },
                decoration: InputDecoration(
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
                style: Constants.headingStyle,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(1),
                  FilteringTextInputFormatter.digitsOnly,
                ],
              ),
            ),
            SizedBox(
              height: MediaQuery.sizeOf(context).height / 13,
              width: MediaQuery.sizeOf(context).width / 6,
              child: TextField(
                controller: widget.codeController2,
                onChanged: (value) {
                  if (value.length == 1) {
                    FocusScope.of(context).nextFocus();
                  }
                },
                decoration: InputDecoration(
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
                style: Constants.headingStyle,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(1),
                  FilteringTextInputFormatter.digitsOnly,
                ],
              ),
            ),
            SizedBox(
              height: MediaQuery.sizeOf(context).height / 13,
              width: MediaQuery.sizeOf(context).width / 6,
              child: TextField(
                controller: widget.codeController3,
                onChanged: (value) {
                  if (value.length == 1) {
                    FocusScope.of(context).nextFocus();
                  }
                },
                decoration: InputDecoration(
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
                style: Constants.headingStyle,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(1),
                  FilteringTextInputFormatter.digitsOnly,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
