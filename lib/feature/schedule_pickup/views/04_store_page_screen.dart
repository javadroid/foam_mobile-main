import 'package:flutter/material.dart';
import 'package:foam_mobile/feature/schedule_pickup/controller/schedule_pickup_provider.dart';
import 'package:foam_mobile/feature/schedule_pickup/views/05_items_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class CustomerStorePageScreen extends StatefulWidget {
  static const String id = '/schedule_pickup/store_page';

  const CustomerStorePageScreen({super.key});

  @override
  State<CustomerStorePageScreen> createState() => _CustomerStorePageScreenState();
}

class _CustomerStorePageScreenState extends State<CustomerStorePageScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider =
          Provider.of<SchedulePickupProvider>(context, listen: false);
      final storeId = provider.currentStore.id;
      if (storeId.isNotEmpty) {
        provider.loadStoreCatalog(storeId: storeId, silent: true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SchedulePickupProvider>(context);
    final store = provider.currentStore;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dark Header section matching Figma
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(left: 16, right: 16, top: 48, bottom: 24),
              decoration: const BoxDecoration(
                color: Color(0xFF001C1F),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    store.name,
                    style: GoogleFonts.dmSans(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${store.address} · ${store.distanceKm} km',
                    style: GoogleFonts.dmSans(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w400,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 3 Stats columns
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatColumn(
                          '★ ${store.rating.toStringAsFixed(1)}',
                          '${store.reviewCount} reviews',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatColumn(
                          store.turnaroundText.replaceAll('Ready in ', ''),
                          'Turnaround',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatColumn(
                          store.operatingHours,
                          'Open today',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Services Body with Turnaround Speed selector
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Turnaround Speed',
                    style: GoogleFonts.dmSans(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF212828),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: store.effectiveTurnaroundOptions.map((opt) {
                      final isSelected =
                          provider.selectedTurnaroundDays == opt.days;
                      return ChoiceChip(
                        label: Text(
                          '${opt.days} ${opt.days == 1 ? "Day" : "Days"} (${opt.name}) · ₦${opt.shirtStartingPrice}',
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isSelected
                                ? Colors.white
                                : const Color(0xFF212828),
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: const Color(0xFF00AABC),
                        backgroundColor: const Color(0xFFF0F3F3),
                        checkmarkColor: Colors.white,
                        onSelected: (_) =>
                            provider.selectTurnaroundDays(opt.days),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  Text(
                    'Services',
                    style: GoogleFonts.dmSans(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF212828),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Service 1: Laundry
                  _buildServiceCard(
                    title: 'Laundry',
                    subtitle:
                        'Folding or non-folding · from ₦${store.effectiveTurnaroundOptions.firstWhere((o) => o.days == provider.selectedTurnaroundDays, orElse: () => store.effectiveTurnaroundOptions.first).shirtStartingPrice}',
                    icon: Icons.local_laundry_service_outlined,
                    onTap: () {
                      provider.selectService('Laundry');
                      Navigator.pushNamed(context, ScheduleItemsScreen.id);
                    },
                  ),

                  const SizedBox(height: 14),

                  // Service 2: Dry cleaning
                  _buildServiceCard(
                    title: 'Dry cleaning',
                    subtitle: 'Suits, dresses, native wear · from ₦1,500',
                    icon: Icons.dry_cleaning_outlined,
                    onTap: () {
                      provider.selectService('Dry cleaning');
                      Navigator.pushNamed(context, ScheduleItemsScreen.id);
                    },
                  ),

                  const SizedBox(height: 28),

                  // Button: Order from this store
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
                        provider.selectService('Laundry');
                        Navigator.pushNamed(context, ScheduleItemsScreen.id);
                      },
                      child: Text(
                        'Order from this store',
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
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.dmSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.dmSans(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildServiceCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE4E4E4), width: 0.8),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFFE5F7F8),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: const Color(0xFF00AABC), size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.dmSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF212828),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF5E5E5E),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Color(0xFF212828)),
          ],
        ),
      ),
    );
  }
}
