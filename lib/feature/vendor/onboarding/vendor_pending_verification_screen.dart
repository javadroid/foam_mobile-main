import 'package:flutter/material.dart';
import 'package:foam_mobile/feature/vendor/onboarding/vendor_approved_screen.dart';
import 'package:foam_mobile/feature/vendor/onboarding/vendor_rejected_screen.dart';
import 'package:foam_mobile/feature/vendor/widgets/vendor_ui_components.dart';
import 'package:google_fonts/google_fonts.dart';

class VendorPendingVerificationScreen extends StatelessWidget {
  static const String id = '/vendor_pending_verification';

  const VendorPendingVerificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: VendorColors.draftBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.hourglass_top_rounded,
                  color: VendorColors.primary,
                  size: 26,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "We're reviewing your business",
                style: GoogleFonts.dmSans(
                  color: VendorColors.textMain,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "This usually takes up to 2 business days. We'll notify you via email and SMS as soon as your account is approved.",
                style: GoogleFonts.dmSans(
                  color: VendorColors.textMuted,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 36),

              // Timeline progression
              _buildTimelineStep(
                title: 'Submitted',
                subtitle: 'Today, 9:12 AM',
                isCompleted: true,
                isActive: false,
                isLast: false,
              ),
              _buildTimelineStep(
                title: 'Under review',
                subtitle: 'Documents and bank account',
                isCompleted: false,
                isActive: true,
                isLast: false,
              ),
              _buildTimelineStep(
                title: 'Approved',
                subtitle: 'Wallet set up for payouts',
                isCompleted: false,
                isActive: false,
                isLast: true,
              ),

              const Spacer(),

              // Quick simulation helpers for review
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: VendorColors.lightBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: VendorColors.border),
                ),
                child: Column(
                  children: [
                    Text(
                      'Preview States (Figma Flows)',
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: VendorColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: VendorButton(
                            text: 'View Approved',
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const VendorApprovedScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: VendorButton(
                            text: 'View Rejected',
                            isSecondary: true,
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const VendorRejectedScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineStep({
    required String title,
    required String subtitle,
    required bool isCompleted,
    required bool isActive,
    required bool isLast,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: isCompleted
                    ? VendorColors.liveBg
                    : isActive
                        ? VendorColors.draftBg
                        : VendorColors.lightBg,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isCompleted
                      ? VendorColors.liveText
                      : isActive
                          ? VendorColors.primary
                          : VendorColors.border,
                  width: 2,
                ),
              ),
              child: Center(
                child: isCompleted
                    ? const Icon(Icons.check, size: 16, color: VendorColors.liveText)
                    : isActive
                        ? Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: VendorColors.primary,
                              shape: BoxShape.circle,
                            ),
                          )
                        : null,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 48,
                color: isCompleted ? VendorColors.liveText : VendorColors.border,
              ),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.dmSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: isActive || isCompleted
                      ? VendorColors.textMain
                      : VendorColors.textMuted,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  color: VendorColors.textMuted,
                ),
              ),
              const SizedBox(height: 28),
            ],
          ),
        ),
      ],
    );
  }
}
