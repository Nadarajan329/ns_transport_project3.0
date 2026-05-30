import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service that handles live location tracking for drivers.
/// Gets the device GPS location and pushes it to Supabase.
class LocationService {
  static LocationService? _instance;
  Timer? _timer;
  bool _isTracking = false;

  LocationService._();

  static LocationService get instance {
    _instance ??= LocationService._();
    return _instance!;
  }

  bool get isTracking => _isTracking;

  /// Check and request location permissions.
  /// Returns true if location access is granted.
  Future<bool> checkPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  /// Get the current device position.
  Future<Position?> getCurrentPosition() async {
    try {
      final hasPermission = await checkPermission();
      if (!hasPermission) return null;

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
    } catch (e) {
      print('Error getting location: $e');
      return null;
    }
  }

  /// Push the current location to Supabase users table.
  Future<void> updateLocationInSupabase() async {
    try {
      final position = await getCurrentPosition();
      if (position == null) return;

      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      await Supabase.instance.client
          .from('users')
          .update({
            'latitude': position.latitude,
            'longitude': position.longitude,
          })
          .eq('id', userId);

      print('Location updated: ${position.latitude}, ${position.longitude}');
    } catch (e) {
      print('Error updating location: $e');
    }
  }

  /// Start periodic location tracking.
  /// Updates location every [intervalSeconds] (default: 30 seconds).
  Future<void> startTracking({int intervalSeconds = 30}) async {
    if (_isTracking) return;

    final hasPermission = await checkPermission();
    if (!hasPermission) return;

    _isTracking = true;

    // Send location immediately
    await updateLocationInSupabase();

    // Then update periodically
    _timer = Timer.periodic(
      Duration(seconds: intervalSeconds),
      (_) => updateLocationInSupabase(),
    );
  }

  /// Stop location tracking.
  void stopTracking() {
    _timer?.cancel();
    _timer = null;
    _isTracking = false;
  }

  /// Dispose the service.
  void dispose() {
    stopTracking();
    _instance = null;
  }
}
