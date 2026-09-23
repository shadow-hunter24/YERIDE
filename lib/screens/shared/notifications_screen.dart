import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class NotificationsScreen extends StatefulWidget {
  final String collection; // 'users' or 'riders'

  const NotificationsScreen({super.key, required this.collection});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _rideUpdates = true;
  bool _promotions = false;
  bool _appUpdates = true;
  bool _loading = true;

  final _db = FirebaseFirestore.instance;
  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final doc = await _db.collection(widget.collection).doc(_uid).get();
    final prefs = doc.data()?['notificationPrefs'] as Map<String, dynamic>?;
    if (prefs != null && mounted) {
      setState(() {
        _rideUpdates = prefs['rideUpdates'] ?? true;
        _promotions = prefs['promotions'] ?? false;
        _appUpdates = prefs['appUpdates'] ?? true;
      });
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _savePrefs() async {
    await _db.collection(widget.collection).doc(_uid).update({
      'notificationPrefs': {
        'rideUpdates': _rideUpdates,
        'promotions': _promotions,
        'appUpdates': _appUpdates,
      }
    });
  }

  void _toggle(String key, bool value) {
    setState(() {
      if (key == 'rideUpdates') _rideUpdates = value;
      if (key == 'promotions') _promotions = value;
      if (key == 'appUpdates') _appUpdates = value;
    });
    _savePrefs();
  }

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
        title: const Text('Notifications',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFFFC107)))
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text('Push Notifications',
                    style: TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1)),
                const SizedBox(height: 12),
                _toggleTile(
                  icon: Icons.electric_moped,
                  title: 'Ride Updates',
                  subtitle: 'Status changes, driver arrival, trip completion',
                  value: _rideUpdates,
                  onChanged: (v) => _toggle('rideUpdates', v),
                ),
                _toggleTile(
                  icon: Icons.local_offer_outlined,
                  title: 'Promotions',
                  subtitle: 'Discounts, referral bonuses, special offers',
                  value: _promotions,
                  onChanged: (v) => _toggle('promotions', v),
                ),
                _toggleTile(
                  icon: Icons.system_update_outlined,
                  title: 'App Updates',
                  subtitle: 'New features and important announcements',
                  value: _appUpdates,
                  onChanged: (v) => _toggle('appUpdates', v),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: Color(0xFFFFC107), size: 18),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Some notifications are required for the app to work correctly and cannot be disabled.',
                          style:
                              TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _toggleTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFFFC107), size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: const TextStyle(
                        color: Colors.white38, fontSize: 12)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: const Color(0xFFFFC107),
            activeTrackColor: const Color(0xFFFFC107).withValues(alpha: 0.4),
            inactiveTrackColor: Colors.white12,
          ),
        ],
      ),
    );
  }
}
