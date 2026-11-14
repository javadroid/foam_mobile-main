import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:foam_mobile/feature/rider/controller/rider_provider.dart';
import 'package:foam_mobile/feature/rider/models/rider_models.dart';

class RiderActiveRideScreen extends StatefulWidget {
  static const String id = '/rider/active-ride';
  final ActiveRide ride;

  const RiderActiveRideScreen({super.key, required this.ride});

  @override
  State<RiderActiveRideScreen> createState() => _RiderActiveRideScreenState();
}

class _RiderActiveRideScreenState extends State<RiderActiveRideScreen> {
  final currencyFormatter = NumberFormat('#,###');
  final _pinController = TextEditingController();
  GoogleMapController? _mapController;
  String? _lastRenderedStage;

  @override
  void dispose() {
    _pinController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  void _fitRouteBounds(LatLng p1, LatLng p2) {
    if (_mapController == null) return;
    final south = math.min(p1.latitude, p2.latitude);
    final north = math.max(p1.latitude, p2.latitude);
    final west = math.min(p1.longitude, p2.longitude);
    final east = math.max(p1.longitude, p2.longitude);

    final bounds = LatLngBounds(
      southwest: LatLng(south, west),
      northeast: LatLng(north, east),
    );

    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted && _mapController != null) {
        if ((north - south).abs() < 0.0005 && (east - west).abs() < 0.0005) {
          _mapController!
              .animateCamera(CameraUpdate.newLatLngZoom(p1, 15.0))
              .catchError((_) {});
        } else {
          _mapController!
              .animateCamera(CameraUpdate.newLatLngBounds(bounds, 50))
              .catchError((_) {});
        }
      }
    });
  }

  double _calculateDistanceKm(LatLng p1, LatLng p2) {
    const earthRadius = 6371.0; // km
    final dLat = (p2.latitude - p1.latitude) * (math.pi / 180.0);
    final dLon = (p2.longitude - p1.longitude) * (math.pi / 180.0);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(p1.latitude * (math.pi / 180.0)) *
            math.cos(p2.latitude * (math.pi / 180.0)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  void _promptPinModal({
    required String title,
    required String description,
    required Function(String) onPinConfirmed,
  }) {
    _pinController.clear(); // Always blank; rider must ask customer in person
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.pin, color: Color(0xFF00AABC), size: 24),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: const Color(0xFF212828),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: GoogleFonts.dmSans(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _pinController,
              keyboardType: TextInputType.number,
              maxLength: 4,
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 10,
              ),
              decoration: InputDecoration(
                counterText: '',
                hintText: '0000',
                hintStyle: GoogleFonts.dmSans(color: Colors.black26),
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF00AABC)),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00AABC),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  final pin = _pinController.text.trim();
                  if (pin.length == 4) {
                    Navigator.pop(ctx);
                    onPinConfirmed(pin);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Please enter valid 4-digit PIN')),
                    );
                  }
                },
                child: Text(
                  'Confirm & Advance',
                  style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _advanceStage(String nextStage, {String? pin}) async {
    final provider = Provider.of<RiderProvider>(context, listen: false);
    final ok = await provider.progressLifecycle(nextStage, pin: pin);

    if (!mounted) return;

    if (!ok && provider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage!),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<RiderProvider>(context);
    final ride = provider.currentActiveRide ?? widget.ride;
    final stage = ride.stage;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      appBar: AppBar(
        title: Text(
          'Active Ride (${ride.orderNumber})',
          style: GoogleFonts.dmSans(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF212828),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF212828)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Interactive Navigation Map (Customer Location on accept -> Store Location after PIN)
              if (stage != 'DELIVERED' && stage != 'DROPPED_AT_STORE') ...[
                _buildNavigationMapCard(ride, stage, provider),
                const SizedBox(height: 18),
              ],

              // 2. Main Action Card or Completion Card
              if (stage == 'DELIVERED' || stage == 'DROPPED_AT_STORE')
                _buildDeliveryCelebrationCard(ride, provider)
              else
                _buildActiveLegCard(ride, stage, provider),

              const SizedBox(height: 18),

              // 4. Trip & Contact Details
              _buildTripDetailsCard(ride),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationMapCard(
      ActiveRide ride, String stage, RiderProvider provider) {
    final rider = provider.currentRider;
    final riderPos =
        (rider?.coverageLatitude != null && rider?.coverageLongitude != null)
            ? LatLng(rider!.coverageLatitude!, rider.coverageLongitude!)
            : const LatLng(4.8633, 7.0292);

    final customerPos =
        (ride.customerLatitude != null && ride.customerLongitude != null)
            ? LatLng(ride.customerLatitude!, ride.customerLongitude!)
            : LatLng(riderPos.latitude + 0.012, riderPos.longitude + 0.008);

    final storePos = (ride.storeLatitude != null && ride.storeLongitude != null)
        ? LatLng(ride.storeLatitude!, ride.storeLongitude!)
        : const LatLng(4.8156, 7.0498);

    final bool isHeadingToStore = (stage == 'PICKED_UP');
    final LatLng targetPos = isHeadingToStore ? storePos : customerPos;

    final double distanceKm = _calculateDistanceKm(riderPos, targetPos);
    final int etaMins = math.max(3, (distanceKm / 25.0 * 60).round() + 2);

    final String targetTitle = isHeadingToStore
        ? 'Store Drop-off: ${ride.storeName}'
        : 'Customer Pickup: ${ride.customerName}';

    final String targetAddress = isHeadingToStore
        ? (ride.storeAddress.isNotEmpty ? ride.storeAddress : 'Store Location')
        : (ride.pickupAddress.isNotEmpty
            ? ride.pickupAddress
            : 'Customer Pickup Address');

    final String badgeLabel = isHeadingToStore
        ? 'NAVIGATING TO STORE LOCATION'
        : 'NAVIGATING TO CUSTOMER LOCATION';

    final Color badgeColor =
        isHeadingToStore ? const Color(0xFFFFA000) : const Color(0xFF00AABC);
    final IconData badgeIcon =
        isHeadingToStore ? Icons.storefront_rounded : Icons.location_on_rounded;

    final markers = <Marker>{
      Marker(
        markerId: const MarkerId('rider_pos'),
        position: riderPos,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow:
            const InfoWindow(title: 'You (Rider)', snippet: 'Current Position'),
      ),
      Marker(
        markerId:
            MarkerId(isHeadingToStore ? 'store_target' : 'customer_target'),
        position: targetPos,
        icon: BitmapDescriptor.defaultMarkerWithHue(
          isHeadingToStore
              ? BitmapDescriptor.hueOrange
              : BitmapDescriptor.hueRed,
        ),
        infoWindow: InfoWindow(title: targetTitle, snippet: targetAddress),
      ),
    };

    final polylines = <Polyline>{
      Polyline(
        polylineId: PolylineId(
            isHeadingToStore ? 'route_to_store' : 'route_to_customer'),
        points: [riderPos, targetPos],
        color: const Color(0xFF00AABC),
        width: 4,
        patterns: [PatternItem.dash(14), PatternItem.gap(6)],
      ),
    };

    if (_lastRenderedStage != stage) {
      _lastRenderedStage = stage;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fitRouteBounds(riderPos, targetPos);
      });
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(badgeIcon, color: badgeColor, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    badgeLabel,
                    style: GoogleFonts.dmSans(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 0.5,
                      color: badgeColor,
                    ),
                  ),
                ),
                InkWell(
                  onTap: () => _fitRouteBounds(riderPos, targetPos),
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.my_location,
                            size: 13, color: Color(0xFF00AABC)),
                        const SizedBox(width: 4),
                        Text(
                          'Recenter',
                          style: GoogleFonts.dmSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF00AABC),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 350,
            width: double.infinity,
            child: Stack(
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    child: GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: riderPos,
                        zoom: 14.0,
                      ),
                      markers: markers,
                      polylines: polylines,
                      zoomControlsEnabled: false,
                      myLocationButtonEnabled: false,
                      compassEnabled: false,
                      mapToolbarEnabled: false,
                      gestureRecognizers:
                          <Factory<OneSequenceGestureRecognizer>>{
                        Factory<OneSequenceGestureRecognizer>(
                            () => EagerGestureRecognizer()),
                      },
                      onMapCreated: (controller) {
                        _mapController = controller;
                        _fitRouteBounds(riderPos, targetPos);
                      },
                    ),
                  ),
                ),
                // Prominent Floating ETA Badge over the map
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: const Color(0xFF001C1F).withOpacity(0.92),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.timer_outlined,
                            color: Color(0xFF21CAAD), size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'Est. Arrival: ~$etaMins mins',
                          style: GoogleFonts.dmSans(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF21CAAD).withOpacity(0.22),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${distanceKm.toStringAsFixed(1)} km',
                            style: GoogleFonts.dmSans(
                              color: const Color(0xFF21CAAD),
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Color(0xFFFAFAFA),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(14),
                bottomRight: Radius.circular(14),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: badgeColor.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isHeadingToStore
                        ? Icons.storefront
                        : Icons.person_pin_circle,
                    size: 16,
                    color: badgeColor,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        targetTitle,
                        style: GoogleFonts.dmSans(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: const Color(0xFF212828),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        targetAddress,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveLegCard(
      ActiveRide ride, String stage, RiderProvider provider) {
    String title = '';
    String subtitle = '';
    String buttonText = '';
    IconData buttonIcon = Icons.arrow_forward;
    VoidCallback onAction = () {};

    if (stage == 'EN_ROUTE_TO_STORE') {
      title = 'Head to Pickup Location';
      subtitle =
          'Arrive at ${ride.pickupAddress.isNotEmpty ? ride.pickupAddress : ride.storeName} to collect laundry and input customer PIN.';
      buttonText = 'Arrived at Pickup & Enter Customer PIN';
      buttonIcon = Icons.pin;
      onAction = () {
        _promptPinModal(
          title: 'Confirm Pickup from Customer',
          description: 'Ask customer for their 4-digit pickup PIN.',
          onPinConfirmed: (pin) => _advanceStage('PICKED_UP', pin: pin),
        );
      };
    } else if (stage == 'PICKED_UP') {
      title = 'Head to Store Drop-off';
      subtitle =
          'Items collected! Follow the map to ${ride.storeName} (${ride.storeAddress.isNotEmpty ? ride.storeAddress : "Store location"}).';
      buttonText = 'Confirm Drop-off at Store';
      buttonIcon = Icons.storefront;
      onAction = () => _advanceStage('DROPPED_AT_STORE');
    } else if (stage == 'OUT_FOR_DELIVERY') {
      title = 'Delivering to Destination';
      subtitle =
          'Deliver package to ${ride.customerName} at ${ride.deliveryAddress}.';
      buttonText = 'Confirm Handover & Enter Delivery PIN';
      buttonIcon = Icons.verified;
      onAction = () {
        _promptPinModal(
          title: 'Customer Delivery PIN',
          description: 'Ask customer for the 4-digit delivery PIN to complete.',
          onPinConfirmed: (pin) => _advanceStage('DELIVERED', pin: pin),
        );
      };
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF00AABC).withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00AABC).withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (ride.pickupTime != null || ride.scheduledPickupTime != null) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFFE082)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.schedule_rounded,
                      color: Color(0xFFF57F17), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Scheduled Pickup: ${ride.pickupTime ?? "Scheduled"}',
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFE65100),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          Text(
            title,
            style: GoogleFonts.dmSans(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: const Color(0xFF212828),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: GoogleFonts.dmSans(fontSize: 13, color: Colors.black54),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00AABC),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: provider.isLoading ? null : onAction,
              icon: provider.isLoading
                  ? const SizedBox()
                  : Icon(buttonIcon, color: Colors.white, size: 20),
              label: provider.isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      buttonText,
                      style: GoogleFonts.dmSans(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
          if (stage == 'EN_ROUTE_TO_STORE') ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                  side: const BorderSide(color: Colors.redAccent, width: 1.2),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: provider.isLoading
                    ? null
                    : () => _confirmCancelRide(ride.orderId),
                icon: const Icon(Icons.close_rounded, size: 18),
                label: Text(
                  'Cancel Ride (Release to Nearby Riders)',
                  style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _confirmCancelRide(String orderId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded,
                color: Colors.redAccent, size: 26),
            const SizedBox(width: 8),
            Text(
              'Cancel This Ride?',
              style:
                  GoogleFonts.dmSans(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to cancel this pickup? The ride will immediately be made available to other nearby riders.',
          style:
              GoogleFonts.dmSans(fontSize: 14, color: const Color(0xFF5E5E5E)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Keep Ride',
                style: GoogleFonts.dmSans(
                    color: Colors.black54, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final provider =
                  Provider.of<RiderProvider>(context, listen: false);
              final ok = await provider.cancelRide(orderId);
              if (!mounted) return;
              if (ok) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                        'Ride cancelled. Order released to nearby riders.'),
                    backgroundColor: Colors.green,
                  ),
                );
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content:
                        Text(provider.errorMessage ?? 'Failed to cancel ride'),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
            },
            child: Text('Cancel Ride',
                style: GoogleFonts.dmSans(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryCelebrationCard(
      ActiveRide ride, RiderProvider provider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF21CAAD)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF21CAAD).withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFFE5FBF7),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              color: Color(0xFF21CAAD),
              size: 54,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            ride.stage == 'DROPPED_AT_STORE'
                ? 'Dropped Off at Store!'
                : 'Delivery Completed!',
            style: GoogleFonts.dmSans(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF212828),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            ride.stage == 'DROPPED_AT_STORE'
                ? 'Order ${ride.orderNumber} successfully delivered to ${ride.storeName}. Earnings credited to your wallet.'
                : 'Order ${ride.orderNumber} successfully completed and verified.',
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(fontSize: 13, color: Colors.black54),
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFE5F7F8),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Earnings Credited:',
                  style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: const Color(0xFF212828),
                  ),
                ),
                Text(
                  '+ ₦${currencyFormatter.format(ride.earnings)}',
                  style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: const Color(0xFF00AABC),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00AABC),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                provider.finishActiveRide();
                Navigator.pop(context);
              },
              child: Text(
                'Return to Rider Dashboard',
                style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTripDetailsCard(ActiveRide ride) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Delivery Information',
            style:
                GoogleFonts.dmSans(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 14),
          _buildDetailRow(
            icon: Icons.storefront,
            label: 'Store Pickup',
            title: ride.storeName,
            subtitle: ride.pickupAddress,
          ),
          const Divider(height: 20),
          _buildDetailRow(
            icon: Icons.location_on,
            label: 'Customer Drop-off',
            title: ride.customerName,
            subtitle: ride.deliveryAddress,
            phone: ride.customerPhone,
          ),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Trip Payout',
                  style:
                      GoogleFonts.dmSans(fontSize: 13, color: Colors.black54)),
              Text(
                '₦${currencyFormatter.format(ride.earnings)}',
                style: GoogleFonts.dmSans(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: const Color(0xFF00AABC),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String title,
    required String subtitle,
    String? phone,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: const Color(0xFF00AABC)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: GoogleFonts.dmSans(
                      fontSize: 11,
                      color: Colors.black45,
                      fontWeight: FontWeight.w600)),
              Text(title,
                  style: GoogleFonts.dmSans(
                      fontSize: 13, fontWeight: FontWeight.bold)),
              Text(subtitle,
                  style:
                      GoogleFonts.dmSans(fontSize: 12, color: Colors.black54)),
            ],
          ),
        ),
        if (phone != null && phone.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.phone, color: Color(0xFF21CAAD), size: 20),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Calling customer $phone...')),
              );
            },
          ),
      ],
    );
  }
}
