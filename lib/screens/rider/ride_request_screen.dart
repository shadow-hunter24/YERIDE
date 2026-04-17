import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/trip_service.dart';
import '../../services/user_service.dart';
import 'navigation_screen.dart';

class RideRequestScreen extends StatefulWidget {
  const RideRequestScreen({super.key});

  @override
  State<RideRequestScreen> createState() => _RideRequestScreenState();
}

class _RideRequestScreenState extends State<RideRequestScreen> {
  final TripService _tripService = TripService();

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
        title: const Text('Incoming Requests',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _tripService.getPendingTrips(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: Color(0xFFFFC107)));
          }
          final trips = snapshot.data?.docs ?? [];
          if (trips.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('🏍', style: TextStyle(fontSize: 48)),
                  SizedBox(height: 12),
                  Text('No ride requests yet',
                      style: TextStyle(color: Colors.white54, fontSize: 16)),
                  SizedBox(height: 6),
                  Text('Waiting for passengers...',
                      style: TextStyle(color: Colors.white38, fontSize: 13)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: trips.length,
            itemBuilder: (_, i) {
              final trip = trips[i].data() as Map<String, dynamic>;
              final tripId = trips[i].id;
              return _TripRequestCard(
                tripId: tripId,
                trip: trip,
                tripService: _tripService,
              );
            },
          );
        },
      ),
    );
  }
}

class _TripRequestCard extends StatefulWidget {
  final String tripId;
  final Map<String, dynamic> trip;
  final TripService tripService;

  const _TripRequestCard({
    required this.tripId,
    required this.trip,
    required this.tripService,
  });

  @override
  State<_TripRequestCard> createState() => _TripRequestCardState();
}

class _TripRequestCardState extends State<_TripRequestCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int _countdown = 30;
  bool _accepting = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..forward();

    Stream.periodic(const Duration(seconds: 1), (i) => i)
        .take(30)
        .listen((i) {
      if (mounted) setState(() => _countdown = 29 - i);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _accept() async {
    setState(() => _accepting = true);
    try {
      final userData = await UserService().getCurrentUserData();
      final riderName = userData?['name'] ?? 'Rider';
      await widget.tripService.acceptTrip(widget.tripId, riderName);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => NavigationScreen(
            tripId: widget.tripId,
            pickup: widget.trip['pickupAddress'] ?? '',
            destination: widget.trip['destinationAddress'] ?? '',
            fare: (widget.trip['fare'] as num?)?.toDouble() ?? 0.0,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to accept: $e'),
              backgroundColor: Colors.redAccent),
        );
        setState(() => _accepting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pickup = widget.trip['pickupAddress'] ?? '';
    final destination = widget.trip['destinationAddress'] ?? '';
    final fare = (widget.trip['fare'] as num?)?.toStringAsFixed(2) ?? '0.00';
    final distance = (widget.trip['distanceKm'] as num?)?.toStringAsFixed(1) ?? '0';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFC107).withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          // Header with countdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFFFC107),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('New Ride Request!',
                    style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 15)),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 36,
                      height: 36,
                      child: AnimatedBuilder(
                        animation: _controller,
                        builder: (_, a) => CircularProgressIndicator(
                          value: 1 - _controller.value,
                          color: Colors.black,
                          backgroundColor: Colors.black26,
                          strokeWidth: 3,
                        ),
                      ),
                    ),
                    Text('$_countdown',
                        style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Fare
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFC107).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: const Color(0xFFFFC107).withValues(alpha: 0.3)),
                  ),
                  child: Text('GH₵ $fare',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Color(0xFFFFC107),
                          fontSize: 26,
                          fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 14),

                // Route
                Row(
                  children: [
                    const Icon(Icons.circle, color: Color(0xFF4CAF50), size: 12),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(pickup,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 13),
                          overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 5),
                  child: Container(width: 2, height: 16, color: Colors.white12),
                ),
                Row(
                  children: [
                    const Icon(Icons.location_on,
                        color: Color(0xFFFFC107), size: 14),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(destination,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 13),
                          overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Details
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _detail(Icons.straighten, '$distance km'),
                    Container(width: 1, height: 28, color: Colors.white12),
                    _detail(Icons.access_time,
                        '~${(double.tryParse(distance) ?? 0 * 3).round()} min'),
                    Container(width: 1, height: 28, color: Colors.white12),
                    _detail(Icons.payments_outlined, 'GH₵ $fare'),
                  ],
                ),
                const SizedBox(height: 16),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white24),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () {},
                        child: const Text('Decline',
                            style: TextStyle(color: Colors.white54)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFC107),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: _accepting ? null : _accept,
                        child: _accepting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    color: Colors.black, strokeWidth: 2))
                            : const Text('Accept',
                                style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detail(IconData icon, String value) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFFFFC107), size: 18),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 12)),
      ],
    );
  }
}
