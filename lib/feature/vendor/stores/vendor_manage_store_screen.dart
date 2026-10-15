import 'package:flutter/material.dart';
import 'package:foam_mobile/feature/vendor/controller/vendor_provider.dart';
import 'package:foam_mobile/feature/vendor/models/vendor_models.dart';
import 'package:foam_mobile/feature/vendor/store_setup/vendor_pricing_fold_screen.dart';
import 'package:foam_mobile/feature/vendor/store_setup/vendor_store_details_screen.dart';
import 'package:foam_mobile/feature/vendor/widgets/vendor_ui_components.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class VendorManageStoreScreen extends StatelessWidget {
  final VendorStore store;

  const VendorManageStoreScreen({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<VendorProvider>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: VendorColors.textMain),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          store.name,
          style: GoogleFonts.dmSans(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: VendorColors.textMain,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Store Status Toggle (Live vs Paused)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: VendorColors.lightBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: VendorColors.border),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          if (!store.isLive) provider.toggleStoreLive(store.id);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: store.isLive ? VendorColors.liveBg : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: VendorColors.liveText,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Live',
                                  style: GoogleFonts.dmSans(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                    color: store.isLive
                                        ? VendorColors.liveText
                                        : VendorColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          if (store.isLive) provider.toggleStoreLive(store.id);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: store.isPaused ? VendorColors.pausedBg : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: VendorColors.pausedText,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Paused',
                                  style: GoogleFonts.dmSans(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                    color: store.isPaused
                                        ? VendorColors.pausedText
                                        : VendorColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Prices section
              Text(
                'Prices',
                style: GoogleFonts.dmSans(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: VendorColors.textMain,
                ),
              ),
              const SizedBox(height: 12),

              _buildManagePriceRow(
                title: 'Laundry · Folding',
                subtitle: '8 items · from ₦400',
                onEdit: () {
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
              const Divider(height: 16, color: VendorColors.border),
              _buildManagePriceRow(
                title: 'Laundry · Non-folding',
                subtitle: '8 items · from ₦350',
                onEdit: () {
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
              const Divider(height: 16, color: VendorColors.border),
              _buildManagePriceRow(
                title: 'Dry cleaning · Folding',
                subtitle: '6 items · from ₦1,200',
                onEdit: () {
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
              const Divider(height: 16, color: VendorColors.border),
              _buildManagePriceRow(
                title: 'Dry cleaning · Non-folding',
                subtitle: '6 items · from ₦1,000',
                onEdit: () {
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

              const SizedBox(height: 28),

              // Details section
              Text(
                'Details',
                style: GoogleFonts.dmSans(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: VendorColors.textMain,
                ),
              ),
              const SizedBox(height: 12),

              _buildManagePriceRow(
                title: 'Address & map pin',
                subtitle: store.address,
                onEdit: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const VendorStoreDetailsScreen(),
                    ),
                  );
                },
              ),
              const Divider(height: 16, color: VendorColors.border),
              _buildManagePriceRow(
                title: 'Operating hours',
                subtitle: '${store.hoursMonFri} (Mon–Fri)',
                onEdit: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const VendorStoreDetailsScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 24),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: VendorColors.lightBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Price changes apply to new orders only. Orders already placed keep their original price.',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    color: VendorColors.textMuted,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildManagePriceRow({
    required String title,
    required String subtitle,
    required VoidCallback onEdit,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.dmSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: VendorColors.textMain,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    color: VendorColors.textMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onEdit,
            child: Text(
              'Edit',
              style: GoogleFonts.dmSans(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: VendorColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
