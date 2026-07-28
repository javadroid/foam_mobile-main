import 'package:flutter/material.dart';
import 'package:foam_mobile/utils/values.dart';
import 'package:google_fonts/google_fonts.dart';

class IntroPage extends StatelessWidget {
  final String imageAsset;
  final String text;

  const IntroPage({
    super.key,
    required this.imageAsset,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15.0),
      child: Column(
        children: [
          Expanded(
            child: Image.asset(
              imageAsset,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            text,
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
              color: AppColors.blackAccentColor,
              fontSize: 25,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
