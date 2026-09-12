import 'dart:async';
import 'package:flutter/material.dart';
import 'package:foam_mobile/core/Screens/basket/controller/order_controller.dart';
import 'package:foam_mobile/core/Screens/basket/controller/remote_basket.dart';
import 'package:foam_mobile/core/Screens/main_screen.dart';
import 'package:foam_mobile/core/provider/basket_provider.dart';
import 'package:foam_mobile/core/services/location_service.dart';
import 'package:foam_mobile/feature/authentication/controller/provider/authprovider.dart';
import 'package:foam_mobile/utils/values.dart';
import 'package:foam_mobile/widgets/click_button.dart';
import 'package:foam_mobile/widgets/message_handler.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class PickupAddressScreen extends StatefulWidget {
  final int totalAmount;
  final bool noFolding;

  const PickupAddressScreen({
    super.key,
    required this.totalAmount,
    this.noFolding = false,
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
    selectedAddress = authProvider.addressStreet;
    _addressController.addListener(_onAddressChanged);
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
      });
    }
  }

  Future<void> _selectTime(BuildContext context, bool isFrom) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
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
    }
  }

  @override
  Widget build(BuildContext context) {
    final AuthProvider authProvider = Provider.of<AuthProvider>(context);
    final BasketProvider basketProvider =
        Provider.of<BasketProvider>(context, listen: false);

    return ScaffoldMessenger(
      key: scaffoldKey,
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new,
              color: AppColors.blackAccentColor,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Pickup Address',
            style: Constants.headingStyle.copyWith(fontSize: 20),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                'Pickup/Delivery Address',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
              ),
              AppSpaces.verticalSpace10,
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                decoration: BoxDecoration(
                  color: AppColors.shadeGreyAccentColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedAddress,
                    isExpanded: true,
                    icon: const Icon(Icons.unfold_more),
                    items: <DropdownMenuItem<String>>[
                      DropdownMenuItem<String>(
                        value: authProvider.addressStreet,
                        child: Text(
                          authProvider.addressStreet.isNotEmpty
                              ? authProvider.addressStreet
                              : 'Default Profile Address',
                          style: const TextStyle(fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (selectedAddress != null &&
                          selectedAddress != authProvider.addressStreet)
                        DropdownMenuItem<String>(
                          value: selectedAddress,
                          child: Text(
                            selectedAddress!,
                            style: const TextStyle(fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: (String? value) {
                      setState(() {
                        selectedAddress = value;
                        if (value == authProvider.addressStreet) {
                          _addressController.clear();
                        }
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 15),

              // Auto-Detect Location Button
              InkWell(
                onTap: _isDetectingLocation ? null : _handleAutoDetect,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                  decoration: BoxDecoration(
                    color: AppColors.primaryAccentColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.primaryAccentColor.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      if (_isDetectingLocation)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else
                        Icon(
                          Icons.my_location,
                          color: AppColors.primaryAccentColor,
                          size: 18,
                        ),
                      const SizedBox(width: 8),
                      Text(
                        _isDetectingLocation
                            ? 'Detecting current location...'
                            : 'Auto-detect My Location',
                        style: TextStyle(
                          color: AppColors.primaryAccentColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              AppSpaces.verticalSpace20,
              const Text(
                'Search or Enter Address',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
              ),
              AppSpaces.verticalSpace10,
              TextField(
                controller: _addressController,
                decoration: InputDecoration(
                  hintText: 'Type street or address...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _addressController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            setState(() {
                              _addressController.clear();
                              _addressSuggestions = <AddressSuggestion>[];
                              selectedAddress = authProvider.addressStreet;
                            });
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.shadeGreyAccentColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              if (_isSearchingSuggestions) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
                  child: LinearProgressIndicator(
                    minHeight: 2,
                    backgroundColor: Colors.grey[200],
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppColors.primaryAccentColor),
                  ),
                ),
              ],

              if (_addressSuggestions.isNotEmpty) ...[
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey[300]!),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12.0, vertical: 6.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
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
                              child: Icon(Icons.close,
                                  size: 16, color: Colors.grey[500]),
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
                          final AddressSuggestion suggestion =
                              _addressSuggestions[index];
                          return ListTile(
                            dense: true,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12.0, vertical: 2.0),
                            leading: Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: AppColors.primaryAccentColor
                                    .withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.location_on_outlined,
                                size: 16,
                                color: AppColors.primaryAccentColor,
                              ),
                            ),
                            title: Text(
                              suggestion.title,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            subtitle: Text(
                              suggestion.subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
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
                const SizedBox(height: 4),
              ],
              AppSpaces.verticalSpace20,
              const Text(
                'Pickup Date',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
              ),
              AppSpaces.verticalSpace10,
              InkWell(
                onTap: () => _selectDate(context),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(
                    color: AppColors.shadeGreyAccentColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      DateFormat('dd MMM yyyy')
                          .format(selectedDate)
                          .toUpperCase(),
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
              ),
              AppSpaces.verticalSpace20,
              const Text(
                'Pickup Time (optional)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
              ),
              AppSpaces.verticalSpace10,
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('From'),
                        AppSpaces.verticalSpace5,
                        InkWell(
                          onTap: () => _selectTime(context, true),
                          child: Container(
                            height: 50,
                            decoration: BoxDecoration(
                              color: AppColors.shadeGreyAccentColor,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                fromTime != null
                                    ? fromTime!.format(context)
                                    : '',
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  AppSpaces.horizontalSpace10,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('To'),
                        AppSpaces.verticalSpace5,
                        InkWell(
                          onTap: () => _selectTime(context, false),
                          child: Container(
                            height: 50,
                            decoration: BoxDecoration(
                              color: AppColors.shadeGreyAccentColor,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                toTime != null ? toTime!.format(context) : '',
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              AppSpaces.verticalSpace40,
              Center(
                child: ClickButton(
                  text: 'Pay Now',
                  textColor: Colors.white,
                  isLoading: isLoading,
                  onPressed: () async {
                    setState(() {
                      isLoading = true;
                    });
                    try {
                      // 1. Re-quote right before payment to get authoritative total from server
                      final freshQuote = await BasketClass.getQuote(
                        widget.noFolding,
                        scaffoldKey: scaffoldKey,
                        context: context,
                      );
                      final int amountToPay = freshQuote != null
                          ? freshQuote.totalPrice
                          : widget.totalAmount;

                      if (!mounted) return;

                      // 2. Perform Paystack payment & create order
                      final bool success =
                          await PayStackOrderClass.payStackOrder(
                        context: context,
                        scaffoldKey: scaffoldKey,
                        totalAmount: amountToPay,
                        noFolding: widget.noFolding,
                      );

                      if (success && mounted) {
                        await basketProvider.fetchBasket(scaffoldKey,
                            showLoading: false);
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          MainScreen.id,
                          (route) => false,
                        );
                      }
                    } finally {
                      if (mounted) {
                        setState(() {
                          isLoading = false;
                        });
                      }
                    }
                  },
                  fontSize: MediaQuery.sizeOf(context).height / 53,
                  color: AppColors.primaryAccentColor,
                ),
              ),
              AppSpaces.verticalSpace40,
            ],
          ),
        ),
      ),
    );
  }
}
