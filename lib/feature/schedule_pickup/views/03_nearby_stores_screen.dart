import 'package:flutter/material.dart';
import 'package:foam_mobile/core/Screens/profile/customer_address_screen.dart';
import 'package:foam_mobile/feature/schedule_pickup/controller/schedule_pickup_provider.dart';
import 'package:foam_mobile/feature/schedule_pickup/models/customer_schedule_models.dart';
import 'package:foam_mobile/feature/schedule_pickup/views/04_store_page_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class NearbyStoresScreen extends StatelessWidget {
  static const String id = '/schedule_pickup/stores';

  const NearbyStoresScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SchedulePickupProvider>(context);
    final stores = provider.nearbyStores;
    final currentFilter = provider.storeFilter;
    final isOutsideReach = provider.tierMetadata?.isFallback == true ||
        (stores.isNotEmpty && stores.first.distanceKm > 20.0);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF212828), size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Stores near you',
          style: GoogleFonts.dmSans(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF212828),
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Filter pills row
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterPill(
                      label: 'Closest',
                      isActive: currentFilter == 'closest',
                      onTap: () => provider.setStoreFilter('closest'),
                    ),
                    const SizedBox(width: 8),
                    _buildFilterPill(
                      label: 'Top rated',
                      isActive: currentFilter == 'top_rated',
                      onTap: () => provider.setStoreFilter('top_rated'),
                    ),
                    const SizedBox(width: 8),
                    _buildFilterPill(
                      label: 'Fastest',
                      isActive: currentFilter == 'fastest',
                      onTap: () => provider.setStoreFilter('fastest'),
                    ),
                  ],
                ),
              ),

              if (isOutsideReach && stores.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, size: 16, color: Color(0xFFD97706)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Showing nearest available stores outside standard 5 km reach.',
                          style: GoogleFonts.dmSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF92400E),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 14),

              // Store cards list or Empty state
              Expanded(
                child: provider.isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: Color(0xFF00AABC)),
                      )
                    : stores.isEmpty
                        ? _buildEmptyState(context, provider)
                        : ListView.separated(
                            itemCount: stores.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final store = stores[index];
                              return _buildStoreCard(context, store, provider);
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(
      BuildContext context, SchedulePickupProvider provider) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: Color(0xFFE5F7F8),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.storefront_outlined,
                size: 36,
                color: Color(0xFF00AABC),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No stores found nearby',
              style: GoogleFonts.dmSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF212828),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'We couldn\'t find any partner laundry stores for your current pickup location. Try updating your pickup address or using GPS auto-detect.',
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                fontSize: 13.5,
                height: 1.4,
                color: const Color(0xFF5E5E5E),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, CustomerAddressScreen.id);
              },
              icon: const Icon(Icons.location_on_outlined, size: 18),
              label: Text(
                'Change Pickup Location',
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00AABC),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterPill({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF001C1F) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? const Color(0xFF001C1F) : const Color(0xFFE4E4E4),
            width: 0.8,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 14,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            color: isActive ? Colors.white : const Color(0xFF212828),
          ),
        ),
      ),
    );
  }

  Widget _buildStoreCard(
    BuildContext context,
    NearbyStore store,
    SchedulePickupProvider provider,
  ) {
    final currencyFormatter = NumberFormat('#,###');

    return InkWell(
      onTap: () {
        provider.selectStore(store);
        Navigator.pushNamed(context, CustomerStorePageScreen.id);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE4E4E4), width: 0.8),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Store Avatar / Thumbnail
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: const Color(0xFFE5F7F8),
                borderRadius: BorderRadius.circular(10),
                image: store.photoUrl != null && store.photoUrl!.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(store.photoUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: (store.photoUrl == null || store.photoUrl!.isEmpty)
                  ? const Center(
                      child: Icon(Icons.storefront_rounded, color: Color(0xFF00AABC), size: 26),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          store.name,
                          style: GoogleFonts.dmSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF212828),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_rounded, size: 16, color: Color(0xFFF59E0B)),
                          const SizedBox(width: 2),
                          Text(
                            store.rating.toStringAsFixed(1),
                            style: GoogleFonts.dmSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF212828),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    store.area.isNotEmpty ? store.area : store.address,
                    style: GoogleFonts.dmSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF5E5E5E),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: store.logisticsType == 'FOAM_RIDERS'
                          ? const Color(0xFFF0FDF4)
                          : store.logisticsType == 'OWN_LOGISTICS'
                              ? const Color(0xFFFEF3C7)
                              : const Color(0xFFE0F2FE),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          store.logisticsType == 'FOAM_RIDERS'
                              ? Icons.two_wheeler_rounded
                              : store.logisticsType == 'OWN_LOGISTICS'
                                  ? Icons.local_shipping_outlined
                                  : Icons.alt_route_rounded,
                          size: 11,
                          color: store.logisticsType == 'FOAM_RIDERS'
                              ? const Color(0xFF16A34A)
                              : store.logisticsType == 'OWN_LOGISTICS'
                                  ? const Color(0xFFD97706)
                                  : const Color(0xFF0284C7),
                        ),
                        const SizedBox(width: 3.5),
                        Text(
                          store.logisticsDisplayText,
                          style: GoogleFonts.dmSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: store.logisticsType == 'FOAM_RIDERS'
                                ? const Color(0xFF16A34A)
                                : store.logisticsType == 'OWN_LOGISTICS'
                                    ? const Color(0xFFD97706)
                                    : const Color(0xFF0284C7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        '${store.distanceKm.toStringAsFixed(1)} km',
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF00AABC),
                        ),
                      ),
                      Text(
                        ' · ${store.turnaroundText}',
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Shirt from ₦${currencyFormatter.format(store.shirtStartingPrice)}',
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF001C1F),
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
    );
  }
}
