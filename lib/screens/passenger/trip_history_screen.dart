import 'package:flutter/material.dart';

class TripHistoryScreen extends StatelessWidget {
  const TripHistoryScreen({super.key});

  final List<Map<String, String>> _trips = const [
    {
      'from': 'Kaneshie Market',
      'to': 'Accra Mall, Spintex',
      'date': 'Today, 9:14 AM',
      'fare': 'GH₵ 8.00',
      'status': 'Completed',
    },
    {
      'from': 'University of Ghana',
      'to': 'Tema Station',
      'date': 'Yesterday, 3:40 PM',
      'fare': 'GH₵ 15.00',
      'status': 'Completed',
    },
    {
      'from': 'Airport Residential',
      'to': 'Osu, Oxford Street',
      'date': 'Apr 13, 11:00 AM',
      'fare': 'GH₵ 10.00',
      'status': 'Cancelled',
    },
  ];

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
        title: const Text('Trip History',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _trips.length,
        itemBuilder: (_, i) {
          final trip = _trips[i];
          final completed = trip['status'] == 'Completed';
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
                    Text(trip['date']!,
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 12)),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: completed
                            ? const Color(0xFF4CAF50).withOpacity(0.15)
                            : Colors.red.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        trip['status']!,
                        style: TextStyle(
                          color: completed
                              ? const Color(0xFF4CAF50)
                              : Colors.redAccent,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _routeRow(Icons.circle, const Color(0xFF4CAF50), trip['from']!),
                Padding(
                  padding: const EdgeInsets.only(left: 7),
                  child: Container(
                      width: 2, height: 16, color: Colors.white12),
                ),
                _routeRow(
                    Icons.location_on, const Color(0xFFFFC107), trip['to']!),
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
                    Text(trip['fare']!,
                        style: const TextStyle(
                            color: Color(0xFFFFC107),
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
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
