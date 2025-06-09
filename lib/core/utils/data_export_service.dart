import 'dart:convert';
import 'package:intl/intl.dart';
import '../constants/strings.dart';
import '../../data/models/water_quality.dart';

class DataExportService {
  static final DataExportService _instance = DataExportService._internal();
  factory DataExportService() => _instance;
  DataExportService._internal();

  // Export data to CSV format
  String exportToCSV(List<WaterQuality> data, String location) {
    if (data.isEmpty) return '';

    final buffer = StringBuffer();

    // Add header with metadata
    buffer.writeln('# Water Quality Data Export');
    buffer.writeln('# Location: $location');
    buffer.writeln(
        '# Export Date: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())}');
    buffer.writeln('# Total Records: ${data.length}');
    buffer.writeln('');

    // Add CSV headers
    buffer.writeln(
        'Timestamp,Temperature (°C),pH,Dissolved Oxygen (mg/L),Turbidity (NTU),Location');

    // Add data rows
    for (final reading in data) {
      final timestamp =
          DateFormat('yyyy-MM-dd HH:mm:ss').format(reading.timestamp);
      buffer.writeln(
          '$timestamp,${reading.temperature},${reading.ph},${reading.dissolvedOxygen},${reading.turbidity},${reading.location ?? location}');
    }

    return buffer.toString();
  }

  // Export data to JSON format
  String exportToJSON(List<WaterQuality> data, String location) {
    final export = {
      'metadata': {
        'location': location,
        'exportDate': DateTime.now().toIso8601String(),
        'totalRecords': data.length,
        'format': 'JSON',
        'version': '1.0',
      },
      'data': data
          .map((reading) => {
                'timestamp': reading.timestamp.toIso8601String(),
                'temperature': reading.temperature,
                'ph': reading.ph,
                'dissolvedOxygen': reading.dissolvedOxygen,
                'turbidity': reading.turbidity,
                'location': reading.location ?? location,
              })
          .toList(),
    };

    return const JsonEncoder.withIndent('  ').convert(export);
  }

  // Generate summary report
  String generateSummaryReport(List<WaterQuality> data, String location) {
    if (data.isEmpty) return 'No data available for report generation.';

    final buffer = StringBuffer();

    // Calculate statistics
    final temperatures = data.map((r) => r.temperature).toList();
    final phValues = data.map((r) => r.ph).toList();
    final doValues = data.map((r) => r.dissolvedOxygen).toList();
    final turbidityValues = data.map((r) => r.turbidity).toList();

    final avgTemp = _calculateAverage(temperatures);
    final avgPH = _calculateAverage(phValues);
    final avgDO = _calculateAverage(doValues);
    final avgTurbidity = _calculateAverage(turbidityValues);

    final minTemp = temperatures.reduce((a, b) => a < b ? a : b);
    final maxTemp = temperatures.reduce((a, b) => a > b ? a : b);
    final minPH = phValues.reduce((a, b) => a < b ? a : b);
    final maxPH = phValues.reduce((a, b) => a > b ? a : b);
    final minDO = doValues.reduce((a, b) => a < b ? a : b);
    final maxDO = doValues.reduce((a, b) => a > b ? a : b);
    final minTurbidity = turbidityValues.reduce((a, b) => a < b ? a : b);
    final maxTurbidity = turbidityValues.reduce((a, b) => a > b ? a : b);

    // Report header
    buffer.writeln('WATER QUALITY SUMMARY REPORT');
    buffer.writeln('=' * 50);
    buffer.writeln('Location: $location');
    buffer.writeln(
        'Report Date: ${DateFormat('MMMM dd, yyyy').format(DateTime.now())}');
    buffer.writeln(
        'Data Period: ${DateFormat('MMM dd, yyyy').format(data.last.timestamp)} - ${DateFormat('MMM dd, yyyy').format(data.first.timestamp)}');
    buffer.writeln('Total Measurements: ${data.length}');
    buffer.writeln('');

    // Temperature section
    buffer.writeln('TEMPERATURE ANALYSIS');
    buffer.writeln('-' * 20);
    buffer.writeln('Average: ${avgTemp.toStringAsFixed(1)}°C');
    buffer.writeln(
        'Range: ${minTemp.toStringAsFixed(1)}°C - ${maxTemp.toStringAsFixed(1)}°C');
    buffer.writeln('Optimal Range: 26.0°C - 31.0°C');
    buffer.writeln('Status: ${_getTemperatureStatus(avgTemp)}');
    buffer.writeln('');

    // pH section
    buffer.writeln('pH ANALYSIS');
    buffer.writeln('-' * 12);
    buffer.writeln('Average: ${avgPH.toStringAsFixed(2)}');
    buffer.writeln(
        'Range: ${minPH.toStringAsFixed(2)} - ${maxPH.toStringAsFixed(2)}');
    buffer.writeln('Optimal Range: 6.5 - 7.5');
    buffer.writeln('Status: ${_getPHStatus(avgPH)}');
    buffer.writeln('');

    // Dissolved Oxygen section
    buffer.writeln('DISSOLVED OXYGEN ANALYSIS');
    buffer.writeln('-' * 25);
    buffer.writeln('Average: ${avgDO.toStringAsFixed(1)} mg/L');
    buffer.writeln(
        'Range: ${minDO.toStringAsFixed(1)} mg/L - ${maxDO.toStringAsFixed(1)} mg/L');
    buffer.writeln('Minimum Required: 4.0 mg/L');
    buffer.writeln('Status: ${_getDOStatus(avgDO)}');
    buffer.writeln('');

    // Turbidity section
    buffer.writeln('TURBIDITY ANALYSIS');
    buffer.writeln('-' * 18);
    buffer.writeln('Average: ${avgTurbidity.toStringAsFixed(1)} NTU');
    buffer.writeln(
        'Range: ${minTurbidity.toStringAsFixed(1)} NTU - ${maxTurbidity.toStringAsFixed(1)} NTU');
    buffer.writeln('Optimal Range: 3.1 - 4.2 NTU');
    buffer.writeln('Status: ${_getTurbidityStatus(avgTurbidity)}');
    buffer.writeln('');

    // Overall assessment
    buffer.writeln('OVERALL ASSESSMENT');
    buffer.writeln('-' * 18);
    final overallStatus =
        _getOverallStatus(avgTemp, avgPH, avgDO, avgTurbidity);
    buffer.writeln('Overall Water Quality: $overallStatus');
    buffer.writeln('');

    // Recommendations
    buffer.writeln('RECOMMENDATIONS');
    buffer.writeln('-' * 15);
    final recommendations =
        _generateRecommendations(avgTemp, avgPH, avgDO, avgTurbidity);
    for (final recommendation in recommendations) {
      buffer.writeln('• $recommendation');
    }
    buffer.writeln('');

    buffer.writeln('Report generated by ${AppStrings.appName}');
    buffer.writeln(
        'For more detailed analysis, please consult with aquaculture experts.');

    return buffer.toString();
  }

