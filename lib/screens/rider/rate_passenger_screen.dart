import 'package:flutter/material.dart';
import 'home_screen.dart';

class RatePassengerScreen extends StatefulWidget {
  const RatePassengerScreen({super.key});

  @override
  State<RatePassengerScreen> createState() => _RatePassengerScreenState();
}

class _RatePassengerScreenState extends State<RatePassengerScreen> {
  int _rating = 0;
  final _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 20),

              // Trip summary
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const Text('Trip Completed!',
                        style: TextStyle(
                            color: Color(0xFF4CAF50),
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _tripStat('Earned', 'GH₵ 8.00'),
                        Container(width: 1, height: 30, color: Colors.white12),
                        _tripStat('Distance', '3.2 km'),
                        Container(width: 1, height: 30, color: Colors.white12),
                        _tripStat('Duration', '12 min'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Passenger avatar
              const CircleAvatar(
                radius: 40,
                backgroundColor: Color(0xFF1E1E1E),
                child: Text('👤', style: TextStyle(fontSize: 36)),
              ),
              const SizedBox(height: 12),
              const Text('Ama Korantema',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              const Text('How was this passenger?',
                  style: TextStyle(color: Colors.white54)),
              const SizedBox(height: 24),

              // Stars
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  return GestureDetector(
                    onTap: () => setState(() => _rating = i + 1),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Icon(
                        i < _rating ? Icons.star : Icons.star_border,
                        color: const Color(0xFFFFC107),
                        size: 40,
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 32),

              // Quick tags
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: ['Polite', 'On time', 'Clear directions', 'Good tipper']
                    .map((tag) => GestureDetector(
                          onTap: () {},
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E1E1E),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white12),
                            ),
                            child: Text(tag,
                                style: const TextStyle(
                                    color: Colors.white54, fontSize: 13)),
                          ),
                        ))
                    .toList(),
              ),
              const Spacer(),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFC107),
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const RiderHomeScreen()),
                  (route) => false,
                ),
                child: const Text('Submit & Go Online',
                    style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const RiderHomeScreen()),
                  (route) => false,
                ),
                child: const Text('Skip',
                    style: TextStyle(color: Colors.white38)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tripStat(String label, String value) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                color: Color(0xFFFFC107),
                fontWeight: FontWeight.bold,
                fontSize: 16)),
        const SizedBox(height: 4),
        Text(label,
            style: const TextStyle(color: Colors.white54, fontSize: 12)),
      ],
    );
  }
}
