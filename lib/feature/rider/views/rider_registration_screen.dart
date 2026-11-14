import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:foam_mobile/core/hive/hive.dart';
import 'package:foam_mobile/core/services/upload_service.dart';
import 'package:foam_mobile/feature/authentication/controller/provider/authprovider.dart';
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
  bool _isLoggedIn = false;

  File? _profileImageFile;
  String? _profileImageUrl;
  bool _isUploadingProfileImage = false;

  File? _driverLicenseFile;
  String? _driverLicenseUrl;
  bool _isUploadingDriverLicense = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initUserData());
  }

  void _initUserData() {
    final token = HiveClass.getToken();
    _isLoggedIn = token.isNotEmpty;
    if (_isLoggedIn) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final fullName = '${auth.firstName} ${auth.lastName}'.trim();
      if (fullName.isNotEmpty) {
        _nameController.text = fullName;
      }
      if (auth.phoneNumber.isNotEmpty) {
        _phoneController.text = auth.phoneNumber;
      }
      if (auth.email.isNotEmpty) {
        _emailController.text = auth.email;
      }
      if (_profileImageUrl == null && HiveClass.pictureExists()) {
        final pic = HiveClass.getPic();
        if (pic.isNotEmpty) {
          _profileImageUrl = pic;
        }
      }
      setState(() {});
    }
  }

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

  Future<void> _pickAndUploadImage({
    required bool isProfileImage,
    required ImageSource source,
  }) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );
      if (picked == null) return;

      final file = File(picked.path);
      setState(() {
        if (isProfileImage) {
          _profileImageFile = file;
          _isUploadingProfileImage = true;
        } else {
          _driverLicenseFile = file;
          _isUploadingDriverLicense = true;
        }
      });

      final uploadedUrl = await UploadService.uploadImage(file);

      if (!mounted) return;
      setState(() {
        if (isProfileImage) {
          _isUploadingProfileImage = false;
          if (uploadedUrl != null) {
            _profileImageUrl = uploadedUrl;
          }
        } else {
          _isUploadingDriverLicense = false;
          if (uploadedUrl != null) {
            _driverLicenseUrl = uploadedUrl;
          }
        }
      });

      if (uploadedUrl == null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to upload image. Please try again.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        if (isProfileImage) {
          _isUploadingProfileImage = false;
        } else {
          _isUploadingDriverLicense = false;
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error selecting image: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _showImageSourceActionSheet({required bool isProfileImage}) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined, color: Color(0xFF00AABC)),
              title: Text('Take Photo', style: GoogleFonts.dmSans(fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(ctx);
                _pickAndUploadImage(isProfileImage: isProfileImage, source: ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: Color(0xFF00AABC)),
              title: Text('Choose from Gallery', style: GoogleFonts.dmSans(fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(ctx);
                _pickAndUploadImage(isProfileImage: isProfileImage, source: ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitRegistration() async {
    if (!_formKey.currentState!.validate()) return;

    if (_profileImageUrl == null || _profileImageUrl!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload an image of yourself (Profile Photo)'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (_driverLicenseUrl == null || _driverLicenseUrl!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please upload a photo of your Driver's License"),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final provider = Provider.of<RiderProvider>(context, listen: false);

    final success = await provider.register(
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim().isNotEmpty
          ? _emailController.text.trim()
          : null,
      password: _isLoggedIn
          ? (_passwordController.text.trim().isNotEmpty ? _passwordController.text.trim() : null)
          : _passwordController.text.trim(),
      profileImageUrl: _profileImageUrl,
      driverLicenseUrl: _driverLicenseUrl,
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
      if (_isLoggedIn) {
        final auth = Provider.of<AuthProvider>(context, listen: false);
        auth.setRiderRegistered(true, status: 'PENDING');
      }
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
                  _isLoggedIn
                      ? 'Your account details are linked. Complete your vehicle & coverage information below to become a rider.'
                      : 'Register your vehicle and route coverage to start accepting delivery orders.',
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
                _buildSectionHeader(_isLoggedIn ? 'Rider Account Details (Linked)' : 'Rider Account Details'),
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
                      Text(
                        _isLoggedIn ? 'Email Address (Locked to account)' : 'Email Address',
                        style: GoogleFonts.dmSans(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _emailController,
                        readOnly: _isLoggedIn,
                        keyboardType: TextInputType.emailAddress,
                        decoration: _inputDecoration(
                          hint: 'rider@example.com',
                          suffixIcon: _isLoggedIn
                              ? const Tooltip(
                                  message: 'Email cannot be changed once linked to account',
                                  child: Icon(Icons.lock_outline, size: 18, color: Colors.black45),
                                )
                              : null,
                          helperText: _isLoggedIn ? 'Your account email cannot be changed' : null,
                        ),
                      ),
                      if (!_isLoggedIn) ...[
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
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                // Identity & Verification Documents
                _buildDocumentUploadSection(),

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

  Widget _buildDocumentUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Identity & Verification Documents'),
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
                '1. Profile Photo (Image of You)',
                style: GoogleFonts.dmSans(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              const SizedBox(height: 4),
              Text(
                'A clear, well-lit photo of yourself for customer and vendor delivery identification.',
                style: GoogleFonts.dmSans(fontSize: 12, color: Colors.black54),
              ),
              const SizedBox(height: 14),
              Center(
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F9FA),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _profileImageUrl != null ? const Color(0xFF00AABC) : Colors.black12,
                          width: 2.5,
                        ),
                      ),
                      child: ClipOval(
                        child: _isUploadingProfileImage
                            ? const Center(
                                child: SizedBox(
                                  width: 26,
                                  height: 26,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Color(0xFF00AABC),
                                  ),
                                ),
                              )
                            : _profileImageFile != null
                                ? Image.file(_profileImageFile!, fit: BoxFit.cover)
                                : (_profileImageUrl != null && _profileImageUrl!.isNotEmpty)
                                    ? Image.network(
                                        _profileImageUrl!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => const Icon(
                                          Icons.person,
                                          size: 48,
                                          color: Color(0xFF00AABC),
                                        ),
                                      )
                                    : const Icon(
                                        Icons.person_outline,
                                        size: 48,
                                        color: Color(0xFF00AABC),
                                      ),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: InkWell(
                        onTap: _isUploadingProfileImage
                            ? null
                            : () => _showImageSourceActionSheet(isProfileImage: true),
                        child: Container(
                          padding: const EdgeInsets.all(7),
                          decoration: const BoxDecoration(
                            color: Color(0xFF00AABC),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton.icon(
                  onPressed: _isUploadingProfileImage
                      ? null
                      : () => _showImageSourceActionSheet(isProfileImage: true),
                  icon: Icon(
                    _profileImageUrl != null ? Icons.check_circle : Icons.upload_file,
                    size: 16,
                    color: _profileImageUrl != null ? const Color(0xFF059669) : const Color(0xFF00AABC),
                  ),
                  label: Text(
                    _isUploadingProfileImage
                        ? 'Uploading photo...'
                        : (_profileImageUrl != null && _profileImageUrl!.isNotEmpty)
                            ? 'Change Profile Photo'
                            : 'Upload Profile Photo',
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _profileImageUrl != null ? const Color(0xFF059669) : const Color(0xFF00AABC),
                    ),
                  ),
                ),
              ),
              const Divider(height: 28),
              Text(
                "2. Driver's License",
                style: GoogleFonts.dmSans(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              const SizedBox(height: 4),
              Text(
                "A clear photo or scan of your valid driver's license for compliance approval.",
                style: GoogleFonts.dmSans(fontSize: 12, color: Colors.black54),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: _isUploadingDriverLicense
                    ? null
                    : () => _showImageSourceActionSheet(isProfileImage: false),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _driverLicenseUrl != null
                        ? const Color(0xFFECFDF5)
                        : const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _driverLicenseUrl != null
                          ? const Color(0xFF10B981)
                          : Colors.black12,
                      width: 1.2,
                    ),
                  ),
                  child: _isUploadingDriverLicense
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color(0xFF00AABC),
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text('Uploading driver license...'),
                              ],
                            ),
                          ),
                        )
                      : Row(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: _driverLicenseUrl != null
                                    ? const Color(0xFFD1FAE5)
                                    : const Color(0xFFE5F7F8),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: _driverLicenseFile != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.file(_driverLicenseFile!, fit: BoxFit.cover),
                                    )
                                  : Icon(
                                      _driverLicenseUrl != null
                                          ? Icons.assignment_turned_in_outlined
                                          : Icons.badge_outlined,
                                      color: _driverLicenseUrl != null
                                          ? const Color(0xFF059669)
                                          : const Color(0xFF00AABC),
                                      size: 26,
                                    ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _driverLicenseUrl != null
                                        ? "Driver's License Uploaded ✓"
                                        : "Upload Driver's License",
                                    style: GoogleFonts.dmSans(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: _driverLicenseUrl != null
                                          ? const Color(0xFF065F46)
                                          : const Color(0xFF212828),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _driverLicenseUrl != null
                                        ? 'Tap to replace photo or document'
                                        : 'Take a photo or choose from gallery',
                                    style: GoogleFonts.dmSans(
                                      fontSize: 12,
                                      color: _driverLicenseUrl != null
                                          ? const Color(0xFF047857)
                                          : Colors.black45,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              _driverLicenseUrl != null
                                  ? Icons.check_circle_rounded
                                  : Icons.file_upload_outlined,
                              color: _driverLicenseUrl != null
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFF00AABC),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ],
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

  InputDecoration _inputDecoration({required String hint, Widget? suffixIcon, String? helperText}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.dmSans(color: Colors.black38, fontSize: 14),
      suffixIcon: suffixIcon,
      helperText: helperText,
      helperStyle: GoogleFonts.dmSans(color: Colors.black45, fontSize: 12),
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
