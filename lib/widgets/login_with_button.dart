import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:foam_mobile/utils/values.dart';

class LoginWithButton extends StatelessWidget {
  final String text;

  const LoginWithButton({
    super.key,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: null,
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: 12.0,
        ),
        width: MediaQuery.sizeOf(context).width * 0.8,
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.grey[800]!,
            width: 1.0,
          ),
          color: Colors.transparent,
          borderRadius: const BorderRadius.all(
            Radius.circular(
              8.0,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              text == 'Google'
                  ? 'assets/images/google.svg'
                  : 'assets/images/apple.svg',
              height: 25,
            ),
            AppSpaces.horizontalSpace10,
            Text(
              'Continue with $text',
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Constants.textStyle.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Colors.grey[500],
                  fontSize: MediaQuery.sizeOf(context).height * 0.017),
            ),
          ],
        ),
      ),
    );
  }
}
