import 'package:flutter/material.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Profile',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Avatar & name
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: const Color(0xFF1E1E1E),
                    child: const Text('👤', style: TextStyle(fontSize: 40)),
                  ),
                  const SizedBox(height: 12),
                  const Text('Ahmed Manuel',
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
                      Text('4.9',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                      SizedBox(width: 4),
                      Text('· 24 trips',
                          style: TextStyle(color: Colors.white54)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Menu items
            _menuItem(Icons.person_outline, 'Edit Profile', () {}),
            _menuItem(Icons.payment, 'Payment Methods', () {}),
            _menuItem(Icons.history, 'Trip History', () {}),
            _menuItem(Icons.notifications_outlined, 'Notifications', () {}),
            _menuItem(Icons.security, 'Safety', () {}),
            _menuItem(Icons.help_outline, 'Help & Support', () {}),
            _menuItem(Icons.info_outline, 'About YɛRide', () {}),
            const SizedBox(height: 8),
            _menuItem(
              Icons.logout,
              'Logout',
              () => Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              ),
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
        leading: Icon(icon, color: color == Colors.white ? const Color(0xFFFFC107) : color),
        title: Text(title, style: TextStyle(color: color, fontSize: 14)),
        trailing: color == Colors.white
            ? const Icon(Icons.chevron_right, color: Colors.white24)
            : null,
        onTap: onTap,
      ),
    );
  }
}
