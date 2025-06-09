import 'package:flutter/foundation.dart';

class AppLogger {
  static const bool _enableLogging = kDebugMode; // Only log in debug mode

  // Different log levels with emojis for easy identification
  static void info(String message, String tag) {
    if (_enableLogging) {
      print(
          'I/flutter: ${DateTime.now().toString().substring(11, 23)} ℹ️  INFO: [$tag] $message');
    }
  }

  static void warning(String message, String tag) {
    if (_enableLogging) {
      print(
          'I/flutter: ${DateTime.now().toString().substring(11, 23)} ⚠️  WARN: [$tag] $message');
    }
  }

  static void error(String message, String tag, [dynamic error]) {
    if (_enableLogging) {
      print(
          'I/flutter: ${DateTime.now().toString().substring(11, 23)} ❌ ERROR: [$tag] $message');
      if (error != null) {
        print(
            'I/flutter: ${DateTime.now().toString().substring(11, 23)} 📋 DETAILS: $error');
      }
    }
  }

  static void debug(String message, String tag) {
    if (_enableLogging) {
      print(
          'I/flutter: ${DateTime.now().toString().substring(11, 23)} 🐛 DEBUG: [$tag] $message');
    }
  }

  // Specific loggers for different modules
  static void firestore(String message) {
    debug(message, 'FIRESTORE');
  }

  static void hive(String message) {
    debug(message, 'HIVE');
  }

  static void auth(String message) {
    debug(message, 'AUTH');
  }

  static void network(String message) {
    debug(message, 'NETWORK');
  }

  static void sync(String message) {
    info(message, 'SYNC');
  }

  // Performance logging
  static void performance(String operation, Duration duration) {
    if (_enableLogging) {
      print(
          'I/flutter: ${DateTime.now().toString().substring(11, 23)} ⏱️  PERF: $operation took ${duration.inMilliseconds}ms');
    }
  }

  // Data flow logging
  static void dataFlow(String flow, int count) {
    if (_enableLogging) {
      print(
          'I/flutter: ${DateTime.now().toString().substring(11, 23)} 📊 DATA: $flow - $count items');
    }
  }
}
