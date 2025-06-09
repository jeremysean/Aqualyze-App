import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../../core/utils/app_logger.dart';
import '../models/prediction_model.dart';
import '../models/water_quality.dart';

class PredictionService {
  static final PredictionService _instance = PredictionService._internal();
  factory PredictionService() => _instance;
  PredictionService._internal();

  static const String _baseUrl = 'https://aqualyze-predict.up.railway.app';
  static const String _predictEndpoint = '/predict';
  static const Duration _timeout = Duration(seconds: 30);

  // Make prediction request with data validation
  Future<PredictionResponse> predict(List<WaterQuality> recentData) async {
    try {
      AppLogger.info('=== ML PREDICTION DEBUG START ===', 'PREDICTION');

      // Validate input data and filter invalid readings
      if (recentData.length < 5) {
        AppLogger.error(
            'Insufficient data: Need 5 readings, got ${recentData.length}',
            'PREDICTION');
        throw PredictionException(
          'Insufficient data for prediction. Need exactly 5 recent readings, got ${recentData.length}.',
        );
      }

      // Filter out readings with invalid sensor values
      final validData = recentData.where((reading) {
        // Check if all sensor values are within valid ranges
        bool isValid = true;
        String invalidReason = '';

        // pH validation (5.0-11.0 according to API)
        if (reading.ph < 5.0 || reading.ph > 11.0) {
          isValid = false;
          invalidReason += 'pH:${reading.ph} (valid:5.0-11.0) ';
        }

        // Temperature validation (reasonable range)
        if (reading.temperature < 0 || reading.temperature > 50) {
          isValid = false;
          invalidReason += 'Temp:${reading.temperature} (valid:0-50) ';
        }

        // DO validation (reasonable range)
        if (reading.dissolvedOxygen < 0 || reading.dissolvedOxygen > 20) {
          isValid = false;
          invalidReason += 'DO:${reading.dissolvedOxygen} (valid:0-20) ';
        }

        // Turbidity validation (reasonable range)
        if (reading.turbidity < 0 || reading.turbidity > 1000) {
          isValid = false;
          invalidReason += 'Turb:${reading.turbidity} (valid:0-1000) ';
        }

        if (!isValid) {
          AppLogger.warning(
              '❌ Invalid reading ${reading.timestamp}: $invalidReason',
              'PREDICTION');
        }

        return isValid;
      }).toList();

      AppLogger.info('📊 Data validation results:', 'PREDICTION');
      AppLogger.info('  - Total readings: ${recentData.length}', 'PREDICTION');
      AppLogger.info('  - Valid readings: ${validData.length}', 'PREDICTION');
      AppLogger.info(
          '  - Invalid readings: ${recentData.length - validData.length}',
          'PREDICTION');

      if (validData.length < 5) {
        AppLogger.error(
            'Insufficient valid data: Need 5 valid readings, got ${validData.length}',
            'PREDICTION');
        throw PredictionException(
          'Insufficient valid data for prediction. Need 5 valid readings, got ${validData.length}. Check sensor data quality.',
        );
      }

      // Sort by timestamp to ensure we get the latest valid readings
      final sortedData = List<WaterQuality>.from(validData);
      sortedData
          .sort((a, b) => b.timestamp.compareTo(a.timestamp)); // Newest first

      // Take exactly the latest 5 valid readings
      final latest5 = sortedData.take(5).toList();

      AppLogger.info('Selected 5 most recent VALID readings:', 'PREDICTION');
      for (int i = 0; i < latest5.length; i++) {
        final reading = latest5[i];
        AppLogger.info(
            '  ${i + 1}. ${reading.timestamp.toIso8601String()} - T:${reading.temperature}°C, pH:${reading.ph}, DO:${reading.dissolvedOxygen}mg/L, Turb:${reading.turbidity}NTU',
            'PREDICTION');
      }

      // Prepare data in exact format expected by API
      final data = latest5
          .map((reading) => [
                reading.temperature,
                reading.ph,
                reading.dissolvedOxygen,
                reading.turbidity,
              ])
          .toList();

      AppLogger.info('Formatted data for API:', 'PREDICTION');
      for (int i = 0; i < data.length; i++) {
        AppLogger.info('  Reading ${i + 1}: ${data[i]}', 'PREDICTION');
      }

      // Create request with timestamp
      final request = PredictionRequest(
        data: data,
        timestamp: DateTime.now().toUtc().toIso8601String(),
      );

      final requestJson = request.toJson();
      AppLogger.info('Full request payload:', 'PREDICTION');
      AppLogger.info(
          JsonEncoder.withIndent('  ').convert(requestJson), 'PREDICTION');

      // Make HTTP request to correct URL
      final uri = Uri.parse('$_baseUrl$_predictEndpoint');
      AppLogger.info('Making request to: $uri', 'PREDICTION');

      final response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'User-Agent': 'Aqualyze-Flutter-App/1.0',
            },
            body: jsonEncode(requestJson),
          )
          .timeout(_timeout);

