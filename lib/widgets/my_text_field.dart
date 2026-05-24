import 'package:flutter/material.dart';
import 'package:foam_mobile/utils/values.dart';

class MyTextField extends StatefulWidget {
  final TextEditingController controller;
  final String hinText;
  final bool obscureText;
  final bool isPassword;
  final TextInputType? keyboardType;

  const MyTextField({
    super.key,
    required this.controller,
    required this.hinText,
    required this.obscureText,
    required this.isPassword,
    this.keyboardType,
  });

  @override
  State<MyTextField> createState() => _MyTextFieldState();
}

class _MyTextFieldState extends State<MyTextField> {
  late var obscureTxt = widget.obscureText;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 17.0,
      ),
      child: TextField(
        controller: widget.controller,
        obscureText: obscureTxt,
        keyboardType: widget.keyboardType,
        decoration: InputDecoration(
          enabledBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.transparent),
            borderRadius: BorderRadius.all(
              Radius.circular(12.0),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: AppColors.primaryAccentColor,
            ),
            borderRadius: const BorderRadius.all(
              Radius.circular(12.0),
            ),
          ),
          fillColor: AppColors.shadeGreyAccentColor,
          filled: true,
          hintText: widget.hinText,
          hintStyle: const TextStyle(
            color: Colors.grey,
          ),
          suffixIcon: widget.isPassword
              ? IconButton(
                  onPressed: () {
                    setState(() {
                      obscureTxt = !obscureTxt;
                    });
                  },
                  icon: obscureTxt
                      ? const Icon(
                          Icons.visibility_off_outlined,
                        )
                      : const Icon(
                          Icons.visibility_outlined,
                        ),
                  color: Colors.grey[600],
                )
              : null,
        ),
      ),
    );
  }
}
