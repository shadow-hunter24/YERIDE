import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../services/location_service.dart';
import 'fare_estimate_screen.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final _pickupController = TextEditingController();
  final _destinationController = TextEditingController();
  final _locationService = LocationService();
  bool _loadingLocation = false;
  Position? _currentPosition;

  final List<String> _recentPlaces = [
    'Accra Mall, Spintex',
    'Kotoka International Airport',
    'University of Ghana, Legon',
    'Tema Station, Accra',
    'Kaneshie Market',
  ];

  @override
  void initState() {
    super.initState();
    _fetchCurrentLocation();
  }

  @override
  void dispose() {
    _pickupController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  void _fetchCurrentLocation() async {
    setState(() => _loadingLocation = true);
    final position = await _locationService.getCurrentPosition();
    if (position != null && mounted) {
      final address = await _locationService.getAddressFromLatLng(
          position.latitude, position.longitude);
      setState(() {
        _currentPosition = position;
        _pickupController.text = address;
        _loadingLocation = false;
      });
    } else {
      setState(() => _loadingLocation = false);
    }
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
            pickupLat: _currentPosition?.latitude ?? 5.6037,
            pickupLng: _currentPosition?.longitude ?? -0.1870,
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
                        const Icon(Icons.circle,
                            color: Color(0xFF4CAF50), size: 12),
                        Container(width: 2, height: 30, color: Colors.white24),
                        const Icon(Icons.location_on,
                            color: Color(0xFFFFC107), size: 16),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _pickupController,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: InputDecoration(
                                    hintText: _loadingLocation
                                        ? 'Getting your location...'
                                        : 'Pickup location',
                                    hintStyle: const TextStyle(
                                        color: Colors.white38),
                                    border: InputBorder.none,
                                    isDense: true,
                                  ),
                                ),
                              ),
                              if (_loadingLocation)
                                const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Color(0xFFFFC107)),
                                )
                              else
                                IconButton(
                                  icon: const Icon(Icons.my_location,
                                      color: Color(0xFFFFC107), size: 18),
                                  onPressed: _fetchCurrentLocation,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                            ],
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
