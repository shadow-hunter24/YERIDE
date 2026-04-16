import 'package:flutter/material.dart';
import 'navigation_screen.dart';

class RideRequestScreen extends StatefulWidget {
  const RideRequestScreen({super.key});

  @override
  State<RideRequestScreen> createState() => _RideRequestScreenState();
}

class _RideRequestScreenState extends State<RideRequestScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int _countdown = 15;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..forward();

    // Countdown timer
    Stream.periodic(const Duration(seconds: 1), (i) => i).take(15).listen((i) {
      if (mounted) {
        setState(() => _countdown = 14 - i);
        if (_countdown <= 0) _decline();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _accept() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const NavigationScreen()),
    );
  }

  void _decline() {
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black54,
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top bar with countdown
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFFFFC107),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('New Ride Request!',
                        style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 16)),
                    // Countdown circle
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 40,
                          height: 40,
                          child: AnimatedBuilder(
                            animation: _controller,
                            builder: (_, __) => CircularProgressIndicator(
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
                                fontSize: 13)),
                      ],
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Fare highlight
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFC107).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: const Color(0xFFFFC107).withOpacity(0.3)),
                      ),
                      child: const Text('GH₵ 8.00',
                          style: TextStyle(
                              color: Color(0xFFFFC107),
                              fontSize: 28,
                              fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 20),

                    // Route
                    _routeRow(Icons.circle, const Color(0xFF4CAF50),
                        'Kaneshie Market'),
                    Padding(
                      padding: const EdgeInsets.only(left: 7),
                      child: Container(
                          width: 2, height: 20, color: Colors.white12),
                    ),
                    _routeRow(Icons.location_on, const Color(0xFFFFC107),
                        'Accra Mall, Spintex'),
                    const SizedBox(height: 20),

                    // Trip details
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _detail(Icons.straighten, '3.2 km'),
                        Container(
                            width: 1, height: 30, color: Colors.white12),
                        _detail(Icons.access_time, '~12 min'),
                        Container(
                            width: 1, height: 30, color: Colors.white12),
                        _detail(Icons.person_outline, 'Ama K.'),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Accept / Decline buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.white24),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: _decline,
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
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: _accept,
                            child: const Text('Accept',
                                style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _routeRow(IconData icon, Color color, String text) {
    return Row(
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 10),
        Text(text, style: const TextStyle(color: Colors.white, fontSize: 14)),
      ],
    );
  }

  Widget _detail(IconData icon, String value) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFFFFC107), size: 18),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(color: Colors.white, fontSize: 12)),
      ],
    );
  }
}
