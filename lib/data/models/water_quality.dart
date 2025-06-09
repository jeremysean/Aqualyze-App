import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import '../../core/utils/app_logger.dart';

part 'water_quality.g.dart';

@HiveType(typeId: 0)
class WaterQuality extends HiveObject {
  @HiveField(0)
  final String? id;

  @HiveField(1)
  final double ph;

  @HiveField(2)
  final double temperature;

  @HiveField(3)
  final double dissolvedOxygen;

  @HiveField(4)
  final double turbidity;

  @HiveField(5)
  final DateTime timestamp;

  @HiveField(6)
  final String? location; // For local storage location tracking

  WaterQuality({
    this.id,
    required this.ph,
    required this.temperature,
    required this.dissolvedOxygen,
    required this.turbidity,
    required this.timestamp,
    this.location,
  });

  // Enhanced factory constructor with flexible timestamp parsing
  factory WaterQuality.fromMap(Map<String, dynamic> map) {
    return WaterQuality(
      id: map['id'] as String?,
      ph: (map['ph'] as num).toDouble(),
      temperature: (map['temperature'] as num).toDouble(),
      dissolvedOxygen: (map['do'] as num).toDouble(), // Note: 'do' field name
      turbidity: (map['turbidity'] as num).toDouble(),
      timestamp: _parseTimestamp(map['timestamp']), // FIXED: Flexible parsing
      location: map['location'] as String?,
    );
  }

  // Helper method to parse timestamp from various formats
  static DateTime _parseTimestamp(dynamic timestampData) {
    if (timestampData == null) {
      AppLogger.warning(
          'Timestamp is null, using current time', 'WATER_QUALITY');
      return DateTime.now(); // Fallback to current time
    }

    // Handle Firestore Timestamp object
    if (timestampData is Timestamp) {
      return timestampData.toDate();
    }

    // Handle string timestamp (ISO 8601 format)
    if (timestampData is String) {
      try {
        return DateTime.parse(timestampData);
      } catch (e) {
        AppLogger.error('Error parsing timestamp string: $timestampData',
            'WATER_QUALITY', e);
        return DateTime.now(); // Fallback
      }
    }

    // Handle milliseconds since epoch (int)
    if (timestampData is int) {
      try {
        return DateTime.fromMillisecondsSinceEpoch(timestampData);
      } catch (e) {
        AppLogger.error(
            'Error parsing timestamp int: $timestampData', 'WATER_QUALITY', e);
        return DateTime.now(); // Fallback
      }
    }

    // Handle Map (Firestore sometimes returns timestamp as map)
    if (timestampData is Map) {
      try {
        // Check for _seconds and _nanoseconds fields (Firestore format)
        if (timestampData.containsKey('_seconds')) {
          final seconds = timestampData['_seconds'] as int;
          final nanoseconds = (timestampData['_nanoseconds'] as int?) ?? 0;
          return DateTime.fromMillisecondsSinceEpoch(
              seconds * 1000 + (nanoseconds / 1000000).round());
        }

        // Check for seconds and nanoseconds fields
        if (timestampData.containsKey('seconds')) {
          final seconds = timestampData['seconds'] as int;
          final nanoseconds = (timestampData['nanoseconds'] as int?) ?? 0;
          return DateTime.fromMillisecondsSinceEpoch(
              seconds * 1000 + (nanoseconds / 1000000).round());
        }
      } catch (e) {
        AppLogger.error(
            'Error parsing timestamp map: $timestampData', 'WATER_QUALITY', e);
      }
    }

    AppLogger.warning(
        'Unknown timestamp format: $timestampData (${timestampData.runtimeType})',
        'WATER_QUALITY');
    return DateTime.now(); // Ultimate fallback
  }

  // Convert to map for Firestore
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'ph': ph,
      'temperature': temperature,
      'do': dissolvedOxygen, // Note: 'do' field name for Firestore
      'turbidity': turbidity,
      'timestamp': Timestamp.fromDate(timestamp),
      if (location != null) 'location': location,
    };
  }

  // Copy with method for updates
  WaterQuality copyWith({
    String? id,
    double? ph,
    double? temperature,
    double? dissolvedOxygen,
    double? turbidity,
    DateTime? timestamp,
    String? location,
  }) {
    return WaterQuality(
      id: id ?? this.id,
      ph: ph ?? this.ph,
      temperature: temperature ?? this.temperature,
      dissolvedOxygen: dissolvedOxygen ?? this.dissolvedOxygen,
      turbidity: turbidity ?? this.turbidity,
      timestamp: timestamp ?? this.timestamp,
      location: location ?? this.location,
    );
  }

  @override
  String toString() {
    return 'WaterQuality(id: $id, ph: $ph, temperature: $temperature, '
        'dissolvedOxygen: $dissolvedOxygen, turbidity: $turbidity, '
        'timestamp: $timestamp, location: $location)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WaterQuality &&
        other.id == id &&
        other.ph == ph &&
        other.temperature == temperature &&
        other.dissolvedOxygen == dissolvedOxygen &&
        other.turbidity == turbidity &&
        other.timestamp == timestamp &&
        other.location == location;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      ph,
      temperature,
      dissolvedOxygen,
      turbidity,
      timestamp,
      location,
    );
  }
}
