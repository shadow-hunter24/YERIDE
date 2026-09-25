import 'dart:async';
import 'package:flutter/material.dart';
import '../services/connectivity_service.dart';

/// Wraps the entire app. Shows a persistent yellow→red banner at the top
/// whenever the device loses internet, and a green "Back online" confirmation
/// when it reconnects. No screen needs to be modified individually.
///
/// Also exposes [ConnectivityWrapper.checkAndAlert] — a static helper that
/// screens call before firing a network request so the user gets a clear
/// message instead of a spinner that hangs forever.
class ConnectivityWrapper extends StatefulWidget {
  final Widget child;
  const ConnectivityWrapper({super.key, required this.child});

  // ── Static helper for inline guards ────────────────────────────────
  /// Returns true when online. When offline, shows a themed SnackBar
  /// on the nearest [ScaffoldMessenger] and returns false.
  static bool checkAndAlert(BuildContext context) {
    if (ConnectivityService.instance.isConnected) return true;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 4),
        content: const Row(
          children: [
            Icon(Icons.wifi_off, color: Color(0xFFFF5252), size: 20),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'No internet connection',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13),
                  ),
                  Text(
                    'Check your data or Wi-Fi and try again.',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    return false;
  }

  @override
  State<ConnectivityWrapper> createState() => _ConnectivityWrapperState();
}

class _ConnectivityWrapperState extends State<ConnectivityWrapper>
    with SingleTickerProviderStateMixin {
  late StreamSubscription<bool> _sub;
  bool _isOnline = true;
  bool _showRestoredBanner = false;
  Timer? _restoredTimer;

  late AnimationController _animController;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();

    _isOnline = ConnectivityService.instance.isConnected;

    // Slide-down animation for the offline banner
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    ));

    if (!_isOnline) _animController.forward();

    _sub = ConnectivityService.instance.onChanged.listen((online) {
      if (!mounted) return;
      setState(() {
        _isOnline = online;
        _showRestoredBanner = false;
      });

      if (online) {
        // Slide the offline banner away
        _animController.reverse();
        // Show a brief "Back online" green banner
        setState(() => _showRestoredBanner = true);
        _restoredTimer?.cancel();
        _restoredTimer = Timer(const Duration(seconds: 3), () {
          if (mounted) setState(() => _showRestoredBanner = false);
        });
      } else {
        // Slide offline banner in
        _animController.forward();
      }
    });
  }

  @override
  void dispose() {
    _sub.cancel();
    _restoredTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,

        // ── Offline banner (slides down from top) ─────────────────────
        if (!_isOnline)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SlideTransition(
              position: _slideAnim,
              child: _OfflineBanner(),
            ),
          ),

        // ── "Back online" confirmation (fades in, auto-hides) ─────────
        if (_showRestoredBanner)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _RestoredBanner(),
          ),
      ],
    );
  }
}

// ── Offline banner widget ─────────────────────────────────────────────────────
class _OfflineBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return Container(
      width: double.infinity,
      color: const Color(0xFFB71C1C), // deep red
      padding: EdgeInsets.fromLTRB(16, topPad + 8, 16, 10),
      child: const Row(
        children: [
          Icon(Icons.wifi_off, color: Colors.white, size: 18),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'No internet connection',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13),
                ),
                Text(
                  'Some features won\'t work until you\'re back online.',
                  style: TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── "Back online" banner widget ───────────────────────────────────────────────
class _RestoredBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return Container(
      width: double.infinity,
      color: const Color(0xFF2E7D32), // dark green
      padding: EdgeInsets.fromLTRB(16, topPad + 8, 16, 10),
      child: const Row(
        children: [
          Icon(Icons.wifi, color: Colors.white, size: 18),
          SizedBox(width: 10),
          Text(
            'Back online',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13),
          ),
        ],
      ),
    );
  }
}
