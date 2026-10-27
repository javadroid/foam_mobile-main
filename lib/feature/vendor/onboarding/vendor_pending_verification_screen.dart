import 'package:flutter/material.dart';
import 'package:foam_mobile/core/Screens/main_screen.dart';
import 'package:foam_mobile/feature/vendor/controller/vendor_provider.dart';
import 'package:foam_mobile/feature/vendor/onboarding/vendor_rejected_screen.dart';
import 'package:foam_mobile/feature/vendor/vendor_main_screen.dart';
import 'package:foam_mobile/feature/vendor/widgets/vendor_ui_components.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class VendorPendingVerificationScreen extends StatelessWidget {
  static const String id = '/vendor_pending_verification';

  const VendorPendingVerificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: VendorColors.textMain, size: 20),
          onPressed: () {
            Navigator.pushNamedAndRemoveUntil(
                context, MainScreen.id, (route) => false);
          },
        ),
        title: Text(
          'Verification Status',
          style: GoogleFonts.dmSans(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: VendorColors.textMain,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: VendorColors.textMain),
            tooltip: 'Check Status',
            onPressed: () async {
              final vendor =
                  Provider.of<VendorProvider>(context, listen: false);
              final profile = await vendor.fetchVendorProfile();
              if (!context.mounted) return;
              if (profile != null) {
                final status = vendor.kycStatus.reviewStatus.toUpperCase();
                if (status == 'APPROVED') {
                  Navigator.pushReplacementNamed(
                      context, VendorMainScreen.id);
                } else if (status == 'REJECTED') {
                  Navigator.pushReplacementNamed(
                      context, VendorRejectedScreen.id);
                } else {
                  ScaffoldMessenger.of(context).clearSnackBars();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.info_outline, color: Colors.white, size: 18),
                          const SizedBox(width: 10),
                          Text(
                            'Your application is still under review.',
                            style: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      backgroundColor: const Color(0xFF0F172A),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                }
              } else {
                ScaffoldMessenger.of(context).clearSnackBars();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded, color: Colors.white, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Unable to check status. Please check your network.',
                            style: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    backgroundColor: const Color(0xFFDC2626),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                "This usually takes up to 2 business days. We'll notify you as soon as your account is approved.",
                style: GoogleFonts.dmSans(
                  color: VendorColors.textMuted,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 32),

              // Timeline progression
              _buildTimelineStep(
                title: 'Application Submitted',
                subtitle: 'Documents & payout bank saved',
                isCompleted: true,
                isActive: false,
                isLast: false,
              ),
              _buildTimelineStep(
                title: 'Under Review',
                subtitle: 'Foam team is reviewing your business',
                isCompleted: false,
                isActive: true,
                isLast: false,
              ),
              _buildTimelineStep(
                title: 'Approved',
                subtitle: 'Ready to set up stores and receive orders',
                isCompleted: false,
                isActive: false,
                isLast: true,
              ),

              const Spacer(),

              // Switch to Customer mode card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: VendorColors.lightBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: VendorColors.border),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: VendorColors.border),
                          ),
                          child: const Icon(
                            Icons.shopping_bag_outlined,
                            color: VendorColors.primary,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Browse as Customer',
                                style: GoogleFonts.dmSans(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  color: VendorColors.textMain,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'You can order laundry and use customer features while you wait.',
                                style: GoogleFonts.dmSans(
                                  fontSize: 12.5,
                                  color: VendorColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    VendorButton(
                      text: 'Switch to Customer App',
                      onPressed: () {
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          MainScreen.id,
                          (route) => false,
                        );
                      },
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
                    ? const Icon(Icons.check,
                        size: 16, color: VendorColors.liveText)
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
                color:
                    isCompleted ? VendorColors.liveText : VendorColors.border,
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
