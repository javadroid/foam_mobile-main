import 'package:flutter/material.dart';
import 'package:foam_mobile/core/Screens/help/help_screen.dart';
import 'package:foam_mobile/feature/vendor/controller/vendor_provider.dart';
import 'package:foam_mobile/feature/vendor/onboarding/vendor_onboarding_stepper_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class VendorRejectedScreen extends StatelessWidget {
  static const String id = '/vendor_rejected';

  const VendorRejectedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vendorProvider = Provider.of<VendorProvider>(context);
    final kyc = vendorProvider.kycStatus;

    String docTag = 'CAC REGISTRATION';
    String rejectionMessage =
        "The certificate is cropped and the RC number isn't readable. Upload a clear scan of the full page.";

    final reason = kyc.rejectionReason;
    if (reason != null && reason.isNotEmpty) {
      rejectionMessage = reason;
      final lower = reason.toLowerCase();
      if (lower.contains('id') ||
          lower.contains('identity') ||
          lower.contains('passport') ||
          lower.contains('nin') ||
          lower.contains('voter')) {
        docTag = "OWNER'S VALID ID";
      } else if (lower.contains('address') ||
          lower.contains('utility') ||
          lower.contains('bill')) {
        docTag = 'PROOF OF BUSINESS ADDRESS';
      }
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 36.0, 16.0, 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 88px Amber Exclamation Circle
              Container(
                width: 88,
                height: 88,
                decoration: const BoxDecoration(
                  color: Color(0xFFFDF0E2),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '!',
                  style: GoogleFonts.dmSans(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFCF7B0C),
                    height: 1.0,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Title
              Text(
                'One document needs another look',
                style: GoogleFonts.dmSans(
                  color: const Color(0xFF212828),
                  fontSize: 31,
                  fontWeight: FontWeight.w500,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 10),

              // Subtitle
              Text(
                'Fix the item below and resubmit. Everything else you sent is saved.',
                style: GoogleFonts.dmSans(
                  color: const Color(0xFF5E5E5E),
                  fontSize: 16,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 32),

              // Rejection Card (#FDF0E2 container)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDF0E2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      docTag,
                      style: GoogleFonts.dmSans(
                        color: const Color(0xFFCF7B0C),
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.04,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      rejectionMessage,
                      style: GoogleFonts.dmSans(
                        color: const Color(0xFF212828),
                        fontSize: 16,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Primary CTA Button: Fix and resubmit
              Container(
                width: double.infinity,
                height: 53,
                decoration: BoxDecoration(
                  color: const Color(0xFF001C1F),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      final vendor =
                          Provider.of<VendorProvider>(context, listen: false);
                      vendor.setOnboardingStep(1);
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const VendorOnboardingStepperScreen(),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Center(
                      child: Text(
                        'Fix and resubmit',
                        style: GoogleFonts.dmSans(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.44,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Footer: Questions? Contact Foam support
              Center(
                child: GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(context, HelpScreen.id);
                  },
                  child: Text.rich(
                    TextSpan(
                      text: 'Questions? ',
                      style: GoogleFonts.dmSans(
                        fontSize: 16,
                        color: const Color(0xFF5E5E5E),
                      ),
                      children: [
                        TextSpan(
                          text: 'Contact Foam support',
                          style: GoogleFonts.dmSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF00AABC),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
