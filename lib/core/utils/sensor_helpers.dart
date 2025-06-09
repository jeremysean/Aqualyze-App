import '../constants/app_constants.dart';
import '../constants/strings.dart';

enum SensorStatus { excellent, good, warning, critical }

class SensorHelpers {
  // pH Status Evaluation
  static SensorStatus getPHStatus(double value) {
    if (value < AppConstants.phAbsoluteMin ||
        value > AppConstants.phAbsoluteMax) {
      return SensorStatus.critical;
    } else if (value >= AppConstants.phMin && value <= AppConstants.phMax) {
      return SensorStatus.excellent;
    } else if ((value >= 6.0 && value < AppConstants.phMin) ||
        (value > AppConstants.phMax && value <= 8.0)) {
      return SensorStatus.good;
    } else if ((value >= 5.5 && value < 6.0) || (value > 8.0 && value <= 8.5)) {
      return SensorStatus.warning;
    } else {
      return SensorStatus.critical;
    }
  }

  // Temperature Status Evaluation
  static SensorStatus getTemperatureStatus(double value) {
    if (value < AppConstants.temperatureAbsoluteMin ||
        value > AppConstants.temperatureAbsoluteMax) {
      return SensorStatus.critical;
    } else if (value >= AppConstants.temperatureMin &&
        value <= AppConstants.temperatureMax) {
      return SensorStatus.excellent;
    } else if ((value >= 24.0 && value < AppConstants.temperatureMin) ||
        (value > AppConstants.temperatureMax && value <= 33.0)) {
      return SensorStatus.good;
    } else if ((value >= 22.0 && value < 24.0) ||
        (value > 33.0 && value <= 34.0)) {
      return SensorStatus.warning;
    } else {
      return SensorStatus.critical;
    }
  }

  // Dissolved Oxygen Status Evaluation
  static SensorStatus getDOStatus(double value) {
    if (value < AppConstants.doAbsoluteMin) {
      return SensorStatus.critical;
    } else if (value >= AppConstants.doMin) {
      return SensorStatus.excellent;
    } else if (value >= 3.0 && value < AppConstants.doMin) {
      return SensorStatus.good;
    } else if (value >= 2.0 && value < 3.0) {
      return SensorStatus.warning;
    } else {
      return SensorStatus.critical;
    }
  }

  // Turbidity Status Evaluation
  static SensorStatus getTurbidityStatus(double value) {
    if (value < AppConstants.turbidityAbsoluteMin ||
        value > AppConstants.turbidityAbsoluteMax) {
      return SensorStatus.critical;
    } else if (value >= AppConstants.turbidityMin &&
        value <= AppConstants.turbidityMax) {
      return SensorStatus.excellent;
    } else if ((value >= 2.5 && value < AppConstants.turbidityMin) ||
        (value > AppConstants.turbidityMax && value <= 5.0)) {
      return SensorStatus.good;
    } else if ((value >= 1.5 && value < 2.5) ||
        (value > 5.0 && value <= 10.0)) {
      return SensorStatus.warning;
    } else {
      return SensorStatus.critical;
    }
  }

  // Get status text
  static String getStatusText(SensorStatus status) {
    switch (status) {
      case SensorStatus.excellent:
        return AppStrings.excellent;
      case SensorStatus.good:
        return AppStrings.good;
      case SensorStatus.warning:
        return AppStrings.warning;
      case SensorStatus.critical:
        return AppStrings.critical;
    }
  }

  // Overall condition evaluation
  static SensorStatus getOverallCondition({
    required double ph,
    required double temperature,
    required double dissolvedOxygen,
    required double turbidity,
  }) {
    final statuses = [
      getPHStatus(ph),
      getTemperatureStatus(temperature),
      getDOStatus(dissolvedOxygen),
      getTurbidityStatus(turbidity),
    ];

    // If any critical, overall is critical
    if (statuses.contains(SensorStatus.critical)) {
      return SensorStatus.critical;
    }
    // If any warning, overall is warning
    if (statuses.contains(SensorStatus.warning)) {
      return SensorStatus.warning;
    }
    // If all excellent, overall is excellent
    if (statuses.every((status) => status == SensorStatus.excellent)) {
      return SensorStatus.excellent;
    }
    // Otherwise, it's good
    return SensorStatus.good;
  }

  // Get sensor unit
  static String getSensorUnit(String sensorType) {
    switch (sensorType.toLowerCase()) {
      case 'temperature':
        return AppStrings.celsiusUnit;
      case 'ph':
        return AppStrings.phUnit;
      case 'turbidity':
        return AppStrings.turbidityUnit;
      case 'do':
      case 'dissolved_oxygen':
        return AppStrings.doUnit;
      default:
        return '';
    }
  }

  // Format sensor value for display
  static String formatSensorValue(double value, String sensorType) {
    switch (sensorType.toLowerCase()) {
      case 'temperature':
        return '${value.toStringAsFixed(1)}${AppStrings.celsiusUnit}';
      case 'ph':
        return value.toStringAsFixed(2);
      case 'turbidity':
        return '${value.toStringAsFixed(1)} ${AppStrings.turbidityUnit}';
      case 'do':
      case 'dissolved_oxygen':
        return '${value.toStringAsFixed(1)} ${AppStrings.doUnit}';
      default:
        return value.toStringAsFixed(1);
    }
  }
}
