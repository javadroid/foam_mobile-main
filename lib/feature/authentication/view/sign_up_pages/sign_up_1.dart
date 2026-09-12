import 'dart:async';
import 'package:flutter/material.dart';
import 'package:foam_mobile/core/services/location_service.dart';
import 'package:foam_mobile/feature/authentication/model/log_out_model.dart';
import 'package:foam_mobile/feature/authentication/model/sign_up_model.dart';
import 'package:foam_mobile/utils/values.dart';
import 'package:foam_mobile/widgets/gradient_button.dart';
import 'package:foam_mobile/widgets/message_handler.dart';
import 'package:foam_mobile/widgets/my_text_field.dart';

class SignUpPage1 extends StatefulWidget {
  const SignUpPage1({super.key});

  @override
  State<SignUpPage1> createState() => _SignUpPage1State();
}

class _SignUpPage1State extends State<SignUpPage1> {
  final GlobalKey<ScaffoldMessengerState> _scaffoldKey =
      GlobalKey<ScaffoldMessengerState>();

  // Text editing controllers
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

  // Address search suggestions
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
            borderRadius: BorderRadius.circular(20.0),
          ),
          elevation: 10,
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22.0, vertical: 24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Icon Badge
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.primaryAccentColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.location_off_rounded,
                    color: AppColors.primaryAccentColor,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Location Access Needed',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: AppColors.blackAccentColor,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  message ??
                      'We could not automatically detect your location. Please check your device location settings or enter your address manually below.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                // Action Buttons
                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryAccentColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () async {
                          Navigator.pop(dialogContext);
                          await LocationService.openAppSettings();
                        },
                        icon: const Icon(Icons.settings, size: 18),
                        label: const Text(
                          'Open Settings',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.blackAccentColor,
                          side: BorderSide(color: Colors.grey[300]!),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(dialogContext);
                          addressFocusNode.requestFocus();
                        },
                        child: const Text(
                          'Enter Manually',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),
                  ],
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
      setState(() {
        isDetectingLocation = false;
      });
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
        appBar: AppBar(
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18.0),
              child: TextButton(
                onPressed: () {
                  LogoutClass.logOut2(context);
                },
                child: Text(
                  'Log Out',
                  style: TextStyle(
                    color: AppColors.primaryAccentColor,
                  ),
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.primaryBackgroundColor,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 17.0),
                  child: Text(
                    'Pickup Address',
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      color: Colors.grey[800],
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 17.0),
                  child: Text(
                    'Auto-detect your location or fill in the details below. You can edit any field.',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Use Current Location Button Card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 17.0),
                  child: InkWell(
                    onTap: isDetectingLocation ? null : _handleAutoDetectLocation,
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppColors.primaryAccentColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.primaryAccentColor.withValues(alpha: 0.35),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.primaryAccentColor,
                              shape: BoxShape.circle,
                            ),
                            child: isDetectingLocation
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Icon(
                                    Icons.my_location,
                                    color: Colors.white,
                                    size: 20,
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
                                  style: TextStyle(
                                    color: AppColors.blackAccentColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  isDetectingLocation
                                      ? 'Getting GPS & reverse geocoding...'
                                      : 'Auto-fill street, city, LGA & state via GPS',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 14,
                            color: AppColors.primaryAccentColor,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 22),

                // OR Divider
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Row(
                    children: [
                      Expanded(child: Divider(color: Colors.grey[300])),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                        child: Text(
                          'OR ENTER MANUALLY',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[500],
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      Expanded(child: Divider(color: Colors.grey[300])),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // Address (Street) textfield
                MyTextField(
                  controller: addressController,
                  focusNode: addressFocusNode,
                  hinText: 'Street / Address',
                  obscureText: false,
                  isPassword: false,
                ),

                if (_isSearchingSuggestions) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 4.0),
                    child: LinearProgressIndicator(
                      minHeight: 2,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryAccentColor),
                    ),
                  ),
                ],

                if (_addressSuggestions.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 17.0, vertical: 4.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Suggested Addresses',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _addressSuggestions = <AddressSuggestion>[];
                                    });
                                  },
                                  child: Icon(Icons.close, size: 16, color: Colors.grey[500]),
                                ),
                              ],
                            ),
                          ),
                          const Divider(height: 1),
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _addressSuggestions.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (BuildContext context, int index) {
                              final AddressSuggestion suggestion = _addressSuggestions[index];
                              return ListTile(
                                dense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 2.0),
                                leading: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryAccentColor.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.location_on_outlined,
                                    size: 18,
                                    color: AppColors.primaryAccentColor,
                                  ),
                                ),
                                title: Text(
                                  suggestion.title,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                subtitle: Text(
                                  suggestion.subtitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
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
                  const SizedBox(height: 4),
                ],

                const SizedBox(height: 10),

                // City textfield
                MyTextField(
                  controller: cityController,
                  hinText: 'City',
                  obscureText: false,
                  isPassword: false,
                ),

                const SizedBox(height: 10),

                // State textfield
                MyTextField(
                  controller: stateController,
                  hinText: 'State (e.g. Rivers, Lagos)',
                  obscureText: false,
                  isPassword: false,
                ),

                const SizedBox(height: 10),

                // LGA textfield
                MyTextField(
                  controller: lgaController,
                  hinText: 'LGA (e.g. Port Harcourt, Obio-Akpor)',
                  obscureText: false,
                  isPassword: false,
                ),

                const SizedBox(height: 10),

                // Instructions textfield
                MyTextField(
                  controller: instructionController,
                  hinText: 'Pickup and delivery instructions (optional)',
                  obscureText: false,
                  isPassword: false,
                ),

                if (latitude != null && longitude != null) ...[
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, size: 14, color: Colors.green),
                        const SizedBox(width: 4),
                        Text(
                          'GPS Coordinates tagged (${latitude!.toStringAsFixed(4)}, ${longitude!.toStringAsFixed(4)})',
                          style: const TextStyle(fontSize: 12, color: Colors.green),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 40),

                // Complete button
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      flex: 1,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 25.0),
                        child: GradientButton(
                          isLoading: loading,
                          onPressed: () async {
                            setState(() {
                              loading = true;
                            });

                            await SignUpModel.getInputAddress(
                              context,
                              addressController.text.trim(),
                              cityController.text.trim(),
                              instructionController.text.trim(),
                              'Nigeria',
                              _scaffoldKey,
                              state: stateController.text.trim(),
                              lga: lgaController.text.trim(),
                              latitude: latitude,
                              longitude: longitude,
                            );

                            setState(() {
                              loading = false;
                            });
                          },
                          text: 'Complete',
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 50.0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
