import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/prediction_model.dart';
import '../models/water_quality.dart';
import '../services/prediction_service.dart';
import 'water_quality_provider.dart';

// Prediction Service Provider
final predictionServiceProvider = Provider<PredictionService>((ref) {
  return PredictionService();
});

// Prediction State
enum PredictionStatus { initial, loading, loaded, error }

class PredictionState {
  final PredictionStatus status;
  final PredictionResponse? prediction;
  final String? errorMessage;
  final DateTime? lastPredictionTime;

  const PredictionState({
    this.status = PredictionStatus.initial,
    this.prediction,
    this.errorMessage,
    this.lastPredictionTime,
  });

  PredictionState copyWith({
    PredictionStatus? status,
    PredictionResponse? prediction,
    String? errorMessage,
    DateTime? lastPredictionTime,
  }) {
    return PredictionState(
      status: status ?? this.status,
      prediction: prediction ?? this.prediction,
      errorMessage: errorMessage ?? this.errorMessage,
      lastPredictionTime: lastPredictionTime ?? this.lastPredictionTime,
    );
  }
}

// Prediction Controller
class PredictionController extends StateNotifier<PredictionState> {
  final PredictionService _predictionService;

  PredictionController(this._predictionService)
      : super(const PredictionState());

  // Make prediction based on recent water quality data
  Future<void> makePrediction(List<WaterQuality> recentData) async {
    try {
      state = state.copyWith(status: PredictionStatus.loading);

      // Check if we have enough data
      if (!_predictionService.canMakePrediction(recentData)) {
        state = state.copyWith(
          status: PredictionStatus.error,
          errorMessage: 'Need at least 5 recent readings for prediction',
        );
        return;
      }

      // Make prediction
      final prediction = await _predictionService.predict(recentData);

      state = state.copyWith(
        status: PredictionStatus.loaded,
        prediction: prediction,
        errorMessage: null,
        lastPredictionTime: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(
        status: PredictionStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  // Clear prediction data
  void clearPrediction() {
    state = const PredictionState();
  }

  // Check if prediction is available
  bool get hasPrediction => state.prediction != null;

  // Check if prediction is recent (within 5 minutes)
  bool get isPredictionRecent {
    if (state.lastPredictionTime == null) return false;
    return DateTime.now().difference(state.lastPredictionTime!).inMinutes < 5;
  }
}

// Prediction Controller Provider
final predictionControllerProvider =
    StateNotifierProvider<PredictionController, PredictionState>((ref) {
  return PredictionController(ref.watch(predictionServiceProvider));
});

// Auto Prediction Provider - triggers prediction when new data is available
final autoPredictionProvider = Provider<void>((ref) {
  final waterQualityState = ref.watch(waterQualityControllerProvider);
  final predictionController = ref.watch(predictionControllerProvider.notifier);

  // Trigger prediction when we have new water quality data
  if (waterQualityState.status == WaterQualityStatus.loaded &&
      waterQualityState.data.isNotEmpty) {
    // Delay to avoid immediate execution during rebuild
    Future.microtask(() {
      predictionController.makePrediction(waterQualityState.data);
    });
  }
});

// Individual Sensor Prediction Providers (for easy access in UI)
final temperaturePredictionProvider = Provider<SensorPrediction?>((ref) {
  final predictionState = ref.watch(predictionControllerProvider);
  return predictionState.prediction?.predictions['temperature'];
});

final phPredictionProvider = Provider<SensorPrediction?>((ref) {
  final predictionState = ref.watch(predictionControllerProvider);
  return predictionState.prediction?.predictions['ph'];
});

final doPredictionProvider = Provider<SensorPrediction?>((ref) {
  final predictionState = ref.watch(predictionControllerProvider);
  return predictionState.prediction?.predictions['do'];
});

final turbidityPredictionProvider = Provider<SensorPrediction?>((ref) {
  final predictionState = ref.watch(predictionControllerProvider);
  return predictionState.prediction?.predictions['turbidity'];
});

// Helper provider to check if we can make predictions
final canMakePredictionProvider = Provider<bool>((ref) {
  final waterQualityState = ref.watch(waterQualityControllerProvider);
  final predictionService = ref.watch(predictionServiceProvider);

  return predictionService.canMakePrediction(waterQualityState.data);
});
