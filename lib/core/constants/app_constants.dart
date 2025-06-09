class AppConstants {
  // App Information
  static const String appName = 'Aqualyze';
  static const String appVersion = '1.0.0';

  // Firestore Collections
  static const String waterQualitySemarangCollection = 'water_quality';
  static const String waterQualityMalangCollection = 'water_quality_malang';
  static const String usersCollection = 'users';

  // Location Options
  static const String defaultLocation = 'semarang';
  static const List<String> availableLocations = ['semarang', 'malang'];

  // Data Sync Settings
  static const int dataRetentionDays = 30;
  static const int syncBatchSize = 100;

  // Sensor Thresholds - Crab Farming Optimized
  // pH: 0-14 range, optimal for crab: 6.5-7.5
  static const double phMin = 6.5;
  static const double phMax = 7.5;
  static const double phAbsoluteMin = 0.0;
  static const double phAbsoluteMax = 14.0;

  // Temperature: 20-34°C range, optimal for crab: 26-31°C
  static const double temperatureMin = 26.0;
  static const double temperatureMax = 31.0;
  static const double temperatureAbsoluteMin = 20.0;
  static const double temperatureAbsoluteMax = 34.0;

  // Dissolved Oxygen: minimum 0, optimal for crab: >4.0 mg/L
  static const double doMin = 4.0;
  static const double doAbsoluteMin = 0.0;

  // Turbidity: 0-1000 NTU range, optimal for crab: 300-700 NTU
  static const double turbidityMin = 300;
  static const double turbidityMax = 700;
  static const double turbidityAbsoluteMin = 0.0;
  static const double turbidityAbsoluteMax = 1000.0;

  // UI Constants
  static const double cardBorderRadius = 16.0;
  static const double buttonBorderRadius = 12.0;
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;

  // Animation Durations
  static const Duration shortAnimationDuration = Duration(milliseconds: 200);
  static const Duration mediumAnimationDuration = Duration(milliseconds: 300);
  static const Duration longAnimationDuration = Duration(milliseconds: 500);

  // Chart Settings
  static const List<String> timeFilters = [
    'Daily',
    'Weekly',
    'Monthly',
    'Year',
    'All'
  ];
  static const int maxChartDataPoints = 100;

  // Hive Box Names
  static const String waterQualityBox = 'water_quality_box';
  static const String userPreferencesBox = 'user_preferences_box';
  static const String syncMetadataBox = 'sync_metadata_box';

    // Helper method to get collection name by location
  static String getWaterQualityCollection(String location) {
    switch (location.toLowerCase()) {
      case 'semarang':
        return waterQualitySemarangCollection;
      case 'malang':
        return waterQualityMalangCollection;
      default:
        return waterQualitySemarangCollection; // Default to Semarang
    }
  }
}
