class AnalyticsData {
  final SensorAggregation temperatureData;
  final SensorAggregation phData;
  final SensorAggregation turbidityData;
  final SensorAggregation dissolvedOxygenData;
  final TimeFilter timeRange;
  final String location;

  AnalyticsData({
    required this.temperatureData,
    required this.phData,
    required this.turbidityData,
    required this.dissolvedOxygenData,
    required this.timeRange,
    required this.location,
  });

  factory AnalyticsData.empty() {
    return AnalyticsData(
      temperatureData: SensorAggregation.empty('°C'),
      phData: SensorAggregation.empty('pH'),
      turbidityData: SensorAggregation.empty('NTU'),
      dissolvedOxygenData: SensorAggregation.empty('mg/L'),
      timeRange: TimeFilter.daily,
      location: '',
    );
  }
}

class SensorAggregation {
  final double current;
  final double average;
  final double minimum;
  final double maximum;
  final double percentageChange;
  final List<ChartDataPoint> chartData;
  final String unit;

  SensorAggregation({
    required this.current,
    required this.average,
    required this.minimum,
    required this.maximum,
    required this.percentageChange,
    required this.chartData,
    required this.unit,
  });

  factory SensorAggregation.empty(String unit) {
    return SensorAggregation(
      current: 0.0,
      average: 0.0,
      minimum: 0.0,
      maximum: 0.0,
      percentageChange: 0.0,
      chartData: [],
      unit: unit,
    );
  }

  // Helper to get percentage change display
  String get percentageChangeDisplay {
    final prefix = percentageChange >= 0 ? '+' : '';
    return '$prefix${percentageChange.toStringAsFixed(1)}%';
  }

  // Helper to determine if trend is positive, negative, or neutral
  TrendDirection get trendDirection {
    if (percentageChange > 1) return TrendDirection.up;
    if (percentageChange < -1) return TrendDirection.down;
    return TrendDirection.neutral;
  }
}

class ChartDataPoint {
  final DateTime timestamp;
  final double value;

  ChartDataPoint({
    required this.timestamp,
    required this.value,
  });
}

enum TimeFilter {
  daily,
  weekly,
  monthly,
  yearly,
  all,
}

extension TimeFilterExtension on TimeFilter {
  String get displayName {
    switch (this) {
      case TimeFilter.daily:
        return 'Daily';
      case TimeFilter.weekly:
        return 'Weekly';
      case TimeFilter.monthly:
        return 'Monthly';
      case TimeFilter.yearly:
        return 'Yearly';
      case TimeFilter.all:
        return 'All Time';
    }
  }
}

enum WaterQualityHealth {
  good,
  fair,
  poor,
  unknown,
}

extension WaterQualityHealthExtension on WaterQualityHealth {
  String get displayName {
    switch (this) {
      case WaterQualityHealth.good:
        return 'Good';
      case WaterQualityHealth.fair:
        return 'Fair';
      case WaterQualityHealth.poor:
        return 'Poor';
      case WaterQualityHealth.unknown:
        return 'Unknown';
    }
  }

  String get description {
    switch (this) {
      case WaterQualityHealth.good:
        return 'All parameters within optimal range';
      case WaterQualityHealth.fair:
        return 'Some parameters need attention';
      case WaterQualityHealth.poor:
        return 'Multiple parameters out of range';
      case WaterQualityHealth.unknown:
        return 'Unable to determine status';
    }
  }
}

enum TrendDirection {
  up,
  down,
  neutral,
}