  double _calculateAverage(List<double> values) {
    if (values.isEmpty) return 0;
    return values.reduce((a, b) => a + b) / values.length;
  }

  String _getTemperatureStatus(double temp) {
    if (temp >= 26.0 && temp <= 31.0) return 'EXCELLENT';
    if (temp >= 24.0 && temp <= 33.0) return 'GOOD';
    if (temp >= 22.0 && temp <= 34.0) return 'WARNING';
    return 'CRITICAL';
  }

  String _getPHStatus(double ph) {
    if (ph >= 6.5 && ph <= 7.5) return 'EXCELLENT';
    if (ph >= 6.0 && ph <= 8.0) return 'GOOD';
    if (ph >= 5.5 && ph <= 8.5) return 'WARNING';
    return 'CRITICAL';
  }

  String _getDOStatus(double dissolvedOxygen) {
    if (dissolvedOxygen >= 4.0) return 'EXCELLENT';
    if (dissolvedOxygen >= 3.0) return 'GOOD';
    if (dissolvedOxygen >= 2.0) return 'WARNING';
    return 'CRITICAL';
  }

  String _getTurbidityStatus(double turbidity) {
    if (turbidity >= 3.1 && turbidity <= 4.2) return 'EXCELLENT';
    if (turbidity >= 2.5 && turbidity <= 5.0) return 'GOOD';
    if (turbidity >= 1.5 && turbidity <= 10.0) return 'WARNING';
    return 'CRITICAL';
  }

  String _getOverallStatus(
      double temp, double ph, double dissolvedOxygen, double turbidity) {
    final tempStatus = _getTemperatureStatus(temp);
    final phStatus = _getPHStatus(ph);
    final doStatus = _getDOStatus(dissolvedOxygen);
    final turbidityStatus = _getTurbidityStatus(turbidity);

    final statuses = [tempStatus, phStatus, doStatus, turbidityStatus];

    if (statuses.any((s) => s == 'CRITICAL')){
      return 'CRITICAL - Immediate Action Required';
    }
      
    if (statuses.any((s) => s == 'WARNING')) {
      return 'WARNING - Monitor Closely';
    }
    if (statuses.every((s) => s == 'EXCELLENT')){
      return 'EXCELLENT - Optimal Conditions';
    }
      return 'GOOD - Acceptable Conditions';
  }

  List<String> _generateRecommendations(
      double temp, double ph, double dissolvedOxygen, double turbidity) {
    final recommendations = <String>[];

    // Temperature recommendations
    if (temp < 26.0) {
      recommendations.add(
          'Consider increasing water temperature to optimal range (26-31°C)');
    } else if (temp > 31.0) {
      recommendations
          .add('Water temperature is high - consider cooling methods');
    }

    // pH recommendations
    if (ph < 6.5) {
      recommendations
          .add('pH is acidic - consider adding lime or buffering agents');
    } else if (ph > 7.5) {
      recommendations.add('pH is alkaline - monitor and adjust if necessary');
    }

    // Dissolved oxygen recommendations
    if (dissolvedOxygen < 4.0) {
      recommendations.add(
          'Low dissolved oxygen - increase aeration or reduce stocking density');
    }

    // Turbidity recommendations
    if (turbidity < 3.1) {
      recommendations.add(
          'Low turbidity - water may be too clear, consider phytoplankton management');
    } else if (turbidity > 4.2) {
      recommendations.add(
          'High turbidity - check for excessive organic matter or algae growth');
    }

    if (recommendations.isEmpty) {
      recommendations.add(
          'All parameters are within optimal ranges - maintain current practices');
    }

    recommendations.add('Conduct regular water quality monitoring');
    recommendations.add('Keep detailed records for trend analysis');

    return recommendations;
  }

  // Generate filename for export
  String generateFilename(String location, String format, {String? dateRange}) {
    final now = DateTime.now();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(now);
    final locationFormatted = location.toLowerCase().replaceAll(' ', '_');

    String filename = 'water_quality_${locationFormatted}_$timestamp';

    if (dateRange != null) {
      filename += '_$dateRange';
    }

    switch (format.toLowerCase()) {
      case 'csv':
        return '$filename.csv';
      case 'json':
        return '$filename.json';
      case 'report':
        return '${filename}_report.txt';
      default:
        return '$filename.txt';
    }
  }
}
