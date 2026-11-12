import 'package:flutter/material.dart';
import 'package:foam_mobile/feature/schedule_pickup/controller/schedule_pickup_provider.dart';
import 'package:foam_mobile/feature/schedule_pickup/models/customer_schedule_models.dart';
import 'package:foam_mobile/feature/schedule_pickup/views/05_items_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class ScheduleTiersScreen extends StatelessWidget {
  static const String id = '/schedule_pickup/tiers';

  const ScheduleTiersScreen({super.key});

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
  Widget build(BuildContext context) {
    final provider = Provider.of<SchedulePickupProvider>(context);
    final selectedTier = provider.currentTier;

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
              // Dynamic tier subtitle based on backend data
              Text(
                provider?.tierSubtitle ?? "",
                style: GoogleFonts.dmSans(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF5E5E5E),
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 20),

              // Dynamic pricing tier cards with Foam turnaround guarantee
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
                        : '${tier.turnaroundText}',
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
                    Navigator.pushNamed(context, ScheduleItemsScreen.id);
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
