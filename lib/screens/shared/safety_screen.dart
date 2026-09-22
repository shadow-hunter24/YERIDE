import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SafetyScreen extends StatelessWidget {
  const SafetyScreen({super.key});

  Future<void> _call(String number) async {
    final uri = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
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
        title: const Text('Safety',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Emergency banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded,
                    color: Colors.redAccent, size: 28),
                const SizedBox(width: 14),
                const Expanded(
                  child: Text(
                    'In an emergency, call 112 (Ghana National Emergency) or 191 (Police) immediately.',
                    style: TextStyle(
                        color: Colors.white, fontSize: 13, height: 1.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          const Text('Emergency Numbers',
              style: TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1)),
          const SizedBox(height: 12),

          _emergencyTile(
            icon: Icons.local_police_outlined,
            title: 'Ghana Police Service',
            number: '191',
            onTap: () => _call('191'),
          ),
          _emergencyTile(
            icon: Icons.local_fire_department_outlined,
            title: 'Fire & Ambulance',
            number: '192',
            onTap: () => _call('192'),
          ),
          _emergencyTile(
            icon: Icons.emergency_outlined,
            title: 'National Emergency',
            number: '112',
            onTap: () => _call('112'),
          ),
          _emergencyTile(
            icon: Icons.support_agent_outlined,
            title: 'YɛRide Safety Team',
            number: '+233000000000',
            onTap: () => _call('+233000000000'),
          ),

          const SizedBox(height: 28),
          const Text('Safety Tips',
              style: TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1)),
          const SizedBox(height: 12),

          ...[
            ('Verify your rider', 'Check the rider\'s name and rating before boarding.'),
            ('Share your trip', 'Let a friend or family member know your route.'),
            ('Wear a helmet', 'Always wear the helmet provided by your rider.'),
            ('Stay on main roads', 'Avoid shortcuts through unfamiliar areas.'),
            ('Trust your instincts', 'If something feels wrong, end the trip and call for help.'),
          ].map((tip) => _tipCard(tip.$1, tip.$2)),
        ],
      ),
    );
  }

  Widget _emergencyTile({
    required IconData icon,
    required String title,
    required String number,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.redAccent),
        title: Text(title,
            style: const TextStyle(color: Colors.white, fontSize: 14)),
        subtitle: Text(number,
            style: const TextStyle(color: Colors.white38, fontSize: 12)),
        trailing: IconButton(
          icon: const Icon(Icons.call, color: Color(0xFFFFC107)),
          onPressed: onTap,
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _tipCard(String title, String body) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_outline,
              color: Color(0xFF4CAF50), size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13)),
                const SizedBox(height: 4),
                Text(body,
                    style: const TextStyle(
                        color: Colors.white54, fontSize: 12, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
