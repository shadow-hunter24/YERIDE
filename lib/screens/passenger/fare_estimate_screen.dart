import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import '../../services/location_service.dart';
import '../../services/trip_service.dart';
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
  String _selectedRide = 'OkadaGo';

  @override
  void initState() {
    super.initState();
    _calculateFare();
  }

  void _calculateFare() async {
    try {
      // Geocode destination
      final locations = await locationFromAddress(widget.destination);
      if (locations.isNotEmpty) {
        _destLat = locations.first.latitude;
        _destLng = locations.first.longitude;
      } else {
        // Fallback: use Accra coordinates
        _destLat = 5.6037;
        _destLng = -0.1870;
      }

      final from = _locationService.getDistanceKm(
        _latLng(widget.pickupLat, widget.pickupLng),
        _latLng(_destLat, _destLng),
      );
      final fare = _locationService.calculateFare(from);
      if (mounted) {
        setState(() {
          _distanceKm = from;
          _fare = _selectedRide == 'OkadaExpress' ? fare * 1.5 : fare;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  dynamic _latLng(double lat, double lng) {
    // Using a simple wrapper since we can't import google_maps_flutter here
    return _LatLngWrapper(lat, lng);
  }

  void _requestRide() async {
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

                // Ride options
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Choose Ride Type',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      _rideOption(
                        icon: '🏍',
                        title: 'OkadaGo',
                        subtitle: '~2 min away',
                        price:
                            'GH₵ ${_locationService.calculateFare(_distanceKm).toStringAsFixed(2)}',
                        selected: _selectedRide == 'OkadaGo',
                        onTap: () => setState(() {
                          _selectedRide = 'OkadaGo';
                          _fare = _locationService.calculateFare(_distanceKm);
                        }),
                      ),
                      const SizedBox(height: 10),
                      _rideOption(
                        icon: '⚡',
                        title: 'OkadaExpress',
                        subtitle: '~5 min away · Faster route',
                        price:
                            'GH₵ ${(_locationService.calculateFare(_distanceKm) * 1.5).toStringAsFixed(2)}',
                        selected: _selectedRide == 'OkadaExpress',
                        onTap: () => setState(() {
                          _selectedRide = 'OkadaExpress';
                          _fare = _locationService.calculateFare(_distanceKm) *
                              1.5;
                        }),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Trip details
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

                const SizedBox(height: 16),

                // Payment method
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.account_balance_wallet_outlined,
                            color: Color(0xFFFFC107)),
                        SizedBox(width: 12),
                        Text('MTN MoMo',
                            style:
                                TextStyle(color: Colors.white, fontSize: 14)),
                        Spacer(),
                        Text('Change',
                            style: TextStyle(
                                color: Color(0xFFFFC107), fontSize: 13)),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
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
                            'Request Ride · GH₵ ${_fare.toStringAsFixed(2)}',
                            style: const TextStyle(
                                color: Colors.black,
                                fontSize: 16,
                                fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 24),
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

  Widget _rideOption({
    required String icon,
    required String title,
    required String subtitle,
    required String price,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFFFFC107).withOpacity(0.1)
              : const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? const Color(0xFFFFC107) : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                  Text(subtitle,
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 12)),
                ],
              ),
            ),
            Text(price,
                style: const TextStyle(
                    color: Color(0xFFFFC107), fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _tripDetail(IconData icon, String value) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFFFFC107), size: 20),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 13)),
      ],
    );
  }

  Widget _divider() =>
      Container(width: 1, height: 30, color: Colors.white12);
}

// Simple wrapper to avoid importing google_maps_flutter in this file
class _LatLngWrapper {
  final double latitude;
  final double longitude;
  _LatLngWrapper(this.latitude, this.longitude);
}
