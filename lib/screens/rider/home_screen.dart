import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/user_service.dart';
import '../../services/auth_service.dart';
import '../../services/location_service.dart';
import '../auth/login_screen.dart';
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
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() async {
    final data = await UserService().getCurrentUserData();
    if (mounted && data != null) {
      setState(() {
        _userData = data;
        _name = data['name'] ?? '';
        _isOnline = data['isOnline'] ?? false;
      });
    }
  }

  Future<void> _toggleOnline() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final newStatus = !_isOnline;
    setState(() => _isOnline = newStatus);

    if (newStatus) {
      // Save location when going online
      final pos = await LocationService().getCurrentPosition();
      await FirebaseFirestore.instance
          .collection('riders')
          .doc(uid)
          .update({
        'isOnline': true,
        if (pos != null) 'lat': pos.latitude,
        if (pos != null) 'lng': pos.longitude,
      });
    } else {
      await FirebaseFirestore.instance
          .collection('riders')
          .doc(uid)
          .update({'isOnline': false});
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
                  onTap: _toggleOnline,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: _isOnline
                          ? const Color(0xFF4CAF50).withValues(alpha: 0.2)
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
                _statCard('Trips', '${_userData?['totalTrips'] ?? 0}', Icons.electric_moped),
                const SizedBox(width: 12),
                _statCard('Rating', '${(_userData?['rating'] ?? 0.0).toStringAsFixed(1)} ⭐', Icons.star_outline),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Map area
          Expanded(
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: GoogleMap(
                      initialCameraPosition: const CameraPosition(
                        target: LatLng(5.6037, -0.1870),
                        zoom: 15,
                      ),
                      myLocationEnabled: true,
                      myLocationButtonEnabled: false,
                      zoomControlsEnabled: false,
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
                            builder: (_) => RideRequestScreen()),
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
                            Text('You are online — tap to view requests',
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
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final monthStart = DateTime(now.year, now.month, 1);

    return SafeArea(
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('trips')
            .where('riderId', isEqualTo: uid)
            .where('status', isEqualTo: 'completed')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          final trips = snapshot.data?.docs ?? [];

          // Calculate earnings
          double totalEarnings = (_userData?['totalEarnings'] ?? 0.0).toDouble();
          double todayEarnings = 0;
          double monthEarnings = 0;

          for (final doc in trips) {
            final data = doc.data() as Map<String, dynamic>;
            final fare = (data['fare'] as num?)?.toDouble() ?? 0.0;
            final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
            if (createdAt != null) {
              if (createdAt.isAfter(todayStart)) todayEarnings += fare;
              if (createdAt.isAfter(monthStart)) monthEarnings += fare;
            }
          }

          return Padding(
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

                // Total earnings card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFC107),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const Text('Total Earnings',
                          style: TextStyle(color: Colors.black54, fontSize: 13)),
                      const SizedBox(height: 8),
                      Text('GH₵ ${totalEarnings.toStringAsFixed(2)}',
                          style: const TextStyle(
                              color: Colors.black,
                              fontSize: 36,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('${trips.length} trips completed',
                          style: const TextStyle(
                              color: Colors.black54, fontSize: 12)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Today / This Month
                Row(
                  children: [
                    Expanded(
                        child: _earningCard(
                            'Today',
                            'GH₵ ${todayEarnings.toStringAsFixed(2)}')),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _earningCard(
                            'This Month',
                            'GH₵ ${monthEarnings.toStringAsFixed(2)}')),
                  ],
                ),
                const SizedBox(height: 20),

                const Text('Recent Trips',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),

                // Real recent trips
                Expanded(
                  child: trips.isEmpty
                      ? const Center(
                          child: Text('No completed trips yet',
                              style: TextStyle(
                                  color: Colors.white38, fontSize: 14)),
                        )
                      : ListView.builder(
                          itemCount: trips.length > 10 ? 10 : trips.length,
                          itemBuilder: (_, i) {
                            final data =
                                trips[i].data() as Map<String, dynamic>;
                            final pickup =
                                data['pickupAddress'] ?? '';
                            final dest =
                                data['destinationAddress'] ?? '';
                            final fare =
                                (data['fare'] as num?)?.toStringAsFixed(2) ??
                                    '0.00';
                            final createdAt =
                                (data['createdAt'] as Timestamp?)
                                    ?.toDate();
                            final time = createdAt != null
                                ? _formatTime(createdAt)
                                : '';
                            return _earningTrip(
                                '$pickup → $dest', 'GH₵ $fare', time);
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) {
      final h = date.hour > 12 ? date.hour - 12 : date.hour;
      final m = date.minute.toString().padLeft(2, '0');
      final p = date.hour >= 12 ? 'PM' : 'AM';
      return 'Today $h:$m $p';
    }
    if (diff.inDays == 1) return 'Yesterday';
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildRiderProfile() {
    final data = _userData;
    final name = data?['name'] ?? _name;
    final phone = data?['phone'] ?? '';
    final rating = (data?['rating'] ?? 0.0).toStringAsFixed(1);
    final totalTrips = data?['totalTrips'] ?? 0;
    final isVerified = data?['isVerified'] ?? false;

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
            Text(name,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(phone, style: const TextStyle(color: Colors.white54)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.star, color: Color(0xFFFFC107), size: 16),
                const SizedBox(width: 4),
                Text(rating,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(width: 4),
                Text('· $totalTrips trips',
                    style: const TextStyle(color: Colors.white54)),
              ],
            ),
            const SizedBox(height: 8),
            if (isVerified)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('✓ Verified Rider',
                    style: TextStyle(
                        color: Color(0xFF4CAF50),
                        fontWeight: FontWeight.bold)),
              ),
            const SizedBox(height: 32),
            _menuItem(Icons.directions_bike, 'My Vehicle'),
            _menuItem(Icons.document_scanner, 'Documents'),
            _menuItem(Icons.account_balance_wallet_outlined, 'Payout Settings'),
            _menuItem(Icons.help_outline, 'Help & Support'),
            _menuItem(Icons.logout, 'Logout', color: Colors.redAccent, onTap: () async {
              await AuthService().logout();
              if (!mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            }),
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

  Widget _menuItem(IconData icon, String title, {Color color = Colors.white, VoidCallback? onTap}) {
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
        onTap: onTap ?? () {},
      ),
    );
  }
}
