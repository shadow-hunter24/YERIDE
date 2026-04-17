import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/trip_service.dart';

class TripHistoryScreen extends StatelessWidget {
  const TripHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text('Trip History',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: TripService().getPassengerTrips(),
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
                  Text('No trips yet',
                      style: TextStyle(color: Colors.white54, fontSize: 16)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: trips.length,
            itemBuilder: (_, i) {
              final trip = trips[i].data() as Map<String, dynamic>;
              final status = trip['status'] ?? '';
              final completed = status == 'completed';
              final createdAt = trip['createdAt'] as Timestamp?;
              final date = createdAt != null
                  ? _formatDate(createdAt.toDate())
                  : 'Recently';

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(date,
                            style: const TextStyle(
                                color: Colors.white54, fontSize: 12)),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: completed
                                ? const Color(0xFF4CAF50).withValues(alpha: 0.15)
                                : status == 'cancelled'
                                    ? Colors.red.withValues(alpha: 0.15)
                                    : Colors.orange.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            status[0].toUpperCase() + status.substring(1),
                            style: TextStyle(
                              color: completed
                                  ? const Color(0xFF4CAF50)
                                  : status == 'cancelled'
                                      ? Colors.redAccent
                                      : Colors.orange,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _routeRow(Icons.circle, const Color(0xFF4CAF50),
                        trip['pickupAddress'] ?? ''),
                    Padding(
                      padding: const EdgeInsets.only(left: 7),
                      child: Container(
                          width: 2, height: 16, color: Colors.white12),
                    ),
                    _routeRow(Icons.location_on, const Color(0xFFFFC107),
                        trip['destinationAddress'] ?? ''),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: const [
                            Text('🏍', style: TextStyle(fontSize: 14)),
                            SizedBox(width: 6),
                            Text('OkadaGo',
                                style: TextStyle(
                                    color: Colors.white54, fontSize: 13)),
                          ],
                        ),
                        Text(
                          'GH₵ ${(trip['fare'] as num?)?.toStringAsFixed(2) ?? '0.00'}',
                          style: const TextStyle(
                              color: Color(0xFFFFC107),
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) return 'Today, ${_time(date)}';
    if (diff.inDays == 1) return 'Yesterday, ${_time(date)}';
    return '${date.day}/${date.month}/${date.year}, ${_time(date)}';
  }

  String _time(DateTime date) {
    final h = date.hour > 12 ? date.hour - 12 : date.hour;
    final m = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $period';
  }

  Widget _routeRow(IconData icon, Color color, String text) {
    return Row(
      children: [
        Icon(icon, color: color, size: 12),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}
