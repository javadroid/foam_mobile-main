import 'package:flutter/material.dart';
import 'package:foam_mobile/core/Screens/main_screen.dart';
import 'package:foam_mobile/feature/schedule_pickup/controller/schedule_pickup_provider.dart';
import 'package:foam_mobile/feature/schedule_pickup/models/customer_schedule_models.dart';
import 'package:foam_mobile/feature/schedule_pickup/views/09_at_store_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

class ScheduleTrackingScreen extends StatefulWidget {
  static const String id = '/schedule_pickup/tracking';
  final String? orderId;

  const ScheduleTrackingScreen({super.key, this.orderId});

  @override
  State<ScheduleTrackingScreen> createState() => _ScheduleTrackingScreenState();
}

class _ScheduleTrackingScreenState extends State<ScheduleTrackingScreen> {
  GoogleMapController? _mapController;

  static const LatLng _fallbackCustomer = LatLng(6.4474, 3.4723);
  static const LatLng _fallbackRider = LatLng(6.4510, 3.4755);
  static const LatLng _fallbackStore = LatLng(6.4550, 3.4800);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final p = Provider.of<SchedulePickupProvider>(context, listen: false);
      final id = widget.orderId ?? (p.lastCreatedOrder?['id']?.toString());
      if (id != null && id.isNotEmpty) {
        p.loadTrackingInfo(id);
      }
    });
  }

  LatLng _parseCoordinate(LocationCoordinate? coord, LatLng fallback) {
    if (coord == null || (coord.latitude == 0.0 && coord.longitude == 0.0)) {
      return fallback;
    }
    return LatLng(coord.latitude, coord.longitude);
  }

  void _onMapCreated(
      GoogleMapController controller, LatLng rider, LatLng customer) {
    _mapController = controller;
    _animateToBounds(rider, customer);
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
          _mapController!
              .animateCamera(CameraUpdate.newLatLngZoom(p1, 15.0))
              .catchError((_) {});
        } else {
          _mapController!
              .animateCamera(CameraUpdate.newLatLngBounds(bounds, 60))
              .catchError((_) {});
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

    if (provider.isLoading && tracking == null) {
      return const Scaffold(
        backgroundColor: Color(0xFFF9FAFB),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF00AABC)),
        ),
      );
    }

    final isUnlocked = tracking?.isTrackingUnlocked ?? false;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        } else {
          Navigator.pushReplacementNamed(context, MainScreen.id);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF9FAFB),
        body: isUnlocked
            ? _buildLiveMapView(context, provider, tracking)
            : _buildGatedLockedView(context, provider, tracking),
      ),
    );
  }

  /// Gated View: Rendered when order is not yet marked OUT_FOR_DELIVERY
  /// Does NOT instantiate GoogleMap widget to ensure zero crashes and clear customer guidance
  Widget _buildGatedLockedView(
    BuildContext context,
    SchedulePickupProvider provider,
    OrderTrackingData? tracking,
  ) {
    final orderNum = tracking?.orderNumber ??
        (provider.lastCreatedOrder?['orderNumber'] as String? ?? '');
    final storeName = tracking?.storeName ??
        (provider.lastCreatedOrder?['storeName'] as String? ??
            (provider.selectedStore?.name ?? 'Laundry Store'));
    final turnaroundOpt = provider.selectedTurnaroundOption;
    final turnaroundName =
        turnaroundOpt?.name ?? provider.currentStore.turnaroundText;
    final deliveryPin = tracking?.deliveryPin.isNotEmpty == true
        ? tracking!.deliveryPin
        : (provider.lastCreatedOrder?['deliveryPin'] as String? ?? '');
    final pickupPin = tracking?.pickupPin.isNotEmpty == true
        ? tracking!.pickupPin
        : (provider.lastCreatedOrder?['pickupPin'] as String? ?? '');
    final stage = tracking?.currentStage ?? 'AT_STORE';

    return SafeArea(
      child: Column(
        children: [
          // Top Header Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CircleAvatar(
                  backgroundColor: Colors.white,
                  radius: 20,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new,
                        color: Color(0xFF212828), size: 18),
                    onPressed: () {
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      } else {
                        Navigator.pushReplacementNamed(context, MainScreen.id);
                      }
                    },
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0F000000),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    'Order #$orderNum',
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

          // Scrollable Body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Informative Order Status Card with Lock Badge
                  Container(
                    key: const Key('gated_locked_card'),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x0D000000),
                          blurRadius: 16,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F6),
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: const Color(0xFFE5E7EB), width: 1.5),
                          ),
                          child: const Center(
                            child: Icon(Icons.lock_outline_rounded,
                                color: Color(0xFF4B5563), size: 28),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Live Tracking Locked',
                          style: GoogleFonts.dmSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '🔒 Live GPS tracking will unlock automatically once your laundry is marked \'Out for Delivery\'.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.dmSans(
                            fontSize: 13.5,
                            height: 1.4,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF4B5563),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Progress Stepper: Order Placed -> Picked Up -> At Store / Washing -> Out for Delivery
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x0D000000),
                          blurRadius: 16,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order Progression',
                          style: GoogleFonts.dmSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(height: 18),
                        _buildStepperStep(
                          title: 'Order Placed',
                          subtitle: 'Order confirmed and registered',
                          isDone: true,
                          isActive: false,
                        ),
                        _buildStepperConnector(
                            isDone: stage != 'EN_ROUTE_TO_STORE'),
                        _buildStepperStep(
                          title: 'Picked Up',
                          subtitle: stage == 'EN_ROUTE_TO_STORE'
                              ? 'Rider heading to pick up laundry'
                              : 'Laundry collected from address',
                          isDone: stage != 'EN_ROUTE_TO_STORE',
                          isActive: stage == 'EN_ROUTE_TO_STORE' ||
                              stage == 'PICKED_UP',
                        ),
                        _buildStepperConnector(
                          isDone: stage == 'AT_STORE' ||
                              stage == 'OUT_FOR_DELIVERY' ||
                              stage == 'DELIVERED',
                        ),
                        _buildStepperStep(
                          title: 'At Store / Washing',
                          subtitle: stage == 'AT_STORE'
                              ? 'Washing & processing at $storeName'
                              : (stage == 'OUT_FOR_DELIVERY' ||
                                      stage == 'DELIVERED'
                                  ? 'Cleaned and packed'
                                  : 'Waiting to arrive at store'),
                          isDone: stage == 'OUT_FOR_DELIVERY' ||
                              stage == 'DELIVERED',
                          isActive: stage == 'AT_STORE',
                        ),
                        _buildStepperConnector(isDone: stage == 'DELIVERED'),
                        _buildStepperStep(
                          title: 'Out for Delivery',
                          subtitle: stage == 'OUT_FOR_DELIVERY'
                              ? 'Rider dispatched with clean clothes'
                              : 'Live GPS tracking will unlock here',
                          isDone: stage == 'DELIVERED',
                          isActive: stage == 'OUT_FOR_DELIVERY',
                          isGatedLock: stage != 'OUT_FOR_DELIVERY' &&
                              stage != 'DELIVERED',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Store & PIN Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x0D000000),
                          blurRadius: 16,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE5F7F8),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.storefront_rounded,
                                  color: Color(0xFF00AABC), size: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Laundry Partner Store',
                                    style: GoogleFonts.dmSans(
                                        fontSize: 12,
                                        color: const Color(0xFF6B7280)),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    storeName,
                                    style: GoogleFonts.dmSans(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF1F2937),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.timer_outlined,
                                      size: 16, color: Color(0xFF00AABC)),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Turnaround Speed:',
                                    style: GoogleFonts.dmSans(
                                        fontSize: 12.5,
                                        color: const Color(0xFF4B5563)),
                                  ),
                                ],
                              ),
                              Text(
                                '$turnaroundName (${turnaroundOpt?.days ?? provider.currentStore.turnaroundDays}d)',
                                style: GoogleFonts.dmSans(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF001C1F),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Divider(height: 1, color: Color(0xFFF3F4F6)),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Delivery PIN',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF6B7280),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  deliveryPin,
                                  style: GoogleFonts.dmSans(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF001C1F),
                                    letterSpacing: 4,
                                  ),
                                ),
                              ],
                            ),
                            if (pickupPin.isNotEmpty)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'Pickup PIN',
                                    style: GoogleFonts.dmSans(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFF6B7280),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    pickupPin,
                                    style: GoogleFonts.dmSans(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF00AABC),
                                      letterSpacing: 4,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Refresh Status Button
                  ElevatedButton.icon(
                    key: const Key('refresh_status_button'),
                    onPressed: () async {
                      final orderId = tracking?.orderId ??
                          (provider.lastCreatedOrder?['id']?.toString() ?? '');
                      if (orderId.isNotEmpty) {
                        await provider.loadTrackingInfo(orderId);
                      }
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Order status refreshed'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00AABC),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.refresh_rounded, size: 20),
                    label: Text(
                      'Refresh Status',
                      style: GoogleFonts.dmSans(
                          fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                  ),

                  const SizedBox(height: 12),

                  TextButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, CustomerAtStoreScreen.id);
                    },
                    icon: const Icon(Icons.local_laundry_service_outlined,
                        color: Color(0xFF00AABC), size: 18),
                    label: Text(
                      'View Store Washing Details',
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF00AABC),
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

  Widget _buildStepperStep({
    required String title,
    required String subtitle,
    required bool isDone,
    required bool isActive,
    bool isGatedLock = false,
  }) {
    Color iconBg;
    Color iconColor;
    IconData icon;

    if (isDone) {
      iconBg = const Color(0xFF00AABC);
      iconColor = Colors.white;
      icon = Icons.check_rounded;
    } else if (isActive) {
      iconBg = const Color(0xFFE5F7F8);
      iconColor = const Color(0xFF00AABC);
      icon = Icons.radio_button_checked_rounded;
    } else if (isGatedLock) {
      iconBg = const Color(0xFFF3F4F6);
      iconColor = const Color(0xFF9CA3AF);
      icon = Icons.lock_outline_rounded;
    } else {
      iconBg = const Color(0xFFF3F4F6);
      iconColor = const Color(0xFF9CA3AF);
      icon = Icons.radio_button_unchecked_rounded;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: iconBg,
            shape: BoxShape.circle,
            border: isActive
                ? Border.all(color: const Color(0xFF00AABC), width: 2)
                : null,
          ),
          child: Center(
            child: Icon(icon, color: iconColor, size: 18),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight:
                      (isDone || isActive) ? FontWeight.w700 : FontWeight.w500,
                  color: (isDone || isActive)
                      ? const Color(0xFF1F2937)
                      : const Color(0xFF9CA3AF),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  color: const Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStepperConnector({required bool isDone}) {
    return Padding(
      padding: const EdgeInsets.only(left: 15),
      child: Container(
        width: 2,
        height: 20,
        color: isDone ? const Color(0xFF00AABC) : const Color(0xFFE5E7EB),
      ),
    );
  }

  /// Live Map View: Rendered once order is marked OUT_FOR_DELIVERY
  Widget _buildLiveMapView(
    BuildContext context,
    SchedulePickupProvider provider,
    OrderTrackingData? tracking,
  ) {
    final customerPos =
        _parseCoordinate(tracking?.customerLocation, _fallbackCustomer);
    final riderPos = _parseCoordinate(tracking?.riderLocation, _fallbackRider);
    final storePos = _parseCoordinate(tracking?.storeLocation, _fallbackStore);

    final deliveryPin = tracking?.deliveryPin.isNotEmpty == true
        ? tracking!.deliveryPin
        : (provider.lastCreatedOrder?['deliveryPin'] as String? ?? '');
    final rider = tracking?.deliveryRider ?? tracking?.pickupRider;
    final orderNum = tracking?.orderNumber ??
        (provider.lastCreatedOrder?['orderNumber'] as String? ?? '');

    final markers = <Marker>{
      Marker(
        markerId: const MarkerId('store'),
        position: storePos,
        infoWindow: InfoWindow(title: tracking?.storeName ?? 'Laundry Store'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
      ),
      Marker(
        markerId: const MarkerId('rider'),
        position: riderPos,
        infoWindow: InfoWindow(
          title: rider?.name != null
              ? 'Rider: ${rider!.name}'
              : 'Rider: Out for Delivery',
          snippet: rider?.vehicle,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan),
      ),
      Marker(
        markerId: const MarkerId('customer'),
        position: customerPos,
        infoWindow: InfoWindow(
            title: 'Your Location',
            snippet: tracking?.customerLocation?.address),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      ),
    };

    final polylines = <Polyline>{
      Polyline(
        polylineId: const PolylineId('route'),
        points: [storePos, riderPos, customerPos],
        color: const Color(0xFF00AABC),
        width: 4,
        patterns: [PatternItem.dash(16), PatternItem.gap(8)],
      ),
    };

    return Container(
      key: const Key('live_tracking_unlocked_view'),
      child: Stack(
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
              onMapCreated: (controller) =>
                  _onMapCreated(controller, riderPos, customerPos),
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
                    icon: const Icon(Icons.arrow_back_ios_new,
                        color: Color(0xFF212828), size: 18),
                    onPressed: () {
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      } else {
                        Navigator.pushReplacementNamed(context, MainScreen.id);
                      }
                    },
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
                    'Order #$orderNum',
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

          // 2. Bottom Sheet Card matching Figma Screen 08 / 10
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
                    'DELIVERY · ${tracking?.deliveryEta ?? 'OUT FOR DELIVERY'}',
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF00AABC),
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    rider?.name != null
                        ? '${rider!.name} is on the way'
                        : 'Your fresh laundry is on the way',
                    style: GoogleFonts.dmSans(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF212828),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Rider Card
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
                            rider?.initials ?? 'RD',
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
                              rider?.name ?? 'Assigned Rider',
                              style: GoogleFonts.dmSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF212828),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${rider != null ? (rider.isNew ? 'New Rider' : '★ ${rider.rating.toStringAsFixed(1)}') : 'Foam Rider'} · ${rider?.vehicle ?? rider?.subtitle ?? 'Express Delivery'}',
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
                          border: Border.all(
                              color: const Color(0xFF777777), width: 0.8),
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
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

                  // 3-Segment Progress Bar
                  Row(
                    children: [
                      _buildStepSegment(
                          label: 'Pickup', isActive: false, isDone: true),
                      const SizedBox(width: 8),
                      _buildStepSegment(
                          label: 'At store', isActive: false, isDone: true),
                      const SizedBox(width: 8),
                      _buildStepSegment(
                          label: 'Delivery', isActive: true, isDone: false),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Simulate / view store progress button
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () {
                        Navigator.pushNamed(context, CustomerAtStoreScreen.id);
                      },
                      icon: const Icon(Icons.arrow_forward_rounded,
                          color: Color(0xFF00AABC), size: 16),
                      label: Text(
                        'View Store Washing Status',
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
    required bool isActive,
    required bool isDone,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: (isActive || isDone)
                  ? const Color(0xFF00AABC)
                  : const Color(0xFFE4E4E4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 12,
              fontWeight:
                  (isActive || isDone) ? FontWeight.w700 : FontWeight.w400,
              color: (isActive || isDone)
                  ? const Color(0xFF212828)
                  : const Color(0xFF5E5E5E),
            ),
          ),
        ],
      ),
    );
  }
}
