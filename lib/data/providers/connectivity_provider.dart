import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/connectivity_service.dart';

// Connectivity Service Provider
final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  return ConnectivityService();
});

// Connectivity State Provider - Stream of connection status
final connectivityProvider = StreamProvider<bool>((ref) {
  final connectivityService = ref.watch(connectivityServiceProvider);
  return connectivityService.connectionStream;
});

// Current Connection Status Provider - Sync access to connection status
final isConnectedProvider = Provider<bool>((ref) {
  final connectivityService = ref.watch(connectivityServiceProvider);
  return connectivityService.isConnected;
});

// Connection Type Provider
final connectionTypeProvider = FutureProvider<String>((ref) async {
  final connectivityService = ref.watch(connectivityServiceProvider);
  return await connectivityService.getConnectionType();
});

// Connectivity Controller for managing connectivity state
final connectivityControllerProvider =
    StateNotifierProvider<ConnectivityController, ConnectivityState>((ref) {
  return ConnectivityController(ref.watch(connectivityServiceProvider));
});

// Connectivity State
class ConnectivityState {
  final bool isConnected;
  final String connectionType;
  final bool hasBeenOffline;
  final DateTime? lastConnectionTime;

  const ConnectivityState({
    this.isConnected = false,
    this.connectionType = 'Unknown',
    this.hasBeenOffline = false,
    this.lastConnectionTime,
  });

  ConnectivityState copyWith({
    bool? isConnected,
    String? connectionType,
    bool? hasBeenOffline,
    DateTime? lastConnectionTime,
  }) {
    return ConnectivityState(
      isConnected: isConnected ?? this.isConnected,
      connectionType: connectionType ?? this.connectionType,
      hasBeenOffline: hasBeenOffline ?? this.hasBeenOffline,
      lastConnectionTime: lastConnectionTime ?? this.lastConnectionTime,
    );
  }
}

// Connectivity Controller
class ConnectivityController extends StateNotifier<ConnectivityState> {
  final ConnectivityService _connectivityService;

  ConnectivityController(this._connectivityService)
      : super(const ConnectivityState()) {
    _initializeConnectivity();
    _listenToConnectivityChanges();
  }

  // Initialize connectivity state
  void _initializeConnectivity() async {
    final isConnected = await _connectivityService.hasInternetConnection();
    final connectionType = await _connectivityService.getConnectionType();

    state = state.copyWith(
      isConnected: isConnected,
      connectionType: connectionType,
      lastConnectionTime: isConnected ? DateTime.now() : null,
    );
  }

  // Listen to connectivity changes
  void _listenToConnectivityChanges() {
    _connectivityService.connectionStream.listen((isConnected) async {
      final connectionType = await _connectivityService.getConnectionType();

      state = state.copyWith(
        isConnected: isConnected,
        connectionType: connectionType,
        hasBeenOffline: state.hasBeenOffline || !isConnected,
        lastConnectionTime:
            isConnected ? DateTime.now() : state.lastConnectionTime,
      );
    });
  }

  // Manually check connectivity
  Future<void> checkConnectivity() async {
    final isConnected = await _connectivityService.hasInternetConnection();
    final connectionType = await _connectivityService.getConnectionType();

    state = state.copyWith(
      isConnected: isConnected,
      connectionType: connectionType,
      lastConnectionTime:
          isConnected ? DateTime.now() : state.lastConnectionTime,
    );
  }

  // Reset offline status (for UI indicators)
  void resetOfflineStatus() {
    state = state.copyWith(hasBeenOffline: false);
  }

  // Get formatted connection info
  String get connectionInfo {
    if (state.isConnected) {
      return 'Connected via ${state.connectionType}';
    } else {
      return 'No internet connection';
    }
  }

  // Get offline duration
  Duration? get offlineDuration {
    if (state.isConnected || state.lastConnectionTime == null) {
      return null;
    }
    return DateTime.now().difference(state.lastConnectionTime!);
  }
}
