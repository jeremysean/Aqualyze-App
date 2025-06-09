// lib\data\services\hive_service.dart

import 'package:hive_flutter/hive_flutter.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/app_logger.dart';
import '../models/water_quality.dart';
import '../models/user_model.dart';

class HiveService {
  static final HiveService _instance = HiveService._internal();
  factory HiveService() => _instance;
  HiveService._internal();

  // Box references
  Box<WaterQuality>? _waterQualityBox;
  Box<UserModel>? _userBox;
  Box<dynamic>? _syncMetadataBox;

  // Track initialization status
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  // Initialize Hive - Static method called from main.dart
  static Future<void> initialize() async {
    try {
      // Check if already initialized
      if (HiveService._instance._isInitialized) {
        AppLogger.hive('Hive already initialized, skipping...');
        return;
      }

      AppLogger.hive('Initializing Hive database...');

      // Initialize Hive with Flutter
      await Hive.initFlutter();

      // Register adapters if not already registered
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(WaterQualityAdapter());
        AppLogger.hive('Registered WaterQuality adapter');
      }

      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(UserModelAdapter());
        AppLogger.hive('Registered UserModel adapter');
      }

      // Mark as initialized and open boxes
      final instance = HiveService._instance;
      await instance._openBoxes();
      instance._isInitialized = true;
      AppLogger.hive('Hive initialization completed successfully');
    } catch (e) {
      AppLogger.error('Failed to initialize Hive', 'HIVE', e);
      throw Exception('Failed to initialize Hive: $e');
    }
  }

  // Private method to open boxes (called during initialization)
  Future<void> _openBoxes() async {
    try {
      AppLogger.hive('Opening Hive boxes...');

      _waterQualityBox =
          await Hive.openBox<WaterQuality>(AppConstants.waterQualityBox);
      _userBox = await Hive.openBox<UserModel>(AppConstants.userPreferencesBox);
      _syncMetadataBox = await Hive.openBox(AppConstants.syncMetadataBox);

      AppLogger.hive('All Hive boxes opened successfully');
    } catch (e) {
      AppLogger.error('Failed to open Hive boxes', 'HIVE', e);
      throw Exception('Failed to open Hive boxes: $e');
    }
  }

  // Ensure boxes are available (with better error handling)
  void _ensureBoxesOpen() {
    if (!_isInitialized) {
      AppLogger.error(
          'Hive not initialized. Call HiveService.initialize() first from main.dart.',
          'HIVE');
      throw Exception(
          'Hive not initialized. Call HiveService.initialize() first from main.dart.');
    }

    if (_waterQualityBox == null ||
        !_waterQualityBox!.isOpen ||
        _userBox == null ||
        !_userBox!.isOpen ||
        _syncMetadataBox == null ||
        !_syncMetadataBox!.isOpen) {
      AppLogger.error(
          'Hive boxes are not open or have been closed. App needs to be restarted.',
          'HIVE');
      throw Exception(
          'Hive boxes are not open or have been closed. App needs to be restarted.');
    }
  }

  // Close boxes
  Future<void> closeBoxes() async {
    try {
      AppLogger.hive('Closing Hive boxes...');

      await _waterQualityBox?.close();
      await _userBox?.close();
      await _syncMetadataBox?.close();

      _waterQualityBox = null;
      _userBox = null;
      _syncMetadataBox = null;

      AppLogger.hive('Hive boxes closed successfully');
    } catch (e) {
      AppLogger.warning('Error closing Hive boxes', 'HIVE');
      // Silently handle close errors in production
    }
  }

  // Water Quality Data Methods
  Future<void> saveWaterQualityData(
      List<WaterQuality> data, String location) async {
    _ensureBoxesOpen();

    try {
      AppLogger.hive(
          'Saving ${data.length} water quality records for $location');

      // Add location to each data point and save
      for (final item in data) {
        final itemWithLocation = item.copyWith(location: location);
        final key = '${location}_${item.timestamp.millisecondsSinceEpoch}';
        await _waterQualityBox!.put(key, itemWithLocation);
      }

      AppLogger.hive('Successfully saved ${data.length} records');
    } catch (e) {
      AppLogger.error('Failed to save water quality data', 'HIVE', e);
      throw Exception('Failed to save water quality data: $e');
    }
  }

  Future<List<WaterQuality>> getWaterQualityData({
    required String location,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  }) async {
    _ensureBoxesOpen();

    try {
      var allData = _waterQualityBox!.values
          .where((item) => item.location == location)
          .toList();

      AppLogger.hive('Found ${allData.length} total records for $location');

      // Apply date filters
      if (startDate != null) {
        allData =
            allData.where((item) => item.timestamp.isAfter(startDate)).toList();
        AppLogger.hive('After start date filter: ${allData.length} records');
      }
      if (endDate != null) {
        allData =
            allData.where((item) => item.timestamp.isBefore(endDate)).toList();
        AppLogger.hive('After end date filter: ${allData.length} records');
      }

      // Sort by timestamp (newest first)
      allData.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      // Apply limit
      if (limit != null && allData.length > limit) {
        allData = allData.take(limit).toList();
        AppLogger.hive('Applied limit, returning ${allData.length} records');
      }

      return allData;
    } catch (e) {
      AppLogger.error('Failed to get water quality data', 'HIVE', e);
      throw Exception('Failed to get water quality data: $e');
    }
  }

  Future<WaterQuality?> getLatestWaterQuality(String location) async {
    _ensureBoxesOpen();

    try {
      final data = await getWaterQualityData(location: location, limit: 1);
      final latest = data.isNotEmpty ? data.first : null;

      if (latest != null) {
        AppLogger.hive('Found latest reading for $location');
      } else {
        AppLogger.warning('No latest reading found for $location', 'HIVE');
      }

      return latest;
    } catch (e) {
      AppLogger.error('Failed to get latest water quality data', 'HIVE', e);
      throw Exception('Failed to get latest water quality data: $e');
    }
  }

  Future<void> cleanOldData() async {
    _ensureBoxesOpen();

    try {
      final cutoffDate = DateTime.now()
          .subtract(Duration(days: AppConstants.dataRetentionDays));

      final keysToDelete = <String>[];

      for (final entry in _waterQualityBox!.toMap().entries) {
        if (entry.value.timestamp.isBefore(cutoffDate)) {
          keysToDelete.add(entry.key.toString());
        }
      }

      await _waterQualityBox!.deleteAll(keysToDelete);
      AppLogger.hive('Cleaned ${keysToDelete.length} old records');
    } catch (e) {
      AppLogger.error('Failed to clean old data', 'HIVE', e);
      throw Exception('Failed to clean old data: $e');
    }
  }

  // User Data Methods
  Future<void> saveUser(UserModel user) async {
    _ensureBoxesOpen();

    try {
      await _userBox!.put('current_user', user);
      AppLogger.hive('User saved successfully: ${user.email}');
    } catch (e) {
      AppLogger.error('Failed to save user', 'HIVE', e);
      throw Exception('Failed to save user: $e');
    }
  }

  UserModel? getCurrentUser() {
    if (!_isInitialized || _userBox == null || !_userBox!.isOpen) {
      AppLogger.warning('Cannot get current user - Hive not ready', 'HIVE');
      return null;
    }

    try {
      final user = _userBox!.get('current_user');
      if (user != null) {
        AppLogger.hive('Current user retrieved: ${user.email}');
      }
      return user;
    } catch (e) {
      AppLogger.warning('Error getting current user', 'HIVE');
      return null;
    }
  }

  Future<void> clearUser() async {
    _ensureBoxesOpen();

    try {
      await _userBox!.delete('current_user');
      AppLogger.hive('User data cleared');
    } catch (e) {
      AppLogger.error('Failed to clear user data', 'HIVE', e);
    }
  }

  // Sync Metadata Methods
  Future<void> setLastSyncTime(String location, DateTime time) async {
    _ensureBoxesOpen();

    try {
      await _syncMetadataBox!
          .put('last_sync_$location', time.millisecondsSinceEpoch);
      AppLogger.hive('Last sync time updated for $location');
    } catch (e) {
      AppLogger.error('Failed to set last sync time', 'HIVE', e);
      throw Exception('Failed to set last sync time: $e');
    }
  }

  DateTime? getLastSyncTime(String location) {
    if (!_isInitialized ||
        _syncMetadataBox == null ||
        !_syncMetadataBox!.isOpen) {
      AppLogger.warning('Cannot get last sync time - Hive not ready', 'HIVE');
      return null;
    }

    try {
      final timestamp = _syncMetadataBox!.get('last_sync_$location') as int?;
      final syncTime = timestamp != null
          ? DateTime.fromMillisecondsSinceEpoch(timestamp)
          : null;

      if (syncTime != null) {
        AppLogger.hive('Last sync time for $location: $syncTime');
      }

      return syncTime;
    } catch (e) {
      AppLogger.warning('Error getting last sync time', 'HIVE');
      return null;
    }
  }

  // Utility Methods
  Future<void> clearAllData() async {
    _ensureBoxesOpen();

    try {
      await _waterQualityBox!.clear();
      await _userBox!.clear();
      await _syncMetadataBox!.clear();
      AppLogger.hive('All local data cleared');
    } catch (e) {
      AppLogger.error('Failed to clear all data', 'HIVE', e);
    }
  }

  int getDataCount(String location) {
    if (!_isInitialized ||
        _waterQualityBox == null ||
        !_waterQualityBox!.isOpen) {
      AppLogger.warning('Cannot get data count - Hive not ready', 'HIVE');
      return 0;
    }

    try {
      final count = _waterQualityBox!.values
          .where((item) => item.location == location)
          .length;
      AppLogger.hive('Data count for $location: $count records');
      return count;
    } catch (e) {
      AppLogger.warning('Error getting data count', 'HIVE');
      return 0;
    }
  }
}
