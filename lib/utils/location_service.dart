import 'package:location/location.dart' as loc;
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart' as permissions;

class LocationService {
  static final loc.Location _location = loc.Location();

  // Check and request location permissions
  static Future<bool> requestLocationPermission() async {
    var status = await permissions.Permission.location.status;
    if (status.isDenied) {
      status = await permissions.Permission.location.request();
    }
    return status.isGranted;
  }

  // Get current location
  static Future<loc.LocationData?> getCurrentLocation() async {
    try {
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

      return await _location.getLocation();
    } catch (e) {
      print('Error getting location: $e');
      return null;
    }
  }

  // Get address from coordinates
  static Future<String> getAddressFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
      );
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        return '${place.street ?? ''}, ${place.locality ?? ''}, ${place.administrativeArea ?? ''}, ${place.country ?? ''}'
            .replaceAll(
              RegExp(r'^,\s*|,\s*$'),
              '',
            ) // Remove leading/trailing commas
            .replaceAll(RegExp(r',\s*,'), ','); // Remove double commas
      }
    } catch (e) {
      print('Error getting address: $e');
    }
    return 'Address not found';
  }
}
