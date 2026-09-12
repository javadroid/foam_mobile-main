import 'package:flutter/material.dart';
import 'package:foam_mobile/core/Screens/basket/controller/order_controller.dart';
import 'package:foam_mobile/core/Screens/basket/controller/remote_basket.dart';
import 'package:foam_mobile/core/Screens/main_screen.dart';
import 'package:foam_mobile/core/provider/basket_provider.dart';
import 'package:foam_mobile/feature/authentication/controller/provider/authprovider.dart';
import 'package:foam_mobile/utils/values.dart';
import 'package:foam_mobile/widgets/click_button.dart';
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

  @override
  void initState() {
    super.initState();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    selectedAddress = authProvider.addressStreet;
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
      builder: (context, child) {
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
      builder: (context, child) {
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
    final authProvider = Provider.of<AuthProvider>(context);
    final basketProvider = Provider.of<BasketProvider>(context, listen: false);

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
            children: [
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
                    items: [
                      DropdownMenuItem(
                        value: authProvider.addressStreet,
                        child: Text(
                          authProvider.addressStreet,
                          style: const TextStyle(fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        selectedAddress = value;
                      });
                    },
                  ),
                ),
              ),
              AppSpaces.verticalSpace20,
              const Text(
                'Change Address (optional)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
              ),
              AppSpaces.verticalSpace10,
              TextField(
                controller: _addressController,
                decoration: InputDecoration(
                  hintText: 'Address',
                  filled: true,
                  fillColor: AppColors.shadeGreyAccentColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
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
                      DateFormat('dd MMM yyyy').format(selectedDate).toUpperCase(),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
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
                                fromTime != null ? fromTime!.format(context) : '',
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

                child: 
                    ClickButton(
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

                          // 2. Perform Paystack payment & create order
                          final bool success =
                              await PayStackOrderClass.payStackOrder(
                            context: context,
                            scaffoldKey: scaffoldKey,
                            totalAmount: amountToPay,
                            noFolding: widget.noFolding,
                          );

                          if (success && mounted) {
                            await basketProvider.fetchBasket(scaffoldKey, showLoading: false);
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
