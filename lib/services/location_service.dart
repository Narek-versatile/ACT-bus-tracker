import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/location_data.dart';
import 'storage_service.dart';

/// Service for managing GPS location tracking
class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  final StorageService _storage = StorageService();

  /// Check and request location permissions
  Future<bool> requestPermissions() async {
    // Check if location service is enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('Location services are disabled');
      return false;
    }

    // Request location permissions
    PermissionStatus locationStatus = await Permission.location.status;
    if (!locationStatus.isGranted) {
      locationStatus = await Permission.location.request();
    }

    if (locationStatus.isGranted) {
      // For Android 10+, also request background location
      if (await Permission.locationAlways.isDenied) {
        await Permission.locationAlways.request();
      }

      // Request notification permission (Android 13+)
      if (await Permission.notification.isDenied) {
        await Permission.notification.request();
      }

      // Request to ignore battery optimizations
      // We do this last as it might switch context
      if (await Permission.ignoreBatteryOptimizations.isDenied) {
        await Permission.ignoreBatteryOptimizations.request();
      }

      // Re-check critical permissions
      final finalLocation = await Permission.location.isGranted;
      final finalNotification = await Permission.notification.isGranted;

      return finalLocation && finalNotification;
    }

    print('Location permission denied');
    return false;
  }

  /// Check if we have the necessary permissions
  Future<bool> hasPermissions() async {
    final locationGranted = await Permission.location.isGranted;
    final notificationGranted = await Permission.notification.isGranted;
    // We treat 'ignore battery' as optional/setup, but location and notification are critical for service
    return locationGranted && notificationGranted;
  }

  /// Get current location
  Future<Position?> getCurrentLocation() async {
    try {
      if (!await hasPermissions()) {
        print('No location permission');
        return null;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      return position;
    } catch (e) {
      print('Error getting location: $e');
      return null;
    }
  }

  /// Create LocationData object from current position
  Future<LocationData?> getLocationData() async {
    final position = await getCurrentLocation();
    if (position == null) {
      return null;
    }

    if (!_storage.isSetupComplete()) {
      print('App not set up');
      return null;
    }

    return LocationData(lat: position.latitude, lon: position.longitude);
  }
}
