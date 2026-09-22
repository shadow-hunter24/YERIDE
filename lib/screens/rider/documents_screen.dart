import 'package:flutter/material.dart';

class DocumentsScreen extends StatelessWidget {
  const DocumentsScreen({super.key});

  static const _docs = [
    {
      'title': 'National ID / Ghana Card',
      'desc': 'A valid government-issued ID',
      'icon': Icons.badge_outlined,
    },
    {
      'title': 'Driver\'s License',
      'desc': 'Valid motorbike licence (Class A)',
      'icon': Icons.drive_eta_outlined,
    },
    {
      'title': 'Roadworthy Certificate',
      'desc': 'Current roadworthy certificate for your bike',
      'icon': Icons.assignment_outlined,
    },
    {
      'title': 'Insurance Certificate',
      'desc': 'Third-party or comprehensive insurance',
      'icon': Icons.security_outlined,
    },
    {
      'title': 'Profile Photo',
      'desc': 'A clear front-facing photo of yourself',
      'icon': Icons.photo_camera_outlined,
    },
  ];

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
        title: const Text('Documents',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFC107).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: const Color(0xFFFFC107).withValues(alpha: 0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Color(0xFFFFC107)),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Document verification is handled by the YɛRide team. '
                    'Contact support to submit or update your documents.',
                    style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text('Required Documents',
              style: TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1)),
          const SizedBox(height: 12),
          ..._docs.map((doc) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(doc['icon'] as IconData,
                        color: const Color(0xFFFFC107), size: 24),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(doc['title'] as String,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14)),
                          const SizedBox(height: 3),
                          Text(doc['desc'] as String,
                              style: const TextStyle(
                                  color: Colors.white38, fontSize: 12)),
                        ],
                      ),
                    ),
                    const Icon(Icons.check_circle,
                        color: Colors.white12, size: 20),
                  ],
                ),
              )),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFFFC107)),
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                      'Contact support@yeride.app to submit your documents'),
                  backgroundColor: Color(0xFF1E1E1E),
                ),
              );
            },
            icon: const Icon(Icons.upload_file, color: Color(0xFFFFC107)),
            label: const Text('Contact Support to Submit',
                style: TextStyle(color: Color(0xFFFFC107))),
          ),
        ],
      ),
    );
  }
}
