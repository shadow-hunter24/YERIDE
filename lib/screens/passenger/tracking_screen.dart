import 'package:flutter/material.dart';
import 'rating_screen.dart';

class TrackingScreen extends StatefulWidget {
  const TrackingScreen({super.key});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  final List<Map<String, String>> _steps = [
    {'status': 'Finding your rider...', 'done': 'false'},
    {'status': 'Rider accepted your request', 'done': 'false'},
    {'status': 'Rider is on the way', 'done': 'false'},
    {'status': 'Rider arrived', 'done': 'false'},
    {'status': 'Trip in progress', 'done': 'false'},
  ];
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    _simulateProgress();
  }

  void _simulateProgress() async {
    for (int i = 0; i < _steps.length; i++) {
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        setState(() => _currentStep = i + 1);
      }
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
                  Text('Live Map',
                      style: TextStyle(color: Colors.white12, fontSize: 16)),
                ],
              ),
            ),
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
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Status
                  Text(
                    _currentStep < _steps.length
                        ? _steps[_currentStep]['status']!
                        : 'Trip Completed!',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),

                  // Rider info
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: const Color(0xFF121212),
                        child: const Text('🏍', style: TextStyle(fontSize: 24)),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text('Kwame Asante',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16)),
                            SizedBox(height: 2),
                            Text('Honda CB125 · GR-1234-21',
                                style: TextStyle(
                                    color: Colors.white54, fontSize: 13)),
                            SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.star,
                                    color: Color(0xFFFFC107), size: 14),
                                SizedBox(width: 4),
                                Text('4.8',
                                    style: TextStyle(
                                        color: Colors.white54, fontSize: 13)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Call & chat buttons
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.call,
                            color: Color(0xFFFFC107)),
                      ),
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.chat_bubble_outline,
                            color: Color(0xFFFFC107)),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Progress steps
                  ...List.generate(_steps.length, (i) {
                    final done = i < _currentStep;
                    final active = i == _currentStep;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Icon(
                            done ? Icons.check_circle : Icons.radio_button_unchecked,
                            color: done
                                ? const Color(0xFF4CAF50)
                                : active
                                    ? const Color(0xFFFFC107)
                                    : Colors.white24,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            _steps[i]['status']!,
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

                  const SizedBox(height: 20),

                  if (_currentStep >= _steps.length)
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFC107),
                        minimumSize: const Size(double.infinity, 52),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const RatingScreen()),
                      ),
                      child: const Text('Complete Trip',
                          style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 16)),
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
