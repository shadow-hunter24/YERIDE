import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/user_service.dart';
import '../../services/auth_service.dart';
import '../../services/trip_service.dart';
import '../../services/location_service.dart';
import '../../widgets/connectivity_wrapper.dart';
import '../auth/login_screen.dart';
import '../shared/edit_profile_screen.dart';
import '../shared/notifications_screen.dart';
import '../shared/help_screen.dart';
import '../shared/about_screen.dart';
import '../shared/safety_screen.dart';
import 'ride_request_screen.dart';
import 'navigation_screen.dart';
import 'vehicle_screen.dart';
import 'documents_screen.dart';
import 'payout_screen.dart';

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

  // In-app trip notification
  StreamSubscription? _tripAlertSub;
  String? _alertTripId; // tracks which trip we are currently showing

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _tripAlertSub?.cancel();
    super.dispose();
  }

  /// Start listening for new trips assigned to this rider.
  /// Called once rider goes online.
  void _startTripListener() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    _tripAlertSub?.cancel();
    _tripAlertSub = FirebaseFirestore.instance
        .collection('trips')
        .where('assignedRiderId', isEqualTo: uid)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .listen((snapshot) {
      if (!mounted) return;
      for (final change in snapshot.docChanges) {
        // Only react to newly added documents
        if (change.type == DocumentChangeType.added) {
          final tripId = change.doc.id;
          // Don't show alert for the same trip twice
          if (_alertTripId == tripId) return;
          _alertTripId = tripId;
          final data = change.doc.data() as Map<String, dynamic>;
          _showTripAlert(tripId, data);
        }
      }
    });
  }

  /// Stop listening when rider goes offline
  void _stopTripListener() {
    _tripAlertSub?.cancel();
    _tripAlertSub = null;
    _alertTripId = null;
  }

  /// Show a full-screen modal bottom sheet with the trip details
  void _showTripAlert(String tripId, Map<String, dynamic> trip) {
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _TripAlertSheet(
        tripId: tripId,
        trip: trip,
        onAccepted: () {
          _alertTripId = null;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => NavigationScreen(
                tripId: tripId,
                pickup: trip['pickupAddress'] ?? '',
                destination: trip['destinationAddress'] ?? '',
                fare: (trip['fare'] as num?)?.toDouble() ?? 0.0,
              ),
            ),
          );
        },
        onDeclined: () {
          _alertTripId = null;
        },
      ),
    );
  }

  void _loadUserData() async {
    final data = await UserService().getCurrentUserData();
    if (mounted && data != null) {
      setState(() {
        _userData = data;
        _name = data['name'] ?? '';
        _isOnline = data['isOnline'] ?? false;
      });
      // If rider was already online, start listening immediately
      if (_isOnline) _startTripListener();
    }
  }

  Future<void> _toggleOnline() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final newStatus = !_isOnline;

    if (newStatus) {
      // Ensure internet before going online
      if (!ConnectivityWrapper.checkAndAlert(context)) return;
      // Ensure location is available before going online
      final ready = await LocationService().ensureLocationReady(context);
      if (!ready || !mounted) return;
    }

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
      _startTripListener(); // ← start watching for new trips
    } else {
      await FirebaseFirestore.instance
          .collection('riders')
          .doc(uid)
          .update({'isOnline': false});
      _stopTripListener(); // ← stop watching
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
            _menuItem(Icons.directions_bike, 'My Vehicle', onTap: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const VehicleScreen()));
            }),
            _menuItem(Icons.document_scanner, 'Documents', onTap: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const DocumentsScreen()));
            }),
            _menuItem(Icons.account_balance_wallet_outlined, 'Payout Settings', onTap: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const PayoutScreen()));
            }),
            _menuItem(Icons.notifications_outlined, 'Notifications', onTap: () {
              Navigator.push(context,
                  MaterialPageRoute(
                      builder: (_) => const NotificationsScreen(collection: 'riders')));
            }),
            _menuItem(Icons.security, 'Safety', onTap: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const SafetyScreen()));
            }),
            _menuItem(Icons.help_outline, 'Help & Support', onTap: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const HelpScreen()));
            }),
            _menuItem(Icons.info_outline, 'About YɛRide', onTap: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const AboutScreen()));
            }),
            _menuItem(Icons.person_outline, 'Edit Profile', onTap: () async {
              final updated = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) => EditProfileScreen(
                    collection: 'riders',
                    currentName: data?['name'] ?? _name,
                    currentPhone: data?['phone'] ?? '',
                  ),
                ),
              );
              if (updated == true) _loadUserData();
            }),
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

