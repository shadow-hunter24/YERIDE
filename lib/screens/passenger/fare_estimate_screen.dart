import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/location_service.dart';
import '../../services/trip_service.dart';
import '../../widgets/connectivity_wrapper.dart';
import 'tracking_screen.dart';

class FareEstimateScreen extends StatefulWidget {
  final String pickup;
  final String destination;
  final double pickupLat;
  final double pickupLng;

  const FareEstimateScreen({
    super.key,
    required this.pickup,
    required this.destination,
    required this.pickupLat,
    required this.pickupLng,
  });

  @override
  State<FareEstimateScreen> createState() => _FareEstimateScreenState();
}

class _FareEstimateScreenState extends State<FareEstimateScreen> {
  final _locationService = LocationService();
  final _tripService = TripService();
  double _distanceKm = 0;
  double _fare = 0;
  double _destLat = 0;
  double _destLng = 0;
  bool _loading = true;
  bool _requesting = false;
  String? _selectedRiderId;
  String _selectedRiderName = '';

  @override
  void initState() {
    super.initState();
    _calculateFare();
  }

  void _calculateFare() async {
    try {
      final locations = await locationFromAddress(widget.destination);
      if (locations.isNotEmpty) {
        _destLat = locations.first.latitude;
        _destLng = locations.first.longitude;
      } else {
        _destLat = 5.6037;
        _destLng = -0.1870;
      }

      final dist = _locationService.getDistanceKm(
        _LatLngWrapper(widget.pickupLat, widget.pickupLng),
        _LatLngWrapper(_destLat, _destLng),
      );
      final fare = _locationService.calculateFare(dist);
      if (mounted) {
        setState(() {
          _distanceKm = dist;
          _fare = fare;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _requestRide() async {
    if (_selectedRiderId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a rider'),
          backgroundColor: Color(0xFF1E1E1E),
        ),
      );
      return;
    }
    if (!ConnectivityWrapper.checkAndAlert(context)) return; // offline guard
    setState(() => _requesting = true);
    try {
      final tripId = await _tripService.createTrip(
        pickupAddress: widget.pickup,
        pickupLat: widget.pickupLat,
        pickupLng: widget.pickupLng,
        destinationAddress: widget.destination,
        destinationLat: _destLat,
        destinationLng: _destLng,
        distanceKm: _distanceKm,
        fare: _fare,
        assignedRiderId: _selectedRiderId,
      );
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TrackingScreen(
            tripId: tripId,
            pickup: widget.pickup,
            destination: widget.destination,
            fare: _fare,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to request ride: $e'),
              backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _requesting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Fare Estimate',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFFFC107)))
          : Column(
              children: [
                // Route summary
                Container(
                  margin: const EdgeInsets.all(20),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      _routeRow(Icons.circle, const Color(0xFF4CAF50),
                          widget.pickup),
                      const Padding(
                        padding: EdgeInsets.only(left: 8),
                        child: Divider(color: Colors.white12),
                      ),
                      _routeRow(Icons.location_on, const Color(0xFFFFC107),
                          widget.destination),
                    ],
                  ),
                ),

                // Trip details bar
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _tripDetail(Icons.straighten,
                          '${_distanceKm.toStringAsFixed(1)} km'),
                      _divider(),
                      _tripDetail(Icons.access_time,
                          '~${(_distanceKm * 3).round()} min'),
                      _divider(),
                      _tripDetail(Icons.payments_outlined,
                          'GH₵ ${_fare.toStringAsFixed(2)}'),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Available riders
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: const [
                      Text('Available Riders',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('riders')
                        .where('isOnline', isEqualTo: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                            child: CircularProgressIndicator(
                                color: Color(0xFFFFC107)));
                      }
                      final riders = snapshot.data?.docs ?? [];
                      if (riders.isEmpty) {
                        return const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('🏍',
                                  style: TextStyle(fontSize: 40)),
                              SizedBox(height: 10),
                              Text('No riders available right now',
                                  style: TextStyle(
                                      color: Colors.white54,
                                      fontSize: 14)),
                              SizedBox(height: 4),
                              Text('Try again in a moment',
                                  style: TextStyle(
                                      color: Colors.white38,
                                      fontSize: 12)),
                            ],
                          ),
                        );
                      }
                      return ListView.builder(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: riders.length,
                        itemBuilder: (_, i) {
                          final rider = riders[i].data()
                              as Map<String, dynamic>;
                          final riderId = riders[i].id;
                          final name = rider['name'] ?? 'Rider';
                          final rating =
                              (rider['rating'] ?? 0.0).toStringAsFixed(1);
                          final trips = rider['totalTrips'] ?? 0;
                          final isVerified =
                              rider['isVerified'] ?? false;
                          final selected = _selectedRiderId == riderId;

                          // Calculate distance from passenger to rider
                          final riderLat = (rider['lat'] as num?)?.toDouble();
                          final riderLng = (rider['lng'] as num?)?.toDouble();
                          String distanceText = 'Nearby';
                          if (riderLat != null && riderLng != null) {
                            final d = _locationService.getDistanceKm(
                              _LatLngWrapper(widget.pickupLat, widget.pickupLng),
                              _LatLngWrapper(riderLat, riderLng),
                            );
                            final eta = (d * 3).round();
                            distanceText = '${d.toStringAsFixed(1)} km · ~$eta min away';
                          }

                          return GestureDetector(
                            onTap: () => setState(() {
                              _selectedRiderId = riderId;
                              _selectedRiderName = name;
                            }),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: selected
                                    ? const Color(0xFFFFC107)
                                        .withValues(alpha: 0.1)
                                    : const Color(0xFF1E1E1E),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: selected
                                      ? const Color(0xFFFFC107)
                                      : Colors.transparent,
                                ),
                              ),
                              child: Row(
                                children: [
                                  const CircleAvatar(
                                    backgroundColor: Color(0xFF121212),
                                    child: Text('🏍',
                                        style: TextStyle(fontSize: 18)),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(name,
                                                style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight:
                                                        FontWeight.bold,
                                                    fontSize: 14)),
                                            if (isVerified) ...[
                                              const SizedBox(width: 6),
                                              const Icon(
                                                  Icons.verified,
                                                  color:
                                                      Color(0xFF4CAF50),
                                                  size: 14),
                                            ],
                                          ],
                                        ),
                                        const SizedBox(height: 3),
                                        Row(
                                          children: [
                                            const Icon(Icons.star,
                                                color: Color(0xFFFFC107),
                                                size: 12),
                                            const SizedBox(width: 3),
                                            Text('$rating · $trips trips',
                                                style: const TextStyle(
                                                    color: Colors.white54,
                                                    fontSize: 12)),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                          'GH₵ ${_fare.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                              color: Color(0xFFFFC107),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14)),
                                      const SizedBox(height: 3),
                                      Text(distanceText,
                                          style: const TextStyle(
                                              color: Colors.white38,
                                              fontSize: 11)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),

                // Payment method
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.account_balance_wallet_outlined,
                            color: Color(0xFFFFC107)),
                        SizedBox(width: 12),
                        Text('MTN MoMo',
                            style: TextStyle(
                                color: Colors.white, fontSize: 14)),
                        Spacer(),
                        Text('Change',
                            style: TextStyle(
                                color: Color(0xFFFFC107), fontSize: 13)),
                      ],
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFC107),
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _requesting ? null : _requestRide,
                    child: _requesting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                color: Colors.black, strokeWidth: 2))
                        : Text(
                            _selectedRiderId == null
                                ? 'Select a Rider'
                                : 'Request $_selectedRiderName · GH₵ ${_fare.toStringAsFixed(2)}',
                            style: const TextStyle(
                                color: Colors.black,
                                fontSize: 15,
                                fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _routeRow(IconData icon, Color color, String text) {
    return Row(
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 12),
        Expanded(
          child: Text(text,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }

  Widget _tripDetail(IconData icon, String value) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFFFFC107), size: 20),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(color: Colors.white, fontSize: 13)),
      ],
    );
  }

  Widget _divider() =>
      Container(width: 1, height: 30, color: Colors.white12);
}

class _LatLngWrapper {
  final double latitude;
  final double longitude;
  _LatLngWrapper(this.latitude, this.longitude);
}
