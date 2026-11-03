import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class BillingWidget extends StatelessWidget {
  const BillingWidget({
    super.key,
    required this.backgroundColor,
    required this.titleColor,
    required this.title,
    required this.subtitle,
    required this.price,
    required this.services,
    required this.additionalBenefits,
    this.isComingSoon = false,
    this.isPopular = false,
    this.isCurrentPlan = false,
    this.onGetStarted,
  });

  final Color backgroundColor;
  final Color titleColor;
  final String title;
  final String subtitle;
  final String price;
  final List<String> services;
  final List<String> additionalBenefits;
  final bool isComingSoon;
  final bool isPopular;
  final bool isCurrentPlan;
  final VoidCallback? onGetStarted;

  @override
  Widget build(BuildContext context) {
    // Format price if numeric
    final cleanPrice = price.replaceAll(',', '').replaceAll('₦', '').trim();
    final numPrice = double.tryParse(cleanPrice);
    final formattedPrice = numPrice != null
        ? NumberFormat('#,###').format(numPrice)
        : price;

    final effectiveColor = titleColor == Colors.black ? const Color(0xFF0284C7) : titleColor;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white,
        border: Border.all(
          color: isCurrentPlan
              ? const Color(0xFF10B981)
              : (isPopular ? effectiveColor.withValues(alpha: 0.5) : const Color(0xFFE2E8F0)),
          width: isCurrentPlan || isPopular ? 1.8 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: (isPopular ? effectiveColor : const Color(0xFF0F172A)).withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Accent / Badge Bar
            if (isPopular || isCurrentPlan || isComingSoon)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                decoration: BoxDecoration(
                  color: isCurrentPlan
                      ? const Color(0xFFDCFCE7)
                      : (isComingSoon
                          ? const Color(0xFFFEF3C7)
                          : effectiveColor.withValues(alpha: 0.12)),
                ),
                child: Row(
                  children: [
                    Icon(
                      isCurrentPlan
                          ? Icons.check_circle_rounded
                          : (isComingSoon ? Icons.hourglass_empty_rounded : Icons.star_rounded),
                      size: 15,
                      color: isCurrentPlan
                          ? const Color(0xFF15803D)
                          : (isComingSoon ? const Color(0xFFB45309) : effectiveColor),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isCurrentPlan
                          ? 'YOUR ACTIVE PLAN'
                          : (isComingSoon ? 'COMING SOON' : 'MOST POPULAR CHOICE'),
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: isCurrentPlan
                            ? const Color(0xFF15803D)
                            : (isComingSoon ? const Color(0xFFB45309) : effectiveColor),
                      ),
                    ),
                  ],
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(22.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    title,
                    style: GoogleFonts.dmSans(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF64748B),
                        height: 1.35,
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Price
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '₦$formattedPrice',
                        style: GoogleFonts.dmSans(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF0F172A),
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '/ month',
                        style: GoogleFonts.dmSans(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  const SizedBox(height: 16),

                  // Services Included
                  Text(
                    'What\'s Included',
                    style: GoogleFonts.dmSans(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...services.map(
                    (service) => Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 2),
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: effectiveColor.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.check_rounded,
                              size: 11,
                              color: effectiveColor,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              service,
                              style: GoogleFonts.dmSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF334155),
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Additional Benefits
                  if (additionalBenefits.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    ...additionalBenefits.map(
                      (benefit) => Padding(
                        padding: const EdgeInsets.only(bottom: 6.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 2),
                              padding: const EdgeInsets.all(3),
                              decoration: const BoxDecoration(
                                color: Color(0xFFFEF3C7),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.star_rounded,
                                size: 11,
                                color: Color(0xFFD97706),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                benefit,
                                style: GoogleFonts.dmSans(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF64748B),
                                  height: 1.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // CTA Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isCurrentPlan
                            ? const Color(0xFFDCFCE7)
                            : (isComingSoon ? const Color(0xFFE2E8F0) : effectiveColor),
                        foregroundColor: isCurrentPlan
                            ? const Color(0xFF15803D)
                            : (isComingSoon ? const Color(0xFF94A3B8) : Colors.white),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: isCurrentPlan
                              ? const BorderSide(color: Color(0xFF86EFAC), width: 1.2)
                              : BorderSide.none,
                        ),
                      ),
                      onPressed: isComingSoon || isCurrentPlan ? null : onGetStarted,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (isCurrentPlan) ...[
                            const Icon(Icons.check_circle_rounded, size: 16),
                            const SizedBox(width: 6),
                          ],
                          Text(
                            isCurrentPlan
                                ? 'Current Active Plan'
                                : (isComingSoon ? 'Coming Soon' : 'Subscribe Now'),
                            style: GoogleFonts.dmSans(
                              fontWeight: FontWeight.w700,
                              fontSize: 14.5,
                            ),
                          ),
                          if (!isCurrentPlan && !isComingSoon) ...[
                            const SizedBox(width: 6),
                            const Icon(Icons.arrow_forward_rounded, size: 15),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
