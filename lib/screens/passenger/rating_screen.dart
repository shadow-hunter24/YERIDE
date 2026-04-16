import 'package:flutter/material.dart';
import 'home_screen.dart';

class RatingScreen extends StatefulWidget {
  const RatingScreen({super.key});

  @override
  State<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends State<RatingScreen> {
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
              const Text('Trip Completed!',
                  style: TextStyle(
                      color: Color(0xFF4CAF50),
                      fontSize: 22,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('GH₵ 8.00 paid via MTN MoMo',
                  style: TextStyle(color: Colors.white54)),
              const SizedBox(height: 40),

              // Rider avatar
              const CircleAvatar(
                radius: 40,
                backgroundColor: Color(0xFF1E1E1E),
                child: Text('🏍', style: TextStyle(fontSize: 36)),
              ),
              const SizedBox(height: 12),
              const Text('Kwame Asante',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              const Text('How was your ride?',
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

              // Comment
              TextField(
                controller: _commentController,
                style: const TextStyle(color: Colors.white),
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Leave a comment (optional)',
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: const Color(0xFF1E1E1E),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
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
                      builder: (_) => const PassengerHomeScreen()),
                  (route) => false,
                ),
                child: const Text('Submit Rating',
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
                      builder: (_) => const PassengerHomeScreen()),
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
}
