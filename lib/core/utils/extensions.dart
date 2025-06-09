import 'package:flutter/material.dart';
import 'sensor_helpers.dart';

// DateTime Extensions
extension DateTimeExtensions on DateTime {
  // Check if date is today
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  // Check if date is yesterday
  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year &&
        month == yesterday.month &&
        day == yesterday.day;
  }

  // Get start of day
  DateTime get startOfDay {
    return DateTime(year, month, day);
  }

  // Get end of day
  DateTime get endOfDay {
    return DateTime(year, month, day, 23, 59, 59, 999);
  }

  // Add days safely
  DateTime addDays(int days) {
    return add(Duration(days: days));
  }

  // Time ago string
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(this);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${(difference.inDays / 7).floor()}w ago';
    }
  }
}

// String Extensions
extension StringExtensions on String {
  // Capitalize first letter
  String get capitalize {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  // Title case
  String get titleCase {
    return split(' ').map((word) => word.capitalize).join(' ');
  }

  // Check if string is email
  bool get isEmail {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(this);
  }

  // Remove extra whitespace
  String get trimmed {
    return replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}

// List Extensions
extension ListExtensions<T> on List<T> {
  // Safe get element at index
  T? safeGet(int index) {
    return (index >= 0 && index < length) ? this[index] : null;
  }

  // Get last element safely
  T? get safeLast {
    return isEmpty ? null : last;
  }

  // Get first element safely
  T? get safeFirst {
    return isEmpty ? null : first;
  }
}

// Double Extensions for sensor values
extension DoubleExtensions on double {
  // Round to specific decimal places
  double roundTo(int decimals) {
    return double.parse(toStringAsFixed(decimals));
  }

  // Check if value is in range
  bool isInRange(double min, double max) {
    return this >= min && this <= max;
  }

  // Get sensor status for this value
  SensorStatus getTemperatureStatus() =>
      SensorHelpers.getTemperatureStatus(this);
  SensorStatus getPHStatus() => SensorHelpers.getPHStatus(this);
  SensorStatus getDOStatus() => SensorHelpers.getDOStatus(this);
  SensorStatus getTurbidityStatus() => SensorHelpers.getTurbidityStatus(this);
}

// Color Extensions
extension ColorExtensions on Color {
  // Get lighter shade
  Color get lighter {
    final hsl = HSLColor.fromColor(this);
    return hsl.withLightness((hsl.lightness + 0.1).clamp(0.0, 1.0)).toColor();
  }

  // Get darker shade
  Color get darker {
    final hsl = HSLColor.fromColor(this);
    return hsl.withLightness((hsl.lightness - 0.1).clamp(0.0, 1.0)).toColor();
  }

  // Convert to hex string (using non-deprecated approach)
  String get hexString {
    final argb = toARGB32();
    return '#${argb.toRadixString(16).padLeft(8, '0').substring(2)}';
  }
}

// BuildContext Extensions
extension BuildContextExtensions on BuildContext {
  // Media query shortcuts
  Size get screenSize => MediaQuery.of(this).size;
  double get screenWidth => screenSize.width;
  double get screenHeight => screenSize.height;

  // Theme shortcuts
  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => theme.textTheme;
  ColorScheme get colorScheme => theme.colorScheme;

  // Navigation shortcuts
  void pop<T>([T? result]) => Navigator.of(this).pop(result);
  Future<T?> push<T>(Widget page) => Navigator.of(this).push<T>(
        MaterialPageRoute(builder: (_) => page),
      );

  // Responsive breakpoints
  bool get isMobile => screenWidth < 768;
  bool get isTablet => screenWidth >= 768 && screenWidth < 1024;
  bool get isDesktop => screenWidth >= 1024;

  // Safe area
  EdgeInsets get safeAreaPadding => MediaQuery.of(this).padding;
  double get statusBarHeight => MediaQuery.of(this).padding.top;
  double get bottomPadding => MediaQuery.of(this).padding.bottom;
}

// Widget Extensions
extension WidgetExtensions on Widget {
  // Add padding
  Widget withPadding(EdgeInsets padding) => Padding(
        padding: padding,
        child: this,
      );

  // Add margin (using Container)
  Widget withMargin(EdgeInsets margin) => Container(
        margin: margin,
        child: this,
      );

  // Make widget expanded
  Widget get expanded => Expanded(child: this);

  // Make widget flexible
  Widget get flexible => Flexible(child: this);

  // Center widget
  Widget get centered => Center(child: this);

  // Make widget clickable
  Widget onTap(VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: this,
      );
}
