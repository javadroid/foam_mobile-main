import 'package:flutter/material.dart';
import 'package:foam_mobile/feature/vendor/controller/vendor_provider.dart';
import 'package:foam_mobile/feature/vendor/models/vendor_models.dart';
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

    final laundryPrices =
        vendorProvider.getItemPrices(store.id, 'Laundry', 'Folding');
    final laundryCount = laundryPrices.length;

    final dryCleaningPrices =
        vendorProvider.getItemPrices(store.id, 'Dry cleaning', 'Standard');
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
                statusText: laundryCount > 0
                    ? '$laundryCount items priced'
                    : 'Not started',
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
                statusText: dryCleaningCount > 0
                    ? '$dryCleaningCount items priced'
                    : 'Not started',
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

              if (vendorProvider.stores.length > 1) ...[
                const SizedBox(height: 16),
                _buildCopyAllPricingCard(context, vendorProvider, store),
              ],

              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: VendorColors.lightBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline,
                        size: 18, color: VendorColors.textMuted),
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
                title == 'Laundry'
                    ? Icons.local_laundry_service
                    : Icons.dry_cleaning,
                color: isConfigured
                    ? VendorColors.primary
                    : VendorColors.textMuted,
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
                      color: isConfigured
                          ? VendorColors.primary
                          : VendorColors.textMuted,
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

  Widget _buildCopyAllPricingCard(
    BuildContext context,
    VendorProvider vendorProvider,
    VendorStore currentStore,
  ) {
    return InkWell(
      onTap: () => _showCopyPricingSheet(context, vendorProvider, currentStore),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFCBD5E1), width: 1.0),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Color(0xFFE0F2FE),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.copy_all_rounded,
                color: VendorColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Copy pricing from another branch',
                    style: GoogleFonts.dmSans(
                      color: VendorColors.textMain,
                      fontWeight: FontWeight.w700,
                      fontSize: 14.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Quickly duplicate items & prices from another branch',
                    style: GoogleFonts.dmSans(
                      color: VendorColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: VendorColors.textMuted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  void _showCopyPricingSheet(
    BuildContext context,
    VendorProvider vendorProvider,
    VendorStore currentStore,
  ) {
    final otherStores =
        vendorProvider.stores.where((s) => s.id != currentStore.id).toList();
    if (otherStores.isEmpty) return;

    String selectedStoreId = otherStores.first.id;
    String selectedServiceOption = 'All Services';
    bool isCopying = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE5F7F8),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.copy_rounded,
                            color: VendorColors.primary, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Copy Pricing to ${currentStore.name}',
                              style: GoogleFonts.dmSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: VendorColors.textMain,
                              ),
                            ),
                            Text(
                              'Select source branch and services to copy',
                              style: GoogleFonts.dmSans(
                                  fontSize: 12, color: VendorColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Source branch',
                    style: GoogleFonts.dmSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: VendorColors.textMain),
                  ),
                  const SizedBox(height: 8),
                  ...otherStores.map((s) {
                    final isSelected = selectedStoreId == s.id;
                    return GestureDetector(
                      onTap: () {
                        setModalState(() => selectedStoreId = s.id);
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFFF0FDF4)
                              : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF16A34A)
                                : const Color(0xFFE2E8F0),
                            width: isSelected ? 1.5 : 1.0,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isSelected
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_off,
                              color: isSelected
                                  ? const Color(0xFF16A34A)
                                  : VendorColors.textMuted,
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                s.name,
                                style: GoogleFonts.dmSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: VendorColors.textMain,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 12),
                  Text(
                    'Services to copy',
                    style: GoogleFonts.dmSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: VendorColors.textMain),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children:
                        ['All Services', 'Laundry', 'Dry cleaning'].map((opt) {
                      final isSelected = selectedServiceOption == opt;
                      return ChoiceChip(
                        label: Text(opt),
                        selected: isSelected,
                        selectedColor: VendorColors.primary,
                        labelStyle: GoogleFonts.dmSans(
                          color:
                              isSelected ? Colors.white : VendorColors.textMain,
                          fontWeight: FontWeight.w700,
                          fontSize: 12.5,
                        ),
                        backgroundColor: const Color(0xFFF1F5F9),
                        onSelected: (val) {
                          if (val) {
                            setModalState(() => selectedServiceOption = opt);
                          }
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  VendorButton(
                    text: isCopying ? 'Copying pricing...' : 'Copy Pricing Now',
                    isLoading: isCopying,
                    onPressed: isCopying
                        ? null
                        : () async {
                            setModalState(() => isCopying = true);
                            final messenger = ScaffoldMessenger.of(context);
                            final navigator = Navigator.of(modalCtx);
                            final serviceParam =
                                selectedServiceOption == 'All Services'
                                    ? null
                                    : selectedServiceOption;

                            final success =
                                await vendorProvider.copyPricingBetweenStores(
                              sourceStoreId: selectedStoreId,
                              targetStoreId: currentStore.id,
                              serviceType: serviceParam,
                            );

                            navigator.pop();

                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  success
                                      ? 'Pricing successfully copied to ${currentStore.name}!'
                                      : 'Failed to copy pricing. Please ensure source branch has pricing set.',
                                  style: GoogleFonts.dmSans(
                                      fontWeight: FontWeight.w600),
                                ),
                                backgroundColor: success
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFFEF4444),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                              ),
                            );
                          },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
