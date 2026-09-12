import 'dart:async';
import 'package:flutter/material.dart';
import 'package:foam_mobile/core/services/location_service.dart';
import 'package:foam_mobile/feature/authentication/model/log_out_model.dart';
import 'package:foam_mobile/feature/authentication/model/sign_up_model.dart';
import 'package:foam_mobile/utils/values.dart';
import 'package:foam_mobile/widgets/gradient_button.dart';
import 'package:foam_mobile/widgets/message_handler.dart';
import 'package:foam_mobile/widgets/my_text_field.dart';
import 'package:google_fonts/google_fonts.dart';

class SignUpPage1 extends StatefulWidget {
  const SignUpPage1({super.key});

  @override
  State<SignUpPage1> createState() => _SignUpPage1State();
}

class _SignUpPage1State extends State<SignUpPage1> {
  final GlobalKey<ScaffoldMessengerState> _scaffoldKey =
      GlobalKey<ScaffoldMessengerState>();

  final TextEditingController addressController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController stateController = TextEditingController();
  final TextEditingController lgaController = TextEditingController();
  final TextEditingController instructionController = TextEditingController();
  final FocusNode addressFocusNode = FocusNode();

  double? latitude;
  double? longitude;

  bool loading = false;
  bool isDetectingLocation = false;

  Timer? _debounceTimer;
  List<AddressSuggestion> _addressSuggestions = <AddressSuggestion>[];
  bool _isSearchingSuggestions = false;
  bool _isAddressSelected = false;

