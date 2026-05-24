import 'package:flutter/material.dart';
import 'package:foam_mobile/utils/values.dart';

class HelpTextField extends StatefulWidget {
  final String hinText;
  final bool isLink;
  final String? suffixText;
  final IconData? prefixIcon;

  const HelpTextField({
    super.key,
    required this.hinText,
    required this.isLink,
    this.suffixText,
    this.prefixIcon,
  });

  @override
  State<HelpTextField> createState() => _HelpTextFieldState();
}

class _HelpTextFieldState extends State<HelpTextField> {
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
                  angle: 95.5,
                  child: IconButton(
                    onPressed: () {},
                    icon: const Icon(
                      Icons.file_upload_outlined,
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
