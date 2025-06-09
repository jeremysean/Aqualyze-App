import '../../core/utils/app_logger.dart';
import '../models/water_quality.dart';
import '../services/firebase_service.dart';
import '../services/hive_service.dart';
import '../../core/network/connectivity_service.dart';

class WaterQualityRepository {
  final FirebaseService _firebaseService;
  final HiveService _hiveService;
  final ConnectivityService _connectivityService;

  static final Map<String, DateTime> _lastSyncAttempt = {};
  static const Duration _minSyncInterval = Duration(minutes: 2);

  WaterQualityRepository({
    FirebaseService? firebaseService,
    HiveService? hiveService,
    ConnectivityService? connectivityService,
  })  : _firebaseService = firebaseService ?? FirebaseService(),
        _hiveService = hiveService ?? HiveService(),
        _connectivityService = connectivityService ?? ConnectivityService();

  // Proper sync logic based on actual data timestamps
  Future<List<WaterQuality>> getWaterQualityData({
    required String location,
    bool forceRefresh = false,
    int? limit,
  }) async {
    try {
      AppLogger.info('=== FIXED SYNC LOGIC DEBUG ===', 'SYNC');

      // Get current local data to determine the REAL last timestamp
      final localData = await _hiveService.getWaterQualityData(
        location: location,
        startDate: null,
        endDate: null,
        limit: null, // Get all to find the newest
      );

      DateTime? actualLastDataTimestamp;
      if (localData.isNotEmpty) {
        // Find the actual newest timestamp in our local data
        actualLastDataTimestamp = localData
            .map((reading) => reading.timestamp)
            .reduce((a, b) => a.isAfter(b) ? a : b);
      }

      final storedLastSyncTime = _hiveService.getLastSyncTime(location);
      final lastSyncAttempt = _lastSyncAttempt[location];

      AppLogger.info('🔍 SYNC STATE ANALYSIS:', 'SYNC');
      AppLogger.info('  - Local data count: ${localData.length}', 'SYNC');
      AppLogger.info(
          '  - Actual newest local data: $actualLastDataTimestamp', 'SYNC');
      AppLogger.info('  - Stored last sync time: $storedLastSyncTime', 'SYNC');
      AppLogger.info('  - Last sync attempt: $lastSyncAttempt', 'SYNC');
      AppLogger.info('  - Force refresh: $forceRefresh', 'SYNC');

      // Use the actual data timestamp, not the stored sync time
      DateTime? syncFromTimestamp = actualLastDataTimestamp;

      // If we have a mismatch, fix it
      if (actualLastDataTimestamp != null && storedLastSyncTime != null) {
        final timeDiff =
            storedLastSyncTime.difference(actualLastDataTimestamp).inMinutes;
        if (timeDiff.abs() > 60) {
          // More than 1 hour difference
          AppLogger.warning('🚨 SYNC TIME MISMATCH DETECTED!', 'SYNC');
          AppLogger.warning(
              '  - Stored sync time: $storedLastSyncTime', 'SYNC');
          AppLogger.warning(
              '  - Actual data time: $actualLastDataTimestamp', 'SYNC');
          AppLogger.warning('  - Difference: ${timeDiff} minutes', 'SYNC');
          AppLogger.warning('  - Using actual data timestamp for sync', 'SYNC');
        }
      }

      // Determine if we need to sync
      bool needsSync = false;
      String syncReason = '';

      if (forceRefresh) {
        needsSync = true;
        syncReason = '🔄 Force refresh requested';
      } else if (!_connectivityService.isConnected) {
        needsSync = false;
        syncReason = '📡 No internet connection';
      } else if (localData.isEmpty) {
        needsSync = true;
        syncReason = '📁 No local data found';
      } else if (actualLastDataTimestamp == null) {
        needsSync = true;
        syncReason = '⏰ No timestamp found in local data';
      } else {
        // Check if local data is old (older than 10 minutes)
        final minutesSinceLastData =
            DateTime.now().difference(actualLastDataTimestamp).inMinutes;
        AppLogger.info(
            '  - Minutes since newest local data: $minutesSinceLastData',
            'SYNC');

        if (minutesSinceLastData > 10) {
          needsSync = true;
          syncReason =
              '⏱️ Local data is ${minutesSinceLastData} minutes old (>10min threshold)';
        }
      }

      AppLogger.info('🤔 SYNC DECISION:', 'SYNC');
      AppLogger.info('  - Needs sync: $needsSync', 'SYNC');
      AppLogger.info('  - Reason: $syncReason', 'SYNC');

      // Check cooldown - BUT ignore cooldown if we have a sync mismatch
      bool cooldownActive = false;
      if (!forceRefresh && lastSyncAttempt != null) {
        final timeSinceLastAttempt = DateTime.now().difference(lastSyncAttempt);
        cooldownActive = timeSinceLastAttempt < _minSyncInterval;

        // FIXED: Ignore cooldown if we detected a sync mismatch
        bool hasSyncMismatch = false;
        if (actualLastDataTimestamp != null && storedLastSyncTime != null) {
          final timeDiff =
              storedLastSyncTime.difference(actualLastDataTimestamp).inMinutes;
          hasSyncMismatch = timeDiff.abs() > 60; // More than 1 hour difference
        }

        if (cooldownActive && hasSyncMismatch) {
          AppLogger.info('⚡ Ignoring cooldown due to sync mismatch', 'SYNC');
          cooldownActive = false;
        }
      }

      if (cooldownActive) {
        AppLogger.info('⏳ Sync cooldown active - skipping sync', 'SYNC');
        return localData.take(limit ?? localData.length).toList();
      }

      // Perform sync if needed
      if (needsSync && _connectivityService.isConnected) {
        try {
          AppLogger.info('🚀 STARTING FIRESTORE SYNC', 'SYNC');
          _lastSyncAttempt[location] = DateTime.now();

          List<WaterQuality> newData;

          if (syncFromTimestamp == null) {
            // Initial sync - get recent data
            AppLogger.info('📡 Initial sync - getting recent data', 'SYNC');
            newData = await _firebaseService.getWaterQualityData(
              location: location,
              lastSyncTime: null,
              limit: 100,
            );
          } else {
            // FIXED: Incremental sync from actual last data timestamp
            // Subtract 1 minute to ensure we don't miss any data
            final syncFrom =
                syncFromTimestamp.subtract(const Duration(minutes: 1));
            AppLogger.info('📡 Incremental sync from: $syncFrom', 'SYNC');

            newData = await _firebaseService.getWaterQualityData(
              location: location,
              lastSyncTime: syncFrom,
              limit: 100,
            );
          }

          AppLogger.info('📊 FIRESTORE RESPONSE:', 'SYNC');
          AppLogger.info('  - Records received: ${newData.length}', 'SYNC');

          if (newData.isNotEmpty) {
            // Log sample data
            for (int i = 0; i < 3 && i < newData.length; i++) {
              final record = newData[i];
              AppLogger.info(
                  '  - Sample ${i + 1}: ${record.timestamp} - T:${record.temperature}°C',
                  'SYNC');
            }

            // Filter out duplicates based on timestamp
            final existingTimestamps = localData
                .map((r) => r.timestamp.millisecondsSinceEpoch)
                .toSet();
            final uniqueNewData = newData
                .where((record) => !existingTimestamps
                    .contains(record.timestamp.millisecondsSinceEpoch))
                .toList();

            AppLogger.info(
                '  - Unique new records: ${uniqueNewData.length}', 'SYNC');

            if (uniqueNewData.isNotEmpty) {
              // Save new data
              await _hiveService.saveWaterQualityData(uniqueNewData, location);

              // FIXED: Set sync time to the newest DATA timestamp, not current time
              final newestDataTimestamp = uniqueNewData
                  .map((r) => r.timestamp)
                  .reduce((a, b) => a.isAfter(b) ? a : b);

              await _hiveService.setLastSyncTime(location, newestDataTimestamp);

              AppLogger.info('✅ SYNC SUCCESS:', 'SYNC');
              AppLogger.info(
                  '  - Saved ${uniqueNewData.length} unique records', 'SYNC');
              AppLogger.info(
                  '  - Updated sync time to actual data time: $newestDataTimestamp',
                  'SYNC');
            } else {
              AppLogger.info(
                  'ℹ️ All data was already in local storage', 'SYNC');
            }
          } else {
            AppLogger.info('ℹ️ No new data found in Firestore', 'SYNC');
            // DON'T update sync time if no data found - keep looking with same timestamp
          }

          // Clean old data
          await _hiveService.cleanOldData();
        } catch (e) {
          AppLogger.error('❌ Sync failed: $e', 'SYNC');
        }
      }

      // Return updated local data
      final finalData = await _hiveService.getWaterQualityData(
        location: location,
        startDate: null,
        endDate: null,
        limit: limit,
      );

      AppLogger.info('🏁 SYNC COMPLETE:', 'SYNC');
      AppLogger.info('  - Final local data count: ${finalData.length}', 'SYNC');

      if (finalData.isNotEmpty) {
        final newest = finalData.first;
        AppLogger.info(
            '  - Newest local data: ${newest.timestamp} - T:${newest.temperature}°C',
            'SYNC');
      }

      return finalData;
    } catch (e) {
      AppLogger.error('💥 Repository error: $e', 'REPOSITORY');
      throw Exception('Failed to get water quality data: $e');
    }
  }

