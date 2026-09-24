import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/trip_service.dart';
import '../../services/map_service.dart';
import '../../services/location_service.dart';
import 'rating_screen.dart';

class TrackingScreen extends StatefulWidget {
  final String tripId;
  final String pickup;
  final String destination;
  final double fare;

  const TrackingScreen({
    super.key,
    required this.tripId,
    required this.pickup,
    required this.destination,
    required this.fare,
  });

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  final _tripService = TripService();
  final _mapService = MapService();
  final _locationService = LocationService();

  GoogleMapController? _mapController;
  Set<Polyline> _polylines = {};
  Set<Marker> _markers = {};

  // Last known positions — used to detect actual movement before redrawing
  LatLng? _lastRiderPos;
  LatLng? _pickupLatLng;
  LatLng? _destinationLatLng;
  String? _riderPhone;
  String _lastStatus = '';

  // Passenger live location stream
  StreamSubscription? _passengerLocationSub;

  @override
  void initState() {
    super.initState();
    _startPassengerLocationUpdates();
  }

  @override
  void dispose() {
    _passengerLocationSub?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  /// Stream the passenger's live position to Firestore so the rider can see it
  void _startPassengerLocationUpdates() {
    _passengerLocationSub =
        _locationService.getLiveLocation().listen((pos) async {
      await _tripService.updatePassengerLocation(
          widget.tripId, pos.latitude, pos.longitude);
    });
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'pending':   return 'Finding your rider...';
      case 'accepted':  return 'Rider accepted your request';
      case 'arriving':  return 'Rider is on the way';
      case 'arrived':   return 'Rider has arrived';
      case 'ongoing':   return 'Trip in progress';
      case 'completed': return 'Trip Completed!';
      default:          return 'Processing...';
    }
  }

  int _stepIndex(String status) {
    switch (status) {
      case 'pending':   return 0;
      case 'accepted':  return 1;
      case 'arriving':  return 2;
      case 'arrived':   return 3;
      case 'ongoing':   return 4;
      case 'completed': return 5;
      default:          return 0;
    }
  }

  final List<String> _steps = [
    'Finding your rider...',
    'Rider accepted your request',
    'Rider is on the way',
    'Rider arrived',
    'Trip in progress',
  ];

