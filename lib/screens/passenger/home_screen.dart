import 'package:flutter/material.dart';
import 'booking_screen.dart';
import 'trip_history_screen.dart';
import 'profile_screen.dart';

class PassengerHomeScreen extends StatefulWidget {
  const PassengerHomeScreen({super.key});

  @override
  State<PassengerHomeScreen> createState() => _PassengerHomeScreenState();
}

class _PassengerHomeScreenState extends State<PassengerHomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    _HomeContent(),
    TripHistoryScreen(),
    _PaymentsContent(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF1E1E1E),
        selectedItemColor: const Color(0xFFFFC107),
        unselectedItemColor: Colors.white38,
        currentIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Trips'),
          BottomNavigationBarItem(icon: Icon(Icons.payment), label: 'Payments'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Good morning 👋',
                        style: TextStyle(color: Colors.white54, fontSize: 13)),
                    SizedBox(height: 2),
                    Text('Where to?',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
                CircleAvatar(
                  backgroundColor: const Color(0xFF1E1E1E),
                  child: const Icon(Icons.person, color: Color(0xFFFFC107)),
                ),
              ],
            ),
          ),

          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BookingScreen()),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.search, color: Color(0xFFFFC107)),
                    SizedBox(width: 12),
                    Text('Where are you going?',
                        style: TextStyle(color: Colors.white54)),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Quick actions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _quickAction(Icons.home_outlined, 'Home'),
                _quickAction(Icons.work_outline, 'Work'),
                _quickAction(Icons.school_outlined, 'School'),
                _quickAction(Icons.favorite_border, 'Saved'),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Map placeholder + Book button
          Expanded(
            child: Stack(
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.map_outlined, color: Colors.white24, size: 60),
                        SizedBox(height: 12),
                        Text('Map coming soon',
                            style: TextStyle(color: Colors.white24)),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 20,
                  left: 40,
                  right: 40,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFC107),
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const BookingScreen()),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.electric_moped, color: Colors.black),
                        SizedBox(width: 8),
                        Text('Book a Ride',
                            style: TextStyle(
                                color: Colors.black,
                                fontSize: 16,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _quickAction(IconData icon, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: const Color(0xFFFFC107)),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
      ],
    );
  }
}

class _PaymentsContent extends StatelessWidget {
  const _PaymentsContent();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Payments',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            _paymentMethod('MTN MoMo', '055 000 0000', '🟡', active: true),
            const SizedBox(height: 12),
            _paymentMethod('Vodafone Cash', '020 000 0000', '🔴'),
            const SizedBox(height: 12),
            _paymentMethod('AirtelTigo', '027 000 0000', '🔵'),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFFFC107)),
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {},
              icon: const Icon(Icons.add, color: Color(0xFFFFC107)),
              label: const Text('Add Payment Method',
                  style: TextStyle(color: Color(0xFFFFC107))),
            ),
          ],
        ),
      ),
    );
  }

  Widget _paymentMethod(String name, String number, String emoji,
      {bool active = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: active ? const Color(0xFFFFC107) : Colors.transparent,
        ),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
                Text(number,
                    style: const TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
          ),
          if (active)
            const Icon(Icons.check_circle, color: Color(0xFFFFC107), size: 20),
        ],
      ),
    );
  }
}
