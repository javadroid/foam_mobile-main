import 'package:flutter/material.dart';
import 'package:foam_mobile/feature/schedule_pickup/controller/schedule_pickup_provider.dart';
import 'package:foam_mobile/feature/schedule_pickup/views/10_delivery_leg_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class CustomerAtStoreScreen extends StatelessWidget {
  static const String id = '/schedule_pickup/at_store';

  const CustomerAtStoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SchedulePickupProvider>(context);
    final tracking = provider.trackingData;
    final orderNumber = tracking?.orderNumber ?? '';
    final storeName = tracking?.storeName ?? 'Laundry Store';
    final readyEta = tracking?.readyEta ?? 'Processing at store';

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
          'Order #$orderNumber',
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
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Dark Teal Store Banner matching Figma Screen 09
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFF001C1F),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      storeName,
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Your clothes are being washed',
                      style: GoogleFonts.dmSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      readyEta,
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Detailed Timeline Vertical Stepper matching Figma Screen 09
              _buildSectionHeader('PICKUP'),
              const SizedBox(height: 8),
              _buildTimelineStep(
                title: tracking?.pickupRider?.name != null
                    ? 'Picked up by ${tracking!.pickupRider!.name}'
                    : 'Picked up by rider',
                subtitle: '',
                isCompleted: true,
                showBottomLine: true,
              ),
              _buildTimelineStep(
                title: 'Dropped at $storeName',
                subtitle: '',
                isCompleted: true,
                showBottomLine: true,
              ),

              const SizedBox(height: 12),
              _buildSectionHeader('AT THE STORE'),
              const SizedBox(height: 8),
              _buildTimelineStep(
                title: 'Washing',
                subtitle: readyEta,
                isActive: true,
                showBottomLine: true,
              ),
              _buildTimelineStep(
                title: 'Ready',
                subtitle: null,
                isPending: true,
                showBottomLine: true,
              ),

              const SizedBox(height: 12),
              _buildSectionHeader('DELIVERY'),
              const SizedBox(height: 8),
              _buildTimelineStep(
                title: 'Out for delivery',
                subtitle: null,
                isPending: true,
                showBottomLine: true,
              ),
              _buildTimelineStep(
                title: 'Delivered',
                subtitle: null,
                isPending: true,
                showBottomLine: false,
              ),

              const SizedBox(height: 36),

              // Button to proceed to Delivery leg simulation
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
                    Navigator.pushNamed(context, CustomerDeliveryLegScreen.id);
                  },
                  child: Text(
                    'Track Delivery Leg',
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 36.0, bottom: 4.0),
      child: Text(
        title,
        style: GoogleFonts.dmSans(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF5E5E5E),
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildTimelineStep({
    required String title,
    String? subtitle,
    bool isCompleted = false,
    bool isActive = false,
    bool isPending = false,
    required bool showBottomLine,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left timeline node & line
        Column(
          children: [
            if (isCompleted)
              Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(
                  color: Color(0xFF00AABC),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text(
                    '✓',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              )
            else if (isActive)
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF00AABC), width: 5),
                ),
              )
            else
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFE4E4E4), width: 2),
                ),
              ),
            if (showBottomLine)
              Container(
                width: 2,
                height: subtitle != null ? 36 : 28,
                color: isCompleted ? const Color(0xFF00AABC) : const Color(0xFFE4E4E4),
              ),
          ],
        ),

        const SizedBox(width: 14),

        // Text Content
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 1.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.dmSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isPending ? const Color(0xFF8B8484) : const Color(0xFF212828),
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF5E5E5E),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
