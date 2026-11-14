import 'package:foam_mobile/core/Screens/billing/payment_success_screen.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:foam_mobile/core/Screens/main_screen.dart';
import 'package:foam_mobile/core/hive/hive.dart';
import 'package:foam_mobile/core/provider/basket_provider.dart';
import 'package:foam_mobile/core/services/location_service.dart';
import 'package:foam_mobile/feature/authentication/controller/provider/authprovider.dart';
import 'package:foam_mobile/feature/schedule_pickup/controller/schedule_pickup_provider.dart';
import 'package:foam_mobile/feature/schedule_pickup/views/07_order_placed_screen.dart';
import 'package:foam_mobile/utils/values.dart';
import 'package:foam_mobile/widgets/message_handler.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:foam_mobile/widgets/foam_payment_sheet.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:foam_mobile/core/services/foam_payment_service.dart';

class PickupAddressScreen extends StatefulWidget {
  final int totalAmount;
  final bool noFolding;
  final bool isSchedulePickup;

  const PickupAddressScreen({
    super.key,
    required this.totalAmount,
    this.noFolding = false,
    this.isSchedulePickup = false,
  });

  @override
  State<PickupAddressScreen> createState() => _PickupAddressScreenState();
}

class _PickupAddressScreenState extends State<PickupAddressScreen> {
  final GlobalKey<ScaffoldMessengerState> scaffoldKey =
      GlobalKey<ScaffoldMessengerState>();

  String? selectedAddress;
  final TextEditingController _addressController = TextEditingController();
  DateTime selectedDate = DateTime.now();
  DateTime? deliveryDate;
  TimeOfDay? fromTime;
  TimeOfDay? toTime;
  bool isLoading = false;

  // Address search & auto-detect state
  Timer? _debounceTimer;
  List<AddressSuggestion> _addressSuggestions = <AddressSuggestion>[];
  bool _isSearchingSuggestions = false;
  bool _isDetectingLocation = false;
  bool _isAddressSelected = false;

  @override
  void initState() {
    super.initState();
    final AuthProvider authProvider =
        Provider.of<AuthProvider>(context, listen: false);

    // 1. Load saved delivery details from Hive for instant prefill
    final savedDetails = HiveClass.getDeliveryDetails();
    final savedAddress = savedDetails['address'];
    final savedPickupDate = savedDetails['pickupDate'];
    final savedFromTime = savedDetails['fromTime'];
    final savedToTime = savedDetails['toTime'];
    final savedDeliveryDate = savedDetails['deliveryDate'];

    if (widget.isSchedulePickup) {
      final sched = Provider.of<SchedulePickupProvider>(context, listen: false);
      if (sched.pickupAddress.isNotEmpty) {
        selectedAddress = sched.pickupAddress;
        _addressController.text = sched.pickupAddress;
      } else if (savedAddress != null && savedAddress.isNotEmpty) {
        selectedAddress = savedAddress;
        _addressController.text = savedAddress;
      } else if (authProvider.addressStreet.isNotEmpty) {
        selectedAddress = authProvider.addressStreet;
        _addressController.text = authProvider.addressStreet;
      }
    } else if (savedAddress != null && savedAddress.isNotEmpty) {
      selectedAddress = savedAddress;
      _addressController.text = savedAddress;
    } else if (authProvider.addressStreet.isNotEmpty) {
      selectedAddress = authProvider.addressStreet;
      _addressController.text = authProvider.addressStreet;
    }

    final today =
        DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    if (savedPickupDate != null) {
      final parsed = DateTime.tryParse(savedPickupDate);
      if (parsed != null && !parsed.isBefore(today)) {
        selectedDate = parsed;
      }
    }

    if (savedDeliveryDate != null) {
      final parsed = DateTime.tryParse(savedDeliveryDate);
      if (parsed != null && !parsed.isBefore(selectedDate)) {
        deliveryDate = parsed;
      } else {
        deliveryDate = selectedDate.add(const Duration(days: 2));
      }
    } else {
      deliveryDate = selectedDate.add(const Duration(days: 2));
    }

    if (savedFromTime != null) {
      fromTime = _parseTimeOfDay(savedFromTime);
    }
    if (savedToTime != null) {
      toTime = _parseTimeOfDay(savedToTime);
    }

    _addressController.addListener(_onAddressChanged);
  }

