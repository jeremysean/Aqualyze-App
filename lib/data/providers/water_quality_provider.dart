import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../models/water_quality.dart';
import '../repositories/water_quality_repository.dart';
import 'auth_provider.dart';

// Water Quality Repository Provider
final waterQualityRepositoryProvider = Provider<WaterQualityRepository>((ref) {
  return WaterQualityRepository();
});

// Current Location Provider - gets user's preferred location
final currentLocationProvider = Provider<String>((ref) {
  final user = ref.watch(localUserProvider);
  return user?.locationPreference ?? AppConstants.defaultLocation;
});

// Latest Water Quality Provider
final latestWaterQualityProvider = FutureProvider<WaterQuality?>((ref) async {
  final repository = ref.watch(waterQualityRepositoryProvider);
  final location = ref.watch(currentLocationProvider);

  return await repository.getLatestWaterQuality(location);
});

// Water Quality Data Provider (for home screen)
final waterQualityDataProvider =
    FutureProvider<List<WaterQuality>>((ref) async {
  final repository = ref.watch(waterQualityRepositoryProvider);
  final location = ref.watch(currentLocationProvider);

  return await repository.getWaterQualityData(
    location: location,
    limit: 50, // Limit for home screen
  );
});

// Analytics Data Provider (with date range)
final analyticsDataProvider =
    FutureProvider.family<List<WaterQuality>, AnalyticsParams>(
        (ref, params) async {
  final repository = ref.watch(waterQualityRepositoryProvider);

  return await repository.getAnalyticsData(
    location: params.location,
    startDate: params.startDate,
    endDate: params.endDate,
    limit: params.limit,
  );
});

// Water Quality Controller for actions
final waterQualityControllerProvider =
    StateNotifierProvider<WaterQualityController, WaterQualityState>((ref) {
  return WaterQualityController(ref.watch(waterQualityRepositoryProvider));
});

// Analytics Parameters
class AnalyticsParams {
  final String location;
  final DateTime? startDate;
  final DateTime? endDate;
  final int? limit;

  AnalyticsParams({
    required this.location,
    this.startDate,
    this.endDate,
    this.limit,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AnalyticsParams &&
        other.location == location &&
        other.startDate == startDate &&
        other.endDate == endDate &&
        other.limit == limit;
  }

  @override
  int get hashCode {
    return Object.hash(location, startDate, endDate, limit);
  }
}

// Water Quality State
enum WaterQualityStatus { initial, loading, loaded, error, syncing }

class WaterQualityState {
  final WaterQualityStatus status;
  final List<WaterQuality> data;
  final WaterQuality? latestReading;
  final String? errorMessage;
  final DateTime? lastSyncTime;

  const WaterQualityState({
    this.status = WaterQualityStatus.initial,
    this.data = const [],
    this.latestReading,
    this.errorMessage,
    this.lastSyncTime,
  });

  WaterQualityState copyWith({
    WaterQualityStatus? status,
    List<WaterQuality>? data,
    WaterQuality? latestReading,
    String? errorMessage,
    DateTime? lastSyncTime,
  }) {
    return WaterQualityState(
      status: status ?? this.status,
      data: data ?? this.data,
      latestReading: latestReading ?? this.latestReading,
      errorMessage: errorMessage ?? this.errorMessage,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
    );
  }
}

// Water Quality Controller
class WaterQualityController extends StateNotifier<WaterQualityState> {
  final WaterQualityRepository _repository;

  WaterQualityController(this._repository) : super(const WaterQualityState());

  // Load water quality data
  Future<void> loadData(String location, {bool forceRefresh = false}) async {
    try {
      state = state.copyWith(
        status: forceRefresh
            ? WaterQualityStatus.syncing
            : WaterQualityStatus.loading,
      );

      final data = await _repository.getWaterQualityData(
        location: location,
        forceRefresh: forceRefresh,
      );

      final latestReading = data.isNotEmpty ? data.first : null;
      final lastSyncTime = _repository.getLastSyncTime(location);

      state = state.copyWith(
        status: WaterQualityStatus.loaded,
        data: data,
        latestReading: latestReading,
        lastSyncTime: lastSyncTime,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        status: WaterQualityStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  // Refresh data (pull-to-refresh)
  Future<void> refreshData(String location) async {
    await loadData(location, forceRefresh: true);
  }

  // Sync data manually
  Future<void> syncData(String location) async {
    try {
      state = state.copyWith(status: WaterQualityStatus.syncing);

      await _repository.syncData(location);

      // Reload data after sync
      await loadData(location);
    } catch (e) {
      state = state.copyWith(
        status: WaterQualityStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  // Clear error
  void clearError() {
    state = state.copyWith(
      status: state.status == WaterQualityStatus.error
          ? WaterQualityStatus.loaded
          : state.status,
      errorMessage: null,
    );
  }

  // Get local data count
  int getLocalDataCount(String location) {
    return _repository.getLocalDataCount(location);
  }
}
