import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  static const _faqs = [
    {
      'q': 'How do I book a ride?',
      'a':
          'Tap "Book a Ride" on the home screen, enter your pickup and destination, select an available rider, then confirm your request.',
    },
    {
      'q': 'How is the fare calculated?',
      'a':
          'Fares start at GH₵ 3.00 base fare plus GH₵ 1.50 per kilometre. The estimated fare is shown before you confirm a booking.',
    },
    {
      'q': 'How do I pay for a ride?',
      'a':
          'Payments are processed via mobile money (MTN MoMo, Vodafone Cash, or AirtelTigo). Your linked account is charged when the trip completes.',
    },
    {
      'q': 'Can I cancel a ride?',
      'a':
          'Yes. You can cancel a pending ride from the tracking screen before the rider accepts it.',
    },
    {
      'q': 'How do ratings work?',
      'a':
          'After every trip, both passengers and riders rate each other out of 5 stars. Your average rating is visible on your profile.',
    },
    {
      'q': 'What if my rider doesn\'t show up?',
      'a':
          'Cancel the ride and book again. If you experience repeated issues, contact support below.',
    },
  ];

  Future<void> _launchEmail() async {
    final uri = Uri(
      scheme: 'mailto',
      path: 'support@yeride.app',
      queryParameters: {'subject': 'YeRide Support Request'},
    );
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _launchPhone() async {
    final uri = Uri(scheme: 'tel', path: '+233000000000');
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
        title: const Text('Help & Support',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Contact cards
          Row(
            children: [
              Expanded(
                child: _contactCard(
                  icon: Icons.email_outlined,
                  label: 'Email Us',
                  sub: 'support@yeride.app',
                  onTap: _launchEmail,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _contactCard(
                  icon: Icons.phone_outlined,
                  label: 'Call Us',
                  sub: '+233 00 000 0000',
                  onTap: _launchPhone,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          const Text('Frequently Asked Questions',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ..._faqs.map((faq) => _FaqTile(
                question: faq['q']!,
                answer: faq['a']!,
              )),
        ],
      ),
    );
  }

  Widget _contactCard({
    required IconData icon,
    required String label,
    required String sub,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFFC107).withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFFFFC107), size: 28),
            const SizedBox(height: 8),
            Text(label,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13)),
            const SizedBox(height: 4),
            Text(sub,
                style: const TextStyle(color: Colors.white38, fontSize: 11),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _FaqTile extends StatefulWidget {
  final String question;
  final String answer;
  const _FaqTile({required this.question, required this.answer});

  @override
  State<_FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<_FaqTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding:
              const EdgeInsets.fromLTRB(16, 0, 16, 16),
          title: Text(widget.question,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500)),
          trailing: Icon(
            _expanded ? Icons.remove : Icons.add,
            color: const Color(0xFFFFC107),
            size: 18,
          ),
          onExpansionChanged: (v) => setState(() => _expanded = v),
          children: [
            Text(widget.answer,
                style: const TextStyle(
                    color: Colors.white54, fontSize: 13, height: 1.5)),
          ],
        ),
      ),
    );
  }
}
