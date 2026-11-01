import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:foam_mobile/core/services/location_service.dart';
import 'package:foam_mobile/core/services/upload_service.dart';
import 'package:foam_mobile/feature/authentication/controller/provider/authprovider.dart';
import 'package:foam_mobile/feature/vendor/controller/vendor_provider.dart';
import 'package:foam_mobile/feature/vendor/models/vendor_models.dart';
import 'package:foam_mobile/feature/vendor/store_setup/vendor_pricing_service_screen.dart';
import 'package:foam_mobile/feature/vendor/widgets/vendor_ui_components.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class VendorStoreDetailsScreen extends StatefulWidget {
  static const String id = '/vendor_store_details';
  final VendorStore? store;

  const VendorStoreDetailsScreen({super.key, this.store});

  @override
  State<VendorStoreDetailsScreen> createState() => _VendorStoreDetailsScreenState();
}

class _VendorStoreDetailsScreenState extends State<VendorStoreDetailsScreen> {
  late final TextEditingController _storeNameController;
  final TextEditingController _addressController = TextEditingController();

  String _hoursMonFri = '8:00 AM – 6:00 PM';
  String _hoursSat = '9:00 AM – 5:00 PM';
  String _hoursSun = 'Closed';
  int _turnaroundDays = 2;

  double? _latitude;
  double? _longitude;
  String? _storePhotoUrl;
  File? _localPhotoFile;

  final ImagePicker _picker = ImagePicker();
  bool _isUploadingPhoto = false;
  bool _isDetectingLocation = false;
  bool _isSearchingSuggestions = false;
  bool _isGeocodingAddress = false;
  String? _lastSelectedAddress;
  List<AddressSuggestion> _addressSuggestions = <AddressSuggestion>[];
  Timer? _debounceTimer;

  bool get isEditing => widget.store != null;

  @override
  void initState() {
    super.initState();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final vendor = Provider.of<VendorProvider>(context, listen: false);
    final currentStore = widget.store;

    String initialName = '';
    if (currentStore != null) {
      initialName = currentStore.name;
      if (currentStore.address.isNotEmpty && currentStore.address != 'No address set') {
        _addressController.text = currentStore.address;
        _lastSelectedAddress = currentStore.address;
      }

      final bool hasValidExistingCoords = currentStore.latitude != null &&
          currentStore.longitude != null &&
          currentStore.latitude != 0.0 &&
          currentStore.longitude != 0.0 &&
          !(currentStore.latitude == 6.4474 && currentStore.longitude == 3.4723);

      if (hasValidExistingCoords) {
        _latitude = currentStore.latitude;
        _longitude = currentStore.longitude;
      } else {
        _latitude = null;
        _longitude = null;
      }

      _storePhotoUrl = currentStore.photoUrl;
      _hoursMonFri = currentStore.hoursMonFri;
      _hoursSat = currentStore.hoursSat;
      _hoursSun = currentStore.hoursSun;
      _turnaroundDays = currentStore.turnaroundDays;
    } else {
      // Adding a new branch
      final storeCount = vendor.stores.length;
      final base = auth.businessName.isNotEmpty ? auth.businessName : 'Store';
      initialName = storeCount == 0 ? base : '$base · Branch ${storeCount + 1}';
      _latitude = null;
      _longitude = null;
    }

    _storeNameController = TextEditingController(text: initialName);
    _addressController.addListener(_onAddressChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _addressController.removeListener(_onAddressChanged);
    _storeNameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _onAddressChanged() {
    final String query = _addressController.text.trim();
    if (query == _lastSelectedAddress) {
      return;
    }
    _lastSelectedAddress = null;

    if (query.length < 2) {
      _debounceTimer?.cancel();
      if (_addressSuggestions.isNotEmpty || _isSearchingSuggestions) {
        setState(() {
          _addressSuggestions = <AddressSuggestion>[];
          _isSearchingSuggestions = false;
        });
      }
      return;
    }

    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 280), () async {
      if (!mounted) return;
      setState(() {
        _isSearchingSuggestions = true;
      });
      final List<AddressSuggestion> results =
          await LocationService.searchAddressSuggestions(query);
      if (!mounted) return;
      setState(() {
        _addressSuggestions = results;
        _isSearchingSuggestions = false;
      });
    });
  }