      AppLogger.info('Response status: ${response.statusCode}', 'PREDICTION');
      AppLogger.info('Response headers: ${response.headers}', 'PREDICTION');
      AppLogger.info('Response body: ${response.body}', 'PREDICTION');

      // Handle response
      if (response.statusCode == 200) {
        try {
          final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
          AppLogger.info('Parsed response JSON:', 'PREDICTION');
          AppLogger.info(
              JsonEncoder.withIndent('  ').convert(jsonData), 'PREDICTION');

          final predictionResponse = PredictionResponse.fromJson(jsonData);

          if (predictionResponse.success) {
            AppLogger.info('ML prediction successful!', 'PREDICTION');
            AppLogger.info(
                'Predictions received for sensors: ${predictionResponse.predictions.keys.toList()}',
                'PREDICTION');

            // Log each prediction
            predictionResponse.predictions.forEach((sensor, prediction) {
              AppLogger.info(
                  '$sensor: ${prediction.value.toStringAsFixed(2)}${prediction.unit} (confidence: ${prediction.modelConfidence}, R²: ${prediction.modelR2.toStringAsFixed(3)})',
                  'PREDICTION');
            });

            AppLogger.info(
                '=== ML PREDICTION DEBUG END (SUCCESS) ===', 'PREDICTION');
            return predictionResponse;
          } else {
            AppLogger.error('ML API returned success=false', 'PREDICTION');
            throw PredictionException('ML API returned success=false');
          }
        } catch (e) {
          AppLogger.error('Failed to parse response JSON: $e', 'PREDICTION');
          AppLogger.error('Raw response: ${response.body}', 'PREDICTION');
          throw PredictionException('Failed to parse prediction response: $e');
        }
      } else {
        AppLogger.error(
            'ML API request failed with status ${response.statusCode}',
            'PREDICTION');
        AppLogger.error('Error response body: ${response.body}', 'PREDICTION');

        // Better error handling for validation errors
        if (response.statusCode == 400) {
          try {
            final errorJson = jsonDecode(response.body);
            if (errorJson['error_type'] == 'validation_error') {
              throw PredictionException(
                'Data validation failed: ${errorJson['error']}\n\nThis usually means your sensor data has values outside the expected ranges. Check your water quality sensors.',
              );
            }
          } catch (e) {
            // If JSON parsing fails, use original error
          }
        }

        throw PredictionException(
          'ML API request failed with status ${response.statusCode}: ${response.body}',
        );
      }
    } on TimeoutException {
      AppLogger.error(
          'ML prediction request timeout after ${_timeout.inSeconds}s',
          'PREDICTION');
      throw PredictionException(
          'Prediction request timed out after ${_timeout.inSeconds} seconds. Please try again.');
    } on PredictionException {
      AppLogger.info('=== ML PREDICTION DEBUG END (ERROR) ===', 'PREDICTION');
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected ML prediction error: $e', 'PREDICTION');
      AppLogger.info(
          '=== ML PREDICTION DEBUG END (UNEXPECTED ERROR) ===', 'PREDICTION');
      throw PredictionException('Failed to get prediction: ${e.toString()}');
    }
  }

  // Helper method to check if we have enough data for prediction
  bool canMakePrediction(List<WaterQuality> data) {
    final canPredict = data.length >= 5;
    AppLogger.info(
        'Can make prediction: $canPredict (have ${data.length} readings)',
        'PREDICTION');
    return canPredict;
  }

  // Debug method to show what data would be sent
  Future<void> debugPredictionData(List<WaterQuality> recentData) async {
    try {
      AppLogger.info('=== PREDICTION DATA DEBUG ===', 'PREDICTION');
      AppLogger.info(
          'Total available readings: ${recentData.length}', 'PREDICTION');

      if (recentData.length < 5) {
        AppLogger.warning('Insufficient data for prediction', 'PREDICTION');
        return;
      }

      // Sort by timestamp
      final sortedData = List<WaterQuality>.from(recentData);
      sortedData.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      // Show what would be sent
      final latest5 = sortedData.take(5).toList();
      AppLogger.info('Would send these 5 readings to API:', 'PREDICTION');

      for (int i = 0; i < latest5.length; i++) {
        final reading = latest5[i];
        final dataPoint = [
          reading.temperature,
          reading.ph,
          reading.dissolvedOxygen,
          reading.turbidity,
        ];

        AppLogger.info(
            '  ${i + 1}. ${reading.timestamp.toIso8601String()}', 'PREDICTION');
        AppLogger.info('     Data: $dataPoint', 'PREDICTION');
        AppLogger.info(
            '     Human: T=${reading.temperature}°C, pH=${reading.ph}, DO=${reading.dissolvedOxygen}mg/L, Turb=${reading.turbidity}NTU',
            'PREDICTION');
      }

      // Show timestamp range
      final oldest = latest5.last;
      final newest = latest5.first;
      final spanMinutes =
          newest.timestamp.difference(oldest.timestamp).inMinutes;
      AppLogger.info(
          'Data span: ${spanMinutes} minutes (${oldest.timestamp} to ${newest.timestamp})',
          'PREDICTION');

      AppLogger.info('=== END PREDICTION DATA DEBUG ===', 'PREDICTION');
    } catch (e) {
      AppLogger.error('Failed to debug prediction data: $e', 'PREDICTION');
    }
  }

  // Get formatted confidence message
  String getConfidenceMessage(SensorPrediction prediction) {
    final confidence = prediction.modelConfidence.toLowerCase();
    final r2 = prediction.modelR2;

    switch (confidence) {
      case 'high':
        return 'High confidence • ${prediction.reliabilityDescription}';
      case 'medium':
        return 'Medium confidence • ${prediction.reliabilityDescription}';
      case 'low':
        return 'Low confidence • ${prediction.reliabilityDescription}';
      default:
        return 'Unknown confidence level';
    }
  }

  // IMPROVED: Test API connectivity with detailed debugging
  Future<bool> testConnection() async {
    try {
      AppLogger.info('=== API CONNECTION TEST START ===', 'PREDICTION');
      AppLogger.info('Testing ML API connection to: $_baseUrl$_predictEndpoint',
          'PREDICTION');

      // Test with realistic sample data
      final testData = PredictionRequest(
        data: [
          [28.5, 7.2, 4.1, 3.8], // Sample reading 1
          [28.3, 7.1, 4.0, 3.9], // Sample reading 2
          [28.4, 7.3, 4.2, 3.7], // Sample reading 3
          [28.6, 7.0, 3.9, 4.0], // Sample reading 4
          [28.2, 7.2, 4.1, 3.8], // Sample reading 5
        ],
        timestamp: DateTime.now().toUtc().toIso8601String(),
      );

      AppLogger.info('Test request data:', 'PREDICTION');
      AppLogger.info(JsonEncoder.withIndent('  ').convert(testData.toJson()),
          'PREDICTION');

      final uri = Uri.parse('$_baseUrl$_predictEndpoint');
      final response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'User-Agent': 'Aqualyze-Flutter-App/1.0-Test',
            },
            body: jsonEncode(testData.toJson()),
          )
          .timeout(const Duration(seconds: 10));

      AppLogger.info(
          'Test response status: ${response.statusCode}', 'PREDICTION');
      AppLogger.info('Test response body: ${response.body}', 'PREDICTION');

      if (response.statusCode == 200) {
        try {
          final jsonData = jsonDecode(response.body);
          final success = jsonData['success'] ?? false;
          AppLogger.info(
              'ML API connection test result: $success', 'PREDICTION');

          if (success && jsonData['predictions'] != null) {
            AppLogger.info('Test predictions received:', 'PREDICTION');
            final predictions = jsonData['predictions'] as Map<String, dynamic>;
            predictions.forEach((sensor, pred) {
              if (pred is Map<String, dynamic>) {
                AppLogger.info(
                    '  $sensor: ${pred['value']} ${pred['unit']} (${pred['model_confidence']})',
                    'PREDICTION');
              }
            });
          }

          AppLogger.info(
              '=== API CONNECTION TEST END (SUCCESS) ===', 'PREDICTION');
          return success;
        } catch (e) {
          AppLogger.error('Failed to parse test response: $e', 'PREDICTION');
          AppLogger.info(
              '=== API CONNECTION TEST END (PARSE ERROR) ===', 'PREDICTION');
          return false;
        }
      } else {
        AppLogger.warning(
            'API connection test failed with status: ${response.statusCode}',
            'PREDICTION');
        AppLogger.info(
            '=== API CONNECTION TEST END (HTTP ERROR) ===', 'PREDICTION');
        return false;
      }
    } catch (e) {
      AppLogger.error('API connection test failed: $e', 'PREDICTION');
      AppLogger.info(
          '=== API CONNECTION TEST END (EXCEPTION) ===', 'PREDICTION');
      return false;
    }
  }

  // Helper to format sensor names for display
  String formatSensorName(String apiSensorName) {
    switch (apiSensorName.toLowerCase()) {
      case 'do':
        return 'Dissolved Oxygen';
      case 'ph':
        return 'pH Level';
      case 'temperature':
        return 'Temperature';
      case 'turbidity':
        return 'Turbidity';
      default:
        return apiSensorName;
    }
  }

  // Helper to get prediction summary
  String getPredictionSummary(Map<String, SensorPrediction> predictions) {
    final highConfidence =
        predictions.values.where((p) => p.modelConfidence == 'high').length;
    final total = predictions.length;

    if (highConfidence == total) {
      return 'All predictions have high confidence';
    } else if (highConfidence > total / 2) {
      return 'Most predictions have good confidence';
    } else {
      return 'Predictions have mixed confidence levels';
    }
  }
}

// Custom exception for prediction errors
class PredictionException implements Exception {
  final String message;

  PredictionException(this.message);

  @override
  String toString() => 'PredictionException: $message';
}
