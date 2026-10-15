import 'package:flutter/material.dart';
import 'package:foam_mobile/feature/vendor/controller/vendor_provider.dart';
import 'package:foam_mobile/feature/vendor/store_setup/vendor_pricing_fold_screen.dart';
import 'package:foam_mobile/feature/vendor/store_setup/vendor_review_live_screen.dart';
import 'package:foam_mobile/feature/vendor/widgets/vendor_ui_components.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class VendorPricingServiceScreen extends StatelessWidget {
  static const String id = '/vendor_pricing_service';

  const VendorPricingServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vendorProvider = Provider.of<VendorProvider>(context);
    final storeName = vendorProvider.currentStore.name;

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
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Set prices',
                style: GoogleFonts.dmSans(
                  color: VendorColors.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                storeName,
                style: GoogleFonts.dmSans(
                  color: VendorColors.textMain,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Which service are you pricing?',
                style: GoogleFonts.dmSans(
                  color: VendorColors.textMuted,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 28),

              // Service Option 1: Laundry
              _buildServiceCard(
                title: 'Laundry',
                subtitle: 'Wash & fold or wash & hang',
                statusText: '8 of 16 items priced',
                isConfigured: true,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const VendorPricingFoldScreen(
                        serviceType: 'Laundry',
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

              // Service Option 2: Dry cleaning
              _buildServiceCard(
                title: 'Dry cleaning',
                subtitle: 'Suits, evening wear, delicate fabrics',
                statusText: 'Not started · 12 items',
                isConfigured: false,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const VendorPricingFoldScreen(
                        serviceType: 'Dry cleaning',
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: VendorColors.lightBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 18, color: VendorColors.textMuted),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Prices apply to this store only. Your other stores keep their own prices.',
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          color: VendorColors.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              VendorButton(
                text: 'Review & go live',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const VendorReviewLiveScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServiceCard({
    required String title,
    required String subtitle,
    required String statusText,
    required bool isConfigured,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: VendorColors.lightBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isConfigured
                ? VendorColors.primary.withOpacity(0.4)
                : VendorColors.border,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isConfigured ? VendorColors.draftBg : Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(
                title == 'Laundry' ? Icons.local_laundry_service : Icons.dry_cleaning,
                color: isConfigured ? VendorColors.primary : VendorColors.textMuted,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.dmSans(
                      fontWeight: FontWeight.w700,
                      fontSize: 17,
                      color: VendorColors.textMain,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      color: VendorColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    statusText,
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isConfigured ? VendorColors.primary : VendorColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: VendorColors.textMuted),
          ],
        ),
      ),
    );
  }
}