  Future<void> _selectSuggestion(AddressSuggestion suggestion) async {
    final selectedText = suggestion.fullAddress.isNotEmpty
        ? suggestion.fullAddress
        : suggestion.title;

    setState(() {
      _lastSelectedAddress = selectedText;
      _addressController.text = selectedText;
      _addressSuggestions = <AddressSuggestion>[];
      _isSearchingSuggestions = false;
      _isGeocodingAddress = true;
    });
    FocusScope.of(context).unfocus();

    try {
      final UserLocationDetails resolved =
          await LocationService.resolveSuggestionDetails(suggestion);
      if (!mounted) return;

      if (resolved.latitude != 0.0 && resolved.longitude != 0.0) {
        setState(() {
          _latitude = resolved.latitude;
          _longitude = resolved.longitude;
          _isGeocodingAddress = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Location pinned: ${_latitude!.toStringAsFixed(4)}° N, ${_longitude!.toStringAsFixed(4)}° E',
              style: GoogleFonts.dmSans(fontWeight: FontWeight.w500),
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      } else {
        // Fallback: direct geocoding lookup
        final coords = await LocationService.getCoordinates(selectedText);
        if (!mounted) return;
        if (coords != null &&
            coords['latitude'] != null &&
            coords['longitude'] != null &&
            coords['latitude'] != 0.0 &&
            coords['longitude'] != 0.0) {
          setState(() {
            _latitude = coords['latitude'];
            _longitude = coords['longitude'];
            _isGeocodingAddress = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Location pinned: ${_latitude!.toStringAsFixed(4)}° N, ${_longitude!.toStringAsFixed(4)}° E',
                style: GoogleFonts.dmSans(fontWeight: FontWeight.w500),
              ),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        } else {
          setState(() {
            _isGeocodingAddress = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Could not resolve coordinates for this place. Please try another suggestion or tap "Use current location".',
                style: GoogleFonts.dmSans(fontWeight: FontWeight.w500),
              ),
              backgroundColor: const Color(0xFFEF4444),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error selecting suggestion: $e');
      if (mounted) {
        setState(() => _isGeocodingAddress = false);
      }
    }
  }

  Future<void> _handleAutoDetectLocation() async {
    setState(() {
      _isDetectingLocation = true;
      _addressSuggestions = <AddressSuggestion>[];
      _isSearchingSuggestions = false;
    });

    try {
      final details = await LocationService.autoDetectLocation();
      if (details != null && mounted) {
        final addressText = details.formattedAddress.isNotEmpty
            ? details.formattedAddress
            : (details.street.isNotEmpty ? details.street : details.city);

        setState(() {
          _lastSelectedAddress = addressText;
          _addressController.text = addressText;
          if (details.latitude != 0.0 && details.longitude != 0.0) {
            _latitude = details.latitude;
            _longitude = details.longitude;
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _latitude != null
                  ? 'Location pinned: ${_latitude!.toStringAsFixed(4)}° N, ${_longitude!.toStringAsFixed(4)}° E'
                  : 'Location detected: ${details.city}',
              style: GoogleFonts.dmSans(fontWeight: FontWeight.w500),
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not detect location: $e'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDetectingLocation = false;
        });
      }
    }
  }

  Future<bool> _ensureCoordinatesResolved() async {
    final bool hasValid = _latitude != null &&
        _longitude != null &&
        _latitude != 0.0 &&
        _longitude != 0.0 &&
        !(_latitude == 6.4474 && _longitude == 3.4723);

    if (hasValid) return true;

    final query = _addressController.text.trim();
    if (query.isEmpty) return false;

    setState(() => _isGeocodingAddress = true);
    final coords = await LocationService.getCoordinates(query);
    if (mounted) {
      setState(() => _isGeocodingAddress = false);
      if (coords != null &&
          coords['latitude'] != null &&
          coords['longitude'] != null &&
          coords['latitude'] != 0.0 &&
          coords['longitude'] != 0.0) {
        setState(() {
          _latitude = coords['latitude'];
          _longitude = coords['longitude'];
        });
        return true;
      }
    }
    return false;
  }

  Future<void> _pickAndUploadStorePhoto(ImageSource source) async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (picked != null) {
        final file = File(picked.path);
        setState(() {
          _localPhotoFile = file;
          _isUploadingPhoto = true;
        });

        final url = await UploadService.uploadImage(file);

        if (!mounted) return;
        setState(() {
          _isUploadingPhoto = false;
          if (url != null) {
            _storePhotoUrl = url;
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              url != null
                  ? 'Storefront photo uploaded successfully'
                  : 'Photo attached locally',
              style: GoogleFonts.dmSans(fontWeight: FontWeight.w500),
            ),
            backgroundColor: url != null ? const Color(0xFF10B981) : Colors.black87,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error uploading storefront photo: $e');
      if (mounted) {
        setState(() {
          _isUploadingPhoto = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload photo: $e'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Text(
                  _storePhotoUrl != null || _localPhotoFile != null
                      ? 'Change Storefront Photo'
                      : 'Upload Storefront Photo',
                  style: GoogleFonts.dmSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: VendorColors.textMain,
                  ),
                ),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: VendorColors.primary),
                title: Text(
                  'Choose from Gallery',
                  style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.w600,
                    color: VendorColors.textMain,
                  ),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndUploadStorePhoto(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined, color: VendorColors.primary),
                title: Text(
                  'Take Photo with Camera',
                  style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.w600,
                    color: VendorColors.textMain,
                  ),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndUploadStorePhoto(ImageSource.camera);
                },
              ),
              if (_storePhotoUrl != null || _localPhotoFile != null)
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  title: Text(
                    'Remove Photo',
                    style: GoogleFonts.dmSans(
                      fontWeight: FontWeight.w600,
                      color: Colors.redAccent,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() {
                      _storePhotoUrl = null;
                      _localPhotoFile = null;
                    });
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _editHoursDialog(String dayLabel, String currentVal, Function(String) onSave) {
    final controller = TextEditingController(text: currentVal);
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Operating Hours · $dayLabel',
            style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, fontSize: 18),
          ),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: 'e.g. 7:00 AM – 7:00 PM or Closed',
              hintStyle: GoogleFonts.dmSans(color: VendorColors.textMuted),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Cancel',
                style: GoogleFonts.dmSans(color: VendorColors.textMuted),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: VendorColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                onSave(controller.text);
                Navigator.pop(ctx);
              },
              child: Text(
                'Save',
                style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasPhoto = _storePhotoUrl != null || _localPhotoFile != null;
    final vendor = Provider.of<VendorProvider>(context);
    final bool isOverLimit = !isEditing && !vendor.canAddStore;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: VendorColors.textMain),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isEditing ? 'Edit Store Profile' : 'Add Store Branch',
          style: GoogleFonts.dmSans(
            color: VendorColors.textMain,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isOverLimit) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFECACA)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Store capacity limit reached (${vendor.stores.length}/${vendor.maxStores} stores). Default maximum is 10 stores. Contact an administrator to increase your account store limit.',
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF991B1B),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Storefront Cover Photo Upload Card
              Text(
                'Storefront photo',
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: VendorColors.textMain,
                ),
              ),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: _isUploadingPhoto ? null : _showPhotoOptions,
                child: Container(
                  height: 160,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: VendorColors.lightBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: hasPhoto ? VendorColors.primary : VendorColors.border,
                      width: hasPhoto ? 1.6 : 1.2,
                    ),
                    image: _localPhotoFile != null
                        ? DecorationImage(
                            image: FileImage(_localPhotoFile!),
                            fit: BoxFit.cover,
                          )
                        : (_storePhotoUrl != null
                            ? DecorationImage(
                                image: NetworkImage(_storePhotoUrl!),
                                fit: BoxFit.cover,
                              )
                            : null),
                  ),
                  child: Stack(
                    children: [
                      if (hasPhoto)
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.65),
                              ],
                            ),
                          ),
                        ),
                      Center(
                        child: _isUploadingPhoto
                            ? Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  shape: BoxShape.circle,
                                ),
                                child: const CircularProgressIndicator(
                                  color: VendorColors.primary,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : (hasPhoto
                                ? Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.55),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.camera_alt_outlined,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Change storefront photo',
                                          style: GoogleFonts.dmSans(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 12.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: VendorColors.primary.withValues(alpha: 0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.add_a_photo_outlined,
                                          color: VendorColors.primary,
                                          size: 26,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Upload storefront or shop photo',
                                        style: GoogleFonts.dmSans(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                          color: VendorColors.textMain,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Helps riders and customers recognize your location',
                                        style: GoogleFonts.dmSans(
                                          fontSize: 12,
                                          color: VendorColors.textMuted,
                                        ),
                                      ),
                                    ],
                                  )),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Store Name
              Text(
                'Store name & branch',
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: VendorColors.textMain,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                decoration: BoxDecoration(
                  color: VendorColors.lightBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: VendorColors.border),
                ),
                child: TextField(
                  controller: _storeNameController,
                  style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: VendorColors.textMain,
                  ),
                  decoration: InputDecoration(
                    hintText: 'e.g. Clean Express Laundry',
                    hintStyle: GoogleFonts.dmSans(
                      color: VendorColors.textMuted,
                      fontWeight: FontWeight.normal,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Physical Address & Location Suggestions Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Physical address',
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: VendorColors.textMain,
                    ),
                  ),
                  GestureDetector(
                    onTap: _isDetectingLocation ? null : _handleAutoDetectLocation,
                    child: Row(
                      children: [
                        if (_isDetectingLocation)
                          const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.8,
                              color: VendorColors.primary,
                            ),
                          )
                        else
                          const Icon(
                            Icons.my_location_rounded,
                            size: 14,
                            color: VendorColors.primary,
                          ),
                        const SizedBox(width: 4),
                        Text(
                          _isDetectingLocation ? 'Locating...' : 'Use current location',
                          style: GoogleFonts.dmSans(
                            color: VendorColors.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Address Search Field
              Container(
                decoration: BoxDecoration(
                  color: VendorColors.lightBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: VendorColors.border),
                ),
                child: TextField(
                  controller: _addressController,
                  style: GoogleFonts.dmSans(
                    fontSize: 15,
                    color: VendorColors.textMain,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search or enter street address...',
                    hintStyle: GoogleFonts.dmSans(color: VendorColors.textMuted),
                    prefixIcon: const Icon(
                      Icons.location_on_outlined,
                      color: VendorColors.primary,
                    ),
                    suffixIcon: _isSearchingSuggestions
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: VendorColors.primary,
                              ),
                            ),
                          )
                        : (_addressController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF94A3B8)),
                                onPressed: () {
                                  _addressController.clear();
                                  setState(() {
                                    _addressSuggestions = [];
                                  });
                                },
                              )
                            : null),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),

              // Suggestions Dropdown Card
              if (_addressSuggestions.isNotEmpty || _isSearchingSuggestions) ...[
                const SizedBox(height: 6),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                if (_isSearchingSuggestions)
                                  const Padding(
                                    padding: EdgeInsets.only(right: 6.0),
                                    child: SizedBox(
                                      width: 12,
                                      height: 12,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 1.8,
                                        color: VendorColors.primary,
                                      ),
                                    ),
                                  ),
                                Text(
                                  _isSearchingSuggestions && _addressSuggestions.isEmpty
                                      ? 'Searching locations...'
                                      : 'Suggested Locations (${_addressSuggestions.length})',
                                  style: GoogleFonts.dmSans(
                                    color: const Color(0xFF64748B),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _addressSuggestions = <AddressSuggestion>[];
                                  _isSearchingSuggestions = false;
                                });
                              },
                              child: const Icon(Icons.close_rounded, size: 16, color: Color(0xFF94A3B8)),
                            ),
                          ],
                        ),
                      ),
                      if (_addressSuggestions.isNotEmpty) ...[
                        const Divider(height: 1, color: Color(0xFFF1F5F9)),
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _addressSuggestions.length,
                          separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                          itemBuilder: (BuildContext context, int index) {
                            final AddressSuggestion suggestion = _addressSuggestions[index];
                            return ListTile(
                              dense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 4.0),
                              leading: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: VendorColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.place_outlined,
                                  color: VendorColors.primary,
                                  size: 18,
                                ),
                              ),
                              title: Text(
                                suggestion.title,
                                style: GoogleFonts.dmSans(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                              subtitle: suggestion.subtitle.isNotEmpty
                                  ? Text(
                                      suggestion.subtitle,
                                      style: GoogleFonts.dmSans(
                                        fontSize: 12,
                                        color: const Color(0xFF64748B),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    )
                                  : null,
                              trailing: const Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 12,
                                color: Color(0xFF94A3B8),
                              ),
                              onTap: () => _selectSuggestion(suggestion),
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // Geocoded Map Pin Card
              Builder(
                builder: (context) {
                  final bool hasValid = _latitude != null &&
                      _longitude != null &&
                      _latitude != 0.0 &&
                      _longitude != 0.0 &&
                      !(_latitude == 6.4474 && _longitude == 3.4723);

                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: hasValid
                          ? const Color(0xFFE5F7F8)
                          : const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: hasValid
                            ? VendorColors.primary.withValues(alpha: 0.3)
                            : const Color(0xFFFDE68A),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: hasValid
                                    ? VendorColors.primary
                                    : const Color(0xFFF59E0B),
                                shape: BoxShape.circle,
                              ),
                              child: _isGeocodingAddress
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Icon(
                                      hasValid
                                          ? Icons.storefront
                                          : Icons.location_off_outlined,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    hasValid
                                        ? 'Geocoded Coordinates'
                                        : 'Coordinates Required',
                                    style: GoogleFonts.dmSans(
                                      color: VendorColors.textMain,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _isGeocodingAddress
                                        ? 'Fetching exact GPS coordinates...'
                                        : (hasValid
                                            ? '${_latitude!.toStringAsFixed(5)}° N, ${_longitude!.toStringAsFixed(5)}° E'
                                            : 'Not captured · Select address or use GPS'),
                                    style: GoogleFonts.dmSans(
                                      color: hasValid
                                          ? VendorColors.primary
                                          : const Color(0xFFB45309),
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: hasValid
                                    ? VendorColors.liveBg
                                    : const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: hasValid
                                      ? VendorColors.liveText.withValues(alpha: 0.2)
                                      : const Color(0xFFF59E0B).withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    hasValid
                                        ? Icons.check_circle_rounded
                                        : Icons.info_outline,
                                    size: 12,
                                    color: hasValid
                                        ? VendorColors.liveText
                                        : const Color(0xFFB45309),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    hasValid ? '5 km radius' : 'Required',
                                    style: GoogleFonts.dmSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: hasValid
                                          ? VendorColors.liveText
                                          : const Color(0xFFB45309),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          hasValid
                              ? "Customers within 5 km of this exact pin will discover your store for pickups & delivery."
                              : "Accurate latitude and longitude coordinates are mandatory to enable customer discovery and delivery route calculations.",
                          style: GoogleFonts.dmSans(
                            color: VendorColors.textMuted,
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 28),

              // Operating Hours Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Operating hours',
                    style: GoogleFonts.dmSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: VendorColors.textMain,
                    ),
                  ),
                  Text(
                    'Tap to edit',
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: VendorColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              _buildHoursRow(
                day: 'Mon – Fri',
                hours: _hoursMonFri,
                onTap: () => _editHoursDialog('Mon – Fri', _hoursMonFri, (val) {
                  setState(() => _hoursMonFri = val);
                }),
              ),
              const Divider(height: 16, color: VendorColors.border),
              _buildHoursRow(
                day: 'Saturday',
                hours: _hoursSat,
                onTap: () => _editHoursDialog('Saturday', _hoursSat, (val) {
                  setState(() => _hoursSat = val);
                }),
              ),
              const Divider(height: 16, color: VendorColors.border),
              _buildHoursRow(
                day: 'Sunday',
                hours: _hoursSun,
                isClosed: _hoursSun.toLowerCase() == 'closed',
                onTap: () => _editHoursDialog('Sunday', _hoursSun, (val) {
                  setState(() => _hoursSun = val);
                }),
              ),
              const SizedBox(height: 28),

              // Standard Turnaround Time Setting
              Text(
                'STANDARD TURNAROUND TIME',
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: VendorColors.textMuted,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Displayed to customers on store cards & used for price level tier matching.',
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  color: VendorColors.textMuted,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildTurnaroundOption(1, 'Next-day (1 day)'),
                  _buildTurnaroundOption(2, '2 days (Standard)'),
                  _buildTurnaroundOption(3, '3 days'),
                  _buildTurnaroundOption(4, '4+ days'),
                ],
              ),
              const SizedBox(height: 36),

              VendorButton(
                text: isEditing
                    ? 'Save Store Profile'
                    : (vendor.stores.isEmpty ? 'Save & Set Prices' : 'Create Store Branch'),
                isLoading: _isUploadingPhoto || _isGeocodingAddress || vendor.isLoading,
                onPressed: _isUploadingPhoto || _isGeocodingAddress || isOverLimit || vendor.isLoading
                    ? null
                    : () async {
                        final storeName = _storeNameController.text.trim();
                        final address = _addressController.text.trim();

                        final vendorProvider = Provider.of<VendorProvider>(context, listen: false);
                        final scaffold = ScaffoldMessenger.of(context);
                        final navigator = Navigator.of(context);

                        if (storeName.isEmpty || address.isEmpty) {
                          scaffold.showSnackBar(
                            SnackBar(
                              content: Text(
                                'Please enter your store branch name and physical address',
                                style: GoogleFonts.dmSans(fontWeight: FontWeight.w500),
                              ),
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: const Color(0xFFEF4444),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          );
                          return;
                        }

                        // Ensure coordinates are resolved and not dummy default data
                        final hasValidCoords = await _ensureCoordinatesResolved();
                        if (!hasValidCoords || _latitude == null || _longitude == null) {
                          if (!mounted) return;
                          scaffold.showSnackBar(
                            SnackBar(
                              content: Text(
                                'GPS coordinates are required. Please select your address from the suggestions or tap "Use current location".',
                                style: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
                              ),
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: const Color(0xFFDC2626),
                              duration: const Duration(seconds: 4),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          );
                          return;
                        }

                        if (!mounted) return;

                        if (isEditing) {
                          final res = await vendorProvider.updateStoreDetails(
                            storeId: widget.store!.id,
                            name: storeName,
                            address: address,
                            lat: _latitude!,
                            lng: _longitude!,
                            photoUrl: _storePhotoUrl,
                            monFri: _hoursMonFri,
                            sat: _hoursSat,
                            sun: _hoursSun,
                            turnaroundDays: _turnaroundDays,
                          );

                          if (!mounted) return;
                          if (res['success'] == true) {
                            scaffold.showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Store profile updated successfully!',
                                  style: GoogleFonts.dmSans(fontWeight: FontWeight.w500),
                                ),
                                backgroundColor: const Color(0xFF10B981),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            );
                            navigator.pop();
                          } else {
                            scaffold.showSnackBar(
                              SnackBar(
                                content: Text(
                                  res['message']?.toString() ?? 'Failed to update store details',
                                  style: GoogleFonts.dmSans(fontWeight: FontWeight.w500),
                                ),
                                backgroundColor: const Color(0xFFEF4444),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            );
                          }
                        } else {
                          final res = await vendorProvider.createStore(
                            name: storeName,
                            address: address,
                            lat: _latitude!,
                            lng: _longitude!,
                            photoUrl: _storePhotoUrl,
                            monFri: _hoursMonFri,
                            sat: _hoursSat,
                            sun: _hoursSun,
                            turnaroundDays: _turnaroundDays,
                          );

                          if (!mounted) return;
                          if (res['success'] == true) {
                            scaffold.showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Store branch created successfully!',
                                  style: GoogleFonts.dmSans(fontWeight: FontWeight.w500),
                                ),
                                backgroundColor: const Color(0xFF10B981),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            );
                            if (vendorProvider.stores.length <= 1) {
                              navigator.pushReplacement(
                                MaterialPageRoute(
                                  builder: (context) => const VendorPricingServiceScreen(),
                                ),
                              );
                            } else {
                              navigator.pop();
                            }
                          } else {
                            scaffold.showSnackBar(
                              SnackBar(
                                content: Text(
                                  res['message']?.toString() ?? 'Failed to create store branch',
                                  style: GoogleFonts.dmSans(fontWeight: FontWeight.w500),
                                ),
                                backgroundColor: const Color(0xFFEF4444),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            );
                          }
                        }
                      },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHoursRow({
    required String day,
    required String hours,
    bool isClosed = false,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              day,
              style: GoogleFonts.dmSans(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: VendorColors.textMain,
              ),
            ),
            Row(
              children: [
                Text(
                  hours,
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isClosed ? VendorColors.urgentText : VendorColors.primary,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.chevron_right, size: 18, color: VendorColors.textMuted),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTurnaroundOption(int days, String label) {
    final isSelected = _turnaroundDays == days;
    return InkWell(
      onTap: () => setState(() => _turnaroundDays = days),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE5F7F8) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? const Color(0xFF00AABC) : VendorColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 13.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? const Color(0xFF001C1F) : VendorColors.textMain,
          ),
        ),
      ),
    );
  }
}
