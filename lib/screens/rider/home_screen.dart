import 'package:flutter/material.dart';
import '../../services/user_service.dart';
import 'ride_request_screen.dart';

class RiderHomeScreen extends StatefulWidget {
  const RiderHomeScreen({super.key});

  @override
  State<RiderHomeScreen> createState() => _RiderHomeScreenState();
}

class _RiderHomeScreenState extends State<RiderHomeScreen> {
  bool _isOnline = false;
  int _selectedIndex = 0;
  String _name = '';

  @override
  void initState() {
    super.initState();
    _loadName();
  }

  void _loadName() async {
    final data = await UserService().getCurrentUserData();
    if (mounted && data != null) {
      setState(() => _name = data['name'] ?? '');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: _selectedIndex == 0
          ? _buildHome()
          : _selectedIndex == 1
              ? _buildEarnings()
              : _buildRiderProfile(),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF1E1E1E),
        selectedItemColor: const Color(0xFFFFC107),
        unselectedItemColor: Colors.white38,
        currentIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_wallet), label: 'Earnings'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildHome() {
    return SafeArea(
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('YɛRide Rider',
                        style: TextStyle(color: Colors.white54, fontSize: 13)),
                    const SizedBox(height: 2),
                    Text(_name.isEmpty ? 'Rider' : _name,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
                // Online toggle
                GestureDetector(
                  onTap: () => setState(() => _isOnline = !_isOnline),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: _isOnline
                          ? const Color(0xFF4CAF50).withOpacity(0.2)
                          : const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _isOnline
                            ? const Color(0xFF4CAF50)
                            : Colors.white24,
                      ),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 5,
                          backgroundColor: _isOnline
                              ? const Color(0xFF4CAF50)
                              : Colors.white38,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isOnline ? 'Online' : 'Offline',
                          style: TextStyle(
                            color: _isOnline
                                ? const Color(0xFF4CAF50)
                                : Colors.white38,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Stats row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                _statCard('Today', 'GH₵ 0.00', Icons.payments_outlined),
                const SizedBox(width: 12),
                _statCard('Trips', '0', Icons.electric_moped),
                const SizedBox(width: 12),
                _statCard('Rating', '4.8 ⭐', Icons.star_outline),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Map area
          Expanded(
            child: Stack(
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.map_outlined,
                            color: _isOnline
                                ? const Color(0xFFFFC107).withOpacity(0.3)
                                : Colors.white12,
                            size: 60),
                        const SizedBox(height: 12),
                        Text(
                          _isOnline
                              ? 'Waiting for ride requests...'
                              : 'Go online to receive requests',
                          style: TextStyle(
                            color: _isOnline
                                ? Colors.white38
                                : Colors.white12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                if (_isOnline)
                  Positioned(
                    top: 16,
                    left: 36,
                    right: 36,
                    child: GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const RideRequestScreen()),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4CAF50),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.wifi, color: Colors.white, size: 16),
                            SizedBox(width: 8),
                            Text('You are online — tap to simulate request',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildEarnings() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Earnings',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFFFC107),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                children: [
                  Text('Total Earnings',
                      style: TextStyle(color: Colors.black54, fontSize: 13)),
                  SizedBox(height: 8),
                  Text('GH₵ 340.00',
                      style: TextStyle(
                          color: Colors.black,
                          fontSize: 36,
                          fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text('This week',
                      style: TextStyle(color: Colors.black54, fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: _earningCard('Today', 'GH₵ 0.00')),
                const SizedBox(width: 12),
                Expanded(child: _earningCard('This Month', 'GH₵ 1,240.00')),
              ],
            ),
            const SizedBox(height: 20),
            const Text('Recent Trips',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _earningTrip('Kaneshie → Accra Mall', 'GH₵ 8.00', 'Today 9:14 AM'),
            _earningTrip('Legon → Tema Station', 'GH₵ 15.00', 'Yesterday'),
          ],
        ),
      ),
    );
  }

  Widget _buildRiderProfile() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 48,
              backgroundColor: Color(0xFF1E1E1E),
              child: Text('🏍', style: TextStyle(fontSize: 40)),
            ),
            const SizedBox(height: 12),
            const Text('Kwame Asante',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text('+233 24 000 0000',
                style: TextStyle(color: Colors.white54)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.star, color: Color(0xFFFFC107), size: 16),
                SizedBox(width: 4),
                Text('4.8',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
                SizedBox(width: 4),
                Text('· 142 trips',
                    style: TextStyle(color: Colors.white54)),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text('✓ Verified Rider',
                  style: TextStyle(
                      color: Color(0xFF4CAF50), fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 32),
            _menuItem(Icons.directions_bike, 'My Vehicle'),
            _menuItem(Icons.document_scanner, 'Documents'),
            _menuItem(Icons.account_balance_wallet_outlined, 'Payout Settings'),
            _menuItem(Icons.help_outline, 'Help & Support'),
            _menuItem(Icons.logout, 'Logout', color: Colors.redAccent),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFFFFC107), size: 20),
            const SizedBox(height: 6),
            Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13)),
            Text(label,
                style: const TextStyle(color: Colors.white38, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _earningCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
          const SizedBox(height: 6),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18)),
        ],
      ),
    );
  }

  Widget _earningTrip(String route, String fare, String time) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.electric_moped, color: Color(0xFFFFC107)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(route,
                    style: const TextStyle(color: Colors.white, fontSize: 13)),
                Text(time,
                    style: const TextStyle(color: Colors.white38, fontSize: 11)),
              ],
            ),
          ),
          Text(fare,
              style: const TextStyle(
                  color: Color(0xFFFFC107), fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _menuItem(IconData icon, String title, {Color color = Colors.white}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon,
            color: color == Colors.white ? const Color(0xFFFFC107) : color),
        title: Text(title, style: TextStyle(color: color, fontSize: 14)),
        trailing: color == Colors.white
            ? const Icon(Icons.chevron_right, color: Colors.white24)
            : null,
        onTap: () {},
      ),
    );
  }
}
