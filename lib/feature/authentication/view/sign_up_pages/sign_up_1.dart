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
  final addressController = TextEditingController();
  final cityController = TextEditingController();
  final stateController = TextEditingController();
  final lgaController = TextEditingController();
  final instructionController = TextEditingController();
  final addressFocusNode = FocusNode();

  double? latitude;
  double? longitude;

  bool loading = false;
  bool isDetectingLocation = false;

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

                // Auto-detect location button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 17.0),
                  child: InkWell(
                    onTap: isDetectingLocation ? null : _handleAutoDetectLocation,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppColors.primaryAccentColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.primaryAccentColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (isDetectingLocation)
                            const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          else
                            Icon(
                              Icons.my_location,
                              color: AppColors.primaryAccentColor,
                              size: 20,
                            ),
                          const SizedBox(width: 10),
                          Text(
                            isDetectingLocation
                                ? 'Detecting current location...'
                                : 'Auto-detect My Location',
                            style: TextStyle(
                              color: AppColors.primaryAccentColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Address (Street) textfield
                MyTextField(
                  controller: addressController,
                  focusNode: addressFocusNode,
                  hinText: 'Street / Address',
                  obscureText: false,
                  isPassword: false,
                ),

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
