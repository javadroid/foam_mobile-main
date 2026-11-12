import 'package:flutter/material.dart';
import 'package:foam_mobile/feature/vendor/controller/vendor_provider.dart';
import 'package:foam_mobile/feature/vendor/store_setup/vendor_store_details_screen.dart';
import 'package:foam_mobile/feature/vendor/stores/vendor_manage_store_screen.dart';
import 'package:foam_mobile/feature/vendor/widgets/vendor_ui_components.dart';
import 'package:foam_mobile/widgets/app_skeleton_loader.dart';
import 'package:foam_mobile/widgets/safe_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class VendorStoresListScreen extends StatelessWidget {
  const VendorStoresListScreen({super.key});

  void _showLimitReachedDialog(BuildContext context, int maxStores) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            const Icon(Icons.info_outline, color: Color(0xFFEF4444)),
            const SizedBox(width: 8),
            Text(
              'Store Limit Reached',
              style: GoogleFonts.dmSans(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: VendorColors.textMain,
              ),
            ),
          ],
        ),
        content: Text(
          'You have reached your limit of $maxStores stores (default limit is 10). To add more branches, please contact the administrator to adjust your capacity.',
          style: GoogleFonts.dmSans(
            fontSize: 14,
            color: const Color(0xFF475569),
            height: 1.4,
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: VendorColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Understood',
              style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<VendorProvider>(context);
    final stores = provider.stores;
    final maxStores = provider.maxStores;
    final bool canAdd = provider.canAddStore;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Stores & Branches',
              style: GoogleFonts.dmSans(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: VendorColors.textMain,
              ),
            ),
            Text(
              '${stores.length} of $maxStores allowed · Admin managed',
              style: GoogleFonts.dmSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: VendorColors.textMuted,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14.0),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add, size: 16),
              label: Text(
                'Add Branch',
                style: GoogleFonts.dmSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: canAdd ? VendorColors.primary : const Color(0xFF94A3B8),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                if (canAdd) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const VendorStoreDetailsScreen(),
                    ),
                  );
                } else {
                  _showLimitReachedDialog(context, maxStores);
                }
              },
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => provider.fetchStores(),
          color: VendorColors.primary,
          child: provider.isLoading && stores.isEmpty
              ? AppSkeletonLoader.list(
                  count: 3,
                  itemBuilder: (_, __) => AppSkeletonLoader.storeCard(),
                )
              : stores.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: const BoxDecoration(
                                color: Color(0xFFEFF6FF),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.storefront_outlined,
                                size: 52,
                                color: VendorColors.primary,
                              ),
                            ),
                            const SizedBox(height: 18),
                            Text(
                              'No Store Branches Yet',
                              style: GoogleFonts.dmSans(
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                                color: VendorColors.textMain,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Add up to $maxStores physical store branches for your laundry business.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.dmSans(
                                fontSize: 14,
                                color: VendorColors.textMuted,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.add),
                              label: const Text('Add First Branch'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: VendorColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const VendorStoreDetailsScreen(),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                      itemCount: stores.length,
                      itemBuilder: (ctx, i) {
                        final store = stores[i];
                        final hasPhoto = store.photoUrl != null && store.photoUrl!.isNotEmpty;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Container(
                                        width: 58,
                                        height: 58,
                                        color: const Color(0xFFF1F5F9),
                                        child: hasPhoto
                                            ? SafeNetworkImage(
                                                imageUrl: store.photoUrl,
                                                width: 58,
                                                height: 58,
                                                fit: BoxFit.cover,
                                                borderRadius: BorderRadius.circular(12),
                                                fallbackBuilder: (_) => const Icon(
                                                  Icons.storefront,
                                                  color: VendorColors.primary,
                                                  size: 28,
                                                ),
                                              )
                                            : const Icon(
                                                Icons.storefront,
                                                color: VendorColors.primary,
                                                size: 28,
                                              ),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  store.name,
                                                  style: GoogleFonts.dmSans(
                                                    fontWeight: FontWeight.w800,
                                                    fontSize: 16.5,
                                                    color: VendorColors.textMain,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              VendorStatusPill(
                                                  status: store.status),
                                            ],
                                          ),
                                          const SizedBox(height: 5),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 7, vertical: 2.5),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF0FDF4),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              border: Border.all(
                                                  color: const Color(0xFFDCFCE7)),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(
                                                    Icons.check_circle_rounded,
                                                    size: 11,
                                                    color: Color(0xFF16A34A)),
                                                const SizedBox(width: 3.5),
                                                Text(
                                                  'Verified Partner',
                                                  style: GoogleFonts.dmSans(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w700,
                                                    color: const Color(0xFF15803D),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 5),
                                          Row(
                                            children: [
                                              const Icon(
                                                  Icons.location_on_outlined,
                                                  size: 14,
                                                  color: VendorColors.textMuted),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  store.address,
                                                  style: GoogleFonts.dmSans(
                                                    fontSize: 12.5,
                                                    color: VendorColors.textMuted,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              const Icon(Icons.access_time,
                                                  size: 13,
                                                  color: VendorColors.textMuted),
                                              const SizedBox(width: 4),
                                              Flexible(
                                                child: Text(
                                                  store.hoursMonFri.isNotEmpty
                                                      ? store.hoursMonFri
                                                      : '8:00 AM – 6:00 PM',
                                                  style: GoogleFonts.dmSans(
                                                    fontSize: 11.5,
                                                    color:
                                                        const Color(0xFF64748B),
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                '· ${store.itemsPricedCount} prices set',
                                                style: GoogleFonts.dmSans(
                                                  fontSize: 11.5,
                                                  fontWeight: FontWeight.w600,
                                                  color: store.itemsPricedCount > 0
                                                      ? const Color(0xFF0284C7)
                                                      : const Color(0xFFEF4444),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Divider(height: 1, color: Color(0xFFF1F5F9)),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        icon: const Icon(Icons.edit_location_alt_outlined, size: 16),
                                        label: Text(
                                          'Edit Store Profile',
                                          style: GoogleFonts.dmSans(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 12.5,
                                          ),
                                        ),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: VendorColors.textMain,
                                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          padding: const EdgeInsets.symmetric(vertical: 10),
                                        ),
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => VendorStoreDetailsScreen(store: store),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        icon: const Icon(Icons.sell_outlined, size: 15),
                                        label: Text(
                                          'Pricing Catalog',
                                          style: GoogleFonts.dmSans(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 12.5,
                                          ),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: VendorColors.primary,
                                          foregroundColor: Colors.white,
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          padding: const EdgeInsets.symmetric(vertical: 10),
                                        ),
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => VendorManageStoreScreen(store: store),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
        ),
      ),
    );
  }
}
