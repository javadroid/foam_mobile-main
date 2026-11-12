import 'package:flutter/material.dart';
import 'package:foam_mobile/feature/schedule_pickup/controller/schedule_pickup_provider.dart';
import 'package:foam_mobile/feature/schedule_pickup/models/customer_schedule_models.dart';
import 'package:foam_mobile/feature/schedule_pickup/views/11_delivered_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

class CustomerDeliveryLegScreen extends StatefulWidget {
  static const String id = '/schedule_pickup/delivery_leg';

  const CustomerDeliveryLegScreen({super.key});

  @override
  State<CustomerDeliveryLegScreen> createState() => _CustomerDeliveryLegScreenState();
}

class _CustomerDeliveryLegScreenState extends State<CustomerDeliveryLegScreen> {
  GoogleMapController? _mapController;

  static const LatLng _fallbackStore = LatLng(6.4520, 3.4800);
  static const LatLng _fallbackRider = LatLng(6.4495, 3.4750);
  static const LatLng _fallbackCustomer = LatLng(6.4474, 3.4723);

  LatLng _parseCoordinate(LocationCoordinate? coord, LatLng fallback) {
    if (coord == null || (coord.latitude == 0.0 && coord.longitude == 0.0)) {
      return fallback;
    }
    return LatLng(coord.latitude, coord.longitude);
  }

  void _onMapCreated(GoogleMapController controller, LatLng p1, LatLng p2) {
    _mapController = controller;
    _animateToBounds(p1, p2);
  }

  void _animateToBounds(LatLng p1, LatLng p2) {
    if (_mapController == null) return;
    final south = p1.latitude < p2.latitude ? p1.latitude : p2.latitude;
    final north = p1.latitude > p2.latitude ? p1.latitude : p2.latitude;
    final west = p1.longitude < p2.longitude ? p1.longitude : p2.longitude;
    final east = p1.longitude > p2.longitude ? p1.longitude : p2.longitude;

    final bounds = LatLngBounds(
      southwest: LatLng(south, west),
      northeast: LatLng(north, east),
    );

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted && _mapController != null) {
        if ((north - south).abs() < 0.001 && (east - west).abs() < 0.001) {
          _mapController!.animateCamera(CameraUpdate.newLatLngZoom(p1, 15.0)).catchError((_) {});
        } else {
          _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 60)).catchError((_) {});
        }
      }
    });
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _mapController = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SchedulePickupProvider>(context);
    final tracking = provider.trackingData;
    final deliveryPin = tracking?.deliveryPin.isNotEmpty == true
        ? tracking!.deliveryPin
        : (provider.lastCreatedOrder?['deliveryPin'] as String? ?? '');
    final rider = tracking?.deliveryRider;

    final customerPos = _parseCoordinate(tracking?.customerLocation, _fallbackCustomer);
    final storePos = _parseCoordinate(tracking?.storeLocation, _fallbackStore);
    final riderPos = _parseCoordinate(tracking?.riderLocation, _fallbackRider);

    final markers = <Marker>{
      Marker(
        markerId: const MarkerId('store'),
        position: storePos,
        infoWindow: InfoWindow(title: tracking?.storeName ?? 'Laundry Store'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
      ),
      Marker(
        markerId: const MarkerId('deliveryRider'),
        position: riderPos,
        infoWindow: InfoWindow(
          title: rider?.name != null ? 'Delivery Rider: ${rider!.name}' : 'Delivery Rider',
          snippet: rider?.vehicle ?? rider?.subtitle,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan),
      ),
      Marker(
        markerId: const MarkerId('customer'),
        position: customerPos,
        infoWindow: InfoWindow(
          title: 'Your Address',
          snippet: tracking?.customerLocation?.address,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      ),
    };

    final polylines = <Polyline>{
      Polyline(
        polylineId: const PolylineId('deliveryRoute'),
        points: [storePos, riderPos, customerPos],
        color: const Color(0xFF00AABC),
        width: 4,
        patterns: [PatternItem.dash(16), PatternItem.gap(8)],
      ),
    };

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 1. Google Maps View
          Positioned.fill(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: riderPos,
                zoom: 15.0,
              ),
              markers: markers,
              polylines: polylines,
              zoomControlsEnabled: false,
              myLocationButtonEnabled: false,
              compassEnabled: false,
              onMapCreated: (controller) => _onMapCreated(controller, riderPos, customerPos),
            ),
          ),

          // Top Header Bar
          Positioned(
            top: 48,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CircleAvatar(
                  backgroundColor: Colors.white,
                  radius: 20,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF212828), size: 18),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x14000000),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    tracking?.orderNumber.isNotEmpty == true
                        ? 'Order #${tracking!.orderNumber}'
                        : (provider.lastCreatedOrder?['orderNumber'] != null
                            ? 'Order #${provider.lastCreatedOrder!['orderNumber']}'
                            : 'Order Details'),
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF212828),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 2. Bottom Sheet Card matching Figma Screen 10
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 16,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE4E4E4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Subtitle & Header
                  Text(
                    'DELIVERY · ARRIVING IN 11 MIN',
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF00AABC),
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Your clean clothes are coming',
                    style: GoogleFonts.dmSans(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF212828),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Delivery Rider Card
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: const BoxDecoration(
                          color: Color(0xFFE5F7F8),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            rider?.initials ?? 'KA',
                            style: GoogleFonts.dmSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF001C1F),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              rider?.name ?? 'Delivery Rider',
                              style: GoogleFonts.dmSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF212828),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              rider != null
                                  ? '★ ${rider.rating} · ${(rider.vehicle != null && rider.vehicle!.isNotEmpty) ? rider.vehicle! : (tracking?.storeName ?? 'Delivery')}'
                                  : (tracking?.storeName ?? 'Delivery in progress'),
                              style: GoogleFonts.dmSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                                color: const Color(0xFF5E5E5E),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF777777), width: 0.8),
                        ),
                        child: Center(
                          child: Text(
                            'Call',
                            style: GoogleFonts.dmSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF212828),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Delivery PIN Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5F7F8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Delivery PIN',
                          style: GoogleFonts.dmSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF212828),
                          ),
                        ),
                        Text(
                          deliveryPin,
                          style: GoogleFonts.dmSans(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF001C1F),
                            letterSpacing: 5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // 3-Segment Progress Bar (Pickup Done, At store Done, Delivery Active)
                  Row(
                    children: [
                      _buildStepSegment(label: 'Pickup', isDone: true),
                      const SizedBox(width: 8),
                      _buildStepSegment(label: 'At store', isDone: true),
                      const SizedBox(width: 8),
                      _buildStepSegment(label: 'Delivery', isDone: true, isActive: true),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Complete Delivery simulation action
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () {
                        Navigator.pushNamed(context, CustomerDeliveredScreen.id);
                      },
                      icon: const Icon(Icons.check_circle_rounded, color: Color(0xFF00AABC), size: 16),
                      label: Text(
                        'Mark as Delivered',
                        style: GoogleFonts.dmSans(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF00AABC),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepSegment({
    required String label,
    bool isActive = false,
    bool isDone = false,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: isDone ? const Color(0xFF00AABC) : const Color(0xFFE4E4E4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 12,
              fontWeight: (isActive || isDone) ? FontWeight.w700 : FontWeight.w400,
              color: isDone ? const Color(0xFF212828) : const Color(0xFF5E5E5E),
            ),
          ),
        ],
      ),
    );
  }
}
