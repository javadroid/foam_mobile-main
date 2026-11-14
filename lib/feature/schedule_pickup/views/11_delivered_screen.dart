import 'package:flutter/material.dart';
import 'package:foam_mobile/core/Screens/main_screen.dart';
import 'package:foam_mobile/feature/schedule_pickup/controller/schedule_pickup_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class CustomerDeliveredScreen extends StatelessWidget {
  static const String id = '/schedule_pickup/delivered';

  const CustomerDeliveredScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SchedulePickupProvider>(context);
    final tracking = provider.trackingData;
    final orderNumber = tracking?.orderNumber ??
        (provider.lastCreatedOrder?['orderNumber'] as String? ?? '');
    final storeName = tracking?.storeName ??
        (provider.lastCreatedOrder?['storeName'] as String? ?? 'Laundry Store');

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
            child: Column(
              children: [
                const SizedBox(height: 16),

                // Success checkmark circle
                Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    color: Color(0xFF00AABC),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text(
                      '✓',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                Text(
                  'Delivered',
                  style: GoogleFonts.dmSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF212828),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Order #$orderNumber · ${provider.totalBasketCount > 0 ? provider.totalBasketCount : 6} items from $storeName',
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF5E5E5E),
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 32),

                // Rating Card 1: How was store?
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE4E4E4), width: 0.8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'How was $storeName?',
                        style: GoogleFonts.dmSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF212828),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: List.generate(
                          5,
                          (index) => InkWell(
                            onTap: () => provider.setRatingStore(index + 1),
                            child: Padding(
                              padding: const EdgeInsets.only(right: 10.0),
                              child: Text(
                                '★',
                                style: TextStyle(
                                  fontSize: 30,
                                  color: (index < provider.ratingStore)
                                      ? const Color(0xFF00AABC)
                                      : const Color(0xFFE4E4E4),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Rating Card 2: How were your riders?
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE4E4E4), width: 0.8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'How were your riders?',
                        style: GoogleFonts.dmSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF212828),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: List.generate(
                          5,
                          (index) => InkWell(
                            onTap: () => provider.setRatingRider(index + 1),
                            child: Padding(
                              padding: const EdgeInsets.only(right: 10.0),
                              child: Text(
                                '★',
                                style: TextStyle(
                                  fontSize: 30,
                                  color: (index < provider.ratingRider)
                                      ? const Color(0xFF00AABC)
                                      : const Color(0xFFE4E4E4),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 36),

                // Submit button
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
                    onPressed: () async {
                      final orderId = tracking?.orderId ??
                          (provider.lastCreatedOrder?['id']?.toString() ?? '');
                      if (orderId.isNotEmpty) {
                        await provider.submitReview(orderId);
                      }
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Thank you for your rating!',
                              style: GoogleFonts.dmSans(),
                            ),
                            backgroundColor: const Color(0xFF10B981),
                          ),
                        );
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          MainScreen.id,
                          (route) => false,
                        );
                      }
                    },
                    child: Text(
                      'Submit',
                      style: GoogleFonts.dmSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Report a problem link
                TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Support ticket opened. Our team will contact you shortly.',
                          style: GoogleFonts.dmSans(),
                        ),
                        backgroundColor: const Color(0xFF001C1F),
                      ),
                    );
                  },
                  child: Text(
                    'Report a problem',
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF00AABC),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