  Future<void> _callRider(String? riderId) async {
    if (_riderPhone == null && riderId != null && riderId.isNotEmpty) {
      final doc = await FirebaseFirestore.instance
          .collection('riders')
          .doc(riderId)
          .get();
      _riderPhone = (doc.data()?['phone'] as String?)?.trim();
    }
    if (_riderPhone == null || _riderPhone!.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rider phone number not available'),
            backgroundColor: Color(0xFF1E1E1E),
          ),
        );
      }
      return;
    }
    final uri = Uri(scheme: 'tel', path: _riderPhone);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  /// Redraws the route and all markers based on the latest trip snapshot.
  /// Called on every Firestore update.
  Future<void> _updateMap(Map<String, dynamic> data) async {
    final pickupLat    = (data['pickupLat']      as num?)?.toDouble();
    final pickupLng    = (data['pickupLng']      as num?)?.toDouble();
    final riderLat     = (data['riderLat']       as num?)?.toDouble();
    final riderLng     = (data['riderLng']       as num?)?.toDouble();
    final destLat      = (data['destinationLat'] as num?)?.toDouble();
    final destLng      = (data['destinationLng'] as num?)?.toDouble();
    final status       = data['status'] as String? ?? 'pending';

    if (pickupLat == null || pickupLng == null) return;

    final pickup = LatLng(pickupLat, pickupLng);
    _pickupLatLng = pickup;

    if (destLat != null && destLng != null) {
      _destinationLatLng = LatLng(destLat, destLng);
    }

    // Determine route endpoints based on trip status
    LatLng? origin;
    LatLng? dest;

    if (riderLat != null && riderLng != null) {
      final riderPos = LatLng(riderLat, riderLng);

      if (status == 'ongoing' && _destinationLatLng != null) {
        // Rider is heading to destination
        origin = riderPos;
        dest   = _destinationLatLng!;
      } else {
        // Rider is heading to pickup
        origin = riderPos;
        dest   = pickup;
      }

      // Only redraw route when rider has actually moved (>5m) or status changed
      final riderMoved = _lastRiderPos == null ||
          _distanceMeters(_lastRiderPos!, riderPos) > 5;
      final statusChanged = status != _lastStatus;

      if (riderMoved || statusChanged) {
        _lastRiderPos = riderPos;
        _lastStatus   = status;

        final points = await _mapService.getRoutePoints(origin, dest);
        if (!mounted) return;

        setState(() {
          _polylines = {
            Polyline(
              polylineId: const PolylineId('route'),
              points: points.isNotEmpty ? points : [origin!, dest!],
              color: const Color(0xFFFFC107),
              width: 5,
            ),
          };
          _markers = _buildMarkers(riderPos, pickup, dest!, status);
        });

        // Smoothly pan camera to keep both endpoints in view
        _mapController
            ?.animateCamera(MapService.fitBounds(origin, dest));
      } else {
        // Just update marker position without redrawing the polyline
        if (!mounted) return;
        setState(() {
          _markers = _buildMarkers(riderPos, pickup, dest!, status);
        });
      }
    } else {
      // No rider position yet — just show pickup pin
      if (!mounted) return;
      setState(() {
        _markers = {
          Marker(
            markerId: const MarkerId('pickup'),
            position: pickup,
            icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueYellow),
            infoWindow: InfoWindow(title: widget.pickup),
          ),
        };
      });
      _mapController
          ?.animateCamera(CameraUpdate.newLatLngZoom(pickup, 15));
    }
  }

  Set<Marker> _buildMarkers(
      LatLng rider, LatLng pickup, LatLng dest, String status) {
    return {
      // Rider — green motorbike marker
      Marker(
        markerId: const MarkerId('rider'),
        position: rider,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: const InfoWindow(title: '🏍 Rider'),
      ),
      // Destination marker
      Marker(
        markerId: const MarkerId('dest'),
        position: dest,
        icon: BitmapDescriptor.defaultMarkerWithHue(
            status == 'ongoing'
                ? BitmapDescriptor.hueRed
                : BitmapDescriptor.hueYellow),
        infoWindow: InfoWindow(
            title: status == 'ongoing' ? widget.destination : widget.pickup),
      ),
    };
  }

  double _distanceMeters(LatLng a, LatLng b) {
    return _locationService.getDistanceKm(a, b) * 1000;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _tripService.listenToTrip(widget.tripId),
        builder: (context, snapshot) {
          final data = snapshot.data?.data() as Map<String, dynamic>?;
          final status    = data?['status']     as String? ?? 'pending';
          final riderName = data?['riderName']  as String? ?? 'Finding rider...';
          final riderId   = data?['riderId']    as String?;
          final currentStep = _stepIndex(status);

          // Fire map update on every Firestore snapshot
          if (data != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _updateMap(data);
            });
          }

          // Auto-navigate to rating when trip completes
          if (status == 'completed') {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => RatingScreen(
                    tripId: widget.tripId,
                    riderId: riderId ?? '',
                    riderName: riderName,
                    fare: widget.fare,
                  ),
                ),
              );
            });
          }

          final initialPos = _pickupLatLng ?? const LatLng(5.6037, -0.1870);

          return Stack(
            children: [
              // ── Full-screen live map ──────────────────────────────────
              GoogleMap(
                initialCameraPosition:
                    CameraPosition(target: initialPos, zoom: 15),
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                polylines: _polylines,
                markers: _markers,
                onMapCreated: (c) {
                  _mapController = c;
                  if (data != null) _updateMap(data);
                },
              ),

              // ── Back button ───────────────────────────────────────────
              Positioned(
                top: 48,
                left: 16,
                child: CircleAvatar(
                  backgroundColor: const Color(0xFF1E1E1E),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),

              // ── Status chip (top center) ──────────────────────────────
              Positioned(
                top: 48,
                left: 70,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _statusLabel(status),
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),

              // ── Bottom sheet ──────────────────────────────────────────
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFF1E1E1E),
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(24)),
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

                      // Rider info row
                      Row(
                        children: [
                          const CircleAvatar(
                            radius: 24,
                            backgroundColor: Color(0xFF121212),
                            child: Text('🏍', style: TextStyle(fontSize: 22)),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(riderName,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15)),
                                const SizedBox(height: 2),
                                Text(
                                  'GH₵ ${widget.fare.toStringAsFixed(2)} · '
                                  '${widget.pickup} → ${widget.destination}',
                                  style: const TextStyle(
                                      color: Colors.white54, fontSize: 12),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          // Call rider button
                          CircleAvatar(
                            backgroundColor:
                                const Color(0xFFFFC107).withValues(alpha: 0.15),
                            child: IconButton(
                              icon: const Icon(Icons.call,
                                  color: Color(0xFFFFC107), size: 20),
                              onPressed: () => _callRider(riderId),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Progress steps
                      ...List.generate(_steps.length, (i) {
                        final done   = i < currentStep;
                        final active = i == currentStep;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Row(
                            children: [
                              Icon(
                                done
                                    ? Icons.check_circle
                                    : Icons.radio_button_unchecked,
                                color: done
                                    ? const Color(0xFF4CAF50)
                                    : active
                                        ? const Color(0xFFFFC107)
                                        : Colors.white24,
                                size: 18,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                _steps[i],
                                style: TextStyle(
                                  color: done
                                      ? Colors.white
                                      : active
                                          ? const Color(0xFFFFC107)
                                          : Colors.white38,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),

                      const SizedBox(height: 16),

                      // Cancel button (only when pending)
                      if (status == 'pending')
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side:
                                const BorderSide(color: Colors.white24),
                            minimumSize:
                                const Size(double.infinity, 48),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () async {
                            final nav = Navigator.of(context);
                            await _tripService.updateTripStatus(
                                widget.tripId, 'cancelled');
                            nav.pop();
                          },
                          child: const Text('Cancel Ride',
                              style:
                                  TextStyle(color: Colors.white54)),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
