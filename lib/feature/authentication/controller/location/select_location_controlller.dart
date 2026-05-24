import 'package:flutter/material.dart';
import 'package:foam_mobile/utils/values.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:google_places_flutter/model/prediction.dart';

class LocationAutocompleteWidget extends StatefulWidget {
  final Function(String) onLocationSelected;
  final InputDecoration? decoration;

  const LocationAutocompleteWidget({
    super.key,
    required this.onLocationSelected,
    this.decoration,
  });

  @override
  LocationAutocompleteWidgetState createState() =>
      LocationAutocompleteWidgetState();
}

class LocationAutocompleteWidgetState
    extends State<LocationAutocompleteWidget> {
  static const String _googleMapsApiKey = Constants.googleMapsApiKey;
  final TextEditingController _searchController = TextEditingController();

  void _handlePredictionTap(Prediction prediction) {
    // Update text controller with selected prediction
    final selectedAddress = prediction.description ?? 'No address selected';
    _searchController.text = selectedAddress;

    // Notify parent widget
    widget.onLocationSelected(selectedAddress);

    // Close keyboard and clear focus
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GooglePlaceAutoCompleteTextField(
          textEditingController: _searchController,
          googleAPIKey: _googleMapsApiKey,

          // Use provided decoration or default
          inputDecoration: widget.decoration ??
              const InputDecoration(
                hintText: 'Enter your address',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.location_on),
              ),

          debounceTime: 800,
          countries: const ["ng"],
          isLatLngRequired: true,

          // Improved place detail retrieval
          getPlaceDetailWithLatLng: (Prediction? prediction) {
            // Safely extract and use the address
            final selectedAddress =
                prediction?.description ?? 'No address selected';

            // Update text controller to show selected address
            _searchController.text = selectedAddress;

            // Notify parent widget
            widget.onLocationSelected(selectedAddress);
          },

          // Customize prediction items with explicit tapping
          itemBuilder: (context, index, Prediction prediction) {
            return GestureDetector(
              onTap: () => _handlePredictionTap(prediction),
              child: ListTile(
                leading: const Icon(Icons.location_on),
                title: Text(prediction.description ?? 'Unknown Location'),
              ),
            );
          },
        ),
      ],
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
