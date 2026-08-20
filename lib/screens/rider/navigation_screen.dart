import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../services/trip_service.dart';
import '../../services/location_service.dart';
import '../../services/map_service.dart';
import 'rate_passenger_screen.dart';

class NavigationScreen extends StatefulWidget {
  final String tripId;
  final String pickup;
  final String destination;
  final double fare;

  const NavigationScreen({
    super.key,
    required this.tripId,
    required this.pickup,
    required this.destination,
    required this.fare,
  });

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  int _step = 0;
  final TripService _tripService = TripService();
  final LocationService _locationService = LocationService();
  final MapService _mapService = MapService();
  GoogleMapController? _mapController;
  Set<Polyline> _polylines = {};
  Set<Marker> _markers = {};
  LatLng? _currentPos;
  LatLng? _pickupLatLng;
  LatLng? _destinationLatLng;
  StreamSubscription? _locationSub;
  bool _loading = false;

  List<Map<String, String>> get _steps => [
        {'label': 'Head to pickup point', 'sub': widget.pickup},
        {'label': 'Passenger onboard', 'sub': 'Navigate to destination'},
        {'label': 'Arrived at destination', 'sub': widget.destination},
      ];

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  @override
  void dispose() {
    _locationSub?.cancel();
    super.dispose();
  }

  void _initLocation() async {
    final pos = await _locationService.getCurrentPosition();
    if (pos != null && mounted) {
      _currentPos = LatLng(pos.latitude, pos.longitude);
      await _drawRoute();
    }

    // Stream live location updates to Firestore
    _locationSub = _locationService.getLiveLocation().listen((pos) async {
      if (!mounted) return;
      _currentPos = LatLng(pos.latitude, pos.longitude);
      await _tripService.updateRiderLocation(
          widget.tripId, pos.latitude, pos.longitude);
      await _drawRoute();
    });
  }

  Future<void> _drawRoute() async {
    if (_currentPos == null) return;

    LatLng destination;

    if (_step == 0) {
      // Going to pickup — need pickup coordinates from Firestore
      if (_pickupLatLng == null) {
        final snap = await _tripService.listenToTrip(widget.tripId).first;
        final data = snap.data() as Map<String, dynamic>?;
        if (data != null) {
          final lat = (data['pickupLat'] as num?)?.toDouble();
          final lng = (data['pickupLng'] as num?)?.toDouble();
          final dLat = (data['destinationLat'] as num?)?.toDouble();
          final dLng = (data['destinationLng'] as num?)?.toDouble();
          if (lat != null && lng != null) {
            _pickupLatLng = LatLng(lat, lng);
          }
          if (dLat != null && dLng != null) {
            _destinationLatLng = LatLng(dLat, dLng);
          }
        }
      }
      if (_pickupLatLng == null) return;
      destination = _pickupLatLng!;
    } else {
      // Going to destination
      if (_destinationLatLng == null) return;
      destination = _destinationLatLng!;
    }

    final points =
        await _mapService.getRoutePoints(_currentPos!, destination);

    if (!mounted) return;
    setState(() {
      _polylines = {
        Polyline(
          polylineId: const PolylineId('route'),
          points: points.isNotEmpty ? points : [_currentPos!, destination],
          color: const Color(0xFFFFC107),
          width: 4,
        ),
      };
      _markers = {
        Marker(
          markerId: const MarkerId('rider'),
          position: _currentPos!,
          icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueGreen),
          infoWindow: const InfoWindow(title: 'You'),
        ),
        Marker(
          markerId: const MarkerId('destination'),
          position: destination,
          icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueYellow),
          infoWindow: InfoWindow(
              title: _step == 0 ? widget.pickup : widget.destination),
        ),
      };
    });

    _mapController
        ?.animateCamera(MapService.fitBounds(_currentPos!, destination));
  }

  void _nextStep() async {
    if (_step < 2) {
      setState(() => _step++);
      if (_step == 1) {
        await _tripService.updateTripStatus(widget.tripId, 'ongoing');
      }
      await _drawRoute();
    } else {
      setState(() => _loading = true);
      await _tripService.completeTrip(widget.tripId, widget.fare);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => RatePassengerScreen(
            tripId: widget.tripId,
            fare: widget.fare,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Stack(
        children: [
          // Live Map with route
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _currentPos ?? const LatLng(5.6037, -0.1870),
              zoom: 15,
            ),
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            polylines: _polylines,
            markers: _markers,
            onMapCreated: (c) {
              _mapController = c;
              _drawRoute();
            },
          ),

          // Top direction banner
          Positioned(
            top: 48,
            left: 16,
            right: 16,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFC107),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.navigation, color: Colors.black),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_steps[_step]['label']!,
                            style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 15)),
                        Text(_steps[_step]['sub']!,
                            style: const TextStyle(
                                color: Colors.black54, fontSize: 12),
                            overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom sheet
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFF1E1E1E),
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: Color(0xFF121212),
                        child: Text('👤', style: TextStyle(fontSize: 20)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${widget.pickup} → ${widget.destination}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'GH₵ ${widget.fare.toStringAsFixed(2)}',
                              style: const TextStyle(
                                  color: Color(0xFFFFC107), fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.call,
                            color: Color(0xFFFFC107)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Step indicators
                  Row(
                    children: List.generate(3, (i) {
                      return Expanded(
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 4,
                                decoration: BoxDecoration(
                                  color: i <= _step
                                      ? const Color(0xFFFFC107)
                                      : Colors.white12,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                            if (i < 2) const SizedBox(width: 4),
                          ],
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 8),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Pickup',
                          style:
                              TextStyle(color: Colors.white38, fontSize: 11)),
                      Text('Onboard',
                          style:
                              TextStyle(color: Colors.white38, fontSize: 11)),
                      Text('Drop-off',
                          style:
                              TextStyle(color: Colors.white38, fontSize: 11)),
                    ],
                  ),
                  const SizedBox(height: 20),

                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFC107),
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _loading ? null : _nextStep,
                    child: _loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.black, strokeWidth: 2))
                        : Text(
                            _step == 0
                                ? 'Arrived at Pickup'
                                : _step == 1
                                    ? 'Start Trip'
                                    : 'Complete Trip',
                            style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 16),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
