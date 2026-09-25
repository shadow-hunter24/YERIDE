import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationService {

  /// Ensures location service is on and permission is granted.
  /// Shows dialogs guiding the user to fix each problem.
  /// Returns true when location is fully ready, false if the user refuses.
  Future<bool> ensureLocationReady(BuildContext context) async {
    // ── 1. Location service (GPS hardware switch) ─────────────────────
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!context.mounted) return false;
      final openSettings = await _showDialog(
        context,
        title: 'Location is off',
        message:
            'YɛRide needs your location to show nearby riders and navigate. '
            'Please turn on Location in your device settings.',
        confirmLabel: 'Open Settings',
      );
      if (openSettings) await Geolocator.openLocationSettings();
      // Re-check after returning from settings
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return false;
    }

    // ── 2. App permission ─────────────────────────────────────────────
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (!context.mounted) return false;
        await _showDialog(
          context,
          title: 'Location permission denied',
          message:
              'YɛRide needs location access to work. '
              'Please allow location permission when prompted.',
          confirmLabel: 'OK',
          showCancel: false,
        );
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (!context.mounted) return false;
      final openSettings = await _showDialog(
        context,
        title: 'Location permission blocked',
        message:
            'Location permission has been permanently denied. '
            'Open App Settings and enable Location to use YɛRide.',
        confirmLabel: 'Open Settings',
      );
      if (openSettings) await Geolocator.openAppSettings();
      // Re-check
      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return false;
      }
    }

    return true;
  }

  /// Generic two-button dialog. Returns true when the confirm button is tapped.
  Future<bool> _showDialog(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
    bool showCancel = true,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.location_on, color: Color(0xFFFFC107)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
        actions: [
          if (showCancel)
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Not now',
                  style: TextStyle(color: Colors.white38)),
            ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFC107),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(confirmLabel,
                style: const TextStyle(
                    color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  // Request permission and get current position
  Future<Position?> getCurrentPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }
    if (permission == LocationPermission.deniedForever) return null;

    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );
  }

  // Stream live location updates
  Stream<Position> getLiveLocation() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // update every 10 meters
      ),
    );
  }

  // Convert coordinates to address
  Future<String> getAddressFromLatLng(double lat, double lng) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        return '${p.street}, ${p.locality}';
      }
    } catch (_) {}
    return '$lat, $lng';
  }

  // Calculate distance in km
  double getDistanceKm(dynamic from, dynamic to) {
    final meters = Geolocator.distanceBetween(
      from.latitude, from.longitude,
      to.latitude, to.longitude,
    );
    return meters / 1000;
  }

  // Calculate fare based on distance
  double calculateFare(double distanceKm) {
    const double baseFare = 3.0;
    const double perKmRate = 1.5;
    final fare = baseFare + (distanceKm * perKmRate);
    return double.parse(fare.toStringAsFixed(2));
  }
}
