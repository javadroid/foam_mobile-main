import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/material.dart';
import 'package:foam_mobile/feature/rider/controller/rider_provider.dart';
import 'package:foam_mobile/feature/rider/models/rider_models.dart';
import 'package:foam_mobile/feature/rider/views/rider_wallet_screen.dart';
import 'package:foam_mobile/feature/rider/widgets/rider_coverage_map_widget.dart';
import 'package:foam_mobile/feature/schedule_pickup/models/rate_model.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class RiderProfileScreen extends StatefulWidget {
  static const String id = '/rider/profile';

  const RiderProfileScreen({super.key});

  @override
  State<RiderProfileScreen> createState() => _RiderProfileScreenState();
}

class _RiderProfileScreenState extends State<RiderProfileScreen> {
  final currencyFormatter = NumberFormat('#,###');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<RiderProvider>(context, listen: false);
      provider.fetchRiderProfile();
      provider.fetchRiderReviews();
    });
  }

  void _showImageDialog(BuildContext context, String imageUrl, String title) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.dmSans(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: const Color(0xFF212828),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Container(
                        height: 200,
                        color: const Color(0xFFF3F4F6),
                        child: const Center(
                          child: Icon(Icons.broken_image,
                              size: 48, color: Colors.grey),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openCoverageModal(
      BuildContext context, RiderProfile rider, RiderProvider provider) {
    double tempLat = rider.coverageLatitude ?? 4.8633;
    double tempLng = rider.coverageLongitude ?? 7.0292;
    double tempRadius = rider.coverageRadiusKm;
    String tempRoute = rider.coverageRoute ?? '';
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Adjust Coverage Zone',
                    style: GoogleFonts.dmSans(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(modalCtx),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  height: 280,
                  child: RiderCoverageMapWidget(
                    initialCenter: LatLng(tempLat, tempLng),
                    initialRadiusKm: tempRadius,
                    height: 280,
                    showHeader: true,
                    onCoverageChanged: ({
                      required double latitude,
                      required double longitude,
                      required double radiusKm,
                      required String routeDescription,
                    }) {
                      tempLat = latitude;
                      tempLng = longitude;
                      tempRadius = radiusKm;
                      tempRoute = routeDescription;
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00AABC),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: isSaving
                      ? null
                      : () async {
                          setModalState(() => isSaving = true);
                          await provider.updateCoverage(
                            latitude: tempLat,
                            longitude: tempLng,
                            radiusKm: tempRadius,
                            routeDescription: tempRoute,
                          );
                          if (!mounted) return;
                          Navigator.pop(modalCtx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content:
                                  Text('Coverage zone updated successfully!'),
                              backgroundColor: Color(0xFF10B981),
                            ),
                          );
                        },
                  child: isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          'Save Coverage Zone',
                          style: GoogleFonts.dmSans(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<RiderProvider>(context);
    final rider = provider.currentRider;
    final isApproved = provider.isApproved;
    final isOnline = provider.isOnline;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF212828), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Rider Profile',
          style: GoogleFonts.dmSans(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: const Color(0xFF212828),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF00AABC)),
            onPressed: () async {
              await provider.fetchRiderProfile();
              await provider.fetchRiderReviews();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Profile refreshed'),
                    duration: Duration(seconds: 1),
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: rider == null
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF00AABC)),
            )
          : RefreshIndicator(
              color: const Color(0xFF00AABC),
              onRefresh: () async {
                await provider.fetchRiderProfile();
                await provider.fetchRiderReviews();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Header Card (Avatar, Name, Badges)
                    _buildHeaderCard(rider, isApproved, isOnline),
                    const SizedBox(height: 16),

                    // 2. Account Details Card
                    _buildSectionCard(
                      title: 'Account Information',
                      icon: Icons.person_outline_rounded,
                      children: [
                        _buildInfoRow('Full Name', rider.name),
                        _buildInfoRow('Phone', rider.phone),
                        if (rider.email != null)
                          _buildInfoRow('Email', rider.email!),
                        _buildInfoRow('Rider ID', rider.id),
                        _buildInfoRow(
                          'Verification',
                          rider.approvalStatus.toUpperCase(),
                          valueColor: isApproved
                              ? const Color(0xFF10B981)
                              : const Color(0xFFFFA000),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // 3. Vehicle & Documents Card
                    _buildSectionCard(
                      title: 'Vehicle & Documents',
                      icon: Icons.two_wheeler_rounded,
                      children: [
                        _buildInfoRow('Vehicle Type', rider.vehicleType),
                        if (rider.vehiclePlate != null &&
                            rider.vehiclePlate!.isNotEmpty)
                          _buildInfoRow('Plate Number', rider.vehiclePlate!),
                        if (rider.licenseNumber != null &&
                            rider.licenseNumber!.isNotEmpty)
                          _buildInfoRow(
                              'Driver\'s License No.', rider.licenseNumber!),
                        const SizedBox(height: 8),

                        // Document preview thumbnails
                        Row(
                          children: [
                            if (rider.driverLicenseUrl != null &&
                                rider.driverLicenseUrl!.isNotEmpty)
                              Expanded(
                                child: InkWell(
                                  onTap: () => _showImageDialog(
                                      context,
                                      rider.driverLicenseUrl!,
                                      'Driver\'s License'),
                                  borderRadius: BorderRadius.circular(10),
                                  child: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF3F4F6),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                          color: const Color(0xFFE5E7EB)),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                            Icons.credit_card_outlined,
                                            size: 22,
                                            color: Color(0xFF00AABC)),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Driver\'s License',
                                            style: GoogleFonts.dmSans(
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w600,
                                              color: const Color(0xFF212828),
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const Icon(
                                            Icons.visibility_outlined,
                                            size: 16,
                                            color: Colors.grey),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            if (rider.profileImageUrl != null &&
                                rider.profileImageUrl!.isNotEmpty) ...[
                              const SizedBox(width: 10),
                              Expanded(
                                child: InkWell(
                                  onTap: () => _showImageDialog(
                                      context,
                                      rider.profileImageUrl!,
                                      'Profile Photo'),
                                  borderRadius: BorderRadius.circular(10),
                                  child: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF3F4F6),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                          color: const Color(0xFFE5E7EB)),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                            Icons.photo_camera_outlined,
                                            size: 22,
                                            color: Color(0xFF00AABC)),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Profile Photo',
                                            style: GoogleFonts.dmSans(
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w600,
                                              color: const Color(0xFF212828),
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const Icon(
                                            Icons.visibility_outlined,
                                            size: 16,
                                            color: Colors.grey),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // 4. Operations & Coverage Card
                    _buildSectionCard(
                      title: 'Coverage Zone',
                      icon: Icons.radar_rounded,
                      action: TextButton(
                        onPressed: () =>
                            _openCoverageModal(context, rider, provider),
                        child: Text(
                          'Adjust',
                          style: GoogleFonts.dmSans(
                            color: const Color(0xFF00AABC),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      children: [
                        _buildInfoRow('Operating Radius',
                            '${rider.coverageRadiusKm.toStringAsFixed(1)} km'),
                        _buildInfoRow('Total Completed Rides',
                            '${rider.totalRides} deliveries'),
                        _buildInfoRow(
                          'Wallet Balance',
                          '₦${currencyFormatter.format(rider.walletBalance)}',
                          valueColor: const Color(0xFF00AABC),
                        ),
                        const SizedBox(height: 6),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const RiderWalletScreen()),
                              );
                            },
                            icon: const Icon(
                                Icons.account_balance_wallet_outlined,
                                size: 18),
                            label: const Text('Open Wallet & Withdrawals'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF00AABC),
                              side: const BorderSide(color: Color(0xFF00AABC)),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // 5. Customer Ratings & Reviews Card
                    _buildReviewsCard(provider),
                    const SizedBox(height: 24),

                    // 6. Sign Out Button
                    SizedBox(
                      width: double.infinity,
                      child: TextButton.icon(
                        onPressed: () => _confirmSignOut(context),
                        icon: const Icon(Icons.logout_rounded,
                            color: Color(0xFFEF4444), size: 18),
                        label: Text(
                          'Sign Out',
                          style: GoogleFonts.dmSans(
                            color: const Color(0xFFEF4444),
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeaderCard(
      RiderProfile rider, bool isApproved, bool isOnline) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Avatar circle
          Stack(
            children: [
              CircleAvatar(
                radius: 42,
                backgroundColor: const Color(0xFFE0F2FE),
                backgroundImage: (rider.profileImageUrl != null &&
                        rider.profileImageUrl!.isNotEmpty)
                    ? NetworkImage(rider.profileImageUrl!)
                    : null,
                child: (rider.profileImageUrl == null ||
                        rider.profileImageUrl!.isEmpty)
                    ? Text(
                        rider.name.isNotEmpty
                            ? rider.name[0].toUpperCase()
                            : 'R',
                        style: GoogleFonts.dmSans(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF00AABC),
                        ),
                      )
                    : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: isOnline
                        ? const Color(0xFF10B981)
                        : const Color(0xFF9CA3AF),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2.5),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Text(
            rider.name,
            style: GoogleFonts.dmSans(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF212828),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            rider.phone,
            style: GoogleFonts.dmSans(
              fontSize: 13,
              color: const Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 12),

          // Badges Row
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              // Approval badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isApproved
                      ? const Color(0xFFECFDF5)
                      : const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isApproved
                        ? const Color(0xFF6EE7B7)
                        : const Color(0xFFFDE68A),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isApproved
                          ? Icons.verified_rounded
                          : Icons.hourglass_top_rounded,
                      size: 14,
                      color: isApproved
                          ? const Color(0xFF059669)
                          : const Color(0xFFD97706),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isApproved ? 'Verified Partner' : 'Pending Approval',
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isApproved
                          ? const Color(0xFF059669)
                          : const Color(0xFFD97706),
                      ),
                    ),
                  ],
                ),
              ),

              // Rating pill (No dummy 5 star!)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_rounded,
                        size: 14, color: Color(0xFFF59E0B)),
                    const SizedBox(width: 3),
                    Text(
                      rider.isNew
                          ? 'New Rider'
                          : '★ ${rider.rating.toStringAsFixed(1)} (${rider.ratingCount})',
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFB45309),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    Widget? action,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, color: const Color(0xFF00AABC), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: GoogleFonts.dmSans(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF212828),
                    ),
                  ),
                ],
              ),
              if (action != null) action,
            ],
          ),
          const Divider(height: 20, color: Color(0xFFF3F4F6)),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 13,
              color: const Color(0xFF6B7280),
              fontWeight: FontWeight.w500,
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: valueColor ?? const Color(0xFF1F2937),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsCard(RiderProvider provider) {
    final summary = provider.ratingSummary;
    final reviews = provider.reviews;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.star_rate_rounded,
                  color: Color(0xFFF59E0B), size: 20),
              const SizedBox(width: 8),
              Text(
                'Customer Ratings & Reviews',
                style: GoogleFonts.dmSans(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF212828),
                ),
              ),
            ],
          ),
          const Divider(height: 20, color: Color(0xFFF3F4F6)),

          if (summary.isNew && reviews.isEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: Center(
                child: Column(
                  children: [
                    const Icon(Icons.rate_review_outlined,
                        size: 36, color: Color(0xFF9CA3AF)),
                    const SizedBox(height: 8),
                    Text(
                      'No reviews yet',
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF4B5563),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Complete scheduled customer pickups to earn real 5-star ratings!',
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: const Color(0xFF9CA3AF),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            // Rating score headline
            Row(
              children: [
                Text(
                  summary.averageRating.toStringAsFixed(1),
                  style: GoogleFonts.dmSans(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF212828),
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: List.generate(
                        5,
                        (i) => Icon(
                          (i < summary.averageRating.round())
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          size: 16,
                          color: const Color(0xFFF59E0B),
                        ),
                      ),
                    ),
                    Text(
                      'Based on ${summary.ratingCount} customer rating${summary.ratingCount == 1 ? '' : 's'}',
                      style: GoogleFonts.dmSans(
                        fontSize: 11.5,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Review comments
            ...reviews.take(5).map((r) => Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            r.customerName ?? 'Verified Customer',
                            style: GoogleFonts.dmSans(
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF212828),
                            ),
                          ),
                          Row(
                            children: [
                              const Icon(Icons.star_rounded,
                                  size: 14, color: Color(0xFFF59E0B)),
                              Text(
                                '${r.rating.toStringAsFixed(1)}',
                                style: GoogleFonts.dmSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      if (r.comment != null && r.comment!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          r.comment!,
                          style: GoogleFonts.dmSans(
                            fontSize: 12,
                            color: const Color(0xFF4B5563),
                          ),
                        ),
                      ],
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }

  void _confirmSignOut(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(
          'Sign Out',
          style: GoogleFonts.dmSans(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to sign out of your rider account?',
          style: GoogleFonts.dmSans(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.dmSans()),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/log_in',
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
            ),
            child: Text('Sign Out', style: GoogleFonts.dmSans()),
          ),
        ],
      ),
    );
  }
}
