import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

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
        title: const Text('About YɛRide',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Logo + tagline
          Center(
            child: Column(
              children: [
                Image.asset('YeRide.png', width: 90),
                const SizedBox(height: 16),
                const Text('YɛRide',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                const Text('Fast. Safe. Affordable.',
                    style: TextStyle(
                        color: Color(0xFFFFC107), fontSize: 14)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('Version 1.0.0',
                      style:
                          TextStyle(color: Colors.white54, fontSize: 12)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          _infoCard(
            'About the App',
            'YɛRide is a motorbike ride-hailing platform built for Ghana. '
                'We connect passengers with verified okada riders for fast, '
                'affordable, and safe transportation across Accra and beyond.',
          ),
          const SizedBox(height: 16),
          _infoCard(
            'Our Mission',
            'To make everyday transportation accessible, affordable, and '
                'reliable for every Ghanaian — whether you\'re heading to '
                'work, school, or the market.',
          ),
          const SizedBox(height: 16),

          // Stats row
          Row(
            children: [
              Expanded(child: _statCard('Ghana 🇬🇭', 'Where we operate')),
              const SizedBox(width: 12),
              Expanded(child: _statCard('GH₵', 'Local currency')),
              const SizedBox(width: 12),
              Expanded(child: _statCard('24/7', 'Available')),
            ],
          ),
          const SizedBox(height: 16),

          _infoCard(
            'Contact',
            'Email: support@yeride.app\nPhone: +233 00 000 0000\nWebsite: www.yeride.app',
          ),
          const SizedBox(height: 16),

          _infoCard(
            'Legal',
            '© 2026 Shadow Technologies. All rights reserved.\n\n'
                'YɛRide is built with Flutter and Firebase. By using this app '
                'you agree to our Terms of Service and Privacy Policy.',
          ),
          const SizedBox(height: 24),
          const Center(
            child: Text(
              'Made with ❤️ in Ghana',
              style: TextStyle(color: Colors.white38, fontSize: 13),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _infoCard(String title, String body) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  color: Color(0xFFFFC107),
                  fontWeight: FontWeight.bold,
                  fontSize: 13)),
          const SizedBox(height: 8),
          Text(body,
              style: const TextStyle(
                  color: Colors.white54, fontSize: 13, height: 1.6)),
        ],
      ),
    );
  }

  Widget _statCard(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16)),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(color: Colors.white38, fontSize: 11),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
