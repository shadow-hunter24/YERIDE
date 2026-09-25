import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
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
  // 0 = heading to pickup   → writes 'arriving'  on accept (already written)
  // 1 = arrived at pickup   → writes 'arrived'   when rider taps "Arrived at Pickup"
  // 2 = passenger onboard   → writes 'ongoing'   when rider taps "Picked Up Passenger"
  // 3 = at destination      → writes 'completed' when rider taps "Complete Trip"
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
  LatLng? _passengerLatLng; // live passenger position

  StreamSubscription? _locationSub;
  StreamSubscription? _tripSub; // listens for passenger location updates

  bool _loading = false;
  bool _drawing = false; // prevents concurrent _drawRoute calls
  String? _passengerPhone;
  String _passengerName = 'Passenger';

  List<Map<String, String>> get _steps => [
        {'label': 'Head to pickup point',    'sub': widget.pickup},
        {'label': 'Arrived at pickup',       'sub': 'Wait for passenger'},
        {'label': 'Passenger onboard',       'sub': 'Navigate to destination'},
        {'label': 'Arrived at destination',  'sub': widget.destination},
      ];

  @override
  void initState() {
    super.initState();
    _loadTripData();
    _startLocationTracking();
    _listenToPassengerLocation();
  }

  @override
  void dispose() {
    _locationSub?.cancel();
    _tripSub?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  /// Load pickup/destination coordinates and passenger details from Firestore
  Future<void> _loadTripData() async {
    final snap = await _tripService.listenToTrip(widget.tripId).first;
    final data = snap.data() as Map<String, dynamic>?;
    if (data == null || !mounted) return;

    final pLat  = (data['pickupLat']      as num?)?.toDouble();
    final pLng  = (data['pickupLng']      as num?)?.toDouble();
    final dLat  = (data['destinationLat'] as num?)?.toDouble();
    final dLng  = (data['destinationLng'] as num?)?.toDouble();
    final psLat = (data['passengerLat']   as num?)?.toDouble();
    final psLng = (data['passengerLng']   as num?)?.toDouble();

    if (pLat != null && pLng != null) _pickupLatLng    = LatLng(pLat, pLng);
    if (dLat != null && dLng != null) _destinationLatLng = LatLng(dLat, dLng);
    if (psLat != null && psLng != null) _passengerLatLng = LatLng(psLat, psLng);

    // Fetch passenger name & phone
    final passengerId = data['passengerId'] as String?;
    if (passengerId != null && passengerId.isNotEmpty) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(passengerId)
          .get();
      final name  = userDoc.data()?['name']  as String?;
      final phone = userDoc.data()?['phone'] as String?;
      if (mounted) {
        setState(() {
          if (name  != null && name.isNotEmpty)  _passengerName  = name.split(' ').first;
          if (phone != null && phone.isNotEmpty) _passengerPhone = phone.trim();
        });
      }
    }

    await _drawRoute();
  }

  /// Listen to live passenger location changes in Firestore
  void _listenToPassengerLocation() {
    _tripSub = _tripService.listenToTrip(widget.tripId).listen((snap) async {
      if (!mounted) return;
      final data = snap.data() as Map<String, dynamic>?;
      if (data == null) return;

      final psLat = (data['passengerLat'] as num?)?.toDouble();
      final psLng = (data['passengerLng'] as num?)?.toDouble();

      if (psLat != null && psLng != null) {
        final newPos = LatLng(psLat, psLng);
        // Compare actual coordinate values, not object references
        final changed = _passengerLatLng == null ||
            (_passengerLatLng!.latitude - newPos.latitude).abs() > 0.000001 ||
            (_passengerLatLng!.longitude - newPos.longitude).abs() > 0.000001;
        if (changed) {
          _passengerLatLng = newPos;
          await _drawRoute();
        }
      }
    });
  }

  /// Stream the rider's GPS to Firestore every 10 metres
  void _startLocationTracking() async {
    final pos = await _locationService.getCurrentPosition();
    if (pos != null && mounted) {
      _currentPos = LatLng(pos.latitude, pos.longitude);
      // Write initial position to Firestore immediately so the passenger map
      // shows the rider marker as soon as the screen opens — the stream won't
      // fire until the device moves ≥10 m, which could take a long time.
      await _tripService.updateRiderLocation(
          widget.tripId, pos.latitude, pos.longitude);
      await _drawRoute();
    }

    _locationSub = _locationService.getLiveLocation().listen((pos) async {
      if (!mounted) return;
      _currentPos = LatLng(pos.latitude, pos.longitude);
      // Write rider position to Firestore (passenger TrackingScreen reads this)
      await _tripService.updateRiderLocation(
          widget.tripId, pos.latitude, pos.longitude);
      await _drawRoute();
    });
  }

  Future<void> _drawRoute() async {
    if (_currentPos == null) return;
    if (_drawing) return; // drop concurrent calls — one draw at a time
    _drawing = true;

    try {
      LatLng destination;

      if (_step <= 1) {
        // Steps 0 & 1: heading to / waiting at pickup
        if (_pickupLatLng == null) {
          return; // finally resets _drawing
        }
        destination = _pickupLatLng!;
      } else {
        // Steps 2 & 3: passenger onboard, heading to drop-off
        if (_destinationLatLng == null) {
          return; // finally resets _drawing
        }
        destination = _destinationLatLng!;
      }

      final points = await _mapService.getRoutePoints(_currentPos!, destination);
      if (!mounted) return;

      setState(() {
        _polylines = {
          Polyline(
            polylineId: const PolylineId('route'),
            points: points.isNotEmpty ? points : [_currentPos!, destination],
            color: const Color(0xFFFFC107),
            width: 5,
          ),
        };
        _markers = _buildMarkers(destination);
      });

      _mapController?.animateCamera(
          MapService.fitBounds(_currentPos!, destination));
    } finally {
      _drawing = false; // always released, even on early return
    }
  }

  Set<Marker> _buildMarkers(LatLng destination) {
    final markers = <Marker>{
      // Rider — green (you)
      Marker(
        markerId: const MarkerId('rider'),
        position: _currentPos!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: const InfoWindow(title: 'You'),
      ),
      // Destination — yellow (pickup or drop-off)
      Marker(
        markerId: const MarkerId('destination'),
        position: destination,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
        infoWindow: InfoWindow(
            title: _step <= 1 ? widget.pickup : widget.destination),
      ),
    };

    // Passenger live location — blue (only shown before pickup)
    if (_step <= 1 && _passengerLatLng != null) {
      markers.add(Marker(
        markerId: const MarkerId('passenger'),
        position: _passengerLatLng!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: InfoWindow(title: '👤 $_passengerName'),
      ));
    }

    return markers;
  }

  Future<void> _callPassenger() async {
    if (_passengerPhone == null || _passengerPhone!.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Passenger phone number not available'),
            backgroundColor: Color(0xFF1E1E1E),
          ),
        );
      }
      return;
    }
    final uri = Uri(scheme: 'tel', path: _passengerPhone);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  void _nextStep() async {
    setState(() => _loading = true);
    try {
      if (_step == 0) {
        // Rider arrived at pickup point → tell passenger "Rider has arrived"
        await _tripService.updateTripStatus(widget.tripId, 'arrived');
        setState(() => _step = 1);
        await _drawRoute();
      } else if (_step == 1) {
        // Passenger boarded → trip is now ongoing
        await _tripService.updateTripStatus(widget.tripId, 'ongoing');
        setState(() => _step = 2);
        await _drawRoute();
      } else if (_step == 2) {
        // Rider arrived at destination → complete the trip
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
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Stack(
        children: [
          // ── Full-screen live map ──────────────────────────────────────
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

          // ── Direction banner (top) ────────────────────────────────────
          Positioned(
            top: 48,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
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

          // ── Bottom sheet ──────────────────────────────────────────────
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFF1E1E1E),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Drag handle
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white12,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Passenger info row
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
                              'GH₵ ${widget.fare.toStringAsFixed(2)} · $_passengerName',
                              style: const TextStyle(
                                  color: Color(0xFFFFC107), fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      CircleAvatar(
                        backgroundColor:
                            const Color(0xFFFFC107).withValues(alpha: 0.15),
                        child: IconButton(
                          icon: const Icon(Icons.call,
                              color: Color(0xFFFFC107), size: 20),
                          onPressed: _callPassenger,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Step progress bar
                  Row(
                    children: List.generate(3, (i) {
                      return Expanded(
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 4,
                                decoration: BoxDecoration(
                                  color: i < _step
                                      ? const Color(0xFFFFC107)
                                      : i == _step
                                          ? const Color(0xFFFFC107).withValues(alpha: 0.4)
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
                          style: TextStyle(color: Colors.white38, fontSize: 11)),
                      Text('Onboard',
                          style: TextStyle(color: Colors.white38, fontSize: 11)),
                      Text('Drop-off',
                          style: TextStyle(color: Colors.white38, fontSize: 11)),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Action button
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
                                    ? 'Picked Up Passenger'
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
