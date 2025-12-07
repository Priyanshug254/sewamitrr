import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../screens/location_permission_screen.dart';

class LocationService {
  Future<Position> getCurrentLocation({BuildContext? context}) async {
    // Check if location services are enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (context != null) {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const LocationPermissionScreen()),
        );
        if (result != true) {
          throw Exception('Location services are disabled');
        }
        // Recheck after user interaction
        serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          throw Exception('Location services are disabled');
        }
      } else {
        throw Exception('Location services are disabled');
      }
    }

    // Check location permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      if (context != null) {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const LocationPermissionScreen()),
        );
        if (result != true) {
          throw Exception('Location permission denied');
        }
        // Recheck permission
        permission = await Geolocator.checkPermission();
      } else {
        permission = await Geolocator.requestPermission();
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (context != null) {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const LocationPermissionScreen()),
        );
      }
      throw Exception('Location permissions are permanently denied');
    }

    if (permission == LocationPermission.denied) {
      throw Exception('Location permission denied');
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  Future<String> getAddressFromCoordinates(double lat, double lng) async {
    // Skip reverse geocoding on web due to CORS
    if (kIsWeb) {
      return 'Lat: ${lat.toStringAsFixed(4)}, Lng: ${lng.toStringAsFixed(4)}';
    }
    
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lng&zoom=18&addressdetails=1'
      );
      
      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'SewaMitr/1.0',
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['display_name'] ?? 'Unknown Location';
      }
      return 'Lat: ${lat.toStringAsFixed(4)}, Lng: ${lng.toStringAsFixed(4)}';
    } catch (e) {
      return 'Lat: ${lat.toStringAsFixed(4)}, Lng: ${lng.toStringAsFixed(4)}';
    }
  }

  Future<Map<String, double>?> getCoordinatesFromAddress(String address) async {
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?format=json&q=${Uri.encodeComponent(address)}&limit=1'
      );
      
      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'SewaMitr/1.0',
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List && data.isNotEmpty) {
          final result = data[0];
          return {
            'latitude': double.parse(result['lat']),
            'longitude': double.parse(result['lon']),
          };
        }
      }
      return null;
    } catch (e) {
      print('Geocoding error: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> searchLocations(String query) async {
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?format=json&q=${Uri.encodeComponent(query)}&limit=5'
      );
      
      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'SewaMitr/1.0',
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List) {
          return data.cast<Map<String, dynamic>>();
        }
      }
      return [];
    } catch (e) {
      print('Search locations error: $e');
      return [];
    }
  }

  Future<double> calculateDistance(double lat1, double lng1, double lat2, double lng2) async {
    return Geolocator.distanceBetween(lat1, lng1, lat2, lng2) / 1000; // Convert to km
  }
}