import 'package:intl/intl.dart';
import '../constants/strings.dart';

class Helpers {
  static String formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return AppStrings.justNow;
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} ${AppStrings.minutesAgo}';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} ${AppStrings.hoursAgo}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ${AppStrings.daysAgo}';
    } else {
      return DateFormat('MMM dd, yyyy').format(timestamp);
    }
  }

  static String formatChartTimestamp(DateTime timestamp, String timeFilter) {
    switch (timeFilter.toLowerCase()) {
      case 'daily':
        return DateFormat('HH:mm').format(timestamp);
      case 'weekly':
      case 'monthly':
        return DateFormat('MMM dd').format(timestamp);
      case 'year':
        return DateFormat('MMM yyyy').format(timestamp);
      default:
        return DateFormat('MMM dd').format(timestamp);
    }
  }

  static String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return AppStrings.goodMorning;
    if (hour < 17) return AppStrings.goodAfternoon;
    return AppStrings.goodEvening;
  }

  static double calculatePercentageChange(double oldValue, double newValue) {
    if (oldValue == 0) return 0;
    return ((newValue - oldValue) / oldValue) * 100;
  }

  static String formatPercentageChange(double percentage) {
    final absPercentage = percentage.abs();
    final direction =
        percentage >= 0 ? AppStrings.increase : AppStrings.decrease;
    return '${absPercentage.toStringAsFixed(1)}% $direction';
  }

  static double calculateAverage(List<double> values) {
    if (values.isEmpty) return 0;
    return values.reduce((a, b) => a + b) / values.length;
  }

  static DateRange getDateRangeForFilter(String filter) {
    final now = DateTime.now();
    late DateTime startDate;

    switch (filter.toLowerCase()) {
      case 'daily':
        // Last 24 hours
        startDate = now.subtract(const Duration(hours: 24));
        break;
      case 'weekly':
        // Last 7 days
        startDate = now.subtract(const Duration(days: 7));
        break;
      case 'monthly':
        // Last 30 days
        startDate = now.subtract(const Duration(days: 30));
        break;
      case 'year':
        // Last 365 days
        startDate = now.subtract(const Duration(days: 365));
        break;
      case 'all':
      default:
        return DateRange(startDate: null, endDate: null);
    }

    return DateRange(startDate: startDate, endDate: now);
  }

  // Method to check if data is within expected range for a filter
  static bool isDataRecentEnoughForFilter(
      String filter, DateTime oldestDataDate) {
    final now = DateTime.now();
    final daysSinceOldest = now.difference(oldestDataDate).inDays;

    switch (filter.toLowerCase()) {
      case 'daily':
        return daysSinceOldest <= 1;
      case 'weekly':
        return daysSinceOldest <= 7;
      case 'monthly':
        return daysSinceOldest <= 30;
      case 'year':
        return daysSinceOldest <= 365;
      case 'all':
      default:
        return true; // 'All' always accepts any data
    }
  }

  // Method to suggest better filter based on available data
  static String suggestBetterFilter(DateTime oldestDataDate) {
    final now = DateTime.now();
    final daysSinceOldest = now.difference(oldestDataDate).inDays;

    if (daysSinceOldest <= 1) return 'Daily';
    if (daysSinceOldest <= 7) return 'Weekly';
    if (daysSinceOldest <= 30) return 'Monthly';
    if (daysSinceOldest <= 365) return 'Year';
    return 'All';
  }

  static bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  static String truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  static List<int> getChartColors() {
    return [
      0xFF2BAE66,
      0xFF8A63D2,
      0xFFF5A623,
      0xFFFF6F4E,
    ];
  }

  static double safeDivision(double numerator, double denominator) {
    return denominator != 0 ? numerator / denominator : 0;
  }

  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  static String getLocationDisplayName(String location) {
    switch (location.toLowerCase()) {
      case 'semarang':
        return 'Semarang';
      case 'malang':
        return 'Malang';
      default:
        return location.toUpperCase();
    }
  }
}

class DateRange {
  final DateTime? startDate;
  final DateTime? endDate; 

  DateRange({this.startDate, this.endDate});

  Duration? get duration {
    if (startDate == null || endDate == null) return null;
    return endDate!.difference(startDate!);
  }

  bool contains(DateTime date) {
    if (startDate != null && date.isBefore(startDate!)) return false;
    if (endDate != null && date.isAfter(endDate!)) return false;
    return true;
  }

  // Helper to check if this is an "all data" range
  bool get isAllData => startDate == null && endDate == null;

  // Helper to get a human readable description
  String get description {
    if (isAllData) return 'All available data';
    if (startDate == null)
      return 'Up to ${DateFormat('MMM dd, yyyy').format(endDate!)}';
    if (endDate == null)
      return 'From ${DateFormat('MMM dd, yyyy').format(startDate!)}';
    return '${DateFormat('MMM dd').format(startDate!)} - ${DateFormat('MMM dd, yyyy').format(endDate!)}';
  }
}
