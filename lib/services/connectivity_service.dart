import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Singleton that tracks internet connectivity for the whole app.
///
/// Usage:
///   ConnectivityService.instance.isConnected   → current state
///   ConnectivityService.instance.onChanged     → stream of bool
///   ConnectivityService.instance.init()        → call once in main()
class ConnectivityService {
  ConnectivityService._();
  static final ConnectivityService instance = ConnectivityService._();

  final Connectivity _connectivity = Connectivity();
  final StreamController<bool> _controller =
      StreamController<bool>.broadcast();

  bool _isConnected = true; // optimistic default until first check

  bool get isConnected => _isConnected;

  /// Broadcast stream of connection state — true = online, false = offline.
  Stream<bool> get onChanged => _controller.stream;

  /// Call once from main() before runApp().
  Future<void> init() async {
    // Get initial state
    final initial = await _connectivity.checkConnectivity();
    _isConnected = _resultIsOnline(initial);

    // Listen for changes
    _connectivity.onConnectivityChanged.listen((results) {
      final online = _resultIsOnline(results);
      if (online != _isConnected) {
        _isConnected = online;
        _controller.add(_isConnected);
      }
    });
  }

  /// Returns true if any of the reported connectivity types mean the device
  /// has a network interface up. Note: connectivity_plus cannot guarantee
  /// actual internet reachability — it only checks the network interface.
  /// A SocketException from Firebase will still catch true offline cases.
  bool _resultIsOnline(List<ConnectivityResult> results) {
    return results.any((r) =>
        r == ConnectivityResult.mobile ||
        r == ConnectivityResult.wifi ||
        r == ConnectivityResult.ethernet ||
        r == ConnectivityResult.vpn);
  }

  void dispose() {
    _controller.close();
  }
}
