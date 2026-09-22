import 'package:flutter/material.dart';
import '../../services/user_service.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';
import '../shared/edit_profile_screen.dart';
import '../shared/notifications_screen.dart';
import '../shared/help_screen.dart';
import '../shared/about_screen.dart';
import '../shared/safety_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _userData;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  void _loadProfile() async {
    final data = await UserService().getCurrentUserData();
    if (mounted) setState(() { _userData = data; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text('Profile',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFC107)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Center(
                    child: Column(
                      children: [
                        const CircleAvatar(
                          radius: 48,
                          backgroundColor: Color(0xFF1E1E1E),
                          child: Text('👤', style: TextStyle(fontSize: 40)),
                        ),
                        const SizedBox(height: 12),
                        Text(_userData?['name'] ?? 'User',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(_userData?['phone'] ?? '',
                            style: const TextStyle(color: Colors.white54)),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.star, color: Color(0xFFFFC107), size: 16),
                            const SizedBox(width: 4),
                            Text(
                              '${(_userData?['rating'] ?? 0.0).toStringAsFixed(1)}',
                              style: const TextStyle(
                                  color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  _menuItem(Icons.person_outline, 'Edit Profile', () async {
                    final updated = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditProfileScreen(
                          collection: 'users',
                          currentName: _userData?['name'] ?? '',
                          currentPhone: _userData?['phone'] ?? '',
                        ),
                      ),
                    );
                    if (updated == true) _loadProfile();
                  }),
                  _menuItem(Icons.payment, 'Payment Methods', () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Payment methods managed from the Payments tab'),
                        backgroundColor: Color(0xFF1E1E1E),
                      ),
                    );
                  }),
                  _menuItem(Icons.notifications_outlined, 'Notifications', () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const NotificationsScreen(collection: 'users'),
                      ),
                    );
                  }),
                  _menuItem(Icons.security, 'Safety', () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SafetyScreen()),
                    );
                  }),
                  _menuItem(Icons.help_outline, 'Help & Support', () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const HelpScreen()),
                    );
                  }),
                  _menuItem(Icons.info_outline, 'About YɛRide', () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AboutScreen()),
                    );
                  }),
                  const SizedBox(height: 8),
                  _menuItem(
                    Icons.logout, 'Logout',
                    () async {
                      final nav = Navigator.of(context);
                      await AuthService().logout();
                      nav.pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (route) => false,
                      );
                    },
                    color: Colors.redAccent,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _menuItem(IconData icon, String title, VoidCallback onTap,
      {Color color = Colors.white}) {
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
        onTap: onTap,
      ),
    );
  }
}