// ─── In-app trip alert bottom sheet ──────────────────────────────────────────

class _TripAlertSheet extends StatefulWidget {
  final String tripId;
  final Map<String, dynamic> trip;
  final VoidCallback onAccepted;
  final VoidCallback onDeclined;

  const _TripAlertSheet({
    required this.tripId,
    required this.trip,
    required this.onAccepted,
    required this.onDeclined,
  });

  @override
  State<_TripAlertSheet> createState() => _TripAlertSheetState();
}

class _TripAlertSheetState extends State<_TripAlertSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int _countdown = 30;
  bool _accepting = false;
  final TripService _tripService = TripService();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..forward();

    // Countdown timer
    Stream.periodic(const Duration(seconds: 1), (i) => i)
        .take(30)
        .listen((i) {
      if (!mounted) return;
      setState(() => _countdown = 29 - i);
      if (_countdown <= 0) {
        // Auto-dismiss when timer expires
        if (mounted) Navigator.pop(context);
        widget.onDeclined();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _accept() async {
    setState(() => _accepting = true);
    try {
      final userData = await UserService().getCurrentUserData();
      final riderName = userData?['name'] ?? 'Rider';
      await _tripService.acceptTrip(widget.tripId, riderName);
      if (!mounted) return;
      Navigator.pop(context); // close sheet
      widget.onAccepted();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to accept: $e'),
              backgroundColor: Colors.redAccent),
        );
        setState(() => _accepting = false);
      }
    }
  }

  void _decline() async {
    await _tripService.updateTripStatus(widget.tripId, 'cancelled');
    if (!mounted) return;
    Navigator.pop(context);
    widget.onDeclined();
  }

  @override
  Widget build(BuildContext context) {
    final pickup      = widget.trip['pickupAddress']      as String? ?? '';
    final destination = widget.trip['destinationAddress'] as String? ?? '';
    final fare        = (widget.trip['fare'] as num?)?.toStringAsFixed(2) ?? '0.00';
    final distance    = (widget.trip['distanceKm'] as num?)?.toStringAsFixed(1) ?? '0';

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E1E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: Colors.white12,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Header with countdown
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('🏍  New Ride Request!',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18)),
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 44, height: 44,
                    child: AnimatedBuilder(
                      animation: _controller,
                      builder: (_, _) => CircularProgressIndicator(
                        value: 1 - _controller.value,
                        color: const Color(0xFFFFC107),
                        backgroundColor: Colors.white12,
                        strokeWidth: 3,
                      ),
                    ),
                  ),
                  Text('$_countdown',
                      style: const TextStyle(
                          color: Color(0xFFFFC107),
                          fontWeight: FontWeight.bold,
                          fontSize: 13)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Fare highlight
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFC107).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: const Color(0xFFFFC107).withValues(alpha: 0.4)),
            ),
            child: Text('GH₵ $fare',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Color(0xFFFFC107),
                    fontSize: 32,
                    fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 16),

          // Route
          _routeRow(Icons.circle, const Color(0xFF4CAF50), pickup),
          Padding(
            padding: const EdgeInsets.only(left: 6),
            child: Container(width: 2, height: 14, color: Colors.white12),
          ),
          _routeRow(Icons.location_on, const Color(0xFFFFC107), destination),
          const SizedBox(height: 16),

          // Details
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _detail(Icons.straighten, '$distance km'),
              Container(width: 1, height: 28, color: Colors.white12),
              _detail(Icons.access_time,
                  '~${(double.tryParse(distance) ?? 0) * 3 ~/ 1} min'),
              Container(width: 1, height: 28, color: Colors.white12),
              _detail(Icons.payments_outlined, 'GH₵ $fare'),
            ],
          ),
          const SizedBox(height: 20),

          // Buttons
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
                  onPressed: _accepting ? null : _decline,
                  child: const Text('Decline',
                      style: TextStyle(color: Colors.white54, fontSize: 15)),
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
                  onPressed: _accepting ? null : _accept,
                  child: _accepting
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.black, strokeWidth: 2))
                      : const Text('Accept Ride',
                          style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 15)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _routeRow(IconData icon, Color color, String text) {
    return Row(
      children: [
        Icon(icon, color: color, size: 13),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              overflow: TextOverflow.ellipsis),
        ),
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
