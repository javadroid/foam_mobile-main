import 'dart:convert';
import 'dart:developer';
import 'package:foam_mobile/utils/values.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class UserLocationDetails {
  final String street;
  final String city;
  final String state;
  final String lga;
  final String postalCode;
  final String country;
  final double latitude;
  final double longitude;
  final String formattedAddress;

  UserLocationDetails({
    required this.street,
    required this.city,
    required this.state,
    required this.lga,
    required this.postalCode,
    required this.country,
    required this.latitude,
    required this.longitude,
    required this.formattedAddress,
  });
}

class LocationService {
  /// Request permission and fetch device's current GPS position
  static Future<Position?> getCurrentPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      log('Location services are disabled.');
      return null;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        log('Location permissions are denied');
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      log('Location permissions are permanently denied');
      return null;
    }

    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  }

  /// Reverse geocode coordinates using Google Geocoding API to parse street, city, state, LGA
  static Future<UserLocationDetails?> reverseGeocode({
    required double latitude,
    required double longitude,
  }) async {
    try {
      const apiKey = Constants.googleMapsApiKey;
      final uri = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json?latlng=$latitude,$longitude&key=$apiKey',
      );

      final response = await http.get(uri);
      if (response.statusCode != 200) {
        log('Google Geocoding API error: ${response.statusCode}');
        return null;
      }

      final data = json.decode(response.body);
      if (data['status'] != 'OK' || (data['results'] as List).isEmpty) {
        log('No geocoding results found: ${data['status']}');
        return null;
      }

      final result = data['results'][0];
      final formattedAddress = result['formatted_address'] ?? '';
      final components = result['address_components'] as List<dynamic>? ?? [];

      String streetNumber = '';
      String route = '';
      String sublocality = '';
      String locality = '';
      String adminArea2 = ''; // Typically LGA in Nigeria
      String adminArea1 = ''; // State
      String country = 'Nigeria';
      String postalCode = '';

      for (var comp in components) {
        final types = (comp['types'] as List<dynamic>).cast<String>();
        final longName = comp['long_name'] ?? '';

        if (types.contains('street_number')) {
          streetNumber = longName;
        } else if (types.contains('route')) {
          route = longName;
        } else if (types.contains('sublocality') || types.contains('sublocality_level_1')) {
          sublocality = longName;
        } else if (types.contains('locality')) {
          locality = longName;
        } else if (types.contains('administrative_area_level_2')) {
          adminArea2 = longName;
        } else if (types.contains('administrative_area_level_1')) {
          adminArea1 = longName;
        } else if (types.contains('country')) {
          country = longName;
        } else if (types.contains('postal_code')) {
          postalCode = longName;
        }
      }

      // Build clean street name
      String street = '';
      if (streetNumber.isNotEmpty && route.isNotEmpty) {
        street = '$streetNumber $route';
      } else if (route.isNotEmpty) {
        street = route;
      } else if (sublocality.isNotEmpty) {
        street = sublocality;
      } else {
        street = formattedAddress.split(',').first.trim();
      }

      // City & LGA resolution
      String city = locality.isNotEmpty ? locality : sublocality.isNotEmpty ? sublocality : adminArea2;
      String lga = adminArea2.isNotEmpty ? adminArea2 : city;
      String state = adminArea1;

      return UserLocationDetails(
        street: street,
        city: city,
        state: state,
        lga: lga,
        postalCode: postalCode,
        country: country.isNotEmpty ? country : 'Nigeria',
        latitude: latitude,
        longitude: longitude,
        formattedAddress: formattedAddress,
      );
    } catch (e) {
      log('Error reverse geocoding: $e');
      return null;
    }
  }

  /// Full auto-detect workflow: gets GPS position and reverse-geocodes it
  static Future<UserLocationDetails?> autoDetectLocation() async {
    final position = await getCurrentPosition();
    if (position == null) return null;

    return await reverseGeocode(
      latitude: position.latitude,
      longitude: position.longitude,
    );
  }

  /// Open device app settings (to grant location permission)
  static Future<bool> openAppSettings() async {
    return await Geolocator.openAppSettings();
  }

  /// Open device location service settings (to turn on GPS)
  static Future<bool> openLocationSettings() async {
    return await Geolocator.openLocationSettings();
  }
}