  @override
  void initState() {
    super.initState();
    addressController.addListener(_onAddressChanged);
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

  void _selectSuggestion(AddressSuggestion suggestion) {
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
            padding: const EdgeInsets.symmetric(horizontal: 22.0, vertical: 24.0),
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
        setState(() {
          if (details.street.isNotEmpty) addressController.text = details.street;
          if (details.city.isNotEmpty) cityController.text = details.city;
          if (details.state.isNotEmpty) stateController.text = details.state;
          if (details.lga.isNotEmpty) lgaController.text = details.lga;
          latitude = details.latitude;
          longitude = details.longitude;
        });
        MyMessageHandler.showSnackBar(
          _scaffoldKey,
          'Location detected: ${details.city}, ${details.state}',
        );
      } else {
        _showLocationPermissionModal();
      }
    } catch (e) {
      _showLocationPermissionModal(
        message: 'Could not access device location ($e). Please grant location permission in settings or enter your address manually.',
      );
    } finally {
      if (mounted) {
        setState(() {
          isDetectingLocation = false;
        });
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
    return ScaffoldMessenger(
      key: _scaffoldKey,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0F172A), size: 20),
            onPressed: () => Navigator.maybePop(context),
          ),
          actions: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12.0),
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
              decoration: BoxDecoration(
                color: AppColors.fadeBlueAccentColor,
                borderRadius: BorderRadius.circular(20.0),
              ),
              child: Text(
                'Step 2 of 2',
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryAccentColor,
                ),
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () => LogoutClass.logOut2(context),
              child: Text(
                'Log Out',
                style: GoogleFonts.dmSans(
                  color: const Color(0xFF94A3B8),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
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
                    // Progress Bar (100%)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4.0),
                        child: LinearProgressIndicator(
                          value: 1.0,
                          backgroundColor: const Color(0xFFE2E8F0),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.primaryAccentColor,
                          ),
                          minHeight: 4,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pickup Address 📍',
                            style: GoogleFonts.dmSans(
                              color: const Color(0xFF0F172A),
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Auto-detect your location or type to search below. You can edit any field anytime.',
                            style: GoogleFonts.dmSans(
                              color: const Color(0xFF64748B),
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Hero "Use Current Location" Card
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18.0),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: isDetectingLocation ? null : _handleAutoDetectLocation,
                          borderRadius: BorderRadius.circular(18),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.fadeBlueAccentColor,
                                  Colors.white,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: AppColors.primaryAccentColor.withValues(alpha: 0.35),
                                width: 1.4,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primaryAccentColor.withValues(alpha: 0.06),
                                  blurRadius: 14,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 46,
                                  height: 46,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        AppColors.primaryAccentColor,
                                        AppColors.oceanBlueColor,
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primaryAccentColor.withValues(alpha: 0.25),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: isDetectingLocation
                                      ? const Center(
                                          child: SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.2,
                                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                            ),
                                          ),
                                        )
                                      : const Icon(
                                          Icons.my_location_rounded,
                                          color: Colors.white,
                                          size: 22,
                                        ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        isDetectingLocation
                                            ? 'Detecting your location...'
                                            : 'Use Current Location',
                                        style: GoogleFonts.dmSans(
                                          color: const Color(0xFF0F172A),
                                          fontWeight: FontWeight.w700,
                                          fontSize: 15.5,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        isDetectingLocation
                                            ? 'Getting GPS coordinates & address...'
                                            : 'Tap to auto-fill street, city, LGA & state',
                                        style: GoogleFonts.dmSans(
                                          color: const Color(0xFF64748B),
                                          fontSize: 12.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: 14,
                                  color: AppColors.primaryAccentColor,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Divider
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 22.0),
                      child: Row(
                        children: [
                          const Expanded(child: Divider(color: Color(0xFFE2E8F0))),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12.0),
                            child: Text(
                              'OR ENTER / SEARCH ADDRESS',
                              style: GoogleFonts.dmSans(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF94A3B8),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const Expanded(child: Divider(color: Color(0xFFE2E8F0))),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Street Address with Autocomplete
                    MyTextField(
                      controller: addressController,
                      focusNode: addressFocusNode,
                      labelText: 'Street Address / Search',
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
                        padding: const EdgeInsets.symmetric(horizontal: 22.0, vertical: 4.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            minHeight: 2,
                            backgroundColor: const Color(0xFFE2E8F0),
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryAccentColor),
                          ),
                        ),
                      ),
                    ],

                    // Suggestions Dropdown Card
                    if (_addressSuggestions.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 6.0),
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
                                padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                          _addressSuggestions = <AddressSuggestion>[];
                                        });
                                      },
                                      child: const Icon(Icons.close_rounded, size: 16, color: Color(0xFF94A3B8)),
                                    ),
                                  ],
                                ),
                              ),
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
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 2.0),
                                    leading: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: AppColors.fadeBlueAccentColor,
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
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18.0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FDF4),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFBBF7D0)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle_rounded, size: 16, color: Color(0xFF16A34A)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'GPS Pin Tagged: (${latitude!.toStringAsFixed(4)}, ${longitude!.toStringAsFixed(4)})',
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
                      ),
                    ],

                    const SizedBox(height: 32),

                    // Submit Button
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18.0),
                      child: GradientButton(
                        isLoading: loading,
                        onPressed: () async {
                          final street = addressController.text.trim();
                          final city = cityController.text.trim();

                          if (street.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please enter your street address'),
                                backgroundColor: Colors.redAccent,
                              ),
                            );
                            return;
                          }
                          if (city.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please enter your city'),
                                backgroundColor: Colors.redAccent,
                              ),
                            );
                            return;
                          }

                          setState(() {
                            loading = true;
                          });

                          await SignUpModel.getInputAddress(
                            context,
                            street,
                            city,
                            instructionController.text.trim(),
                            'Nigeria',
                            _scaffoldKey,
                            state: stateController.text.trim(),
                            lga: lgaController.text.trim(),
                            latitude: latitude,
                            longitude: longitude,
                          );

                          if (mounted) {
                            setState(() {
                              loading = false;
                            });
                          }
                        },
                        text: 'Complete Registration',
                      ),
                    ),

                    const SizedBox(height: 40.0),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

