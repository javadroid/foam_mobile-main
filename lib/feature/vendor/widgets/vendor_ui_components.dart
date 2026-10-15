import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class VendorColors {
  static const Color primary = Color(0xFF00AABC);
  static const Color darkBg = Color(0xFF001C1F);
  static const Color lightBg = Color(0xFFF8FAFC);
  static const Color cardBg = Colors.white;
  static const Color textMain = Color(0xFF0F172A);
  static const Color textMuted = Color(0xFF64748B);
  static const Color border = Color(0xFFE2E8F0);

  // Status colors
  static const Color liveBg = Color(0xFFECFDF5);
  static const Color liveText = Color(0xFF047857);

  static const Color pausedBg = Color(0xFFFFFBEB);
  static const Color pausedText = Color(0xFFB45309);

  static const Color draftBg = Color(0xFFEFF6FF);
  static const Color draftText = Color(0xFF1D4ED8);

  static const Color urgentBg = Color(0xFFFEF2F2);
  static const Color urgentText = Color(0xFFDC2626);
}

class VendorButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isSecondary;
  final Color? color;
  final Color? textColor;

  const VendorButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.isSecondary = false,
    this.color,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = color ??
        (isSecondary
            ? Colors.white
            : VendorColors.primary);
    final fgColor = textColor ??
        (isSecondary
            ? VendorColors.textMain
            : Colors.white);

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: fgColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: isSecondary
                ? const BorderSide(color: VendorColors.border, width: 1.5)
                : BorderSide.none,
          ),
        ),
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                text,
                style: GoogleFonts.dmSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: fgColor,
                ),
              ),
      ),
    );
  }
}

class VendorStatusPill extends StatelessWidget {
  final String status;

  const VendorStatusPill({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg = VendorColors.draftBg;
    Color fg = VendorColors.draftText;
    String label = status.toUpperCase();

    if (label == 'LIVE') {
      bg = VendorColors.liveBg;
      fg = VendorColors.liveText;
    } else if (label == 'PAUSED') {
      bg = VendorColors.pausedBg;
      fg = VendorColors.pausedText;
    } else if (label == 'DRAFT') {
      bg = VendorColors.draftBg;
      fg = VendorColors.draftText;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: fg,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label[0] + label.substring(1).toLowerCase(),
            style: GoogleFonts.dmSans(
              color: fg,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class VendorCountdownBadge extends StatelessWidget {
  final String countdownText;

  const VendorCountdownBadge({super.key, required this.countdownText});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: VendorColors.urgentBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.timer_outlined,
            size: 14,
            color: VendorColors.urgentText,
          ),
          const SizedBox(width: 4),
          Text(
            '$countdownText to accept',
            style: GoogleFonts.dmSans(
              color: VendorColors.urgentText,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
