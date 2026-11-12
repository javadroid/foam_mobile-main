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
  State<VendorStoreDetailsScreen> createState() =>
      _VendorStoreDetailsScreenState();
}

class _VendorStoreDetailsScreenState extends State<VendorStoreDetailsScreen> {
  late final TextEditingController _storeNameController;
  final TextEditingController _addressController = TextEditingController();

  final List<String> _daysOfWeek = const [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  late final Map<String, bool> _dayOpen;
  late final Map<String, TimeOfDay> _dayOpenTime;
  late final Map<String, TimeOfDay> _dayCloseTime;

  int _basicPercentage = 0;
  int _balancePercentage = 15;
  int _premiumPercentage = 35;
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

  TimeOfDay _parseTime(String? timeStr, TimeOfDay fallback) {
    if (timeStr == null || timeStr.trim().isEmpty) return fallback;
    try {
      final clean = timeStr.trim().toUpperCase();
      final isPm = clean.contains('PM');
      final isAm = clean.contains('AM');
      final numbers = clean.replaceAll(RegExp(r'[^0-9:]'), '');
      final parts = numbers.split(':');
      int hour = int.parse(parts[0]);
      int minute = parts.length > 1 ? int.parse(parts[1]) : 0;
      if (isPm && hour < 12) hour += 12;
      if (isAm && hour == 12) hour = 0;
      return TimeOfDay(hour: hour, minute: minute);
    } catch (_) {
      return fallback;
    }
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  @override
  void initState() {
    super.initState();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final vendor = Provider.of<VendorProvider>(context, listen: false);
    final currentStore = widget.store;

    _dayOpen = {
      for (final day in _daysOfWeek) day: day != 'Sunday',
    };
    _dayOpenTime = {
      for (final day in _daysOfWeek) day: const TimeOfDay(hour: 8, minute: 0),
    };
    _dayCloseTime = {
      for (final day in _daysOfWeek)
        day: (day == 'Saturday' || day == 'Sunday')
            ? const TimeOfDay(hour: 17, minute: 0)
            : const TimeOfDay(hour: 18, minute: 0),
    };

    String initialName = '';
    if (currentStore != null) {
      initialName = currentStore.name;
      if (currentStore.address.isNotEmpty &&
          currentStore.address != 'No address set') {
        _addressController.text = currentStore.address;
        _lastSelectedAddress = currentStore.address;
      }

      final bool hasValidExistingCoords = currentStore.latitude != null &&
          currentStore.longitude != null &&
          currentStore.latitude != 0.0 &&
          currentStore.longitude != 0.0 &&
          !(currentStore.latitude == 6.4474 &&
              currentStore.longitude == 3.4723);

      if (hasValidExistingCoords) {
        _latitude = currentStore.latitude;
        _longitude = currentStore.longitude;
      } else {
        _latitude = null;
        _longitude = null;
      }

      _storePhotoUrl = currentStore.photoUrl;
      _turnaroundDays = currentStore.turnaroundDays;
      _basicPercentage = currentStore.basicPercentage.round();
      _balancePercentage = currentStore.balancePercentage.round();
      _premiumPercentage = currentStore.premiumPercentage.round();

      if (currentStore.operatingHoursMap != null) {
        final map = currentStore.operatingHoursMap!;
        for (final day in _daysOfWeek) {
          final dayKey = day.toLowerCase();
          if (map[dayKey] is Map) {
            final dayData = map[dayKey] as Map;
            _dayOpen[day] = dayData['isOpen'] == true;
            _dayOpenTime[day] =
                _parseTime(dayData['open']?.toString(), _dayOpenTime[day]!);
            _dayCloseTime[day] =
                _parseTime(dayData['close']?.toString(), _dayCloseTime[day]!);
          }
        }
      } else {
        if (currentStore.hoursSat.toLowerCase() == 'closed') {
          _dayOpen['Saturday'] = false;
        }
        if (currentStore.hoursSun.toLowerCase() == 'closed') {
          _dayOpen['Sunday'] = false;
        }
      }
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
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
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
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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

  Future<void> _pickAndUploadPhoto(
    ImageSource source, {
    bool updateProfileAcrossAllStores = false,
  }) async {
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

        if (updateProfileAcrossAllStores && url != null) {
          final auth = Provider.of<AuthProvider>(context, listen: false);
          final vendor = Provider.of<VendorProvider>(context, listen: false);
          auth.updateAvatarUrl(url);
          await vendor.updateVendorProfileImage(url);
        }

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              updateProfileAcrossAllStores
                  ? 'Business profile image updated across all branches!'
                  : (url != null
                      ? 'Branch photo uploaded successfully'
                      : 'Photo attached locally'),
              style: GoogleFonts.dmSans(fontWeight: FontWeight.w500),
            ),
            backgroundColor:
                url != null ? const Color(0xFF10B981) : Colors.black87,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error uploading photo: $e');
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

  void _showPhotoOptions({bool isBrandUpdateOnly = false}) {
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isBrandUpdateOnly
                          ? 'Update Business Profile Photo'
                          : (_storePhotoUrl != null || _localPhotoFile != null
                              ? 'Change Branch Photo'
                              : 'Upload Store Photo'),
                      style: GoogleFonts.dmSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: VendorColors.textMain,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isBrandUpdateOnly
                          ? 'This photo is displayed across all branches on Foam.'
                          : 'You can set a photo for this branch or update your brand profile photo.',
                      style: GoogleFonts.dmSans(
                        fontSize: 12.5,
                        color: VendorColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(),
              if (isBrandUpdateOnly) ...[
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined,
                      color: VendorColors.primary),
                  title: Text(
                    'Choose Brand Photo from Gallery',
                    style: GoogleFonts.dmSans(
                        fontWeight: FontWeight.w600,
                        color: VendorColors.textMain),
                  ),
                  subtitle: Text('Applies across all store branches',
                      style: GoogleFonts.dmSans(fontSize: 11.5)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickAndUploadPhoto(ImageSource.gallery,
                        updateProfileAcrossAllStores: true);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt_outlined,
                      color: VendorColors.primary),
                  title: Text(
                    'Take Brand Photo with Camera',
                    style: GoogleFonts.dmSans(
                        fontWeight: FontWeight.w600,
                        color: VendorColors.textMain),
                  ),
                  subtitle: Text('Applies across all store branches',
                      style: GoogleFonts.dmSans(fontSize: 11.5)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickAndUploadPhoto(ImageSource.camera,
                        updateProfileAcrossAllStores: true);
                  },
                ),
              ] else ...[
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined,
                      color: VendorColors.primary),
                  title: Text(
                    'Choose Branch Photo from Gallery',
                    style: GoogleFonts.dmSans(
                        fontWeight: FontWeight.w600,
                        color: VendorColors.textMain),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickAndUploadPhoto(ImageSource.gallery,
                        updateProfileAcrossAllStores: false);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt_outlined,
                      color: VendorColors.primary),
                  title: Text(
                    'Take Branch Photo with Camera',
                    style: GoogleFonts.dmSans(
                        fontWeight: FontWeight.w600,
                        color: VendorColors.textMain),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickAndUploadPhoto(ImageSource.camera,
                        updateProfileAcrossAllStores: false);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.business, color: Color(0xFF0284C7)),
                  title: Text(
                    'Update Brand Profile Photo (All Branches)',
                    style: GoogleFonts.dmSans(
                        fontWeight: FontWeight.w600, color: Color(0xFF0284C7)),
                  ),
                  subtitle: Text('Replaces profile photo across every branch',
                      style: GoogleFonts.dmSans(fontSize: 11.5)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showPhotoOptions(isBrandUpdateOnly: true);
                  },
                ),
                if (_storePhotoUrl != null)
                  ListTile(
                    leading:
                        const Icon(Icons.restore, color: Color(0xFF0F766E)),
                    title: Text(
                      'Use Brand Profile Photo',
                      style: GoogleFonts.dmSans(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0F766E)),
                    ),
                    subtitle: Text(
                        'Remove branch photo and use business brand photo',
                        style: GoogleFonts.dmSans(fontSize: 11.5)),
                    onTap: () {
                      Navigator.pop(ctx);
                      setState(() {
                        _storePhotoUrl = null;
                        _localPhotoFile = null;
                      });
                    },
                  ),
                if (_storePhotoUrl != null || _localPhotoFile != null)
                  ListTile(
                    leading: const Icon(Icons.delete_outline,
                        color: Colors.redAccent),
                    title: Text(
                      'Remove Photo',
                      style: GoogleFonts.dmSans(
                          fontWeight: FontWeight.w600, color: Colors.redAccent),
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
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectDayTime(String day, bool isOpenTime) async {
    final initial = isOpenTime ? _dayOpenTime[day]! : _dayCloseTime[day]!;
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      helpText:
          isOpenTime ? 'Select $day Opening Time' : 'Select $day Closing Time',
    );
    if (picked != null) {
      setState(() {
        if (isOpenTime) {
          _dayOpenTime[day] = picked;
        } else {
          _dayCloseTime[day] = picked;
        }
      });
    }
  }

  void _editPackagePercentageDialog({
    required String packageName,
    required int currentVal,
    required ValueChanged<int> onSave,
  }) {
    int tempVal = currentVal;
    final controller = TextEditingController(text: currentVal.toString());

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: Text(
                '$packageName Speed Markup',
                style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.w700, fontSize: 17),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Specify the % surcharge added to the price of an item for $packageName turnaround.',
                    style: GoogleFonts.dmSans(
                        fontSize: 13, color: VendorColors.textMuted),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: () {
                          if (tempVal > 0) {
                            setDialogState(() {
                              tempVal = (tempVal - 5).clamp(0, 200);
                              controller.text = tempVal.toString();
                            });
                          }
                        },
                        icon: const Icon(Icons.remove_circle_outline),
                        color: VendorColors.primary,
                      ),
                      SizedBox(
                        width: 90,
                        child: TextField(
                          controller: controller,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.dmSans(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: VendorColors.textMain,
                          ),
                          decoration: const InputDecoration(
                            suffixText: '%',
                            border: UnderlineInputBorder(),
                          ),
                          onChanged: (val) {
                            final parsed = int.tryParse(val);
                            if (parsed != null) {
                              setDialogState(() {
                                tempVal = parsed.clamp(0, 200);
                              });
                            }
                          },
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          setDialogState(() {
                            tempVal = (tempVal + 5).clamp(0, 200);
                            controller.text = tempVal.toString();
                          });
                        },
                        icon: const Icon(Icons.add_circle_outline),
                        color: VendorColors.primary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    alignment: WrapAlignment.center,
                    children: [0, 10, 15, 20, 25, 30, 35, 40, 50].map((preset) {
                      return ActionChip(
                        label: Text('+$preset%'),
                        labelStyle: GoogleFonts.dmSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: tempVal == preset
                              ? VendorColors.primary
                              : VendorColors.textMain,
                        ),
                        backgroundColor: tempVal == preset
                            ? const Color(0xFFE5F7F8)
                            : Colors.white,
                        onPressed: () {
                          setDialogState(() {
                            tempVal = preset;
                            controller.text = preset.toString();
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('Cancel',
                      style: GoogleFonts.dmSans(color: VendorColors.textMuted)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: VendorColors.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    onSave(tempVal);
                    Navigator.pop(ctx);
                  },
                  child: Text('Save %',
                      style: GoogleFonts.dmSans(
                          color: Colors.white, fontWeight: FontWeight.w700)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildSpeedPackageCard({
    required String packageName,
    required String badgeText,
    required Color badgeColor,
    required String daysLabel,
    required int percentage,
    required String description,
    required VoidCallback onEditPercentage,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: VendorColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    Text(
                      packageName,
                      style: GoogleFonts.dmSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: VendorColors.textMain,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        badgeText,
                        style: GoogleFonts.dmSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: badgeColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: onEditPercentage,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5F7F8),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: VendorColors.primary.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        percentage == 0 ? '0% added' : '+$percentage% added',
                        style: GoogleFonts.dmSans(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: VendorColors.primary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.edit_outlined,
                          size: 13, color: VendorColors.primary),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.schedule,
                  size: 14, color: VendorColors.textMuted),
              const SizedBox(width: 4),
              Text(
                daysLabel,
                style: GoogleFonts.dmSans(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: VendorColors.textMain,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: GoogleFonts.dmSans(
              fontSize: 12,
              color: VendorColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final vendor = Provider.of<VendorProvider>(context);
    final profileImg = auth.avatarUrl.isNotEmpty
        ? auth.avatarUrl
        : (vendor.vendorAvatarUrl ?? '');
    final String? displayPhotoUrl =
        _storePhotoUrl ?? (profileImg.isNotEmpty ? profileImg : null);
    final bool hasPhoto = _localPhotoFile != null || displayPhotoUrl != null;
    final bool isUsingBrandPhoto =
        _storePhotoUrl == null && profileImg.isNotEmpty;
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
          isEditing ? 'Edit Store Branch' : 'Add Store Branch',
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
                      const Icon(Icons.warning_amber_rounded,
                          color: Color(0xFFDC2626)),
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

              // Store Photo Section Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Store photo',
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: VendorColors.textMain,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(50, 30),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    icon: const Icon(Icons.account_circle_outlined,
                        size: 15, color: VendorColors.primary),
                    label: Text(
                      'Update Brand Photo',
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: VendorColors.primary,
                      ),
                    ),
                    onPressed: _isUploadingPhoto
                        ? null
                        : () => _showPhotoOptions(isBrandUpdateOnly: true),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                'Uses your business brand photo across all branches by default, or you can set a branch photo.',
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  color: VendorColors.textMuted,
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _isUploadingPhoto
                    ? null
                    : () => _showPhotoOptions(isBrandUpdateOnly: false),
                child: Container(
                  height: 160,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: VendorColors.lightBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color:
                          hasPhoto ? VendorColors.primary : VendorColors.border,
                      width: hasPhoto ? 1.6 : 1.2,
                    ),
                    image: _localPhotoFile != null
                        ? DecorationImage(
                            image: FileImage(_localPhotoFile!),
                            fit: BoxFit.cover,
                          )
                        : (displayPhotoUrl != null
                            ? DecorationImage(
                                image: NetworkImage(displayPhotoUrl),
                                fit: BoxFit.cover,
                              )
                            : null),
                  ),
                  child: Stack(
                    children: [
                      if (hasPhoto) ...[
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
                        if (isUsingBrandPhoto)
                          Positioned(
                            top: 10,
                            left: 10,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.7),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: VendorColors.primary
                                        .withValues(alpha: 0.4)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.verified,
                                      size: 12, color: Color(0xFF00AABC)),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Brand Profile Photo',
                                    style: GoogleFonts.dmSans(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
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
                                      color:
                                          Colors.black.withValues(alpha: 0.55),
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
                                          color: VendorColors.primary
                                              .withValues(alpha: 0.1),
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
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Physical Address & Location Suggestions Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Physical address',
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: VendorColors.textMain,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap:
                        _isDetectingLocation ? null : _handleAutoDetectLocation,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
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
                          _isDetectingLocation
                              ? 'Locating...'
                              : 'Use current location',
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
                    hintStyle:
                        GoogleFonts.dmSans(color: VendorColors.textMuted),
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
                                icon: const Icon(Icons.close_rounded,
                                    size: 18, color: Color(0xFF94A3B8)),
                                onPressed: () {
                                  _addressController.clear();
                                  setState(() {
                                    _addressSuggestions = [];
                                  });
                                },
                              )
                            : null),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                  ),
                ),
              ),

              // Suggestions Dropdown Card
              if (_addressSuggestions.isNotEmpty ||
                  _isSearchingSuggestions) ...[
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14.0, vertical: 10.0),
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
                                  _isSearchingSuggestions &&
                                          _addressSuggestions.isEmpty
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
                              child: const Icon(Icons.close_rounded,
                                  size: 16, color: Color(0xFF94A3B8)),
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
                          separatorBuilder: (_, __) => const Divider(
                              height: 1, color: Color(0xFFF1F5F9)),
                          itemBuilder: (BuildContext context, int index) {
                            final AddressSuggestion suggestion =
                                _addressSuggestions[index];
                            return ListTile(
                              dense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14.0, vertical: 4.0),
                              leading: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: VendorColors.primary
                                      .withValues(alpha: 0.1),
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

              // Compact Geocoded Coordinates Card
              Builder(
                builder: (context) {
                  final bool hasValid = _latitude != null &&
                      _longitude != null &&
                      _latitude != 0.0 &&
                      _longitude != 0.0 &&
                      !(_latitude == 6.4474 && _longitude == 3.4723);

                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                    decoration: BoxDecoration(
                      color: hasValid
                          ? const Color(0xFFE5F7F8)
                          : const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: hasValid
                            ? VendorColors.primary.withValues(alpha: 0.25)
                            : const Color(0xFFFDE68A),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: hasValid
                                ? VendorColors.primary
                                : const Color(0xFFF59E0B),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: _isGeocodingAddress
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Icon(
                                  hasValid
                                      ? Icons.location_on_rounded
                                      : Icons.location_off_outlined,
                                  color: Colors.white,
                                  size: 17,
                                ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                hasValid
                                    ? 'Branch Location Pinned'
                                    : 'Coordinates Required',
                                style: GoogleFonts.dmSans(
                                  color: VendorColors.textMain,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12.5,
                                ),
                              ),
                              Text(
                                _isGeocodingAddress
                                    ? 'Fetching GPS coordinates...'
                                    : (hasValid
                                        ? '${_latitude!.toStringAsFixed(4)}° N, ${_longitude!.toStringAsFixed(4)}° E'
                                        : 'Select address or use GPS'),
                                style: GoogleFonts.dmSans(
                                  color: hasValid
                                      ? VendorColors.primary
                                      : const Color(0xFFB45309),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: hasValid
                                ? VendorColors.liveBg
                                : const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: hasValid
                                  ? VendorColors.liveText.withValues(alpha: 0.2)
                                  : const Color(0xFFF59E0B)
                                      .withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                hasValid
                                    ? Icons.check_circle_rounded
                                    : Icons.info_outline,
                                size: 11,
                                color: hasValid
                                    ? VendorColors.liveText
                                    : const Color(0xFFB45309),
                              ),
                              const SizedBox(width: 3),
                              Text(
                                hasValid ? '5 km radius' : 'Required',
                                style: GoogleFonts.dmSans(
                                  fontSize: 10.5,
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
                  );
                },
              ),

              const SizedBox(height: 28),

              // Operating Hours Section (Monday to Sunday)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
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
                          'Select open days and working times',
                          style: GoogleFonts.dmSans(
                            fontSize: 12,
                            color: VendorColors.textMuted,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  PopupMenuButton<String>(
                    tooltip: 'Quick apply hours',
                    onSelected: (val) {
                      setState(() {
                        final open = _dayOpenTime['Monday']!;
                        final close = _dayCloseTime['Monday']!;
                        if (val == 'all') {
                          for (final day in _daysOfWeek) {
                            _dayOpen[day] = true;
                            _dayOpenTime[day] = open;
                            _dayCloseTime[day] = close;
                          }
                        } else if (val == 'weekdays') {
                          for (final day in [
                            'Monday',
                            'Tuesday',
                            'Wednesday',
                            'Thursday',
                            'Friday'
                          ]) {
                            _dayOpen[day] = true;
                            _dayOpenTime[day] = open;
                            _dayCloseTime[day] = close;
                          }
                        }
                      });
                    },
                    itemBuilder: (ctx) => [
                      const PopupMenuItem(
                        value: 'weekdays',
                        child: Text('Copy Monday hours to Mon–Fri'),
                      ),
                      const PopupMenuItem(
                        value: 'all',
                        child: Text('Copy Monday hours to all 7 days'),
                      ),
                    ],
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5F7F8),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.copy_rounded,
                              size: 13, color: VendorColors.primary),
                          const SizedBox(width: 4),
                          Text(
                            'Quick copy',
                            style: GoogleFonts.dmSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: VendorColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: VendorColors.border),
                ),
                child: Column(
                  children: _daysOfWeek.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final day = entry.value;
                    final isOpen = _dayOpen[day] ?? false;
                    final openTime = _dayOpenTime[day]!;
                    final closeTime = _dayCloseTime[day]!;

                    return Column(
                      children: [
                        if (idx > 0)
                          const Divider(height: 1, color: VendorColors.border),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 7),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 74,
                                child: Text(
                                  day,
                                  style: GoogleFonts.dmSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: isOpen
                                        ? VendorColors.textMain
                                        : VendorColors.textMuted,
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 38,
                                height: 24,
                                child: FittedBox(
                                  fit: BoxFit.contain,
                                  child: Switch(
                                    value: isOpen,
                                    activeColor: VendorColors.primary,
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    onChanged: (val) {
                                      setState(() {
                                        _dayOpen[day] = val;
                                      });
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: isOpen
                                    ? FittedBox(
                                        fit: BoxFit.scaleDown,
                                        alignment: Alignment.centerRight,
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: [
                                            InkWell(
                                              onTap: () =>
                                                  _selectDayTime(day, true),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 7,
                                                        vertical: 4),
                                                decoration: BoxDecoration(
                                                  color:
                                                      const Color(0xFFF1F5F9),
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                  border: Border.all(
                                                      color: const Color(
                                                          0xFFCBD5E1)),
                                                ),
                                                child: Text(
                                                  _formatTimeOfDay(openTime),
                                                  style: GoogleFonts.dmSans(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                    color:
                                                        VendorColors.textMain,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 3),
                                              child: Text('–',
                                                  style: GoogleFonts.dmSans(
                                                      color: VendorColors
                                                          .textMuted,
                                                      fontWeight:
                                                          FontWeight.bold)),
                                            ),
                                            InkWell(
                                              onTap: () =>
                                                  _selectDayTime(day, false),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 7,
                                                        vertical: 4),
                                                decoration: BoxDecoration(
                                                  color:
                                                      const Color(0xFFF1F5F9),
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                  border: Border.all(
                                                      color: const Color(
                                                          0xFFCBD5E1)),
                                                ),
                                                child: Text(
                                                  _formatTimeOfDay(closeTime),
                                                  style: GoogleFonts.dmSans(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                    color:
                                                        VendorColors.textMain,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    : Align(
                                        alignment: Alignment.centerRight,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF1F5F9),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            'Closed',
                                            style: GoogleFonts.dmSans(
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w600,
                                              color: VendorColors.textMuted,
                                            ),
                                          ),
                                        ),
                                      ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 28),

              // Turnaround Speed Packages Section
              Text(
                'TURNAROUND SPEED PACKAGES',
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: VendorColors.textMuted,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Set the turnaround packages for your branch. Set the surcharge % added to each item price.',
                style: GoogleFonts.dmSans(
                  fontSize: 12.5,
                  color: VendorColors.textMuted,
                ),
              ),
              const SizedBox(height: 12),

              _buildSpeedPackageCard(
                packageName: 'Basic',
                badgeText: 'STANDARD',
                badgeColor: const Color(0xFF10B981),
                daysLabel: '3 days turnaround',
                percentage: _basicPercentage,
                description: 'Standard turnaround. Base item price is charged.',
                onEditPercentage: () => _editPackagePercentageDialog(
                  packageName: 'Basic',
                  currentVal: _basicPercentage,
                  onSave: (val) => setState(() => _basicPercentage = val),
                ),
              ),
              const SizedBox(height: 10),

              _buildSpeedPackageCard(
                packageName: 'Balance',
                badgeText: 'RECOMMENDED',
                badgeColor: const Color(0xFF00AABC),
                daysLabel: '2 days turnaround',
                percentage: _balancePercentage,
                description:
                    'Faster 2-day turnaround with custom speed markup.',
                onEditPercentage: () => _editPackagePercentageDialog(
                  packageName: 'Balance',
                  currentVal: _balancePercentage,
                  onSave: (val) => setState(() => _balancePercentage = val),
                ),
              ),
              const SizedBox(height: 10),

              _buildSpeedPackageCard(
                packageName: 'Premium',
                badgeText: 'EXPRESS RUSH',
                badgeColor: const Color(0xFF8B5CF6),
                daysLabel: '1 day / 24h express',
                percentage: _premiumPercentage,
                description:
                    'Priority same-day/24h turnaround for urgent orders.',
                onEditPercentage: () => _editPackagePercentageDialog(
                  packageName: 'Premium',
                  currentVal: _premiumPercentage,
                  onSave: (val) => setState(() => _premiumPercentage = val),
                ),
              ),

              const SizedBox(height: 12),

              // Live example calculation preview
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calculate_outlined,
                        size: 16, color: VendorColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '₦1,000 item → ₦${1000 + (1000 * _basicPercentage ~/ 100)} (Basic) · ₦${1000 + (1000 * _balancePercentage ~/ 100)} (Balance) · ₦${1000 + (1000 * _premiumPercentage ~/ 100)} (Premium)',
                        style: GoogleFonts.dmSans(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: VendorColors.textMain,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 36),

              VendorButton(
                text: isEditing
                    ? 'Save Branch Details'
                    : (vendor.stores.isEmpty
                        ? 'Save & Set Prices'
                        : 'Create Store Branch'),
                isLoading: _isUploadingPhoto ||
                    _isGeocodingAddress ||
                    vendor.isLoading,
                onPressed: _isUploadingPhoto ||
                        _isGeocodingAddress ||
                        isOverLimit ||
                        vendor.isLoading
                    ? null
                    : () async {
                        final storeName = _storeNameController.text.trim();
                        final address = _addressController.text.trim();

                        final vendorProvider =
                            Provider.of<VendorProvider>(context, listen: false);
                        final scaffold = ScaffoldMessenger.of(context);
                        final navigator = Navigator.of(context);

                        if (storeName.isEmpty || address.isEmpty) {
                          scaffold.showSnackBar(
                            SnackBar(
                              content: Text(
                                'Please enter your store branch name and physical address',
                                style: GoogleFonts.dmSans(
                                    fontWeight: FontWeight.w500),
                              ),
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: const Color(0xFFEF4444),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                          );
                          return;
                        }

                        // Ensure coordinates are resolved and not dummy default data
                        final hasValidCoords =
                            await _ensureCoordinatesResolved();
                        if (!hasValidCoords ||
                            _latitude == null ||
                            _longitude == null) {
                          if (!mounted) return;
                          scaffold.showSnackBar(
                            SnackBar(
                              content: Text(
                                'GPS coordinates are required. Please select your address from the suggestions or tap "Use current location".',
                                style: GoogleFonts.dmSans(
                                    fontWeight: FontWeight.w600),
                              ),
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: const Color(0xFFDC2626),
                              duration: const Duration(seconds: 4),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                          );
                          return;
                        }

                        if (!mounted) return;

                        final operatingHoursData = <String, dynamic>{
                          for (final day in _daysOfWeek)
                            day.toLowerCase(): {
                              'isOpen': _dayOpen[day] ?? false,
                              'open': _formatTimeOfDay(_dayOpenTime[day]!),
                              'close': _formatTimeOfDay(_dayCloseTime[day]!),
                            },
                          'monFri': _dayOpen['Monday'] == true
                              ? '${_formatTimeOfDay(_dayOpenTime['Monday']!)} – ${_formatTimeOfDay(_dayCloseTime['Monday']!)}'
                              : 'Closed',
                          'sat': _dayOpen['Saturday'] == true
                              ? '${_formatTimeOfDay(_dayOpenTime['Saturday']!)} – ${_formatTimeOfDay(_dayCloseTime['Saturday']!)}'
                              : 'Closed',
                          'sun': _dayOpen['Sunday'] == true
                              ? '${_formatTimeOfDay(_dayOpenTime['Sunday']!)} – ${_formatTimeOfDay(_dayCloseTime['Sunday']!)}'
                              : 'Closed',
                        };

                        final turnaroundOptionsData = <Map<String, dynamic>>[
                          {
                            'package': 'BASIC',
                            'name': 'Basic',
                            'days': 3,
                            'percentage': _basicPercentage,
                            'description': 'Standard 3-day turnaround',
                          },
                          {
                            'package': 'BALANCE',
                            'name': 'Balance',
                            'days': 2,
                            'percentage': _balancePercentage,
                            'description': 'Balanced 2-day turnaround',
                          },
                          {
                            'package': 'PREMIUM',
                            'name': 'Premium',
                            'days': 1,
                            'percentage': _premiumPercentage,
                            'description': 'Priority 24h express turnaround',
                          },
                        ];

                        if (isEditing) {
                          final res = await vendorProvider.updateStoreDetails(
                            storeId: widget.store!.id,
                            name: storeName,
                            address: address,
                            lat: _latitude!,
                            lng: _longitude!,
                            photoUrl: _storePhotoUrl,
                            turnaroundDays: 2,
                            operatingHours: operatingHoursData,
                            turnaroundOptions: turnaroundOptionsData,
                          );

                          if (!mounted) return;
                          if (res['success'] == true) {
                            scaffold.showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Store branch updated successfully!',
                                  style: GoogleFonts.dmSans(
                                      fontWeight: FontWeight.w500),
                                ),
                                backgroundColor: const Color(0xFF10B981),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                              ),
                            );
                            navigator.pop();
                          } else {
                            scaffold.showSnackBar(
                              SnackBar(
                                content: Text(
                                  res['message']?.toString() ??
                                      'Failed to update store branch',
                                  style: GoogleFonts.dmSans(
                                      fontWeight: FontWeight.w500),
                                ),
                                backgroundColor: const Color(0xFFEF4444),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
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
                            turnaroundDays: 2,
                            operatingHours: operatingHoursData,
                            turnaroundOptions: turnaroundOptionsData,
                          );

                          if (!mounted) return;
                          if (res['success'] == true) {
                            scaffold.showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Store branch created successfully!',
                                  style: GoogleFonts.dmSans(
                                      fontWeight: FontWeight.w500),
                                ),
                                backgroundColor: const Color(0xFF10B981),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                              ),
                            );
                            if (vendorProvider.stores.length <= 1) {
                              navigator.pushReplacement(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const VendorPricingServiceScreen(),
                                ),
                              );
                            } else {
                              navigator.pop();
                            }
                          } else {
                            scaffold.showSnackBar(
                              SnackBar(
                                content: Text(
                                  res['message']?.toString() ??
                                      'Failed to create store branch',
                                  style: GoogleFonts.dmSans(
                                      fontWeight: FontWeight.w500),
                                ),
                                backgroundColor: const Color(0xFFEF4444),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
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
}
