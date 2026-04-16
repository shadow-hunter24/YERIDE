import 'package:flutter/material.dart';
import 'tracking_screen.dart';

class FareEstimateScreen extends StatelessWidget {
  final String pickup;
  final String destination;

  const FareEstimateScreen({
    super.key,
    required this.pickup,
    required this.destination,
  });

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
        title: const Text('Fare Estimate',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // Route summary
          Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _routeRow(Icons.circle, const Color(0xFF4CAF50), pickup),
                const Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: Divider(color: Colors.white12),
                ),
                _routeRow(
                    Icons.location_on, const Color(0xFFFFC107), destination),
              ],
            ),
          ),

          // Ride options
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Choose Ride Type',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _rideOption(
                  context,
                  icon: '🏍',
                  title: 'OkadaGo',
                  subtitle: '2 min away',
                  price: 'GH₵ 8.00',
                  selected: true,
                ),
                const SizedBox(height: 10),
                _rideOption(
                  context,
                  icon: '⚡',
                  title: 'OkadaExpress',
                  subtitle: '5 min away · Faster route',
                  price: 'GH₵ 12.00',
                  selected: false,
                ),
              ],
            ),
          ),

          const Spacer(),

          // Trip details
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _tripDetail(Icons.straighten, '3.2 km'),
                _divider(),
                _tripDetail(Icons.access_time, '~12 min'),
                _divider(),
                _tripDetail(Icons.payments_outlined, 'GH₵ 8.00'),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Payment method
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: const [
                  Icon(Icons.account_balance_wallet_outlined,
                      color: Color(0xFFFFC107)),
                  SizedBox(width: 12),
                  Text('MTN MoMo',
                      style: TextStyle(color: Colors.white, fontSize: 14)),
                  Spacer(),
                  Text('Change',
                      style:
                          TextStyle(color: Color(0xFFFFC107), fontSize: 13)),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFC107),
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TrackingScreen()),
              ),
              child: const Text('Request Ride · GH₵ 8.00',
                  style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _routeRow(IconData icon, Color color, String text) {
    return Row(
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 12),
        Expanded(
          child: Text(text,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }

  Widget _rideOption(BuildContext context,
      {required String icon,
      required String title,
      required String subtitle,
      required String price,
      required bool selected}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: selected
            ? const Color(0xFFFFC107).withOpacity(0.1)
            : const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selected ? const Color(0xFFFFC107) : Colors.transparent,
        ),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
                Text(subtitle,
                    style:
                        const TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
          ),
          Text(price,
              style: const TextStyle(
                  color: Color(0xFFFFC107), fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _tripDetail(IconData icon, String value) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFFFFC107), size: 20),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(color: Colors.white, fontSize: 13)),
      ],
    );
  }

  Widget _divider() {
    return Container(width: 1, height: 30, color: Colors.white12);
  }
}
