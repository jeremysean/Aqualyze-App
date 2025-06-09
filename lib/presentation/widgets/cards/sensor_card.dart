import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/colors.dart';
import '../../../core/utils/helpers.dart';
import '../../../core/utils/sensor_helpers.dart';

class SensorCard extends StatelessWidget {
  final String title;
  final double value;
  final String unit;
  final IconData icon;
  final Color color;
  final DateTime timestamp;
  final VoidCallback? onTap;

  const SensorCard({
    super.key,
    required this.title,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
    required this.timestamp,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final status = _getSensorStatus();
    final statusColor = _getStatusColor(status);

    return Card(
      elevation: 2,
      shadowColor: AppColors.shadowColor,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with icon and status
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      icon,
                      color: color,
                      size: 20,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Sensor name
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 4),

              // Value and unit
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: value.toStringAsFixed(_getDecimalPlaces()),
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                    if (unit.isNotEmpty)
                      TextSpan(
                        text: ' $unit',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                  ],
                ),
              ),

              const Spacer(),

              // Timestamp
              Text(
                Helpers.formatTimestamp(timestamp),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textTertiary,
                    ),
              ),

              // Mini visualization (optional)
              const SizedBox(height: 8),
              _buildMiniVisualization(status),
            ],
          ),
        ),
      ),
    );
  }

  SensorStatus _getSensorStatus() {
    switch (title.toLowerCase()) {
      case 'temperature':
        return SensorHelpers.getTemperatureStatus(value);
      case 'ph level':
      case 'ph':
        return SensorHelpers.getPHStatus(value);
      case 'dissolved oxygen':
        return SensorHelpers.getDOStatus(value);
      case 'turbidity':
        return SensorHelpers.getTurbidityStatus(value);
      default:
        return SensorStatus.good;
    }
  }

  Color _getStatusColor(SensorStatus status) {
    switch (status) {
      case SensorStatus.excellent:
        return AppColors.success;
      case SensorStatus.good:
        return AppColors.info;
      case SensorStatus.warning:
        return AppColors.warning;
      case SensorStatus.critical:
        return AppColors.error;
    }
  }

  int _getDecimalPlaces() {
    switch (title.toLowerCase()) {
      case 'ph level':
      case 'ph':
        return 2;
      default:
        return 1;
    }
  }

  Widget _buildMiniVisualization(SensorStatus status) {
    return Container(
      height: 4,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(2),
        color: AppColors.surfaceVariant,
      ),
      child: Row(
        children: [
          Expanded(
            flex: _getStatusProgress(status),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: _getStatusColor(status),
              ),
            ),
          ),
          Expanded(
            flex: 4 - _getStatusProgress(status),
            child: const SizedBox(),
          ),
        ],
      ),
    );
  }

  int _getStatusProgress(SensorStatus status) {
    switch (status) {
      case SensorStatus.excellent:
        return 4;
      case SensorStatus.good:
        return 3;
      case SensorStatus.warning:
        return 2;
      case SensorStatus.critical:
        return 1;
    }
  }
}
