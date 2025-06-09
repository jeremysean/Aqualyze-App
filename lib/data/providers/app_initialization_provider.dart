import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/hive_service.dart';
import '../services/firebase_service.dart';
import '../../core/network/connectivity_service.dart';

// App Initialization State
enum InitializationStatus {
  loading,
  completed,
  error,
}

class InitializationState {
  final InitializationStatus status;
  final String? errorMessage;
  final List<String> completedSteps;

  const InitializationState({
    this.status = InitializationStatus.loading,
    this.errorMessage,
    this.completedSteps = const [],
  });

  InitializationState copyWith({
    InitializationStatus? status,
    String? errorMessage,
    List<String>? completedSteps,
  }) {
    return InitializationState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      completedSteps: completedSteps ?? this.completedSteps,
    );
  }
}

// App Initialization Provider (matching your splash page naming)
final initializationControllerProvider =
    StateNotifierProvider<InitializationController, InitializationState>((ref) {
  return InitializationController();
});

class InitializationController extends StateNotifier<InitializationState> {
  InitializationController() : super(const InitializationState());

  // Initialize all app services
  Future<void> initializeApp() async {
    try {
      state = state.copyWith(
        status: InitializationStatus.loading,
        completedSteps: ['Starting initialization...'],
      );

      // Step 1: Initialize Hive
      await HiveService.initialize();
      state = state.copyWith(
        completedSteps: [...state.completedSteps, 'Database ready...'],
      );

      // Step 2: Initialize connectivity service
      await ConnectivityService().initialize();
      state = state.copyWith(
        completedSteps: [...state.completedSteps, 'Network ready...'],
      );

      // Step 3: Complete initialization
      state = state.copyWith(
        status: InitializationStatus.completed,
        completedSteps: [...state.completedSteps, 'Ready!'],
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        status: InitializationStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  // Retry initialization
  Future<void> retry() async {
    await initializeApp();
  }

  // Check if services are initialized
  bool get isInitialized => state.status == InitializationStatus.completed;

  // Get Hive service instance
  HiveService get hiveService => HiveService();

  // Check if Hive is ready
  bool get isHiveReady => HiveService().isInitialized;
}
