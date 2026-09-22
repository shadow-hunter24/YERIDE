import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/trip_service.dart';
import 'home_screen.dart';

class RatePassengerScreen extends StatefulWidget {
  final String tripId;
  final double fare;

  const RatePassengerScreen({
    super.key,
    required this.tripId,
    required this.fare,
  });

  @override
  State<RatePassengerScreen> createState() => _RatePassengerScreenState();
}

class _RatePassengerScreenState extends State<RatePassengerScreen> {
  int _rating = 0;
  final _commentController = TextEditingController();
  final TripService _tripService = TripService();
  bool _submitting = false;
  String _passengerName = 'Passenger';
  String _passengerId = '';
  final Set<String> _selectedTags = {};

  @override
  void initState() {
    super.initState();
    _loadTripData();
  }

  void _loadTripData() async {
    final snap = await _tripService.listenToTrip(widget.tripId).first;
    final data = snap.data() as Map<String, dynamic>?;
    if (data != null && mounted) {
      final pid = data['passengerId'] ?? '';
      setState(() => _passengerId = pid);

      // Fetch passenger's real name from users collection
      if (pid.isNotEmpty) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(pid)
            .get();
        final name = userDoc.data()?['name'] as String?;
        if (name != null && name.isNotEmpty && mounted) {
          setState(() => _passengerName = name.split(' ').first);
        }
      }
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a rating')),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      if (_passengerId.isNotEmpty) {
        // Combine typed comment with selected tags
        final tagText = _selectedTags.isNotEmpty
            ? _selectedTags.join(', ')
            : '';
        final fullComment = [
          if (_commentController.text.trim().isNotEmpty)
            _commentController.text.trim(),
          if (tagText.isNotEmpty) tagText,
        ].join(' · ');

        await _tripService.submitRating(
          tripId: widget.tripId,
          ratedUserId: _passengerId,
          rating: _rating,
          comment: fullComment,
          raterRole: 'rider',
        );
      }
    } catch (_) {}
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const RiderHomeScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 20),

              // Trip summary
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const Text('Trip Completed!',
                        style: TextStyle(
                            color: Color(0xFF4CAF50),
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _tripStat('Earned',
                            'GH₵ ${widget.fare.toStringAsFixed(2)}'),
                        Container(
                            width: 1, height: 30, color: Colors.white12),
                        _tripStat('Trip ID',
                            '#${widget.tripId.substring(0, 6).toUpperCase()}'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Passenger avatar
              const CircleAvatar(
                radius: 40,
                backgroundColor: Color(0xFF1E1E1E),
                child: Text('👤', style: TextStyle(fontSize: 36)),
              ),
              const SizedBox(height: 12),
              Text(_passengerName,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              const Text('How was this passenger?',
                  style: TextStyle(color: Colors.white54)),
              const SizedBox(height: 24),

              // Stars
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  return GestureDetector(
                    onTap: () => setState(() => _rating = i + 1),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Icon(
                        i < _rating ? Icons.star : Icons.star_border,
                        color: const Color(0xFFFFC107),
                        size: 40,
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 24),

              // Quick tags
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: ['Polite', 'On time', 'Clear directions', 'Good tipper']
                    .map((tag) {
                      final selected = _selectedTags.contains(tag);
                      return GestureDetector(
                        onTap: () => setState(() {
                          selected
                              ? _selectedTags.remove(tag)
                              : _selectedTags.add(tag);
                        }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: selected
                                ? const Color(0xFFFFC107).withValues(alpha: 0.15)
                                : const Color(0xFF1E1E1E),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: selected
                                  ? const Color(0xFFFFC107)
                                  : Colors.white12,
                            ),
                          ),
                          child: Text(tag,
                              style: TextStyle(
                                  color: selected
                                      ? const Color(0xFFFFC107)
                                      : Colors.white54,
                                  fontSize: 13)),
                        ),
                      );
                    })
                    .toList(),
              ),
              const Spacer(),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFC107),
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.black, strokeWidth: 2))
                    : const Text('Submit & Go Online',
                        style: TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const RiderHomeScreen()),
                  (route) => false,
                ),
                child: const Text('Skip',
                    style: TextStyle(color: Colors.white38)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tripStat(String label, String value) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                color: Color(0xFFFFC107),
                fontWeight: FontWeight.bold,
                fontSize: 16)),
        const SizedBox(height: 4),
        Text(label,
            style: const TextStyle(color: Colors.white54, fontSize: 12)),
      ],
    );
  }
}
