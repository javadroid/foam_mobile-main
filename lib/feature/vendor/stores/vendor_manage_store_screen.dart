import 'package:flutter/material.dart';
import 'package:foam_mobile/feature/vendor/controller/vendor_provider.dart';
import 'package:foam_mobile/feature/vendor/models/vendor_models.dart';
import 'package:foam_mobile/feature/vendor/store_setup/vendor_pricing_items_screen.dart';
import 'package:foam_mobile/feature/vendor/store_setup/vendor_store_details_screen.dart';
import 'package:foam_mobile/feature/vendor/widgets/vendor_ui_components.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class VendorManageStoreScreen extends StatelessWidget {
  final VendorStore store;

  const VendorManageStoreScreen({super.key, required this.store});

  String _getPriceSummary(
    VendorProvider provider,
    String storeId,
    String serviceType,
    String foldType,
  ) {
    final prices = provider.getItemPrices(storeId, serviceType, foldType);
    if (prices.isEmpty) {
      return 'Not set yet · Tap to set prices';
    }
    final count = prices.length;
    final minPrice = prices.values.reduce((a, b) => a < b ? a : b);
    return '$count ${count == 1 ? "item" : "items"} · from ₦${minPrice.toInt()}';
  }

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
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_location_alt_outlined, color: VendorColors.primary),
            tooltip: 'Edit Store Profile',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => VendorStoreDetailsScreen(store: store),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Branch Info & Verified Partner Badge
              Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFF1F5F9)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on_outlined,
                        size: 15, color: VendorColors.textMuted),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        store.address.isNotEmpty
                            ? store.address
                            : 'Branch location',
                        style: GoogleFonts.dmSans(
                          fontSize: 12.5,
                          color: VendorColors.textMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFDCFCE7)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_circle_rounded,
                              size: 12, color: Color(0xFF16A34A)),
                          const SizedBox(width: 4),
                          Text(
                            'Verified Partner',
                            style: GoogleFonts.dmSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF15803D),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

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
                title: 'Laundry',
                subtitle: _getPriceSummary(provider, store.id, 'Laundry', 'Folding'),
                onEdit: () {
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
              const Divider(height: 16, color: VendorColors.border),
              _buildManagePriceRow(
                title: 'Dry cleaning',
                subtitle: _getPriceSummary(provider, store.id, 'Dry cleaning', 'Standard'),
                onEdit: () {
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
              const Divider(height: 16, color: VendorColors.border),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Include Folding Service',
                            style: GoogleFonts.dmSans(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: VendorColors.textMain,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Wash, dry, iron and fold by default (customers can opt out at checkout)',
                            style: GoogleFonts.dmSans(
                              fontSize: 12.5,
                              color: VendorColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: provider.getStoreIncludeFolding(store.id),
                      activeThumbColor: const Color(0xFF16A34A),
                      onChanged: (val) {
                        provider.setStoreIncludeFolding(store.id, val);
                      },
                    ),
                  ],
                ),
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
