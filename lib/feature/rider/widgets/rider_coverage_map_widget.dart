
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class RiderCoverageMapWidget extends StatefulWidget {
  final LatLng? initialCenter;
  final double initialRadiusKm;
  final Function({
    required double latitude,
    required double longitude,
    required double radiusKm,
    required String routeDescription,
  }) onCoverageChanged;
  final double height;
  final bool showHeader;

  const RiderCoverageMapWidget({
    super.key,
    this.initialCenter,
    this.initialRadiusKm = 10.0,
    required this.onCoverageChanged,
    this.height = 300.0,
    this.showHeader = true,
  });

  @override
  State<RiderCoverageMapWidget> createState() => _RiderCoverageMapWidgetState();
}

class _RiderCoverageMapWidgetState extends State<RiderCoverageMapWidget> {
  late LatLng _center;
  late double _radiusKm;
  GoogleMapController? _mapController;
  bool _isLocating = false;
  String _areaDescription = 'Detecting coverage zone...';

  static const Color _primaryTeal = Color(0xFF00AABC);
  static const Color _darkCharcoal = Color(0xFF212828);

  @override
  void initState() {
    super.initState();
    // Default to Port Harcourt (Eneka) if no initialCenter supplied
    _center = widget.initialCenter ?? const LatLng(4.8633, 7.0292);
    _radiusKm = widget.initialRadiusKm.clamp(1.0, 35.0);
    _updateAreaDescription();

    // Automatically attempt to locate rider on first load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _detectCurrentLocation(silent: true);
    });
  }

  void _updateAreaDescription() {
    final areaSqKm = (math.pi * _radiusKm * _radiusKm).toStringAsFixed(0);
    // Derive sensible neighborhood name based on latitude/longitude proximity
    String regionName = 'Custom Zone';
    if ((_center.latitude - 4.86).abs() < 0.1 && (_center.longitude - 7.03).abs() < 0.1) {
      regionName = 'Port Harcourt · Eneka Hub';
    } else if ((_center.latitude - 4.82).abs() < 0.1 && (_center.longitude - 7.01).abs() < 0.1) {
      regionName = 'Port Harcourt · Town & GRA';
    } else if ((_center.latitude - 6.45).abs() < 0.2 && (_center.longitude - 3.48).abs() < 0.2) {
      regionName = 'Lagos · Lekki & Island';
    } else if ((_center.latitude - 9.08).abs() < 0.2 && (_center.longitude - 7.48).abs() < 0.2) {
      regionName = 'Abuja · Central Metro';
    } else {
      regionName = 'Coverage Center (${_center.latitude.toStringAsFixed(3)}, ${_center.longitude.toStringAsFixed(3)})';
    }

    _areaDescription = '$regionName · ${_radiusKm.toStringAsFixed(1)} km radius (~$areaSqKm km²)';

    widget.onCoverageChanged(
      latitude: _center.latitude,
      longitude: _center.longitude,
      radiusKm: _radiusKm,
      routeDescription: _areaDescription,
    );
  }

  double _calculateZoomForRadius(double radiusKm) {
    // Dynamic camera zoom formula so the full circle remains visible
    // 1km ~ 14.8, 5km ~ 12.8, 10km ~ 11.8, 20km ~ 10.8, 30km ~ 10.0
    final zoom = 14.8 - (math.log(radiusKm) / math.ln2) * 0.72;
    return zoom.clamp(9.5, 15.5);
  }

  Future<void> _detectCurrentLocation({bool silent = false}) async {
    if (!mounted) return;
    setState(() => _isLocating = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!silent && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location services are disabled on device.')),
          );
        }
        setState(() => _isLocating = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (!silent && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location permissions denied.')),
            );
          }
          setState(() => _isLocating = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (!silent && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permissions permanently denied in settings.')),
          );
        }
        setState(() => _isLocating = false);
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 4),
        ),
      );

      final newCenter = LatLng(position.latitude, position.longitude);
      _setCenter(newCenter, animateCamera: true);

      if (!silent && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Centered to your GPS location: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}',
              style: GoogleFonts.dmSans(),
            ),
            backgroundColor: _primaryTeal,
          ),
        );
      }
    } catch (e) {
      debugPrint('[CoverageMap] Could not auto-detect location: $e');
      // Keep existing center gracefully
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  void _setCenter(LatLng newCenter, {bool animateCamera = false}) {
    setState(() {
      _center = newCenter;
      _updateAreaDescription();
    });

    if (animateCamera && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: newCenter,
            zoom: _calculateZoomForRadius(_radiusKm),
          ),
        ),
      );
    }
  }

  void _setRadius(double newRadiusKm) {
    final clamped = newRadiusKm.clamp(1.0, 35.0);
    setState(() {
      _radiusKm = clamped;
      _updateAreaDescription();
    });

    if (_mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: _center,
            zoom: _calculateZoomForRadius(clamped),
          ),
        ),
      );
    }
  }

  Set<Circle> _buildCircles() {
    return {
      // 1. Shaded coverage circle with brand teal fill and defined boundary
      Circle(
        circleId: const CircleId('coverage_radius_circle'),
        center: _center,
        radius: _radiusKm * 1000, // in meters
        fillColor: _primaryTeal.withValues(alpha: 0.28), // clear shaded portion
        strokeColor: const Color(0xFF007E8A), // defined darker teal border
        strokeWidth: 3,
      ),
      // 2. Inner core circle highlighting the center coordinate
      Circle(
        circleId: const CircleId('coverage_center_anchor'),
        center: _center,
        radius: math.min(180.0, _radiusKm * 1000 * 0.08),
        fillColor: _primaryTeal.withValues(alpha: 0.65),
        strokeColor: Colors.white,
        strokeWidth: 2,
      ),
    };
  }

  Set<Marker> _buildMarkers() {
    // Calculate perimeter handle position to the East of center
    final cosLat = math.cos(_center.latitude * math.pi / 180.0);
    final effectiveCos = cosLat.abs() < 0.001 ? 1.0 : cosLat;
    final deltaLng = _radiusKm / (111.32 * effectiveCos);
    final perimeterPoint = LatLng(_center.latitude, _center.longitude + deltaLng);

    return {
      // 1. Center Pin: Can be dragged to MOVE the entire shaded coverage zone
      Marker(
        markerId: const MarkerId('coverage_center_marker'),
        position: _center,
        draggable: true,
        onDrag: (newPosition) {
          setState(() {
            _center = newPosition;
            _updateAreaDescription();
          });
        },
        onDragEnd: (newPosition) => _setCenter(newPosition),
        infoWindow: InfoWindow(
          title: 'Coverage Center Point',
          snippet: 'Drag to move center • ${_center.latitude.toStringAsFixed(4)}, ${_center.longitude.toStringAsFixed(4)}',
        ),
      ),

      // 2. Perimeter Handle Pin: Can be dragged to EXPAND or CONTRACT radius directly on the map!
      Marker(
        markerId: const MarkerId('coverage_perimeter_handle'),
        position: perimeterPoint,
        draggable: true,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan),
        infoWindow: InfoWindow(
          title: 'Coverage Radius: ${_radiusKm.toStringAsFixed(1)} km',
          snippet: 'Drag outward to expand, inward to contract radius',
        ),
        onDrag: (newPosition) {
          final distMeters = Geolocator.distanceBetween(
            _center.latitude,
            _center.longitude,
            newPosition.latitude,
            newPosition.longitude,
          );
          final km = (distMeters / 1000.0).clamp(1.0, 35.0);
          setState(() {
            _radiusKm = km;
            _updateAreaDescription();
          });
        },
        onDragEnd: (newPosition) {
          final distMeters = Geolocator.distanceBetween(
            _center.latitude,
            _center.longitude,
            newPosition.latitude,
            newPosition.longitude,
          );
          _setRadius(distMeters / 1000.0);
        },
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final areaSqKm = (math.pi * _radiusKm * _radiusKm).toStringAsFixed(0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showHeader) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Coverage Route & Radius',
                style: GoogleFonts.dmSans(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: _darkCharcoal,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F7FA),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.radar, size: 14, color: _primaryTeal),
                    const SizedBox(width: 4),
                    Text(
                      '${_radiusKm.toStringAsFixed(1)} km Zone',
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _primaryTeal,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Tap or drag anywhere on the map to shift your coverage center. Adjust the slider to expand or contract your delivery perimeter.',
            style: GoogleFonts.dmSans(
              fontSize: 12,
              color: const Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 12),
        ],

        // 1. Google Map View with Circular Coverage Area
        Container(
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFCFD8DC), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _center,
                    zoom: _calculateZoomForRadius(_radiusKm),
                  ),
                  onMapCreated: (controller) {
                    _mapController = controller;
                  },
                  onTap: (tappedPos) => _setCenter(tappedPos),
                  circles: _buildCircles(),
                  markers: _buildMarkers(),
                  gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                    Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer()),
                  },
                  myLocationEnabled: false,
                  myLocationButtonEnabled: false,
                  zoomGesturesEnabled: true,
                  zoomControlsEnabled: false,
                  scrollGesturesEnabled: true,
                  rotateGesturesEnabled: true,
                  tiltGesturesEnabled: false,
                  mapToolbarEnabled: false,
                ),

                // Map Overlay: Zoom In / Zoom Out / Auto-Fit Buttons
                Positioned(
                  top: 12,
                  left: 12,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildMapIconButton(
                        icon: Icons.add,
                        tooltip: 'Zoom In',
                        onTap: () => _mapController?.animateCamera(CameraUpdate.zoomIn()),
                      ),
                      const SizedBox(height: 6),
                      _buildMapIconButton(
                        icon: Icons.remove,
                        tooltip: 'Zoom Out',
                        onTap: () => _mapController?.animateCamera(CameraUpdate.zoomOut()),
                      ),
                      const SizedBox(height: 6),
                      _buildMapIconButton(
                        icon: Icons.filter_center_focus_rounded,
                        tooltip: 'Fit Coverage Area',
                        onTap: () {
                          if (_mapController != null) {
                            _mapController!.animateCamera(
                              CameraUpdate.newCameraPosition(
                                CameraPosition(
                                  target: _center,
                                  zoom: _calculateZoomForRadius(_radiusKm),
                                ),
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),

                // Map Overlay: Center on My GPS Button
                Positioned(
                  top: 12,
                  right: 12,
                  child: Material(
                    color: Colors.white,
                    elevation: 3,
                    borderRadius: BorderRadius.circular(30),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(30),
                      onTap: _isLocating ? null : () => _detectCurrentLocation(silent: false),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _isLocating
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: _primaryTeal),
                                  )
                                : const Icon(Icons.my_location, size: 16, color: _primaryTeal),
                            const SizedBox(width: 6),
                            Text(
                              'My Location',
                              style: GoogleFonts.dmSans(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: _primaryTeal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Map Overlay: Active Perimeter Chip
                Positioned(
                  bottom: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.adjust_rounded, size: 14, color: Color(0xFF21CAAD)),
                        const SizedBox(width: 6),
                        Text(
                          'Center: ${_center.latitude.toStringAsFixed(4)}, ${_center.longitude.toStringAsFixed(4)}',
                          style: GoogleFonts.dmSans(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 8),

        // Map Direct Interaction Guide
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              const Icon(Icons.touch_app_rounded, size: 15, color: _primaryTeal),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Tap or drag red pin to move • Drag cyan pin or slider to expand • Pinch or +/- to zoom',
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    color: const Color(0xFF475569),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // 2. Interactive Radius Slider & Fine-Tuning Controls
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.linear_scale_rounded, size: 18, color: _primaryTeal),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'Coverage Radius',
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.dmSans(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: _darkCharcoal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${_radiusKm.toStringAsFixed(1)} km (~$areaSqKm km²)',
                    style: GoogleFonts.dmSans(
                      fontWeight: FontWeight.bold,
                      fontSize: 12.5,
                      color: _primaryTeal,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Slider with Stepper Buttons on Ends
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline, color: Color(0xFF6B7280)),
                    iconSize: 22,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: _radiusKm > 1.5 ? () => _setRadius(_radiusKm - 1.0) : null,
                  ),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: _primaryTeal,
                        inactiveTrackColor: const Color(0xFFB2EBF2),
                        thumbColor: _primaryTeal,
                        overlayColor: _primaryTeal.withValues(alpha: 0.15),
                        trackHeight: 4,
                      ),
                      child: Slider(
                        value: _radiusKm,
                        min: 1.0,
                        max: 30.0,
                        divisions: 29,
                        label: '${_radiusKm.toStringAsFixed(1)} km',
                        onChanged: (val) => _setRadius(val),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, color: _primaryTeal),
                    iconSize: 22,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: _radiusKm < 29.5 ? () => _setRadius(_radiusKm + 1.0) : null,
                  ),
                ],
              ),

              // Quick Preset Radius Chips (Horizontally Scrollable / Adaptive)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    _buildPresetChip(3.0, '3 km · Local'),
                    const SizedBox(width: 6),
                    _buildPresetChip(5.0, '5 km · City'),
                    const SizedBox(width: 6),
                    _buildPresetChip(10.0, '10 km · Town'),
                    const SizedBox(width: 6),
                    _buildPresetChip(20.0, '20 km · Metro'),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // 3. Active Zone Info Banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFBBF7D0)),
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle_outline_rounded, size: 16, color: Color(0xFF16A34A)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _areaDescription,
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF15803D),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMapIconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      elevation: 3,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Tooltip(
          message: tooltip,
          child: Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            child: Icon(icon, size: 18, color: _primaryTeal),
          ),
        ),
      ),
    );
  }

  Widget _buildPresetChip(double km, String label) {
    final isSelected = (_radiusKm - km).abs() < 0.2;
    return GestureDetector(
      onTap: () => _setRadius(km),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? _primaryTeal : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? _primaryTeal : const Color(0xFFE5E7EB),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 10.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF4B5563),
          ),
        ),
      ),
    );
  }
}