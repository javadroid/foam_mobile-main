import 'dart:convert';
import 'dart:developer';
import 'package:flutter/cupertino.dart';
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

class AddressSuggestion {
  final String title;
  final String subtitle;
  final String fullAddress;
  final UserLocationDetails details;

  AddressSuggestion({
    required this.title,
    required this.subtitle,
    required this.fullAddress,
    required this.details,
  });
}

class LocationService {
  /// Request permission and fetch device's current GPS position
  static Future<Position?> getCurrentPosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('Location services are disabled.');
        return await Geolocator.getLastKnownPosition();
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('Location permissions are denied');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('Location permissions are permanently denied');
        return null;
      }

      try {
        final Position pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 8),
          ),
        );
        return pos;
      } catch (timeoutErr) {
        debugPrint(
            'High accuracy GPS timed out, trying last known position: $timeoutErr');
        return await Geolocator.getLastKnownPosition();
      }
    } catch (e) {
      debugPrint('Error getting position: $e');
      try {
        return await Geolocator.getLastKnownPosition();
      } catch (_) {
        return null;
      }
    }
  }

  /// Reverse geocode coordinates using Google Geocoding API with OpenStreetMap Nominatim fallback
  static Future<UserLocationDetails?> reverseGeocode({
    required double latitude,
    required double longitude,
  }) async {
    // 1. Try Google Geocoding API first
    try {
      const String apiKey = Constants.googleMapsApiKey;
      final Uri uri = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json?latlng=$latitude,$longitude&key=$apiKey',
      );

      final http.Response response =
          await http.get(uri).timeout(const Duration(seconds: 6));
      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);
        if (data['status'] == 'OK' && (data['results'] as List).isNotEmpty) {
          final dynamic result = data['results'][0];
          final String formattedAddress = result['formatted_address'] ?? '';
          final List<dynamic> components =
              result['address_components'] as List<dynamic>? ?? <dynamic>[];

          String streetNumber = '';
          String route = '';
          String sublocality = '';
          String locality = '';
          String adminArea2 = ''; // Typically LGA in Nigeria
          String adminArea1 = ''; // State
          String country = 'Nigeria';
          String postalCode = '';

          for (dynamic comp in components) {
            final List<String> types =
                (comp['types'] as List<dynamic>).cast<String>();
            final String longName = comp['long_name'] ?? '';

            if (types.contains('street_number')) {
              streetNumber = longName;
            } else if (types.contains('route')) {
              route = longName;
            } else if (types.contains('sublocality') ||
                types.contains('sublocality_level_1')) {
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

          final String city = locality.isNotEmpty
              ? locality
              : sublocality.isNotEmpty
                  ? sublocality
                  : adminArea2;
          final String lga = adminArea2.isNotEmpty ? adminArea2 : city;
          final String state = adminArea1;

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
        }
      }
    } catch (googleErr) {
      debugPrint(
          'Google Geocoding failed or not enabled, trying OpenStreetMap: $googleErr');
    }

    // 2. Fallback: Free OpenStreetMap Nominatim reverse geocoding API
    try {
      final Uri osmUri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=$latitude&lon=$longitude',
      );

      final http.Response osmRes = await http.get(
        osmUri,
        headers: <String, String>{'User-Agent': 'FoamLaundryApp/1.0'},
      ).timeout(const Duration(seconds: 6));

      if (osmRes.statusCode == 200) {
        final dynamic data = json.decode(osmRes.body);
        final dynamic address = data['address'] ?? <String, dynamic>{};

        final String road = address['road'] ?? address['street'] ?? '';
        final String houseNumber = address['house_number'] ?? '';
        final String suburb =
            address['suburb'] ?? address['neighbourhood'] ?? '';
        final String city = address['city'] ??
            address['town'] ??
            address['municipality'] ??
            suburb;
        final String lga = address['county'] ?? address['district'] ?? city;
        final String state = address['state'] ?? '';
        final String country = address['country'] ?? 'Nigeria';
        final String postcode = address['postcode'] ?? '';
        final String displayName = data['display_name'] ?? '';

        String street = '';
        if (houseNumber.isNotEmpty && road.isNotEmpty) {
          street = '$houseNumber $road';
        } else if (road.isNotEmpty) {
          street = road;
        } else if (suburb.isNotEmpty) {
          street = suburb;
        } else {
          street = displayName.split(',').first.trim();
        }

        return UserLocationDetails(
          street: street,
          city: city.isNotEmpty ? city : lga,
          state: state,
          lga: lga.isNotEmpty ? lga : city,
          postalCode: postcode,
          country: country,
          latitude: latitude,
          longitude: longitude,
          formattedAddress: displayName,
        );
      }
    } catch (osmErr) {
      debugPrint('OpenStreetMap Nominatim reverse geocoding error: $osmErr');
    }

    // 3. Fallback: return coordinates with default structure
    return UserLocationDetails(
      street: '',
      city: '',
      state: '',
      lga: '',
      postalCode: '',
      country: 'Nigeria',
      latitude: latitude,
      longitude: longitude,
      formattedAddress: 'Lat: $latitude, Lng: $longitude',
    );
  }

  /// Full auto-detect workflow: gets GPS position and reverse-geocodes it
  static Future<UserLocationDetails?> autoDetectLocation() async {
    final Position? position = await getCurrentPosition();
    if (position == null) return null;

    return await reverseGeocode(
      latitude: position.latitude,
      longitude: position.longitude,
    );
  }

  /// Search address suggestions with autocomplete (Google Places primary + OpenStreetMap Nominatim fallback)
  static Future<List<AddressSuggestion>> searchAddressSuggestions(
      String query) async {
    final String trimmed = query.trim();
    if (trimmed.length < 2) return <AddressSuggestion>[];

    final List<AddressSuggestion> suggestions = <AddressSuggestion>[];

    // 1. Primary: Google Places Autocomplete API
    try {
      const String apiKey = Constants.googleMapsApiKey;
      final Uri googleUri = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=${Uri.encodeComponent(trimmed)}&components=country:ng&key=$apiKey',
      );
      final http.Response gRes =
          await http.get(googleUri).timeout(const Duration(seconds: 4));

      if (gRes.statusCode == 200) {
        final dynamic gData = json.decode(gRes.body);
        if (gData['status'] == 'OK') {
          final List<dynamic> predictions = gData['predictions'] ?? <dynamic>[];
          for (dynamic pred in predictions) {
            final String desc = pred['description'] ?? '';
            final dynamic structured =
                pred['structured_formatting'] ?? <String, dynamic>{};
            final String mainText =
                structured['main_text'] ?? desc.split(',').first.trim();
            final String secondaryText = structured['secondary_text'] ?? '';

            // Split secondary text (e.g. "Ikeja, Lagos, Nigeria" -> city, state)
            final List<String> parts = secondaryText
                .split(',')
                .map((String s) => s.trim())
                .where((String s) => s.isNotEmpty && s != 'Nigeria')
                .toList();

            final String city = parts.isNotEmpty ? parts.first : '';
            final String state = parts.length > 1
                ? parts[1]
                : (parts.isNotEmpty ? parts.first : '');
            final String lga = city;

            suggestions.add(AddressSuggestion(
              title: mainText,
              subtitle: secondaryText,
              fullAddress: desc,
              details: UserLocationDetails(
                street: mainText,
                city: city,
                state: state,
                lga: lga,
                postalCode: '',
                country: 'Nigeria',
                latitude: 0.0,
                longitude: 0.0,
                formattedAddress: desc,
              ),
            ));
          }
        } else {
          debugPrint(
              'Google Places API returned status: ${gData['status']} (${gData['error_message'] ?? ''}) - falling back to OpenStreetMap');
        }
      }
    } catch (gErr) {
      debugPrint('Google Places autocomplete failed or timed out: $gErr');
    }

    // 2. Fallback: OpenStreetMap Nominatim search if Google Places had no results or failed
    if (suggestions.isEmpty) {
      try {
        final Uri uri = Uri.parse(
          'https://nominatim.openstreetmap.org/search?format=json&addressdetails=1&countrycodes=ng&limit=6&q=${Uri.encodeComponent(trimmed)}',
        );
        final http.Response res = await http.get(
          uri,
          headers: <String, String>{'User-Agent': 'FoamLaundryApp/1.0'},
        ).timeout(const Duration(seconds: 4));

        if (res.statusCode == 200) {
          final List<dynamic> data = json.decode(res.body);
          for (dynamic item in data) {
            final double lat =
                double.tryParse(item['lat']?.toString() ?? '0') ?? 0.0;
            final double lon =
                double.tryParse(item['lon']?.toString() ?? '0') ?? 0.0;
            final dynamic address = item['address'] ?? <String, dynamic>{};

            final String road = address['road'] ?? address['street'] ?? '';
            final String houseNumber = address['house_number'] ?? '';
            final String suburb =
                address['suburb'] ?? address['neighbourhood'] ?? '';
            final String city = address['city'] ??
                address['town'] ??
                address['municipality'] ??
                suburb;
            final String lga = address['county'] ?? address['district'] ?? city;
            final String state = address['state'] ?? '';
            final String country = address['country'] ?? 'Nigeria';
            final String postcode = address['postcode'] ?? '';
            final String displayName = item['display_name'] ?? '';

            String title = item['name'] ?? '';
            if (title.isEmpty) {
              title = road.isNotEmpty
                  ? (houseNumber.isNotEmpty ? '$houseNumber $road' : road)
                  : displayName.split(',').first.trim();
            }

            String subtitle = [suburb, lga, state]
                .where((String s) => s.isNotEmpty)
                .toSet()
                .join(', ');
            if (subtitle.isEmpty) {
              subtitle = displayName;
            }

            final UserLocationDetails details = UserLocationDetails(
              street: title,
              city: city.isNotEmpty ? city : lga,
              state: state,
              lga: lga.isNotEmpty ? lga : city,
              postalCode: postcode,
              country: country,
              latitude: lat,
              longitude: lon,
              formattedAddress: displayName,
            );

            suggestions.add(AddressSuggestion(
              title: title,
              subtitle: subtitle,
              fullAddress: displayName,
              details: details,
            ));
          }
        }
      } catch (e) {
        debugPrint('Nominatim fallback search suggestions error: $e');
      }
    }

    return suggestions;
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
