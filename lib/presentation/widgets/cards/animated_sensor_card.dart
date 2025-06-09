import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/colors.dart';
import '../../../core/utils/helpers.dart';
import '../../../core/utils/sensor_helpers.dart';

class AnimatedSensorCard extends StatefulWidget {
  final String title;
  final double value;
  final String unit;
  final IconData icon;
  final Color color;
  final DateTime timestamp;
  final VoidCallback? onTap;
  final int animationDelay;

  const AnimatedSensorCard({
    super.key,
    required this.title,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
    required this.timestamp,
    this.onTap,
    this.animationDelay = 0,
  });

  @override
  State<AnimatedSensorCard> createState() => _AnimatedSensorCardState();
}

class _AnimatedSensorCardState extends State<AnimatedSensorCard>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _pulseController;
  late AnimationController _valueController;

  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _valueAnimation;

  double _displayValue = 0.0;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startAnimations();
  }

  void _setupAnimations() {
    _slideController = AnimationController(
      duration: Duration(milliseconds: 300 + widget.animationDelay),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 4000),
      vsync: this,
    );

    _valueController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _valueAnimation = Tween<double>(
      begin: 0.0,
      end: widget.value,
    ).animate(CurvedAnimation(
      parent: _valueController,
      curve: Curves.easeOut,
    ));

    _valueAnimation.addListener(() {
      if (mounted) {
        setState(() {
          _displayValue = _valueAnimation.value;
        });
      }
    });
  }

  void _startAnimations() {
    Future.delayed(Duration(milliseconds: widget.animationDelay), () {
      if (mounted) {
        _slideController.forward();
        _valueController.forward();

        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) {
            _pulseController.repeat(reverse: true);
          }
        });
      }
    });
  }

  @override
  void didUpdateWidget(AnimatedSensorCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _updateValue();
    }
  }

  void _updateValue() {
    if (!mounted) return;

    _valueController.reset();
    _valueAnimation = Tween<double>(
      begin: _displayValue,
      end: widget.value,
    ).animate(CurvedAnimation(
      parent: _valueController,
      curve: Curves.easeOut,
    ));
    _valueController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _pulseController.dispose();
    _valueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final status = _getSensorStatus();
    final statusColor = _getStatusColor(status);

    return RepaintBoundary(
      child: SlideTransition(
        position: _slideAnimation,
        child: Card(
          elevation: 3,
          shadowColor: AppColors.shadowColor,
          child: InkWell(
            onTap: widget.onTap != null
                ? () {
                    HapticFeedback.lightImpact();
                    widget.onTap!();
                  }
                : null,
            borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
            child: Container(
              decoration: BoxDecoration(
                borderRadius:
                    BorderRadius.circular(AppConstants.cardBorderRadius),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.surface,
                    widget.color.withValues(alpha: 0.03),
                  ],
                ),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.all(12.0), // FIXED: Increased from 6.0
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header with icon and animated status
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8), // FIXED: Increased
                          decoration: BoxDecoration(
                            color: widget.color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            widget.icon,
                            color: widget.color,
                            size: 20, // FIXED: Increased from 16
                          ),
                        ),
                        const Spacer(),
                        AnimatedBuilder(
                          animation: _scaleAnimation,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _scaleAnimation.value,
                              child: Container(
                                width: 8, // FIXED: Increased from 6
                                height: 8,
                                decoration: BoxDecoration(
                                  color: statusColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 8), // FIXED: Increased from 4

                    // Sensor name - FIXED: Better text size
                    Text(
                      widget.title,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                            fontSize: 12, // FIXED: Increased from 10
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 4),

                    // FIXED: Better value display with larger text
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '${_displayValue.toStringAsFixed(_getDecimalPlaces())}${widget.unit}',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                            // FIXED: Changed from titleMedium
                            color: widget.color,
                            fontWeight: FontWeight.bold,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 6), // FIXED: Increased spacing

                    // FIXED: Better status display
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6, // FIXED: Increased
                        vertical: 3, // FIXED: Increased
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        SensorHelpers.getStatusText(status),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: statusColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 10, // FIXED: Increased from 8
                            ),
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),

                    const SizedBox(height: 4),

                    // Timestamp - FIXED: Better size
                    Text(
                      Helpers.formatTimestamp(widget.timestamp),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textTertiary,
                            fontSize: 9, // FIXED: Increased from 7
                          ),
                      textAlign: TextAlign.start, // FIXED: Changed from center
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 6), // FIXED: Increased

                    // Progress indicator
                    _buildMinimalProgress(status),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  SensorStatus _getSensorStatus() {
    switch (widget.title.toLowerCase()) {
      case 'temperature':
        return SensorHelpers.getTemperatureStatus(widget.value);
      case 'ph level':
      case 'ph':
        return SensorHelpers.getPHStatus(widget.value);
      case 'dissolved oxygen':
        return SensorHelpers.getDOStatus(widget.value);
      case 'turbidity':
        return SensorHelpers.getTurbidityStatus(widget.value);
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
    switch (widget.title.toLowerCase()) {
      case 'ph level':
      case 'ph':
        return 2;
      default:
        return 1;
    }
  }

  Widget _buildMinimalProgress(SensorStatus status) {
    final progress = _getStatusProgress(status) / 4.0;

    return Container(
      height: 3, // FIXED: Increased from 2
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(2),
        color: AppColors.surfaceVariant,
      ),
      child: AnimatedBuilder(
        animation: _slideController,
        builder: (context, child) {
          return LinearProgressIndicator(
            value: progress * _slideController.value,
            backgroundColor: Colors.transparent,
            valueColor: AlwaysStoppedAnimation<Color>(_getStatusColor(status)),
            borderRadius: BorderRadius.circular(2),
          );
        },
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
