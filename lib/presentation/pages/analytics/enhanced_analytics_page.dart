import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/strings.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/helpers.dart';
import '../../../core/utils/sensor_helpers.dart';
import '../../../data/models/water_quality.dart';
import '../../../data/providers/water_quality_provider.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/common/error_widget.dart';

class EnhancedAnalyticsPage extends ConsumerStatefulWidget {
  const EnhancedAnalyticsPage({super.key});

  @override
  ConsumerState<EnhancedAnalyticsPage> createState() =>
      _EnhancedAnalyticsPageState();
}

class _EnhancedAnalyticsPageState extends ConsumerState<EnhancedAnalyticsPage>
    with TickerProviderStateMixin {
  String _selectedTimeFilter = AppConstants.timeFilters[1]; // Weekly
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final location = ref.watch(currentLocationProvider);
    final dateRange = Helpers.getDateRangeForFilter(_selectedTimeFilter);

    final analyticsData = ref.watch(analyticsDataProvider(AnalyticsParams(
      location: location,
      startDate: dateRange.startDate,
      endDate: dateRange.endDate,
      limit: AppConstants.maxChartDataPoints,
    )));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(AppStrings.analytics),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withValues(alpha: 0.7),
          tabs: const [
            Tab(icon: Icon(Icons.thermostat), text: 'Temp'),
            Tab(icon: Icon(Icons.science), text: 'pH'),
            Tab(icon: Icon(Icons.air), text: 'DO'),
            Tab(icon: Icon(Icons.water), text: 'Turbidity'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Time Filter Section
          _buildTimeFilterSection(),

          // Charts Section
          Expanded(
            child: analyticsData.when(
              data: (data) => TabBarView(
                controller: _tabController,
                children: [
                  _buildTemperatureChart(data),
                  _buildPHChart(data),
                  _buildDOChart(data),
                  _buildTurbidityChart(data),
                ],
              ),
              loading: () =>
                  const LoadingWidget(message: 'Loading analytics...'),
              error: (error, stack) => CustomErrorWidget(
                message: 'Failed to load analytics data: $error',
                onRetry: () =>
                    ref.refresh(analyticsDataProvider(AnalyticsParams(
                  location: location,
                  startDate: dateRange.startDate,
                  endDate: dateRange.endDate,
                ))),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeFilterSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      color: AppColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Time Range',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: AppConstants.timeFilters.map((filter) {
                final isSelected = filter == _selectedTimeFilter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(filter),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedTimeFilter = filter;
                        });
                      }
                    },
                    backgroundColor: AppColors.surfaceVariant,
                    selectedColor: AppColors.primary.withValues(alpha: 0.2),
                    checkmarkColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textSecondary,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemperatureChart(List<WaterQuality> data) {
    return _buildSensorChart(
      data: data,
      title: AppStrings.temperature,
      getValue: (reading) => reading.temperature,
      unit: AppStrings.celsiusUnit,
      color: AppColors.temperatureDark,
      icon: Icons.thermostat,
      optimalMin: AppConstants.temperatureMin,
      optimalMax: AppConstants.temperatureMax,
      getStatus: (value) => SensorHelpers.getTemperatureStatus(value),
    );
  }

  Widget _buildPHChart(List<WaterQuality> data) {
    return _buildSensorChart(
      data: data,
      title: AppStrings.ph,
      getValue: (reading) => reading.ph,
      unit: AppStrings.phUnit,
      color: AppColors.phDark,
      icon: Icons.science,
      optimalMin: AppConstants.phMin,
      optimalMax: AppConstants.phMax,
      getStatus: (value) => SensorHelpers.getPHStatus(value),
    );
  }

  Widget _buildDOChart(List<WaterQuality> data) {
    return _buildSensorChart(
      data: data,
      title: AppStrings.dissolvedOxygen,
      getValue: (reading) => reading.dissolvedOxygen,
      unit: AppStrings.doUnit,
      color: AppColors.doDark,
      icon: Icons.air,
      optimalMin: AppConstants.doMin,
      optimalMax: null, // No upper limit for DO
      getStatus: (value) => SensorHelpers.getDOStatus(value),
    );
  }

  Widget _buildTurbidityChart(List<WaterQuality> data) {
    return _buildSensorChart(
      data: data,
      title: AppStrings.turbidity,
      getValue: (reading) => reading.turbidity,
      unit: AppStrings.turbidityUnit,
      color: AppColors.turbidityDark,
      icon: Icons.water,
      optimalMin: AppConstants.turbidityMin,
      optimalMax: AppConstants.turbidityMax,
      getStatus: (value) => SensorHelpers.getTurbidityStatus(value),
    );
  }

  Widget _buildSensorChart({
    required List<WaterQuality> data,
    required String title,
    required double Function(WaterQuality) getValue,
    required String unit,
    required Color color,
    required IconData icon,
    required double optimalMin,
    required double? optimalMax,
    required SensorStatus Function(double) getStatus,
  }) {
    if (data.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.show_chart,
              size: 64,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: 16),
            Text(
              'No data available for selected time range',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ),
      );
    }

    // Calculate statistics
    final values = data.map(getValue).toList();
    final average = Helpers.calculateAverage(values);
    final latest = values.isNotEmpty ? values.first : 0.0;
    final previous = values.length > 1 ? values[1] : latest;
    final change = Helpers.calculatePercentageChange(previous, latest);
    final status = getStatus(latest);

    // Prepare chart data
    final chartData = data.reversed.map((reading) {
      return ChartData(
        x: reading.timestamp,
        y: getValue(reading),
        status: getStatus(getValue(reading)),
      );
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Statistics Card
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(icon, color: color, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            Text(
                              SensorHelpers.getStatusText(status),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: _getStatusColor(status),
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Current Value & Statistics
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Current',
                          '${latest.toStringAsFixed(1)}$unit',
                          color,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          'Average',
                          '${average.toStringAsFixed(1)}$unit',
                          AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          'Change',
                          Helpers.formatPercentageChange(change),
                          change >= 0 ? AppColors.success : AppColors.error,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Chart Card
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Trend Over Time',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 300,
                    child: SfCartesianChart(
                      primaryXAxis: DateTimeAxis(
                        majorGridLines: const MajorGridLines(width: 0),
                        labelStyle: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 10,
                        ),
                      ),
                      primaryYAxis: NumericAxis(
                        majorGridLines: MajorGridLines(
                          width: 1,
                          color: AppColors.surfaceVariant,
                        ),
                        labelStyle: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 10,
                        ),
                        plotBands: _buildPlotBands(optimalMin, optimalMax),
                      ),
                      plotAreaBorderWidth: 0,
                      tooltipBehavior: TooltipBehavior(
                        enable: true,
                        header: title,
                        format: 'point.x : point.y$unit',
                      ),
                      zoomPanBehavior: ZoomPanBehavior(
                        enablePinching: true,
                        enablePanning: true,
                        zoomMode: ZoomMode.x,
                      ),
                      series: <CartesianSeries>[
                        // Main line series
                        LineSeries<ChartData, DateTime>(
                          dataSource: chartData,
                          xValueMapper: (ChartData data, _) => data.x,
                          yValueMapper: (ChartData data, _) => data.y,
                          color: color,
                          width: 2,
                          markerSettings: MarkerSettings(
                            isVisible: true,
                            color: color,
                            borderColor: Colors.white,
                            borderWidth: 2,
                            shape: DataMarkerType.circle,
                            height: 6,
                            width: 6,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<PlotBand> _buildPlotBands(double optimalMin, double? optimalMax) {
    final bands = <PlotBand>[];

    // Optimal range band
    if (optimalMax != null) {
      bands.add(PlotBand(
        start: optimalMin,
        end: optimalMax,
        color: AppColors.success.withValues(alpha: 0.1),
        borderColor: AppColors.success.withValues(alpha: 0.3),
        borderWidth: 1,
      ));
    }

    return bands;
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
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
}

class ChartData {
  final DateTime x;
  final double y;
  final SensorStatus status;

  ChartData({required this.x, required this.y, required this.status});
}
