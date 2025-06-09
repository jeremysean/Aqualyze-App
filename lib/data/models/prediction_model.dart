//lib/data/models/prediction_model.dart
import 'package:flutter/material.dart';
class PredictionRequest {
  final List<List<double>> data;
  final String timestamp;

  PredictionRequest({
    required this.data,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'data': data,
      'timestamp': timestamp,
    };
  }
}

class PredictionResponse {
  final bool success;
  final PredictionMetadata metadata;
  final Map<String, SensorPrediction> predictions;

  PredictionResponse({
    required this.success,
    required this.metadata,
    required this.predictions,
  });

  factory PredictionResponse.fromJson(Map<String, dynamic> json) {
    return PredictionResponse(
      success: json['success'] ?? false,
      metadata: PredictionMetadata.fromJson(json['metadata'] ?? {}),
      predictions: Map<String, SensorPrediction>.fromEntries(
        (json['predictions'] as Map<String, dynamic>? ?? {}).entries.map(
          (entry) => MapEntry(
            entry.key,
            SensorPrediction.fromJson(entry.value as Map<String, dynamic>),
          ),
        ),
      ),
    );
  }
}

class PredictionMetadata {
  final String apiVersion;
  final String deploymentNote;
  final String predictionTimestamp;
  final int sequenceLength;
  final String timeConfidenceReason;
  final String timestamp;
  final String trainingWindow;

  PredictionMetadata({
    required this.apiVersion,
    required this.deploymentNote,
    required this.predictionTimestamp,
    required this.sequenceLength,
    required this.timeConfidenceReason,
    required this.timestamp,
    required this.trainingWindow,
  });

  factory PredictionMetadata.fromJson(Map<String, dynamic> json) {
    return PredictionMetadata(
      apiVersion: json['api_version'] ?? '',
      deploymentNote: json['deployment_note'] ?? '',
      predictionTimestamp: json['prediction_timestamp'] ?? '',
      sequenceLength: json['sequence_length'] ?? 5,
      timeConfidenceReason: json['time_confidence_reason'] ?? '',
      timestamp: json['timestamp'] ?? '',
      trainingWindow: json['training_window'] ?? '',
    );
  }
}

class SensorPrediction {
  final String algorithm;
  final String modelConfidence;
  final double modelR2;
  final String timeConfidence;
  final String unit;
  final double value;

  SensorPrediction({
    required this.algorithm,
    required this.modelConfidence,
    required this.modelR2,
    required this.timeConfidence,
    required this.unit,
    required this.value,
  });

  factory SensorPrediction.fromJson(Map<String, dynamic> json) {
    return SensorPrediction(
      algorithm: json['algorithm'] ?? '',
      modelConfidence: json['model_confidence'] ?? '',
      modelR2: (json['model_r2'] as num?)?.toDouble() ?? 0.0,
      timeConfidence: json['time_confidence'] ?? '',
      unit: json['unit'] ?? '',
      value: (json['value'] as num?)?.toDouble() ?? 0.0,
    );
  }

  // Helper method to get confidence color
  Color get confidenceColor {
    switch (modelConfidence.toLowerCase()) {
      case 'high':
        return const Color(0xFF10B981); // Green
      case 'medium':
        return const Color(0xFF3B82F6); // Blue
      case 'low':
        return const Color(0xFFF59E0B); // Yellow
      default:
        return const Color(0xFF6B7280); // Gray
    }
  }

  // Helper method to get confidence icon
  IconData get confidenceIcon {
    switch (modelConfidence.toLowerCase()) {
      case 'high':
        return Icons.check_circle;
      case 'medium':
        return Icons.info;
      case 'low':
        return Icons.warning;
      default:
        return Icons.help;
    }
  }

  // Helper method to format R² score
  String get formattedR2 {
    return 'R² = ${modelR2.toStringAsFixed(3)}';
  }

  // Helper method to get model reliability description
  String get reliabilityDescription {
    if (modelR2 >= 0.9) {
      return 'Highly reliable';
    } else if (modelR2 >= 0.7) {
      return 'Moderately reliable';
    } else if (modelR2 >= 0.3) {
      return 'Limited reliability';
    } else {
      return 'Low reliability';
    }
  }
}

