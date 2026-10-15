import 'package:flutter/material.dart';
import 'package:foam_mobile/feature/vendor/onboarding/vendor_documents_screen.dart';
import 'package:foam_mobile/feature/vendor/widgets/vendor_ui_components.dart';
import 'package:google_fonts/google_fonts.dart';

class VendorRejectedScreen extends StatelessWidget {
  static const String id = '/vendor_rejected';

  const VendorRejectedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: VendorColors.textMain),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: VendorColors.urgentBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.priority_high_rounded,
                  color: VendorColors.urgentText,
                  size: 26,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'One document needs another look',
                style: GoogleFonts.dmSans(
                  color: VendorColors.textMain,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Fix the item below and resubmit. Everything else you sent was approved.',
                style: GoogleFonts.dmSans(
                  color: VendorColors.textMuted,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 32),

              // Rejection Card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: VendorColors.urgentBg.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: VendorColors.urgentText.withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: VendorColors.urgentText,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'CAC REGISTRATION',
                          style: GoogleFonts.dmSans(
                            color: VendorColors.urgentText,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "The certificate is cropped and the RC number isn't visible. Please upload the full page clearly showing your company number.",
                      style: GoogleFonts.dmSans(
                        color: VendorColors.textMain,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              VendorButton(
                text: 'Fix and resubmit',
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const VendorDocumentsScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 14),
              Center(
                child: TextButton(
                  onPressed: () {
                    // Contact support action
                  },
                  child: Text(
                    'Questions? Contact Foam support',
                    style: GoogleFonts.dmSans(
                      color: VendorColors.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
