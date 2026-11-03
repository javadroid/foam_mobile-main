import 'package:flutter/material.dart';
import 'package:foam_mobile/feature/vendor/controller/vendor_provider.dart';
import 'package:foam_mobile/feature/vendor/store_setup/vendor_pricing_items_screen.dart';
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
    final store = vendorProvider.currentStore;
    final storeName = store.name;

    final laundryPrices = vendorProvider.getItemPrices(store.id, 'Laundry', 'Folding');
    final laundryCount = laundryPrices.length;

    final dryCleaningPrices = vendorProvider.getItemPrices(store.id, 'Dry cleaning', 'Standard');
    final dryCleaningCount = dryCleaningPrices.length;

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

              // Service Option 1: Laundry (Direct to Items with Folding Setting)
              _buildServiceCard(
                title: 'Laundry',
                subtitle: 'Wash, dry, iron & folding care',
                statusText: laundryCount > 0 ? '$laundryCount items priced' : 'Not started',
                isConfigured: laundryCount > 0,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const VendorPricingItemsScreen(
                        serviceType: 'Laundry',
                        foldType: 'Folding',
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

              // Service Option 2: Dry cleaning (Direct to Items)
              _buildServiceCard(
                title: 'Dry cleaning',
                subtitle: 'Suits, evening wear, delicate fabrics',
                statusText: dryCleaningCount > 0 ? '$dryCleaningCount items priced' : 'Not started',
                isConfigured: dryCleaningCount > 0,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const VendorPricingItemsScreen(
                        serviceType: 'Dry cleaning',
                        foldType: 'Standard',
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isConfigured ? VendorColors.primary : VendorColors.border,
            width: isConfigured ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isConfigured
                    ? VendorColors.primary.withValues(alpha: 0.1)
                    : VendorColors.lightBg,
                shape: BoxShape.circle,
              ),
              child: Icon(
                title == 'Laundry' ? Icons.local_laundry_service : Icons.dry_cleaning,
                color: isConfigured ? VendorColors.primary : VendorColors.textMuted,
                size: 22,
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
                      color: VendorColors.textMain,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.dmSans(
                      color: VendorColors.textMuted,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    statusText,
                    style: GoogleFonts.dmSans(
                      color: isConfigured ? VendorColors.primary : VendorColors.textMuted,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: VendorColors.border,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}