  TimeOfDay? _parseTimeOfDay(String str) {
    try {
      final parts = str.split(':');
      if (parts.length >= 2) {
        return TimeOfDay(
            hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      }
    } catch (_) {}
    return null;
  }

  void _saveCurrentDetails() {
    final effectiveAddr = _addressController.text.trim().isNotEmpty
        ? _addressController.text.trim()
        : (selectedAddress ?? '');
    HiveClass.saveDeliveryDetails(
      address: effectiveAddr,
      pickupDate: selectedDate.toIso8601String(),
      fromTime:
          fromTime != null ? '${fromTime!.hour}:${fromTime!.minute}' : null,
      toTime: toTime != null ? '${toTime!.hour}:${toTime!.minute}' : null,
      deliveryDate: deliveryDate?.toIso8601String(),
    );
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _addressController.removeListener(_onAddressChanged);
    _addressController.dispose();
    super.dispose();
  }

  void _onAddressChanged() {
    final String query = _addressController.text.trim();
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
      final String chosen = suggestion.fullAddress.isNotEmpty
          ? suggestion.fullAddress
          : suggestion.title;
      _addressController.text = chosen;
      selectedAddress = chosen;
      _addressSuggestions = <AddressSuggestion>[];
      _isSearchingSuggestions = false;
    });
    _saveCurrentDetails();
    FocusScope.of(context).unfocus();
  }

  Future<void> _handleAutoDetect() async {
    setState(() {
      _isDetectingLocation = true;
    });
    try {
      final UserLocationDetails? details =
          await LocationService.autoDetectLocation();
      if (details != null && mounted) {
        final String detected = details.formattedAddress.isNotEmpty
            ? details.formattedAddress
            : <String>[details.street, details.lga, details.state]
                .where((String s) => s.isNotEmpty)
                .join(', ');
        setState(() {
          _isAddressSelected = true;
          _addressController.text = detected;
          selectedAddress = detected;
        });
        _saveCurrentDetails();
        MyMessageHandler.showSnackBar(
          scaffoldKey,
          'Location detected: ${details.city.isNotEmpty ? details.city : details.lga}',
        );
      } else {
        MyMessageHandler.showSnackBar(
          scaffoldKey,
          'Unable to auto-detect location. Please type your address manually.',
        );
      }
    } catch (e) {
      MyMessageHandler.showSnackBar(
        scaffoldKey,
        'Error detecting location: $e',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isDetectingLocation = false;
        });
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primaryAccentColor,
              onPrimary: Colors.white,
              onSurface: AppColors.blackAccentColor,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
        if (deliveryDate != null && deliveryDate!.isBefore(picked)) {
          deliveryDate = picked.add(const Duration(days: 2));
        }
      });
      _saveCurrentDetails();
    }
  }

  Future<void> _selectDeliveryDate(BuildContext context) async {
    final initial =
        deliveryDate != null && !deliveryDate!.isBefore(selectedDate)
            ? deliveryDate!
            : selectedDate.add(const Duration(days: 2));
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: selectedDate,
      lastDate: DateTime(2101),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primaryAccentColor,
              onPrimary: Colors.white,
              onSurface: AppColors.blackAccentColor,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != deliveryDate) {
      setState(() {
        deliveryDate = picked;
      });
      _saveCurrentDetails();
    }
  }

  Future<void> _selectTime(BuildContext context, bool isFrom) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: (isFrom ? fromTime : toTime) ?? TimeOfDay.now(),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primaryAccentColor,
              onPrimary: Colors.white,
              onSurface: AppColors.blackAccentColor,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isFrom) {
          fromTime = picked;
        } else {
          toTime = picked;
        }
      });
      _saveCurrentDetails();
    }
  }

  @override
  Widget build(BuildContext context) {
    final AuthProvider authProvider = Provider.of<AuthProvider>(context);
    final BasketProvider basketProvider =
        Provider.of<BasketProvider>(context, listen: false);
    final currencyFormatter = NumberFormat('#,###');
    final int effectiveAmount = widget.totalAmount > 0
        ? widget.totalAmount
        : (widget.isSchedulePickup
            ? Provider.of<SchedulePickupProvider>(context, listen: false)
                .grandTotal
            : basketProvider.totalPrice);

    return ScaffoldMessenger(
      key: scaffoldKey,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          elevation: 0.5,
          backgroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: Color(0xFF212828),
              size: 20,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Pickup & Delivery Details',
            style: GoogleFonts.dmSans(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF212828),
            ),
          ),
          centerTitle: false,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Pickup Address Section Header
                Text(
                  'Pickup & Delivery Address',
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF212828),
                  ),
                ),
                const SizedBox(height: 10),

                // Profile Address Quick Select (if user has a saved profile address)
                if (authProvider.addressStreet.isNotEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: const Color(0xFFE4E4E4), width: 0.8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.home_outlined,
                            color: Color(0xFF00AABC), size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Profile Address',
                                style: GoogleFonts.dmSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF5E5E5E),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                authProvider.addressStreet,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.dmSans(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF212828),
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              selectedAddress = authProvider.addressStreet;
                              _addressController.text =
                                  authProvider.addressStreet;
                              _addressSuggestions = [];
                            });
                            _saveCurrentDetails();
                          },
                          child: Text(
                            'Use',
                            style: GoogleFonts.dmSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF00AABC),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                ],

                // Auto-Detect Location Button
                InkWell(
                  onTap: _isDetectingLocation ? null : _handleAutoDetect,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        vertical: 11, horizontal: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5F7F8),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFF00AABC).withValues(alpha: 0.25),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_isDetectingLocation)
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF00AABC),
                            ),
                          )
                        else
                          const Icon(
                            Icons.my_location,
                            color: Color(0xFF00AABC),
                            size: 17,
                          ),
                        const SizedBox(width: 8),
                        Text(
                          _isDetectingLocation
                              ? 'Detecting current location...'
                              : 'Auto-detect My Location',
                          style: GoogleFonts.dmSans(
                            color: const Color(0xFF00AABC),
                            fontWeight: FontWeight.w600,
                            fontSize: 13.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // Search or Enter Address
                TextField(
                  controller: _addressController,
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    color: const Color(0xFF212828),
                  ),
                  decoration: InputDecoration(
                    hintText: 'Type street or house address...',
                    hintStyle: GoogleFonts.dmSans(
                      fontSize: 13.5,
                      color: const Color(0xFF9E9E9E),
                    ),
                    prefixIcon: const Icon(
                      Icons.search,
                      size: 20,
                      color: Color(0xFF757575),
                    ),
                    suffixIcon: _addressController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear,
                                size: 18, color: Color(0xFF757575)),
                            onPressed: () {
                              setState(() {
                                _addressController.clear();
                                _addressSuggestions = <AddressSuggestion>[];
                                selectedAddress = authProvider.addressStreet;
                              });
                              _saveCurrentDetails();
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: const Color(0xFFF9FAFB),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                          color: Color(0xFFE4E4E4), width: 0.8),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                          color: Color(0xFFE4E4E4), width: 0.8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                          color: Color(0xFF00AABC), width: 1.2),
                    ),
                  ),
                ),

                if (_isSearchingSuggestions) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: LinearProgressIndicator(
                      minHeight: 2,
                      backgroundColor: Colors.grey[200],
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF00AABC)),
                    ),
                  ),
                ],

                if (_addressSuggestions.isNotEmpty) ...[
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: const Color(0xFFE4E4E4), width: 0.8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12.0, vertical: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Suggested Addresses',
                                style: GoogleFonts.dmSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF757575),
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _addressSuggestions = <AddressSuggestion>[];
                                  });
                                },
                                child: const Icon(Icons.close,
                                    size: 16, color: Color(0xFF757575)),
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1, color: Color(0xFFE4E4E4)),
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _addressSuggestions.length,
                          separatorBuilder: (_, __) => const Divider(
                              height: 1, color: Color(0xFFE4E4E4)),
                          itemBuilder: (context, index) {
                            final suggestion = _addressSuggestions[index];
                            return ListTile(
                              dense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12.0, vertical: 2.0),
                              leading: Container(
                                padding: const EdgeInsets.all(5),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFE5F7F8),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.location_on_outlined,
                                  size: 16,
                                  color: Color(0xFF00AABC),
                                ),
                              ),
                              title: Text(
                                suggestion.title,
                                style: GoogleFonts.dmSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF212828),
                                ),
                              ),
                              subtitle: Text(
                                suggestion.subtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.dmSans(
                                  fontSize: 11,
                                  color: const Color(0xFF757575),
                                ),
                              ),
                              onTap: () => _selectSuggestion(suggestion),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 22),

                // 2. Schedule Section
                Text(
                  'Pickup Schedule',
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF212828),
                  ),
                ),
                const SizedBox(height: 8),

                // Pickup Date Picker Card
                InkWell(
                  onTap: () => _selectDate(context),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: const Color(0xFFE4E4E4), width: 0.8),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: const BoxDecoration(
                            color: Color(0xFFE5F7F8),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.calendar_today_rounded,
                            size: 16,
                            color: Color(0xFF00AABC),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                DateFormat('EEEE, MMMM d, yyyy')
                                    .format(selectedDate),
                                style: GoogleFonts.dmSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF212828),
                                ),
                              ),
                              Text(
                                'Tap to choose pickup day',
                                style: GoogleFonts.dmSans(
                                  fontSize: 11.5,
                                  color: const Color(0xFF757575),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios_rounded,
                            size: 13, color: Color(0xFF9E9E9E)),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Pickup Time Window
                Text(
                  'Pickup Time Window (optional)',
                  style: GoogleFonts.dmSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF5E5E5E),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _selectTime(context, true),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 11),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: const Color(0xFFE4E4E4), width: 0.8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.access_time_rounded,
                                  size: 16, color: Color(0xFF00AABC)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  fromTime != null
                                      ? fromTime!.format(context)
                                      : 'Start Time',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: fromTime != null
                                        ? const Color(0xFF212828)
                                        : const Color(0xFF9E9E9E),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: InkWell(
                        onTap: () => _selectTime(context, false),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 11),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: const Color(0xFFE4E4E4), width: 0.8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.access_time_filled_rounded,
                                  size: 16, color: Color(0xFF00AABC)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  toTime != null
                                      ? toTime!.format(context)
                                      : 'End Time',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: toTime != null
                                        ? const Color(0xFF212828)
                                        : const Color(0xFF9E9E9E),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Delivery Date (Optional)
                Text(
                  'Estimated Delivery Date',
                  style: GoogleFonts.dmSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF5E5E5E),
                  ),
                ),
                const SizedBox(height: 6),
                InkWell(
                  onTap: () => _selectDeliveryDate(context),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: const Color(0xFFE4E4E4), width: 0.8),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: const BoxDecoration(
                            color: Color(0xFFDCFCE7),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.local_shipping_outlined,
                            size: 16,
                            color: Color(0xFF15803D),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                deliveryDate != null
                                    ? DateFormat('EEEE, MMMM d, yyyy')
                                        .format(deliveryDate!)
                                    : 'Select estimated delivery date',
                                style: GoogleFonts.dmSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: deliveryDate != null
                                      ? const Color(0xFF212828)
                                      : const Color(0xFF9E9E9E),
                                ),
                              ),
                              Text(
                                deliveryDate != null
                                    ? 'Tap to change delivery date'
                                    : 'Optional standard 2-day return',
                                style: GoogleFonts.dmSans(
                                  fontSize: 11.5,
                                  color: const Color(0xFF757575),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios_rounded,
                            size: 13, color: Color(0xFF9E9E9E)),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 22),

                // Order Summary Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: const Color(0xFFE4E4E4), width: 0.8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total to Pay',
                            style: GoogleFonts.dmSans(
                              fontSize: 13,
                              color: const Color(0xFF5E5E5E),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.noFolding
                                ? 'No Folding'
                                : 'Standard Care Included',
                            style: GoogleFonts.dmSans(
                              fontSize: 11.5,
                              color: const Color(0xFF9E9E9E),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '₦${currencyFormatter.format(effectiveAmount)}',
                        style: GoogleFonts.dmSans(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF00AABC),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 26),

                // Modern Pay Button (Foam gradient theme)
                Container(
                  width: double.infinity,
                  height: 53,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00AABC), Color(0xFFC5EFF3)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: isLoading ? null : _handlePayment,
                    child: isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            'Pay ₦${currencyFormatter.format(effectiveAmount)}',
                            style: GoogleFonts.dmSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              letterSpacing: 0.6,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handlePayment() async {
    final String effectiveAddress = _addressController.text.trim().isNotEmpty
        ? _addressController.text.trim()
        : (selectedAddress ?? '');

    if (effectiveAddress.isEmpty) {
      MyMessageHandler.showSnackBar(
        scaffoldKey,
        'Please enter or auto-detect your pickup address',
      );
      return;
    }

    _saveCurrentDetails();

    final String? formattedPickupTime = fromTime != null && toTime != null
        ? '${fromTime!.format(context)} - ${toTime!.format(context)}'
        : fromTime?.format(context);

    final BasketProvider basketProvider =
        Provider.of<BasketProvider>(context, listen: false);
    final nav = Navigator.of(context);

    if (widget.isSchedulePickup) {
      final sched = Provider.of<SchedulePickupProvider>(context, listen: false);
      sched.setPickupAddress(effectiveAddress);
      final slot =
          '${DateFormat('MMM d').format(selectedDate)}, ${formattedPickupTime ?? "3:00 – 4:00 PM"}';
      sched.setPickupSlot(slot);

      final double schedAmount = widget.totalAmount > 0
          ? widget.totalAmount.toDouble()
          : (sched.grandTotal > 0 ? sched.grandTotal.toDouble() : 0.0);

      final result = await FoamPaymentSheet.show(
        context: context,
        title: 'Schedule Pickup Payment',
        itemTitle: sched.currentStore.name.isNotEmpty
            ? sched.currentStore.name
            : 'Schedule Pickup',
        itemSubtitle: widget.noFolding
            ? 'No Folding Service'
            : 'Standard Care Included',
        amount: schedAmount,
        purpose: FoamPaymentPurpose.order,
        noFolding: widget.noFolding,
        storeId: sched.currentStore.id,
        pickupAddress: effectiveAddress,
        deliveryAddress: effectiveAddress,
        pickupDate: selectedDate,
        pickupTime: formattedPickupTime,
        deliveryDate: deliveryDate,
        onProcessPayment: (method) async {
          return await FoamPaymentService.processScheduleOrderPayment(
            context: context,
            provider: sched,
            method: method,
            amount: schedAmount,
            pickupAddress: effectiveAddress,
            pickupDate: selectedDate,
            pickupTime: formattedPickupTime,
            deliveryAddress: effectiveAddress,
            deliveryDate: deliveryDate,
          );
        },
      );

      if (result != null) {
        if (result.success) {
          if (mounted) {
            Navigator.pushReplacementNamed(
                context, ScheduleOrderPlacedScreen.id);
          }
        } else {
          if (mounted) {
            MyMessageHandler.showSnackBar(
              scaffoldKey,
              result.message.isNotEmpty
                  ? result.message
                  : 'Payment could not be completed. Please try again.',
            );
          }
        }
      }
      return;
    }

    // Regular basket order flow:
    final double orderAmount = widget.totalAmount > 0
        ? widget.totalAmount.toDouble()
        : basketProvider.totalPrice.toDouble();

    final result = await FoamPaymentSheet.show(
      context: context,
      title: 'Complete Order Payment',
      itemTitle: '',
      itemSubtitle: widget.noFolding
          ? 'No Folding Service'
          : 'Standard Care Included',
      amount: orderAmount,
      purpose: FoamPaymentPurpose.order,
      noFolding: widget.noFolding,
      pickupAddress: effectiveAddress,
      deliveryAddress: effectiveAddress,
      pickupDate: selectedDate,
      pickupTime: formattedPickupTime,
      deliveryDate: deliveryDate,
    );

    if (result != null) {
      if (result.success) {
        setState(() => isLoading = true);
        try {
          final previousTotalItems = basketProvider.totalItems;
          await basketProvider.fetchBasket(scaffoldKey, showLoading: false);

          final orderData = result.data;
          final String orderRef = result.reference ??
              (orderData != null && orderData.containsKey('id')
                  ? '#FM-${orderData['id']}'
                  : (orderData != null && orderData.containsKey('reference')
                      ? orderData['reference'].toString()
                      : ''));

          if (mounted) {
            await nav.push(
              MaterialPageRoute(
                builder: (_) => PaymentSuccessScreen(
                  title: 'Order Placed Successfully! 🎉',
                  subtitle: 'Your laundry order was placed and confirmed.',
                  itemTitle: '$previousTotalItems Laundry Items',
                  amount: orderAmount,
                  paymentMethod: orderData != null &&
                          orderData.containsKey('paymentMethod')
                      ? orderData['paymentMethod'].toString()
                      : (orderData != null &&
                              orderData.containsKey('paymentType')
                          ? orderData['paymentType'].toString()
                          : 'Online Payment'),
                  reference: orderRef.isNotEmpty ? orderRef : null,
                  details: [
                    MapEntry('Pickup Address', effectiveAddress),
                    MapEntry('Pickup Date',
                        DateFormat('dd MMM yyyy').format(selectedDate)),
                    if (formattedPickupTime != null)
                      MapEntry('Pickup Time', formattedPickupTime),
                    if (deliveryDate != null)
                      MapEntry('Delivery Date',
                          DateFormat('dd MMM yyyy').format(deliveryDate!)),
                    MapEntry(
                        'Folding Service',
                        widget.noFolding
                            ? 'No Folding'
                            : 'Standard Care Included'),
                  ],
                  primaryButtonLabel: 'View Order in History',
                  onPrimaryPressed: () {
                    nav.pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (_) => const MainScreen(initialIndex: 1),
                      ),
                      (route) => false,
                    );
                  },
                ),
              ),
            );
          }
        } finally {
          if (mounted) {
            setState(() {
              isLoading = false;
            });
          }
        }
      } else {
        MyMessageHandler.showSnackBar(scaffoldKey, result.message);
      }
    }
  }
}
