import 'package:flutter/material.dart';
import 'fare_estimate_screen.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final _pickupController = TextEditingController();
  final _destinationController = TextEditingController();

  final List<String> _recentPlaces = [
    'Accra Mall, Spintex',
    'Kotoka International Airport',
    'University of Ghana, Legon',
    'Tema Station, Accra',
    'Kaneshie Market',
  ];

  @override
  void dispose() {
    _pickupController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  void _proceed() {
    if (_pickupController.text.isNotEmpty &&
        _destinationController.text.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => FareEstimateScreen(
            pickup: _pickupController.text,
            destination: _destinationController.text,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter pickup and destination'),
          backgroundColor: Color(0xFF1E1E1E),
        ),
      );
    }
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
        title: const Text('Book a Ride',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // Pickup & destination inputs
          Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Column(
                      children: [
                        const Icon(Icons.circle, color: Color(0xFF4CAF50), size: 12),
                        Container(
                            width: 2, height: 30, color: Colors.white24),
                        const Icon(Icons.location_on,
                            color: Color(0xFFFFC107), size: 16),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        children: [
                          TextField(
                            controller: _pickupController,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              hintText: 'Pickup location',
                              hintStyle: TextStyle(color: Colors.white38),
                              border: InputBorder.none,
                              isDense: true,
                            ),
                          ),
                          const Divider(color: Colors.white12),
                          TextField(
                            controller: _destinationController,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              hintText: 'Where to?',
                              hintStyle: TextStyle(color: Colors.white38),
                              border: InputBorder.none,
                              isDense: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Recent places
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: const [
                Icon(Icons.history, color: Colors.white38, size: 16),
                SizedBox(width: 8),
                Text('Recent Places',
                    style: TextStyle(color: Colors.white38, fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: _recentPlaces.length,
              itemBuilder: (_, i) => ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.location_on_outlined,
                      color: Color(0xFFFFC107), size: 18),
                ),
                title: Text(_recentPlaces[i],
                    style: const TextStyle(color: Colors.white, fontSize: 14)),
                trailing: const Icon(Icons.north_west,
                    color: Colors.white38, size: 16),
                onTap: () {
                  if (_pickupController.text.isEmpty) {
                    _pickupController.text = _recentPlaces[i];
                  } else {
                    _destinationController.text = _recentPlaces[i];
                  }
                  setState(() {});
                },
              ),
            ),
          ),

          // Confirm button
          Padding(
            padding: const EdgeInsets.all(20),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFC107),
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _proceed,
              child: const Text('Confirm Locations',
                  style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
