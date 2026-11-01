import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:foam_mobile/feature/rider/controller/rider_provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:foam_mobile/feature/rider/views/rider_dashboard_screen.dart';
import 'package:foam_mobile/feature/rider/widgets/rider_coverage_map_widget.dart';

class RiderRegistrationScreen extends StatefulWidget {
  static const String id = '/rider/register';
  const RiderRegistrationScreen({super.key});

  @override
  State<RiderRegistrationScreen> createState() => _RiderRegistrationScreenState();
}

class _RiderRegistrationScreenState extends State<RiderRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _licenseController = TextEditingController();
  final _plateController = TextEditingController();
  double _coverageLatitude = 4.8633;
  double _coverageLongitude = 7.0292;
  double _coverageRadiusKm = 10.0;
  String _coverageRouteDescription = 'Port Harcourt · Eneka Hub (10.0 km radius)';

  String _selectedVehicleType = 'Motorcycle';
  final List<String> _vehicleTypes = ['Motorcycle', 'Bicycle', 'Car', 'Van'];

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _licenseController.dispose();
    _plateController.dispose();

    super.dispose();
  }

  Future<void> _submitRegistration() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = Provider.of<RiderProvider>(context, listen: false);

    final success = await provider.register(
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim().isNotEmpty
          ? _emailController.text.trim()
          : null,
      password: _passwordController.text,
      vehicleType: _selectedVehicleType.toUpperCase(),
      vehiclePlate: _plateController.text.trim(),
      licenseNumber: _licenseController.text.trim().isNotEmpty
          ? _licenseController.text.trim()
          : null,
      coverageLatitude: _coverageLatitude,
      coverageLongitude: _coverageLongitude,
      coverageRadiusKm: _coverageRadiusKm,
      coverageRoute: _coverageRouteDescription,
    );

    if (!mounted) return;

    if (success) {
      _showPendingApprovalDialog();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Registration failed'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _showPendingApprovalDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.hourglass_top_rounded, color: Color(0xFFFFA000), size: 28),
            const SizedBox(width: 8),
            Text(
              'Pending Approval',
              style: GoogleFonts.dmSans(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your rider application has been submitted successfully with status PENDING.',
              style: GoogleFonts.dmSans(fontSize: 14, color: const Color(0xFF212828)),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFFECB3)),
              ),
              child: Text(
                'Foam Administrators must verify your vehicle details and license before order dispatch broadcasts become active.',
                style: GoogleFonts.dmSans(fontSize: 12, color: const Color(0xFF795548)),
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00AABC),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const RiderDashboardScreen()),
              );
            },
            child: Text(
              'Go to Rider Dashboard',
              style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<RiderProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      appBar: AppBar(
        title: Text(
          'Rider Onboarding',
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
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Join Foam Logistics Fleet',
                  style: GoogleFonts.dmSans(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF212828),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Register your vehicle and route coverage to start accepting delivery orders.',
                  style: GoogleFonts.dmSans(fontSize: 14, color: Colors.black54),
                ),
                const SizedBox(height: 24),

                // Vehicle Information Section
                _buildSectionHeader('Vehicle & Fleet Information'),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.black12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Vehicle Type',
                        style: GoogleFonts.dmSans(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedVehicleType,
                        decoration: _inputDecoration(hint: 'Select Vehicle Type'),
                        items: _vehicleTypes.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Row(
                              children: [
                                Icon(_getVehicleIcon(type), size: 20, color: const Color(0xFF00AABC)),
                                const SizedBox(width: 8),
                                Text(type, style: GoogleFonts.dmSans()),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedVehicleType = val);
                        },
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Vehicle Plate Number',
                        style: GoogleFonts.dmSans(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _plateController,
                        decoration: _inputDecoration(hint: 'e.g. ABJ-492-XY'),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Enter vehicle plate number' : null,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Rider License Number (Optional)',
                        style: GoogleFonts.dmSans(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _licenseController,
                        decoration: _inputDecoration(hint: 'e.g. RDL-78219'),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                // Interactive Coverage Map & Radius Expander Section
                RiderCoverageMapWidget(
                  initialCenter: LatLng(_coverageLatitude, _coverageLongitude),
                  initialRadiusKm: _coverageRadiusKm,
                  height: 280,
                  showHeader: true,
                  onCoverageChanged: ({
                    required double latitude,
                    required double longitude,
                    required double radiusKm,
                    required String routeDescription,
                  }) {
                    _coverageLatitude = latitude;
                    _coverageLongitude = longitude;
                    _coverageRadiusKm = radiusKm;
                    _coverageRouteDescription = routeDescription;
                  },
                ),

                const SizedBox(height: 24),
                // Personal & Account Info
                _buildSectionHeader('Rider Account Details'),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.black12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Full Name', style: GoogleFonts.dmSans(fontWeight: FontWeight.w600, fontSize: 13)),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _nameController,
                        decoration: _inputDecoration(hint: 'e.g. Emeka Okafor'),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter your full name' : null,
                      ),
                      const SizedBox(height: 14),
                      Text('Phone Number (WhatsApp Active)', style: GoogleFonts.dmSans(fontWeight: FontWeight.w600, fontSize: 13)),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: _inputDecoration(hint: '+2348012345678'),
                        validator: (v) => (v == null || v.trim().length < 10) ? 'Enter valid phone number' : null,
                      ),
                      const SizedBox(height: 14),
                      Text('Email Address', style: GoogleFonts.dmSans(fontWeight: FontWeight.w600, fontSize: 13)),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: _inputDecoration(hint: 'rider@example.com'),
                      ),
                      const SizedBox(height: 14),
                      Text('Password', style: GoogleFonts.dmSans(fontWeight: FontWeight.w600, fontSize: 13)),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: _inputDecoration(hint: '••••••••'),
                        validator: (v) => (v == null || v.length < 6) ? 'Password must be at least 6 characters' : null,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),
                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00AABC),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 1,
                    ),
                    onPressed: provider.isLoading ? null : _submitRegistration,
                    child: provider.isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            'Submit Registration for Approval',
                            style: GoogleFonts.dmSans(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: const Color(0xFF00AABC),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.dmSans(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF212828),
          ),
        ),
      ],
    );
  }

  IconData _getVehicleIcon(String type) {
    switch (type.toLowerCase()) {
      case 'bicycle':
        return Icons.pedal_bike;
      case 'car':
        return Icons.directions_car;
      case 'van':
        return Icons.local_shipping;
      case 'motorcycle':
      default:
        return Icons.two_wheeler;
    }
  }

  InputDecoration _inputDecoration({required String hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.dmSans(color: Colors.black38, fontSize: 14),
      filled: true,
      fillColor: const Color(0xFFF9FAFB),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.black12),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.black12),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF00AABC), width: 1.5),
      ),
    );
  }
}
