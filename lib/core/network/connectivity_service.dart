import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  late StreamController<bool> _connectionStreamController;

  bool _isConnected = false;
  bool get isConnected => _isConnected;

  // Stream of connection status
  Stream<bool> get connectionStream => _connectionStreamController.stream;

  // Initialize connectivity monitoring
  Future<void> initialize() async {
    _connectionStreamController = StreamController<bool>.broadcast();

    // Check initial connectivity
    final result = await _connectivity.checkConnectivity();
    _updateConnectionStatus(
        result); // result is already a List<ConnectivityResult>

    // Listen for connectivity changes
    _connectivity.onConnectivityChanged
        .listen((List<ConnectivityResult> results) {
      _updateConnectionStatus(results);
    });
  }

  // Update connection status and notify listeners
  void _updateConnectionStatus(List<ConnectivityResult> results) {
    final bool hasConnection = results.any((result) =>
        result == ConnectivityResult.mobile ||
        result == ConnectivityResult.wifi ||
        result == ConnectivityResult.ethernet);

    if (_isConnected != hasConnection) {
      _isConnected = hasConnection;
      _connectionStreamController.add(_isConnected);
    }
  }

  // Check if device has internet connection
  Future<bool> hasInternetConnection() async {
    try {
      final result = await _connectivity.checkConnectivity();
      return result.any((conn) =>
          conn == ConnectivityResult.mobile ||
          conn == ConnectivityResult.wifi ||
          conn == ConnectivityResult.ethernet);
    } catch (e) {
      return false;
    }
  }

  // Get current connectivity type
  Future<String> getConnectionType() async {
    try {
      final result = await _connectivity.checkConnectivity();
      if (result.contains(ConnectivityResult.wifi)) {
        return 'WiFi';
      } else if (result.contains(ConnectivityResult.mobile)) {
        return 'Mobile Data';
      } else if (result.contains(ConnectivityResult.ethernet)) {
        return 'Ethernet';
      } else {
        return 'None';
      }
    } catch (e) {
      return 'Unknown';
    }
  }

  // Dispose resources
  void dispose() {
    _connectionStreamController.close();
  }
}
