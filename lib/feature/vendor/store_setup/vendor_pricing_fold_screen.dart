import 'package:flutter/material.dart';
import 'package:foam_mobile/feature/vendor/controller/vendor_provider.dart';
import 'package:foam_mobile/feature/vendor/store_setup/vendor_pricing_items_screen.dart';
import 'package:foam_mobile/feature/vendor/widgets/vendor_ui_components.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class VendorPricingFoldScreen extends StatelessWidget {
  final String serviceType;

  const VendorPricingFoldScreen({super.key, required this.serviceType});

  @override
  Widget build(BuildContext context) {
    final vendorProvider = Provider.of<VendorProvider>(context);
    final store = vendorProvider.currentStore;
    final foldingCount = vendorProvider.getItemPrices(store.id, serviceType, 'Folding').length;
    final nonFoldingCount = vendorProvider.getItemPrices(store.id, serviceType, 'Non-folding').length;

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
                serviceType,
                style: GoogleFonts.dmSans(
                  color: VendorColors.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${store.name} · $serviceType',
                style: GoogleFonts.dmSans(
                  color: VendorColors.textMain,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Folding or non-folding?',
                style: GoogleFonts.dmSans(
                  color: VendorColors.textMain,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Customers choose one when they book. Price each service so customers can book with clarity.',
                style: GoogleFonts.dmSans(
                  color: VendorColors.textMuted,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 28),

              // Option 1: Folding
              _buildFoldCard(
                title: 'Folding',
                subtitle: 'Items washed, dried, ironed, and folded in Foam packaging',
                status: foldingCount > 0 ? '✓ $foldingCount items priced' : 'Not priced',
                isPriced: foldingCount > 0,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => VendorPricingItemsScreen(
                        serviceType: serviceType,
                        foldType: 'Folding',
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

              // Option 2: Non-folding
              _buildFoldCard(
                title: 'Non-folding',
                subtitle: 'Items washed, dried, ironed, and returned on hangers',
                status: nonFoldingCount > 0 ? '✓ $nonFoldingCount items priced' : 'Not priced',
                isPriced: nonFoldingCount > 0,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => VendorPricingItemsScreen(
                        serviceType: serviceType,
                        foldType: 'Non-folding',
                      ),
                    ),
                  );
                },
              ),

              const Spacer(),

              VendorButton(
                text: 'Done with fold types',
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFoldCard({
    required String title,
    required String subtitle,
    required String status,
    required bool isPriced,
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
            color: isPriced
                ? VendorColors.primary.withValues(alpha: 0.3)
                : VendorColors.border,
          ),
        ),
        child: Row(
          children: [
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
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      color: VendorColors.textMuted,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    status,
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: VendorColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: VendorColors.border),
              ),
              child: Text(
                'Edit',
                style: GoogleFonts.dmSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: VendorColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
