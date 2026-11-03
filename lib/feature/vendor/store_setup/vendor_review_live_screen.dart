import 'package:flutter/material.dart';
import 'package:foam_mobile/feature/vendor/controller/vendor_provider.dart';
import 'package:foam_mobile/feature/vendor/vendor_main_screen.dart';
import 'package:foam_mobile/feature/vendor/widgets/vendor_ui_components.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class VendorReviewLiveScreen extends StatelessWidget {
  static const String id = '/vendor_review_live';

  const VendorReviewLiveScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vendorProvider = Provider.of<VendorProvider>(context);
    final store = vendorProvider.currentStore;
    final initials = store.name.trim().isNotEmpty
        ? (store.name.trim().split(' ').length > 1
            ? '${store.name.trim().split(' ')[0][0]}${store.name.trim().split(' ')[1][0]}'.toUpperCase()
            : store.name.substring(0, store.name.length >= 2 ? 2 : 1).toUpperCase())
        : 'ST';

    final laundryPriced = vendorProvider.getItemPrices(store.id, 'Laundry', 'Folding').length;
    final dryCleaningPriced = vendorProvider.getItemPrices(store.id, 'Dry cleaning', 'Standard').length;
    final includeFolding = vendorProvider.getStoreIncludeFolding(store.id);

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
              Text(
                'Ready to go live',
                style: GoogleFonts.dmSans(
                  color: VendorColors.textMain,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Confirm your store setup and publish to nearby customers.',
                style: GoogleFonts.dmSans(
                  color: VendorColors.textMuted,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),

              // Store Card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: VendorColors.lightBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: VendorColors.border),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: VendorColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          initials,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            store.name,
                            style: GoogleFonts.dmSans(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: VendorColors.textMain,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            store.address,
                            style: GoogleFonts.dmSans(
                              fontSize: 13,
                              color: VendorColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Checklist
              _buildCheckItem('Address & map pin', '${store.address.isNotEmpty ? store.address : "Store address"} geocoded'),
              const SizedBox(height: 12),
              _buildCheckItem('Operating hours', store.hoursMonFri),
              const SizedBox(height: 12),
              _buildCheckItem('Laundry prices', laundryPriced > 0 ? '$laundryPriced items configured' : 'Not configured'),
              const SizedBox(height: 12),
              _buildCheckItem('Dry cleaning prices', dryCleaningPriced > 0 ? '$dryCleaningPriced items configured' : 'Not configured'),
              const SizedBox(height: 12),
              _buildCheckItem('Folding service', includeFolding ? 'Included by default' : 'Optional'),

              const SizedBox(height: 24),

              // Live Status Banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: VendorColors.liveBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: VendorColors.liveText.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: VendorColors.liveText, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Store is live',
                            style: GoogleFonts.dmSans(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: VendorColors.liveText,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Visible to customers nearby. You can pause anytime from store settings.',
                            style: GoogleFonts.dmSans(
                              fontSize: 12,
                              color: VendorColors.liveText.withValues(alpha: 0.85),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              VendorButton(
                text: 'Go to orders',
                onPressed: () {
                  // Mark store live
                  if (!store.isLive) {
                    vendorProvider.toggleStoreLive(store.id);
                  }
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const VendorMainScreen(),
                    ),
                    (route) => false,
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

  Widget _buildCheckItem(String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: VendorColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, color: VendorColors.liveText, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.dmSans(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: VendorColors.textMain,
              ),
            ),
          ),
          Text(
            subtitle,
            style: GoogleFonts.dmSans(
              fontSize: 12,
              color: VendorColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
