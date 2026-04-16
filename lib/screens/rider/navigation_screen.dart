import 'package:flutter/material.dart';
import 'rate_passenger_screen.dart';

class NavigationScreen extends StatefulWidget {
  const NavigationScreen({super.key});

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  int _step = 0; // 0=going to pickup, 1=passenger onboard, 2=arrived

  final List<Map<String, String>> _steps = [
    {'label': 'Head to pickup point', 'sub': 'Kaneshie Market'},
    {'label': 'Passenger onboard', 'sub': 'Navigate to destination'},
    {'label': 'Arrived at destination', 'sub': 'Accra Mall, Spintex'},
  ];

  void _nextStep() {
    if (_step < 2) {
      setState(() => _step++);
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const RatePassengerScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Stack(
        children: [
          // Map placeholder
          Container(
            color: const Color(0xFF1A1A2E),
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.map, color: Colors.white12, size: 80),
                  SizedBox(height: 12),
                  Text('Navigation Map',
                      style: TextStyle(color: Colors.white12)),
                ],
              ),
            ),
          ),

          // Top direction banner
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
                                color: Colors.black54, fontSize: 12)),
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
                  // Passenger info
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
                          children: const [
                            Text('Ama Korantema',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold)),
                            Text('Passenger',
                                style: TextStyle(
                                    color: Colors.white54, fontSize: 12)),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text('Pickup', style: TextStyle(color: Colors.white38, fontSize: 11)),
                      Text('Onboard', style: TextStyle(color: Colors.white38, fontSize: 11)),
                      Text('Drop-off', style: TextStyle(color: Colors.white38, fontSize: 11)),
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
                    onPressed: _nextStep,
                    child: Text(
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