  // Method to fix sync timestamp based on actual data
  Future<void> fixSyncTimestamp(String location) async {
    try {
      AppLogger.info('🔧 FIXING SYNC TIMESTAMP FOR $location', 'SYNC');

      final localData = await _hiveService.getWaterQualityData(
        location: location,
        startDate: null,
        endDate: null,
        limit: null,
      );

      if (localData.isNotEmpty) {
        final actualNewestTimestamp = localData
            .map((r) => r.timestamp)
            .reduce((a, b) => a.isAfter(b) ? a : b);

        await _hiveService.setLastSyncTime(location, actualNewestTimestamp);

        AppLogger.info(
            '✅ Fixed sync timestamp to: $actualNewestTimestamp', 'SYNC');
      } else {
        AppLogger.warning('No local data found to fix timestamp', 'SYNC');
      }
    } catch (e) {
      AppLogger.error('Failed to fix sync timestamp: $e', 'SYNC');
    }
  }

  // Force sync method that resets everything
  Future<void> forceFullSync(String location) async {
    try {
      AppLogger.info('🔥 FORCING FULL SYNC FOR $location', 'SYNC');

      // First, fix the sync timestamp based on actual data
      await fixSyncTimestamp(location);

      // Clear sync attempt to bypass cooldown
      _lastSyncAttempt.remove(location);

      // Force refresh
      await getWaterQualityData(location: location, forceRefresh: true);

      AppLogger.info('✅ Force sync completed', 'SYNC');
    } catch (e) {
      AppLogger.error('❌ Force sync failed: $e', 'SYNC');
      throw e;
    }
  }

