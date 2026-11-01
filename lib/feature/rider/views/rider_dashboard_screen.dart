import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:foam_mobile/feature/rider/widgets/rider_coverage_map_widget.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:foam_mobile/feature/rider/controller/rider_provider.dart';
import 'package:foam_mobile/feature/rider/models/rider_models.dart';
import 'package:foam_mobile/feature/rider/views/rider_active_ride_screen.dart';
import 'package:foam_mobile/feature/rider/views/rider_history_screen.dart';
import 'package:foam_mobile/feature/rider/views/rider_wallet_screen.dart';

class RiderDashboardScreen extends StatefulWidget {
  static const String id = '/rider/dashboard';
  const RiderDashboardScreen({super.key});

  @override
  State<RiderDashboardScreen> createState() => _RiderDashboardScreenState();
}

class _RiderDashboardScreenState extends State<RiderDashboardScreen> {
  final currencyFormatter = NumberFormat('#,###');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<RiderProvider>(context, listen: false);
      if (provider.isApproved) {
        provider.fetchAvailableRides();
        provider.fetchWallet();
      }
    });
  }

  Future<void> _handleAcceptRide(AvailableRide ride) async {
    final provider = Provider.of<RiderProvider>(context, listen: false);
    final success = await provider.acceptRide(ride);

    if (!mounted) return;

    if (success && provider.currentActiveRide != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RiderActiveRideScreen(ride: provider.currentActiveRide!),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Could not accept ride'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              rider?.name.isNotEmpty == true ? rider!.name : 'Rider Console',
              style: GoogleFonts.dmSans(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: const Color(0xFF212828),
              ),
            ),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: !isApproved
                        ? const Color(0xFFFFA000)
                        : (isOnline ? const Color(0xFF21CAAD) : Colors.grey),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  !isApproved
                      ? 'PENDING APPROVAL'
                      : (isOnline ? 'ONLINE & READY' : 'OFFLINE'),
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: !isApproved
                        ? const Color(0xFFFFA000)
                        : (isOnline ? const Color(0xFF21CAAD) : Colors.grey),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          if (isApproved)
            Row(
              children: [
                Text(
                  isOnline ? 'Go Offline' : 'Go Online',
                  style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                Switch(
                  value: isOnline,
                  activeThumbColor: const Color(0xFF00AABC),
                  onChanged: (val) => provider.toggleOnlineStatus(val),
                ),
              ],
            ),
          IconButton(
            icon: const Icon(Icons.account_balance_wallet_outlined, color: Color(0xFF00AABC)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RiderWalletScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.history, color: Color(0xFF212828)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RiderHistoryScreen()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: const Color(0xFF00AABC),
          onRefresh: () async {
            if (isApproved) {
              await provider.fetchAvailableRides();
              await provider.fetchWallet();
            }
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Pending Approval Banner
                if (!isApproved) ...[
                  _buildPendingApprovalBanner(),
                  const SizedBox(height: 20),
                ],

                // 2. Metrics Summary Row
                _buildMetricsRow(provider),
                const SizedBox(height: 16),

                // Coverage Zone & Radius Adjust Card
                _buildCoverageZoneCard(provider),
                const SizedBox(height: 24),

                // 3. Active Delivery Alert Banner (if ride active)
                if (provider.currentActiveRide != null) ...[
                  _buildActiveRideBanner(provider.currentActiveRide!),
                  const SizedBox(height: 20),
                ],

                // 4. Section Title & Broadcast Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Available Broadcast Rides',
                      style: GoogleFonts.dmSans(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF212828),
                      ),
                    ),
                    if (isApproved)
                      Text(
                        '${provider.availableRides.length} Live',
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF00AABC),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                // 5. Available Rides List or Gated / Empty State
                if (!isApproved)
                  _buildGatedState()
                else if (provider.availableRides.isEmpty)
                  _buildEmptyRidesState()
                else
                  ...provider.availableRides.map((ride) => _buildRideCard(ride, provider)),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPendingApprovalBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFD54F), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Color(0xFFFFA000), size: 24),
              const SizedBox(width: 8),
              Text(
                'Approval In Progress',
                style: GoogleFonts.dmSans(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: const Color(0xFFE65100),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Your rider profile is currently pending verification by Foam Operations. Live customer dispatch alerts will appear automatically as soon as your registration is approved.',
            style: GoogleFonts.dmSans(fontSize: 13, color: const Color(0xFF5D4037)),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsRow(RiderProvider provider) {
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            title: 'Wallet Balance',
            value: '₦${currencyFormatter.format(provider.walletBalance)}',
            icon: Icons.account_balance_wallet,
            color: const Color(0xFF00AABC),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricCard(
            title: 'Completed',
            value: '${provider.currentRider?.totalRides ?? provider.history.length}',
            icon: Icons.check_circle_outline,
            color: const Color(0xFF21CAAD),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricCard(
            title: 'Rider Rating',
            value: '★ ${provider.currentRider?.rating ?? 5.0}',
            icon: Icons.star_border,
            color: const Color(0xFFFFA000),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.dmSans(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF212828),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: GoogleFonts.dmSans(
              fontSize: 11,
              color: Colors.black54,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveRideBanner(ActiveRide ride) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF00AABC).withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF00AABC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.directions_bike, color: Color(0xFF00AABC)),
                  const SizedBox(width: 8),
                  Text(
                    'Active Delivery (${ride.orderNumber})',
                    style: GoogleFonts.dmSans(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: const Color(0xFF00AABC),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF00AABC),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  ride.stage.replaceAll('_', ' '),
                  style: GoogleFonts.dmSans(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Deliver from ${ride.storeName} to ${ride.deliveryAddress}',
            style: GoogleFonts.dmSans(fontSize: 13, color: const Color(0xFF212828)),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00AABC),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => RiderActiveRideScreen(ride: ride)),
                );
              },
              child: Text(
                'Open Delivery Progress Tracker',
                style: GoogleFonts.dmSans(fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRideCard(AvailableRide ride, RiderProvider provider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
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
              Text(
                ride.orderNumber,
                style: GoogleFonts.dmSans(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: const Color(0xFF212828),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE5F7F8),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '₦${currencyFormatter.format(ride.earnings)} Payout',
                  style: GoogleFonts.dmSans(
                    color: const Color(0xFF00AABC),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.storefront_outlined, size: 18, color: Color(0xFF00AABC)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ride.storeName,
                      style: GoogleFonts.dmSans(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    Text(
                      ride.pickupAddress,
                      style: GoogleFonts.dmSans(color: Colors.black54, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on_outlined, size: 18, color: Colors.redAccent),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Customer: ${ride.customerName}',
                      style: GoogleFonts.dmSans(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    Text(
                      ride.deliveryAddress,
                      style: GoogleFonts.dmSans(color: Colors.black54, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.route_outlined, size: 16, color: Colors.black54),
                  const SizedBox(width: 4),
                  Text(
                    '${ride.distanceKm} km trip',
                    style: GoogleFonts.dmSans(fontSize: 12, color: Colors.black54),
                  ),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00AABC),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: provider.isLoading ? null : () => _handleAcceptRide(ride),
                icon: const Icon(Icons.flash_on, size: 16, color: Colors.white),
                label: Text(
                  'Accept Ride',
                  style: GoogleFonts.dmSans(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGatedState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
      ),
      child: Column(
        children: [
          const Icon(Icons.lock_clock_outlined, size: 48, color: Color(0xFFFFA000)),
          const SizedBox(height: 12),
          Text(
            'Order Broadcast Locked',
            style: GoogleFonts.dmSans(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF212828),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Live customer dispatch notifications are locked until your rider account is verified and approved by admin.',
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(fontSize: 13, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyRidesState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
      ),
      child: Column(
        children: [
          const Icon(Icons.motorcycle, size: 48, color: Colors.black26),
          const SizedBox(height: 12),
          Text(
            'No Rides Currently Available',
            style: GoogleFonts.dmSans(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF212828),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'New customer pickups within your coverage zone will broadcast here automatically.',
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(fontSize: 13, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _buildCoverageZoneCard(RiderProvider provider) {
    final rider = provider.currentRider;
    final lat = rider?.coverageLatitude ?? 4.8633;
    final lng = rider?.coverageLongitude ?? 7.0292;
    final radius = rider?.coverageRadiusKm ?? 10.0;
    final areaSqKm = (3.14159 * radius * radius).toStringAsFixed(0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
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
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0F7FA),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.radar_rounded, color: Color(0xFF00AABC), size: 20),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Delivery Coverage Zone',
                        style: GoogleFonts.dmSans(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: const Color(0xFF212828),
                        ),
                      ),
                      Text(
                        '${radius.toStringAsFixed(1)} km radius (~$areaSqKm km²)',
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          color: const Color(0xFF00AABC),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF00AABC)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () => _showAdjustCoverageModal(provider),
                icon: const Icon(Icons.tune_rounded, size: 16, color: Color(0xFF00AABC)),
                label: Text(
                  'Adjust',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF00AABC),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF6B7280)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Center: ${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)} · Orders broadcast within this radius',
                    style: GoogleFonts.dmSans(fontSize: 11, color: const Color(0xFF6B7280)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAdjustCoverageModal(RiderProvider provider) {
    final rider = provider.currentRider;
    double tempLat = rider?.coverageLatitude ?? 4.8633;
    double tempLng = rider?.coverageLongitude ?? 7.0292;
    double tempRadius = rider?.coverageRadiusKm ?? 10.0;
    String tempRoute = rider?.coverageRoute ?? 'Custom Zone';
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.82,
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Adjust Coverage Zone',
                    style: GoogleFonts.dmSans(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF212828),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(modalCtx),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Expanded(
                child: SingleChildScrollView(
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
                            SnackBar(
                              content: Text(
                                'Coverage updated to ${tempRadius.toStringAsFixed(1)} km radius',
                                style: GoogleFonts.dmSans(),
                              ),
                              backgroundColor: const Color(0xFF00AABC),
                            ),
                          );
                        },
                  child: isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          'Save Coverage Area',
                          style: GoogleFonts.dmSans(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
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
}
