import 'package:flutter/material.dart';
import 'package:foam_mobile/core/Screens/home/services_screen/views/services_screen.dart';
import 'package:foam_mobile/feature/schedule_pickup/controller/schedule_pickup_provider.dart';
import 'package:foam_mobile/feature/schedule_pickup/models/customer_schedule_models.dart';
import 'package:foam_mobile/feature/schedule_pickup/views/04_store_page_screen.dart';
import 'package:foam_mobile/widgets/app_skeleton_loader.dart';
import 'package:foam_mobile/widgets/store_out_of_range_dialog.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class ScheduleTiersScreen extends StatefulWidget {
  static const String id = '/schedule_pickup/tiers';

  const ScheduleTiersScreen({super.key});

  @override
  State<ScheduleTiersScreen> createState() => _ScheduleTiersScreenState();
}

class _ScheduleTiersScreenState extends State<ScheduleTiersScreen> {
  static const List<ScheduleTier> fallbackTiers = [
    ScheduleTier(
      id: 'BEST_VALUE',
      title: 'Best value',
      startingPrice: 350,
      turnaroundDays: 3,
      turnaroundText: 'Ready in 3 days · ★ 4.2 average',
      isMostPicked: false,
    ),
    ScheduleTier(
      id: 'BALANCED',
      title: 'Balanced',
      startingPrice: 500,
      turnaroundDays: 2,
      turnaroundText: 'Ready in 2 days · ★ 4.6 average',
      isMostPicked: true,
      badge: 'MOST PICKED',
    ),
    ScheduleTier(
      id: 'PREMIUM',
      title: 'Premium',
      startingPrice: 800,
      turnaroundDays: 1,
      turnaroundText: 'Ready in 24 hours · ★ 4.9 average',
      isMostPicked: false,
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider =
          Provider.of<SchedulePickupProvider>(context, listen: false);
      final hasLoadedBefore = provider.hasTiersLoaded;
      provider.loadTiersAndNearbyStores(silent: hasLoadedBefore);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SchedulePickupProvider>(context);
    final selectedTier = provider.currentTier;
    final isInitialLoading =
        provider.isTiersLoading && !provider.hasTiersLoaded;

    // Use live tiers from provider or standard fallback
    final displayTiers =
        provider.tiers.isNotEmpty ? provider.tiers : fallbackTiers;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Color(0xFF212828), size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Pick a price level',
          style: GoogleFonts.dmSans(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF212828),
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isInitialLoading && !provider.hasStoresWithinMaxRadius) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFECACA)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.location_off_rounded,
                          color: Color(0xFFDC2626), size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'No partner stores found within ${provider.maxRadiusKm.toInt()} km of your location.',
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF991B1B),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Dynamic tier subtitle based on backend data
              if (isInitialLoading)
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: AppSkeletonLoader.box(
                    width: double.infinity,
                    height: 16,
                    borderRadius: 4,
                  ),
                )
              else
                Text(
                  provider.tierSubtitle,
                  style: GoogleFonts.dmSans(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF5E5E5E),
                    height: 1.4,
                  ),
                ),

              const SizedBox(height: 20),

              // Dynamic pricing tier cards with skeleton loader for initial load
              if (isInitialLoading) ...[
                AppSkeletonLoader.tierCard(),
                AppSkeletonLoader.tierCard(),
                AppSkeletonLoader.tierCard(),
              ] else
                ...displayTiers.map(
                  (tier) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _buildTierCard(
                      context: context,
                      tierId: tier.id,
                      title: tier.title,
                      priceText: 'from ₦${tier.startingPrice}',
                      metaText: tier.turnaroundText.contains('Foam Guarantee')
                          ? tier.turnaroundText
                          : tier.turnaroundText,
                      isSelected: provider.selectedTierId == tier.id,
                      badgeText: tier.badge,
                      onTap: () => provider.selectTier(tier.id),
                    ),
                  ),
                ),

              const SizedBox(height: 20),

              Center(
                child: Text(
                  "You'll see the store we matched you with before you pay.",
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF5E5E5E),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 12),

              // Continue button
              Container(
                width: double.infinity,
                height: 53,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00AABC), Color(0xFFC5EFF3)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    if (!provider.hasStoresWithinMaxRadius) {
                      StoreOutOfRangeDialog.showNoStoresNearby(
                        context,
                        maxRadiusKm: provider.maxRadiusKm,
                        address: provider.pickupAddress,
                      );
                      return;
                    }

                    final matched = selectedTier.matchedStore;
                    if (matched != null) {
                      final matchedStore = provider.nearbyStores.firstWhere(
                        (s) => s.id == matched.id.toString(),
                        orElse: () => NearbyStore(
                          id: matched.id.toString(),
                          name: matched.name,
                          area: '',
                          address: '',
                          rating: matched.rating,
                          distanceKm: matched.distanceKm,
                          turnaroundDays: matched.turnaroundDays,
                          turnaroundText:
                              'Ready in ${matched.turnaroundDays} days',
                          shirtStartingPrice: selectedTier.startingPrice,
                        ),
                      );
                      provider.selectStore(matchedStore);
                    }
                    if (provider.currentStore.id.isNotEmpty) {
                      provider.loadStoreCatalog(
                        storeId: provider.currentStore.id,
                        silent: true,
                      );
                    }
                    Navigator.pushNamed(context, CustomerStorePageScreen.id);
                  },
                  child: Text(
                    'Continue with ${selectedTier.title}',
                    style: GoogleFonts.dmSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
              ),
              if (!provider.hasStoresWithinMaxRadius) ...[
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF00AABC)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pushNamed(context, ServicesScreen.id);
                    },
                    icon: const Icon(Icons.cleaning_services_rounded,
                        color: Color(0xFF00AABC), size: 18),
                    label: Text(
                      'Explore All Services',
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF00AABC),
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTierCard({
    required BuildContext context,
    required String tierId,
    required String title,
    required String priceText,
    required String metaText,
    required bool isSelected,
    String? badgeText,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE5F7F8) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                isSelected ? const Color(0xFF00AABC) : const Color(0xFFE4E4E4),
            width: isSelected ? 1.4 : 0.8,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.dmSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF212828),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  priceText,
                  style: GoogleFonts.dmSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF212828),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              metaText,
              style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF5E5E5E),
              ),
            ),
            if (badgeText != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF00AABC),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badgeText,
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