  Future<WaterQuality?> getLatestWaterQuality(String location) async {
    try {
      await getWaterQualityData(location: location, limit: 1);
      final latest = await _hiveService.getLatestWaterQuality(location);

      if (latest != null) {
        AppLogger.info(
            'Latest reading: ${latest.timestamp} - Temp: ${latest.temperature}°C',
            'REPOSITORY');
      }

      return latest;
    } catch (e) {
      AppLogger.error('Failed to get latest water quality: $e', 'REPOSITORY');
      throw Exception('Failed to get latest water quality data: $e');
    }
  }

  Future<List<WaterQuality>> getAnalyticsData({
    required String location,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  }) async {
    try {
      await getWaterQualityData(location: location);

      var data = await _hiveService.getWaterQualityData(
        location: location,
        startDate: startDate,
        endDate: endDate,
        limit: limit,
      );

      return data;
    } catch (e) {
      AppLogger.error('Failed to get analytics data: $e', 'REPOSITORY');
      throw Exception('Failed to get analytics data: $e');
    }
  }

  Future<void> syncData(String location) async {
    if (!_connectivityService.isConnected) {
      throw Exception('No internet connection available');
    }
    await forceFullSync(location);
  }

  int getLocalDataCount(String location) => _hiveService.getDataCount(location);
  DateTime? getLastSyncTime(String location) =>
      _hiveService.getLastSyncTime(location);
  Stream<List<WaterQuality>> getWaterQualityStream(String location) =>
      _firebaseService.getWaterQualityStream(location);
  Future<void> clearLocalData() async {
    await _hiveService.clearAllData();
    _lastSyncAttempt.clear();
  }

  bool isSyncOnCooldown(String location) {
    final lastAttempt = _lastSyncAttempt[location];
    if (lastAttempt == null) return false;
    final timeSinceLastAttempt = DateTime.now().difference(lastAttempt);
    return timeSinceLastAttempt < _minSyncInterval;
  }

  Duration? getSyncCooldownRemaining(String location) {
    final lastAttempt = _lastSyncAttempt[location];
    if (lastAttempt == null) return null;
    final timeSinceLastAttempt = DateTime.now().difference(lastAttempt);
    final remaining = _minSyncInterval - timeSinceLastAttempt;
    return remaining.isNegative ? null : remaining;
  }
}
