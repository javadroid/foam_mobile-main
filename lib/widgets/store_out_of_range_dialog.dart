import 'package:flutter/material.dart';
import 'package:foam_mobile/core/Screens/home/services_screen/views/services_screen.dart';
import 'package:foam_mobile/core/Screens/profile/customer_address_screen.dart';
import 'package:foam_mobile/feature/schedule_pickup/models/customer_schedule_models.dart';
import 'package:google_fonts/google_fonts.dart';

class StoreOutOfRangeDialog extends StatelessWidget {
  final String title;
  final String message;
  final String? distanceBadgeText;
  final String primaryButtonText;
  final VoidCallback onPrimaryPressed;
  final String secondaryButtonText;
  final VoidCallback onSecondaryPressed;

  const StoreOutOfRangeDialog({
    super.key,
    required this.title,
    required this.message,
    this.distanceBadgeText,
    this.primaryButtonText = 'Explore All Services',
    required this.onPrimaryPressed,
    this.secondaryButtonText = 'Close',
    required this.onSecondaryPressed,
  });

  /// Show modal when no stores are found within maxRadiusKm
  static Future<void> showNoStoresNearby(
    BuildContext context, {
    required double maxRadiusKm,
    required String address,
    VoidCallback? onChangeAddress,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StoreOutOfRangeDialog(
        title: 'No Stores Within ${maxRadiusKm.toInt()} km',
        distanceBadgeText: '> ${maxRadiusKm.toInt()} km away',
        message:
            'We couldn\'t find any partner laundry stores within ${maxRadiusKm.toInt()} km of your location ($address). You can explore all our services or change your pickup address.',
        primaryButtonText: 'Explore All Services',
        onPrimaryPressed: () {
          Navigator.pop(ctx);
          Navigator.pushNamed(context, ServicesScreen.id);
        },
        secondaryButtonText: 'Change Address',
        onSecondaryPressed: () {
          Navigator.pop(ctx);
          if (onChangeAddress != null) {
            onChangeAddress();
          } else {
            Navigator.pushNamed(context, CustomerAddressScreen.id);
          }
        },
      ),
    );
  }

  /// Show modal when a user selects a store that is farther than maxRadiusKm
  static Future<void> showStoreTooFar(
    BuildContext context, {
    required NearbyStore store,
    required double maxRadiusKm,
    VoidCallback? onPickAnother,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StoreOutOfRangeDialog(
        title: 'Store is Too Far',
        distanceBadgeText: '${store.distanceKm.toStringAsFixed(1)} km away',
        message:
            '${store.name} is ${store.distanceKm.toStringAsFixed(1)} km away, which is very far and outside our ${maxRadiusKm.toInt()} km pickup zone. You can explore all our services or choose a closer store.',
        primaryButtonText: 'Explore All Services',
        onPrimaryPressed: () {
          Navigator.pop(ctx);
          Navigator.pushNamed(context, ServicesScreen.id);
        },
        secondaryButtonText: 'Choose Another Store',
        onSecondaryPressed: () {
          Navigator.pop(ctx);
          onPickAnother?.call();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Color(0x1F000000),
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Drag handle pill
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            // Warning Icon
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFFEE2E2), width: 2),
              ),
              child: const Center(
                child: Icon(
                  Icons.location_off_rounded,
                  color: Color(0xFFDC2626),
                  size: 32,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Distance badge if present
            if (distanceBadgeText != null && distanceBadgeText!.isNotEmpty) ...[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.near_me_disabled_outlined,
                      size: 14,
                      color: Color(0xFFD97706),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      distanceBadgeText!,
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFB45309),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Title
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 10),

            // Description message
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  height: 1.45,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF64748B),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Primary Button: Explore All Services
            Container(
              width: double.infinity,
              height: 52,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00AABC), Color(0xFF007E8C)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x3300AABC),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: onPrimaryPressed,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.cleaning_services_rounded,
                      color: Colors.white,
                      size: 19,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      primaryButtonText,
                      style: GoogleFonts.dmSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 17,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Secondary Button: Change Address or Pick Another
            SizedBox(
              width: double.infinity,
              height: 48,
              child: TextButton(
                style: TextButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                ),
                onPressed: onSecondaryPressed,
                child: Text(
                  secondaryButtonText,
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF475569),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
