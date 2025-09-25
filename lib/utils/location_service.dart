import 'package:location/location.dart' as loc;
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart' as permissions;

class LocationService {
  static final loc.Location _location = loc.Location();
  static const int _locationTimeoutSeconds = 10;
  static const int _geocodingTimeoutSeconds = 5;

  // Cache for recent geocoding results
  static final Map<String, String> _geocodingCache = {};

  // Configure location settings for better performance
  static Future<void> _configureLocationSettings() async {
    try {
      // Set location settings for faster response
      await _location.changeSettings(
        accuracy:
            loc.LocationAccuracy.balanced, // Balanced instead of high for speed
        interval: 5000, // 5 seconds
        distanceFilter: 10, // 10 meters
      );
    } catch (e) {
      print('Failed to configure location settings: $e');
    }
  }

  // Check and request location permissions
  static Future<bool> requestLocationPermission() async {
    var status = await permissions.Permission.location.status;
    if (status.isDenied) {
      status = await permissions.Permission.location.request();
    }
    return status.isGranted;
  }

  // Get current location with timeout and performance optimization
  static Future<loc.LocationData?> getCurrentLocation() async {
    try {
      // Configure location settings for better performance
      await _configureLocationSettings();

      bool serviceEnabled = await _location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await _location.requestService();
        if (!serviceEnabled) {
          return null;
        }
      }

      loc.PermissionStatus permissionGranted = await _location.hasPermission();
      if (permissionGranted == loc.PermissionStatus.denied) {
        permissionGranted = await _location.requestPermission();
        if (permissionGranted != loc.PermissionStatus.granted) {
          return null;
        }
      }

      // Get location with timeout for better user experience
      return await _location.getLocation().timeout(
        Duration(seconds: _locationTimeoutSeconds),
        onTimeout: () {
          print(
            'Location request timed out after $_locationTimeoutSeconds seconds',
          );
          throw Exception('Location request timed out');
        },
      );
    } catch (e) {
      print('Error getting location: $e');
      return null;
    }
  }

  // Get address from coordinates with caching and timeout
  static Future<String> getAddressFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    try {
      // Create cache key for this location (rounded to avoid too many cache entries)
      final cacheKey =
          '${latitude.toStringAsFixed(4)},${longitude.toStringAsFixed(4)}';

      // Check cache first
      if (_geocodingCache.containsKey(cacheKey)) {
        print('Using cached address for $cacheKey');
        return _geocodingCache[cacheKey]!;
      }

      // Get address with timeout
      List<Placemark>
      placemarks = await placemarkFromCoordinates(latitude, longitude).timeout(
        Duration(seconds: _geocodingTimeoutSeconds),
        onTimeout: () {
          print(
            'Geocoding request timed out after $_geocodingTimeoutSeconds seconds',
          );
          throw Exception('Geocoding request timed out');
        },
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        String address =
            '${place.street ?? ''}, ${place.locality ?? ''}, ${place.administrativeArea ?? ''}, ${place.country ?? ''}'
                .replaceAll(
                  RegExp(r'^,\s*|,\s*$'),
                  '',
                ) // Remove leading/trailing commas
                .replaceAll(RegExp(r',\s*,'), ','); // Remove double commas

        // Cache the result
        _geocodingCache[cacheKey] = address;

        // Limit cache size to prevent memory issues
        if (_geocodingCache.length > 50) {
          final firstKey = _geocodingCache.keys.first;
          _geocodingCache.remove(firstKey);
        }

        return address;
      }
    } catch (e) {
      print('Error getting address: $e');

      // Return a basic coordinate-based address if geocoding fails
      return 'Location: ${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';
    }
    return 'Address not found';
  }

  // Get location with fallback to last known location for speed
  static Future<loc.LocationData?> getLocationFast() async {
    try {
      // Configure settings for speed
      await _configureLocationSettings();

      // Try to get last known location first (much faster)
      try {
        final lastKnown = await _location.getLocation().timeout(
          const Duration(seconds: 2), // Very short timeout for fast response
        );
        print(
          'Got location quickly: ${lastKnown.latitude}, ${lastKnown.longitude}',
        );
        return lastKnown;
      } catch (e) {
        print('Fast location failed, falling back to regular method: $e');
        // If fast method fails, fall back to regular method
        return await getCurrentLocation();
      }
    } catch (e) {
      print('Error in fast location: $e');
      return null;
    }
  }

  // Clear geocoding cache
  static void clearGeocodingCache() {
    _geocodingCache.clear();
    print('Geocoding cache cleared');
  }
}
