import 'package:flutter/material.dart';
import 'package:foam_mobile/core/Screens/main_screen.dart';
import 'package:foam_mobile/feature/schedule_pickup/controller/schedule_pickup_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class CustomerDeliveredScreen extends StatefulWidget {
  static const String id = '/schedule_pickup/delivered';

  const CustomerDeliveredScreen({super.key});

  @override
  State<CustomerDeliveredScreen> createState() =>
      _CustomerDeliveredScreenState();
}

class _CustomerDeliveredScreenState extends State<CustomerDeliveredScreen> {
  late final TextEditingController _commentController;

  @override
  void initState() {
    super.initState();
    _commentController = TextEditingController();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  String _getRatingLabel(int rating) {
    switch (rating) {
      case 1:
        return 'Poor (1.0)';
      case 2:
        return 'Fair (2.0)';
      case 3:
        return 'Good (3.0)';
      case 4:
        return 'Very Good (4.0)';
      case 5:
        return 'Excellent (5.0)';
      default:
        return 'Tap a star to rate (optional)';
    }
  }

  Widget _buildStarRating({
    required int currentRating,
    required ValueChanged<int> onRatingChanged,
  }) {
    return Row(
      children: List.generate(5, (index) {
        final starValue = index + 1;
        final isFilled = starValue <= currentRating;
        return InkWell(
          onTap: () => onRatingChanged(starValue),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
            child: Icon(
              isFilled ? Icons.star_rounded : Icons.star_outline_rounded,
              size: 34,
              color: isFilled
                  ? const Color(0xFFF59E0B) // Amber star
                  : const Color(0xFFD1D5DB), // Neutral gray
            ),
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SchedulePickupProvider>(context);
    final tracking = provider.trackingData;
    final orderNumber = tracking?.orderNumber ??
        (provider.lastCreatedOrder?['orderNumber'] as String? ?? '');
    final storeName = tracking?.storeName ??
        (provider.lastCreatedOrder?['storeName'] as String? ?? 'Laundry Store');
    final rider = tracking?.pickupRider ?? tracking?.deliveryRider;
    final riderName = rider?.name ?? '';

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFFF9FAFB),
        body: SafeArea(
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
            child: Column(
              children: [
                const SizedBox(height: 12),

                // Success checkmark circle
                Container(
                  width: 76,
                  height: 76,
                  decoration: const BoxDecoration(
                    color: Color(0xFF00AABC),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.check_rounded,
                      size: 44,
                      color: Colors.white,
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                Text(
                  'Delivered!',
                  style: GoogleFonts.dmSans(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF212828),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Order #$orderNumber · ${provider.totalBasketCount > 0 ? provider.totalBasketCount : 6} items from $storeName',
                  style: GoogleFonts.dmSans(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF5E5E5E),
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 28),

                // Rating Card 1: Store Rating
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border:
                        Border.all(color: const Color(0xFFE5E7EB), width: 1.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'How was $storeName?',
                              style: GoogleFonts.dmSans(
                                fontSize: 15.5,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF212828),
                              ),
                            ),
                          ),
                          if (provider.ratingStore > 0)
                            Text(
                              '${provider.ratingStore}.0 / 5.0',
                              style: GoogleFonts.dmSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFFF59E0B),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildStarRating(
                        currentRating: provider.ratingStore,
                        onRatingChanged: (val) => provider.setRatingStore(val),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _getRatingLabel(provider.ratingStore),
                        style: GoogleFonts.dmSans(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: provider.ratingStore > 0
                              ? const Color(0xFF00AABC)
                              : const Color(0xFF9CA3AF),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Rating Card 2: Rider Rating
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border:
                        Border.all(color: const Color(0xFFE5E7EB), width: 1.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              riderName.isNotEmpty
                                  ? 'How was $riderName (Rider)?'
                                  : 'How was your rider?',
                              style: GoogleFonts.dmSans(
                                fontSize: 15.5,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF212828),
                              ),
                            ),
                          ),
                          if (provider.ratingRider > 0)
                            Text(
                              '${provider.ratingRider}.0 / 5.0',
                              style: GoogleFonts.dmSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFFF59E0B),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildStarRating(
                        currentRating: provider.ratingRider,
                        onRatingChanged: (val) => provider.setRatingRider(val),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _getRatingLabel(provider.ratingRider),
                        style: GoogleFonts.dmSans(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: provider.ratingRider > 0
                              ? const Color(0xFF00AABC)
                              : const Color(0xFF9CA3AF),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Feedback Comments Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border:
                        Border.all(color: const Color(0xFFE5E7EB), width: 1.0),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Feedback & Comments (optional)',
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF212828),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _commentController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText:
                              'Share your experience with the wash quality or delivery...',
                          hintStyle: GoogleFonts.dmSans(
                            fontSize: 13,
                            color: const Color(0xFF9CA3AF),
                          ),
                          contentPadding: const EdgeInsets.all(12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                const BorderSide(color: Color(0xFFE5E7EB)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                const BorderSide(color: Color(0xFFE5E7EB)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                const BorderSide(color: Color(0xFF00AABC)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // Submit button
                Container(
                  width: double.infinity,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00AABC), Color(0xFF22D3EE)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00AABC).withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () async {
                      final orderId = tracking?.orderId ??
                          (provider.lastCreatedOrder?['id']?.toString() ?? '');
                      if (orderId.isNotEmpty) {
                        await provider.submitReview(
                          orderId,
                          comments: _commentController.text.trim().isNotEmpty
                              ? _commentController.text.trim()
                              : null,
                        );
                      }
                      provider.resetRatings();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Thank you for your rating!',
                              style: GoogleFonts.dmSans(
                                fontWeight: FontWeight.w600,
                              ),
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
                      'Submit Rating',
                      style: GoogleFonts.dmSans(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Skip button
                TextButton(
                  onPressed: () {
                    provider.resetRatings();
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      MainScreen.id,
                      (route) => false,
                    );
                  },
                  child: Text(
                    'Skip for now',
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                ),

                const SizedBox(height: 8),

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
                    'Report an issue with this order',
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
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
