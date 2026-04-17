import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../services/trip_service.dart';
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

  String _statusLabel(String status) {
    switch (status) {
      case 'pending': return 'Finding your rider...';
      case 'accepted': return 'Rider accepted your request';
      case 'arriving': return 'Rider is on the way';
      case 'arrived': return 'Rider has arrived';
      case 'ongoing': return 'Trip in progress';
      case 'completed': return 'Trip Completed!';
      default: return 'Processing...';
    }
  }

  int _stepIndex(String status) {
    switch (status) {
      case 'pending': return 0;
      case 'accepted': return 1;
      case 'arriving': return 2;
      case 'arrived': return 3;
      case 'ongoing': return 4;
      case 'completed': return 5;
      default: return 0;
    }
  }

  final List<String> _steps = [
    'Finding your rider...',
    'Rider accepted your request',
    'Rider is on the way',
    'Rider arrived',
    'Trip in progress',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _tripService.listenToTrip(widget.tripId),
        builder: (context, snapshot) {
          final data = snapshot.data?.data() as Map<String, dynamic>?;
          final status = data?['status'] ?? 'pending';
          final riderName = data?['riderName'] ?? 'Finding rider...';
          final currentStep = _stepIndex(status);

          // Auto navigate to rating when completed
          if (status == 'completed') {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => RatingScreen(
                    tripId: widget.tripId,
                    riderId: data?['riderId'] ?? '',
                    riderName: riderName,
                    fare: widget.fare,
                  ),
                ),
              );
            });
          }

          return Stack(
            children: [
              // Live Map
              GoogleMap(
                initialCameraPosition: const CameraPosition(
                  target: LatLng(5.6037, -0.1870),
                  zoom: 15,
                ),
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
              ),

              // Back button
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
                      Text(
                        _statusLabel(status),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),

                      // Rider info
                      Row(
                        children: [
                          const CircleAvatar(
                            radius: 28,
                            backgroundColor: Color(0xFF121212),
                            child: Text('🏍', style: TextStyle(fontSize: 24)),
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
                                        fontSize: 16)),
                                const SizedBox(height: 2),
                                Text(
                                  'GH₵ ${widget.fare.toStringAsFixed(2)} · ${widget.pickup} → ${widget.destination}',
                                  style: const TextStyle(
                                      color: Colors.white54, fontSize: 12),
                                  overflow: TextOverflow.ellipsis,
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

                      const SizedBox(height: 20),

                      // Progress steps
                      ...List.generate(_steps.length, (i) {
                        final done = i < currentStep;
                        final active = i == currentStep;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
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
                            side: const BorderSide(color: Colors.white24),
                            minimumSize: const Size(double.infinity, 48),
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
                              style: TextStyle(color: Colors.white54)),
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
