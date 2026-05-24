import 'package:flutter/material.dart';
import 'package:foam_mobile/feature/authentication/controller/provider/authprovider.dart';
import 'package:foam_mobile/utils/values.dart';
import 'package:provider/provider.dart';

class PickupDropdown extends StatefulWidget {
  const PickupDropdown({super.key});

  @override
  State<PickupDropdown> createState() => _PickupDropdownState();
}

class _PickupDropdownState extends State<PickupDropdown> {
  //defining the variable for item selected the dropdown
  String? selectedItem;

  @override
  Widget build(BuildContext context) {
    //get the reportType
    final List<String> reportType = [
      Provider.of<AuthProvider>(context, listen: false).addressStreet,
    ];

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 20.0,
      ),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          focusedBorder: OutlineInputBorder(
            borderSide:
                BorderSide(color: Theme.of(context).colorScheme.primary),
            borderRadius: const BorderRadius.all(
              Radius.circular(10.0),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: AppColors.blackAccentColor,
            ),
            borderRadius: const BorderRadius.all(
              Radius.circular(10.0),
            ),
          ),
          fillColor: AppColors.shadeGreyAccentColor,
        ),
        value: selectedItem,
        onChanged: (String? newItem) =>
            setState(() => selectedItem = newItem ?? 'Select Report type'),
        icon: const Icon(Icons.keyboard_arrow_down_rounded),
        iconEnabledColor: Colors.black,
        isExpanded: true,
        borderRadius: BorderRadius.circular(5),
        items: [
          for (var item in reportType)
            DropdownMenuItem<String>(
              value: item,
              child: Text(item),
            ),
        ],
        hint: const Text('Select Pickup Address'),
      ),
    );
  }
}
