import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:foam_mobile/core/hive/hive.dart';
import 'package:foam_mobile/core/services/location_service.dart';
import 'package:foam_mobile/feature/authentication/controller/provider/authprovider.dart';
import 'package:foam_mobile/utils/values.dart';
import 'package:foam_mobile/widgets/my_text_field.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

class CustomerAddressScreen extends StatefulWidget {
  const CustomerAddressScreen({super.key});

  static const String id = '/customer-pickup-address';

  @override
  State<CustomerAddressScreen> createState() => _CustomerAddressScreenState();
}

class _CustomerAddressScreenState extends State<CustomerAddressScreen> {
  final TextEditingController addressController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController stateController = TextEditingController();
  final TextEditingController lgaController = TextEditingController();
  final TextEditingController instructionController = TextEditingController();
  final FocusNode addressFocusNode = FocusNode();

  double? latitude;
  double? longitude;

  bool isSaving = false;
  bool isDetectingLocation = false;

  Timer? _debounceTimer;
  List<AddressSuggestion> _addressSuggestions = <AddressSuggestion>[];
  bool _isSearchingSuggestions = false;
  bool _isAddressSelected = false;

  @override
  void initState() {
    super.initState();
    addressController.addListener(_onAddressChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadExistingAddress();
    });
  }

  void _loadExistingAddress() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.addressStreet.isNotEmpty) {
      addressController.text = auth.addressStreet;
    }
    if (auth.addressCity.isNotEmpty) {
      cityController.text = auth.addressCity;
    }
    if (auth.addressState.isNotEmpty) {
      stateController.text = auth.addressState;
    }
    if (auth.addressLga.isNotEmpty) {
      lgaController.text = auth.addressLga;
    }
    if (auth.addressLatitude != null && auth.addressLongitude != null) {
      setState(() {
        latitude = auth.addressLatitude;
        longitude = auth.addressLongitude;
      });
    }

    _fetchBackendAddress();
  }

  Future<void> _fetchBackendAddress() async {
    try {
      final res = await http.get(
        Uri.parse("${Constants.url}/api/user/address"),
        headers: {
          "Authorization": "Bearer ${HiveClass.getToken()}",
          "Accept": "application/json",
          "Content-Type": "application/json",
        },
      );
      if (!mounted) return;
      if (res.statusCode == 200 || res.statusCode == 201) {
        final data = json.decode(res.body);
        if (data["address"] != null && (data["address"] as List).isNotEmpty) {
          final addr = data["address"][0];
          setState(() {
            if (addressController.text.isEmpty && addr["street"] != null) {
              addressController.text = addr["street"];
            }
            if (cityController.text.isEmpty && addr["city"] != null) {
              cityController.text = addr["city"];
            }
            if (stateController.text.isEmpty && addr["state"] != null) {
              stateController.text = addr["state"];
            }
            if (lgaController.text.isEmpty && addr["lga"] != null) {
              lgaController.text = addr["lga"];
            }
            if (addr["latitude"] != null && addr["longitude"] != null) {
              latitude = double.tryParse(addr["latitude"].toString());
              longitude = double.tryParse(addr["longitude"].toString());
            }
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching backend address: $e");
    }
  }

  void _onAddressChanged() {
    final String query = addressController.text.trim();
    if (_isAddressSelected) {
      _isAddressSelected = false;
      return;
    }
    if (query.length < 3) {
      if (_addressSuggestions.isNotEmpty || _isSearchingSuggestions) {
        setState(() {
          _addressSuggestions = <AddressSuggestion>[];
          _isSearchingSuggestions = false;
        });
      }
      return;
    }

    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 350), () async {
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
    setState(() {
      _isAddressSelected = true;
      addressController.text = suggestion.title;
      if (suggestion.details.city.isNotEmpty) {
        cityController.text = suggestion.details.city;
      }
      if (suggestion.details.state.isNotEmpty) {
        stateController.text = suggestion.details.state;
      }
      if (suggestion.details.lga.isNotEmpty) {
        lgaController.text = suggestion.details.lga;
      }
      if (suggestion.details.latitude != 0.0) {
        latitude = suggestion.details.latitude;
        longitude = suggestion.details.longitude;
      }
      _addressSuggestions = <AddressSuggestion>[];
      _isSearchingSuggestions = false;
    });
    FocusScope.of(context).unfocus();

    if (suggestion.details.latitude == 0.0) {
      final resolved =
          await LocationService.resolveSuggestionDetails(suggestion);
      if (mounted && resolved.latitude != 0.0) {
        setState(() {
          latitude = resolved.latitude;
          longitude = resolved.longitude;
        });
      }
    }
  }

  void _showLocationPermissionModal({String? message}) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24.0),
          ),
          elevation: 10,
          backgroundColor: Colors.white,
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 22.0, vertical: 24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppColors.primaryAccentColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.location_off_rounded,
                    color: AppColors.primaryAccentColor,
                    size: 30,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Location Access Needed',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.dmSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  message ??
                      'We could not automatically detect your location. Please check your device location settings or enter your address manually below.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.dmSans(
                    fontSize: 13.5,
                    color: const Color(0xFF64748B),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryAccentColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () async {
                      Navigator.pop(dialogContext);
                      await LocationService.openAppSettings();
                    },
                    icon: const Icon(Icons.settings_rounded, size: 18),
                    label: Text(
                      'Open Settings',
                      style: GoogleFonts.dmSans(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF475569),
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(dialogContext);
                      addressFocusNode.requestFocus();
                    },
                    child: Text(
                      'Enter Manually',
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleAutoDetectLocation() async {
    setState(() {
      isDetectingLocation = true;
    });

    try {
      final details = await LocationService.autoDetectLocation();
      if (details != null) {
        final street = details.street.isNotEmpty
            ? details.street
            : (details.formattedAddress.isNotEmpty
                ? details.formattedAddress
                : '${details.city}, ${details.state}');
        final city = details.city.isNotEmpty ? details.city : 'Port Harcourt';
        final state = details.state.isNotEmpty ? details.state : 'Rivers State';
        final lga = details.lga.isNotEmpty ? details.lga : city;

        setState(() {
          _isAddressSelected = true;
          _addressSuggestions = <AddressSuggestion>[];
          _isSearchingSuggestions = false;

          addressController.text = street;
          cityController.text = city;
          stateController.text = state;
          lgaController.text = lga;

          latitude = details.latitude;
          longitude = details.longitude;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Location detected: $city, $state',
                style: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
              ),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      } else {
        _showLocationPermissionModal();
      }
    } catch (e) {
      _showLocationPermissionModal(
        message:
            'Could not access device location ($e). Please grant location permission in settings or enter your address manually.',
      );
    } finally {
      if (mounted) {
        setState(() {
          isDetectingLocation = false;
        });
      }
    }
  }

  Future<void> _saveAddress() async {
    final street = addressController.text.trim();
    final city = cityController.text.trim();
    final state = stateController.text.trim();
    final lga = lgaController.text.trim();
    final instructions = instructionController.text.trim();

    if (street.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your street address or landmark'),
          backgroundColor: Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (city.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your city'),
          backgroundColor: Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => isSaving = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);

    try {
      final res = await http.post(
        Uri.parse("${Constants.url}/api/user/address"),
        headers: {
          "Authorization": "Bearer ${HiveClass.getToken()}",
          "Accept": "application/json",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "street": street,
          "city": city,
          "state": state.isNotEmpty ? state : null,
          "lga": lga.isNotEmpty ? lga : null,
          "postalCode": instructions,
          "country": "Nigeria",
          "latitude": latitude ?? 0,
          "longitude": longitude ?? 0,
        }),
      );

      final data = json.decode(res.body);

      if (res.statusCode == 200 || res.statusCode == 201) {
        auth.fillAddress(
          street,
          city,
          instructions,
          "Nigeria",
          state: state,
          lga: lga,
          latitude: latitude,
          longitude: longitude,
        );

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              data["message"] ?? 'Pickup address updated successfully!',
              style: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        Navigator.pop(context, true);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              data["error"] ?? 'Could not save address. Please try again.',
              style: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
            ),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Network error: $e',
            style: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
          ),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => isSaving = false);
      }
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    addressController.removeListener(_onAddressChanged);
    addressFocusNode.dispose();
    addressController.dispose();
    cityController.dispose();
    stateController.dispose();
    lgaController.dispose();
    instructionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF0F172A),
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Pickup Address',
          style: GoogleFonts.dmSans(
            color: const Color(0xFF0F172A),
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 8.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Subheader
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Delivery & Pickup Address ',
                          style: GoogleFonts.dmSans(
                            color: const Color(0xFF0F172A),
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Update where your laundry will be picked up and delivered by our riders.',
                          style: GoogleFonts.dmSans(
                            color: const Color(0xFF64748B),
                            fontSize: 13.5,
                            fontWeight: FontWeight.w400,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Compact "Use Current Location" Button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18.0),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: isDetectingLocation
                            ? null
                            : _handleAutoDetectLocation,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          height: 44,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: AppColors.primaryAccentColor
                                .withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.primaryAccentColor
                                  .withValues(alpha: 0.28),
                              width: 1.2,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isDetectingLocation) ...[
                                SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      AppColors.primaryAccentColor,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ] else ...[
                                Icon(
                                  Icons.my_location_rounded,
                                  color: AppColors.primaryAccentColor,
                                  size: 17,
                                ),
                                const SizedBox(width: 6),
                              ],
                              Flexible(
                                child: Text(
                                  isDetectingLocation
                                      ? 'Detecting location...'
                                      : 'Use Current Location',
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.dmSans(
                                    color: AppColors.primaryAccentColor,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Divider
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 22.0),
                    child: Row(
                      children: [
                        const Expanded(
                            child: Divider(color: Color(0xFFE2E8F0))),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0),
                          child: Text(
                            'OR SEARCH ADDRESS',
                            style: GoogleFonts.dmSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF94A3B8),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const Expanded(
                            child: Divider(color: Color(0xFFE2E8F0))),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Street Address with Autocomplete
                  MyTextField(
                    controller: addressController,
                    focusNode: addressFocusNode,
                    labelText: 'Street Address / Landmark',
                    hinText: 'Type an address or landmark...',
                    textInputAction: TextInputAction.next,
                    obscureText: false,
                    isPassword: false,
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: Color(0xFF94A3B8),
                      size: 20,
                    ),
                  ),

                  // Live search loading indicator
                  if (_isSearchingSuggestions) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 22.0, vertical: 4.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          minHeight: 2,
                          backgroundColor: const Color(0xFFE2E8F0),
                          valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.primaryAccentColor),
                        ),
                      ),
                    ),
                  ],

                  // Suggestions Dropdown Card
                  if (_addressSuggestions.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18.0, vertical: 6.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 14,
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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Suggested Locations',
                                    style: GoogleFonts.dmSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF64748B),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _addressSuggestions =
                                            <AddressSuggestion>[];
                                      });
                                    },
                                    child: const Icon(Icons.close_rounded,
                                        size: 16, color: Color(0xFF94A3B8)),
                                  ),
                                ],
                              ),
                            ),
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
                                      horizontal: 14.0, vertical: 2.0),
                                  leading: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryAccentColor
                                          .withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.location_on_rounded,
                                      size: 16,
                                      color: AppColors.primaryAccentColor,
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
                                  subtitle: Text(
                                    suggestion.subtitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.dmSans(
                                      fontSize: 12,
                                      color: const Color(0xFF64748B),
                                    ),
                                  ),
                                  onTap: () => _selectSuggestion(suggestion),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),

                  // City & LGA Row
                  Row(
                    children: [
                      Expanded(
                        child: MyTextField(
                          controller: cityController,
                          labelText: 'City',
                          hinText: 'Port Harcourt',
                          textInputAction: TextInputAction.next,
                          obscureText: false,
                          isPassword: false,
                          padding: const EdgeInsets.only(left: 18, right: 6),
                          prefixIcon: const Icon(
                            Icons.location_city_rounded,
                            color: Color(0xFF94A3B8),
                            size: 20,
                          ),
                        ),
                      ),
                      Expanded(
                        child: MyTextField(
                          controller: lgaController,
                          labelText: 'LGA',
                          hinText: 'Obio-Akpor',
                          textInputAction: TextInputAction.next,
                          obscureText: false,
                          isPassword: false,
                          padding: const EdgeInsets.only(left: 6, right: 18),
                          prefixIcon: const Icon(
                            Icons.map_outlined,
                            color: Color(0xFF94A3B8),
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // State
                  MyTextField(
                    controller: stateController,
                    labelText: 'State',
                    hinText: 'Rivers State',
                    textInputAction: TextInputAction.next,
                    obscureText: false,
                    isPassword: false,
                    prefixIcon: const Icon(
                      Icons.flag_outlined,
                      color: Color(0xFF94A3B8),
                      size: 20,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Special Instructions
                  MyTextField(
                    controller: instructionController,
                    labelText: 'Pickup & Delivery Notes (Optional)',
                    hinText: 'e.g. Leave with gate security, Apartment 4B',
                    textInputAction: TextInputAction.done,
                    obscureText: false,
                    isPassword: false,
                    prefixIcon: const Icon(
                      Icons.note_alt_outlined,
                      color: Color(0xFF94A3B8),
                      size: 20,
                    ),
                  ),

                  // GPS Pin Badge
                  if (latitude != null && longitude != null) ...[
                    const SizedBox(height: 14),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14.0, vertical: 10.0),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFBBF7D0)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_rounded,
                                size: 18, color: Color(0xFF16A34A)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'GPS Pin Tagged',
                                    style: GoogleFonts.dmSans(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF15803D),
                                    ),
                                  ),
                                  const SizedBox(height: 1),
                                  Text(
                                    '${latitude!.toStringAsFixed(5)}° N, ${longitude!.toStringAsFixed(5)}° E',
                                    style: GoogleFonts.dmSans(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFF166534),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 28),

                  // Save Button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18.0),
                    child: SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryAccentColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: isSaving ? null : _saveAddress,
                        child: isSaving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.2,
                                ),
                              )
                            : Text(
                                'Save Pickup Address',
                                style: GoogleFonts.dmSans(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15.5,
                                ),
                              ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40.0),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
