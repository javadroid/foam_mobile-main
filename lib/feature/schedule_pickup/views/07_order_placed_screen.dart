import 'package:flutter/material.dart';
import 'package:foam_mobile/core/Screens/history/history_screen.dart';
import 'package:foam_mobile/core/Screens/main_screen.dart';
import 'package:foam_mobile/feature/schedule_pickup/controller/schedule_pickup_provider.dart';
import 'package:foam_mobile/feature/schedule_pickup/views/08_pickup_leg_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class ScheduleOrderPlacedScreen extends StatelessWidget {
  static const String id = '/schedule_pickup/order_placed';

  const ScheduleOrderPlacedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SchedulePickupProvider>(context);
    final order = provider.lastCreatedOrder ?? {};
    final orderNumber = order['orderNumber'] as String? ?? (order['id'] != null ? 'FM-${order['id']}' : '');
    final storeName = order['storeName'] as String? ?? (provider.hasSelectedStore ? provider.currentStore.name : 'Store');
    final pickupPin = order['pickupPin'] as String? ?? '';
    final pickupTime = order['pickupTime'] as String? ?? provider.pickupSlot;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
            child: Column(
              children: [
                const SizedBox(height: 20),

                // Teal Checkmark Circle
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

                const SizedBox(height: 24),

                // Order placed title & description
                Text(
                  'Order placed',
                  style: GoogleFonts.dmSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF212828),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "$storeName has your order #$orderNumber. We'll send a rider for pickup $pickupTime.",
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF5E5E5E),
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 24),

                // Pickup PIN Card matching Figma Screen 07
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5F7F8),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Your pickup PIN',
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF5E5E5E),
                        ),
                      ),
                      const SizedBox(height: 8),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          pickupPin,
                          style: GoogleFonts.dmSans(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF001C1F),
                            letterSpacing: 8,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Give this to the rider when they collect your clothes.',
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF5E5E5E),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Track order button
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
                      final orderId = order['id']?.toString() ?? '';
                      if (orderId.isNotEmpty) {
                        provider.loadTrackingInfo(orderId);
                      }
                      Navigator.pushNamed(context, ScheduleTrackingScreen.id);
                    },
                    child: Text(
                      'Track order',
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

                // Order history navigation button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF00AABC), width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        HistoryScreen.id,
                        (route) => route.isFirst,
                      );
                    },
                    child: Text(
                      'View in Order History',
                      style: GoogleFonts.dmSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF00AABC),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Return to Home button
                TextButton(
                  onPressed: () {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      MainScreen.id,
                      (route) => false,
                    );
                  },
                  child: Text(
                    'Return to Home',
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF5E5E5E),
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
