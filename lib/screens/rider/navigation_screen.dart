import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../services/trip_service.dart';
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
  int _step = 0; // 0=going to pickup, 1=passenger onboard, 2=arrived
  final TripService _tripService = TripService();
  bool _loading = false;

  List<Map<String, String>> get _steps => [
        {'label': 'Head to pickup point', 'sub': widget.pickup},
        {'label': 'Passenger onboard', 'sub': 'Navigate to destination'},
        {'label': 'Arrived at destination', 'sub': widget.destination},
      ];

  void _nextStep() async {
    if (_step < 2) {
      setState(() => _step++);
      if (_step == 1) {
        await _tripService.updateTripStatus(widget.tripId, 'ongoing');
      }
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
                  // Trip info
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
                          style: TextStyle(
                              color: Colors.white38, fontSize: 11)),
                      Text('Onboard',
                          style: TextStyle(
                              color: Colors.white38, fontSize: 11)),
                      Text('Drop-off',
                          style: TextStyle(
                              color: Colors.white38, fontSize: 11)),
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
