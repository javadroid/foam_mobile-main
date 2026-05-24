import 'package:flutter/material.dart';
import 'package:foam_mobile/utils/values.dart';

class PickupTextField extends StatefulWidget {
  final String hinText;
  final bool isLink;
  final String? suffixText;
  final IconData? prefixIcon;

  const PickupTextField({
    super.key,
    required this.hinText,
    required this.isLink,
    this.suffixText,
    this.prefixIcon,
  });

  @override
  State<PickupTextField> createState() => _PickupTextFieldState();
}

class _PickupTextFieldState extends State<PickupTextField> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 20.0,
      ),
      child: TextField(
        enabled: false,
        decoration: InputDecoration(
          border: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.transparent),
            borderRadius: BorderRadius.all(
              Radius.circular(12.0),
            ),
          ),
          fillColor: AppColors.shadeGreyAccentColor,
          filled: true,
          prefixIcon: widget.isLink
              ? null
              : Padding(
                  padding: const EdgeInsets.only(
                    left: 5.0,
                  ),
                  child: Icon(
                    widget.prefixIcon,
                  ),
                ),
          hintText: widget.hinText,
          hintStyle: Constants.subHeadingStyle.copyWith(
            fontSize: MediaQuery.sizeOf(context).height / 58,
          ),
          suffixIcon: widget.isLink
              ? Transform.rotate(
                  angle: 0,
                  child: IconButton(
                    onPressed: () {},
                    icon: const Icon(
                      Icons.edit,
                    ),
                    color: Colors.grey[800],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.only(
                    top: 13.0,
                    right: 20.0,
                  ),
                  child: Text(
                    widget.suffixText!,
                    style: Constants.subHeadingStyle.copyWith(
                      fontSize: MediaQuery.sizeOf(context).height / 58,
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
