import 'package:flutter/material.dart';
import 'package:foam_mobile/feature/schedule_pickup/controller/schedule_pickup_provider.dart';
import 'package:foam_mobile/feature/schedule_pickup/models/customer_schedule_models.dart';
import 'package:foam_mobile/feature/schedule_pickup/views/04_store_page_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class NearbyStoresScreen extends StatelessWidget {
  static const String id = '/schedule_pickup/stores';

  const NearbyStoresScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SchedulePickupProvider>(context);
    final stores = provider.nearbyStores;
    final currentFilter = provider.storeFilter;

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

              const SizedBox(height: 18),

              // Store cards list
              Expanded(
                child: provider.isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: Color(0xFF00AABC)),
                      )
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
    return InkWell(
      onTap: () {
        provider.selectStore(store);
        Navigator.pushNamed(context, CustomerStorePageScreen.id);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE4E4E4), width: 0.8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '${store.name} · ${store.area}',
                    style: GoogleFonts.dmSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF212828),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '★ ${store.rating.toStringAsFixed(1)}',
                  style: GoogleFonts.dmSans(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF212828),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${store.distanceKm} km · ${store.turnaroundText} · Shirt from ₦${store.shirtStartingPrice}',
              style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF5E5E5E),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
