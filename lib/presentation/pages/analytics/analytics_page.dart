//UNUSED, CHANGED TO enhanced_analytics_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/strings.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/helpers.dart';
import '../../../data/providers/water_quality_provider.dart';
import '../../../data/models/water_quality.dart';

class AnalyticsPage extends ConsumerStatefulWidget {
  const AnalyticsPage({super.key});

  DateRange _getExpandedDateRange(String filter) {
    final now = DateTime.now();
    DateTime? startDate;

    switch (filter.toLowerCase()) {
      case 'daily':
        // Look back 7 days instead of just 1 day
        startDate = now.subtract(const Duration(days: 7));
        break;
      case 'weekly':
        // Look back 30 days instead of 7 days
        startDate = now.subtract(const Duration(days: 30));
        break;
      case 'monthly':
        // Look back 90 days instead of 30 days
        startDate = now.subtract(const Duration(days: 90));
        break;
      case 'year':
        // Look back 2 years instead of 1 year
        startDate = now.subtract(const Duration(days: 730));
        break;
      default:
        // For any other filter, don't filter by date
        return DateRange(startDate: null, endDate: null);
    }

    return DateRange(startDate: startDate, endDate: now);
  }

  ConsumerState<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends ConsumerState<AnalyticsPage> {
  String _selectedTimeFilter = 'Daily'; // Changed from 'All' to 'Daily'
  bool _isLoading = false;
  List<WaterQuality> _currentData = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // Direct data loading without complex providers
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {

      final location = ref.read(currentLocationProvider);
      final repository = ref.read(waterQualityRepositoryProvider);

      // Get date range
      final dateRange = _selectedTimeFilter.toLowerCase() == 'all'
          ? DateRange(startDate: null, endDate: null)
          : _getExpandedDateRange(_selectedTimeFilter);

      // Load data directly from repository
      final data = await repository.getAnalyticsData(
        location: location,
        startDate: dateRange.startDate,
        endDate: dateRange.endDate,
        limit: AppConstants.maxChartDataPoints,
      );


      setState(() {
        _currentData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
        _currentData = [];
      });
    }
  }

  // Expanded date range to actually find June 4th data
  DateRange _getExpandedDateRange(String filter) {
    final now = DateTime.now();
    DateTime? startDate;

    switch (filter.toLowerCase()) {
      case 'daily':
        // Look back 7 days instead of just 1 day
        startDate = now.subtract(const Duration(days: 7));
        break;
      case 'weekly':
        // Look back 30 days instead of 7 days
        startDate = now.subtract(const Duration(days: 30));
        break;
      case 'monthly':
        // Look back 90 days instead of 30 days
        startDate = now.subtract(const Duration(days: 90));
        break;
      case 'year':
        // Look back 2 years instead of 1 year
        startDate = now.subtract(const Duration(days: 730));
        break;
      default:
        // For any other filter, don't filter by date
        return DateRange(startDate: null, endDate: null);
    }

    return DateRange(startDate: startDate, endDate: now);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          AppStrings.analytics,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Time Filter Chips
          Container(
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
                            if (selected && filter != _selectedTimeFilter) {
                              setState(() {
                                _selectedTimeFilter = filter;
                              });
                              _loadData(); // Reload data when filter changes
                            }
                          },
                          backgroundColor: AppColors.surfaceVariant,
                          selectedColor:
                              AppColors.primary.withValues(alpha: 0.2),
                          checkmarkColor: AppColors.primary,
                          labelStyle: TextStyle(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.textSecondary,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // Content Area
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Loading $_selectedTimeFilter data...',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Reading from local database...',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textTertiary,
                  ),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (_currentData.isEmpty) {
      return _buildNoDataState();
    }

    return _buildChartsGrid(_currentData);
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to Load Analytics',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Unknown error occurred',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoDataState() {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Column(
        children: [
          // Status Card
          Card(
            color: AppColors.warning.withValues(alpha: 0.1),
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppColors.warning,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'No Data for $_selectedTimeFilter',
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.warning,
                                  ),
                        ),
                        Text(
                          _getNoDataReason(),
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Action Buttons
          Row(
            children: [
              if (_selectedTimeFilter != 'Daily' &&
                  AppConstants.timeFilters.length > 1) ...[
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _selectedTimeFilter =
                            'Year'; // Use 'Year' as the broadest option
                      });
                      _loadData();
                    },
                    icon: const Icon(Icons.date_range),
                    label: const Text('Show More Data'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _loadData,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: BorderSide(color: AppColors.primary),
                  ),
                ),
              ),
            ],
          ),

          const Spacer(),

          // Helpful Info
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: AppColors.info,
                  size: 32,
                ),
                const SizedBox(height: 12),
                Text(
                  'Analytics Ready',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.info,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  _selectedTimeFilter == 'All'
                      ? 'No water quality data found in your local database. Make sure your IoT sensors are sending data and try syncing from the home page.'
                      : 'Try selecting "All" to see your available data, or check if your sensors have sent recent readings.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          const Spacer(),
        ],
      ),
    );
  }

  String _getNoDataReason() {
    switch (_selectedTimeFilter.toLowerCase()) {
      case 'daily':
        return 'No readings in the last 24 hours';
      case 'weekly':
        return 'No readings in the last 7 days';
      case 'monthly':
        return 'No readings in the last 30 days';
      case 'year':
        return 'No readings in the last 2 years';
      default:
        return 'No data available for selected period';
    }
  }

  Widget _buildChartsGrid(List<WaterQuality> data) {
    final location = ref.watch(currentLocationProvider);

    return Padding(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: SingleChildScrollView(
        child: Column(
          children: [
            // Success Card
            Card(
              color: AppColors.success.withValues(alpha: 0.1),
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.defaultPadding),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: AppColors.success,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Data Found!',
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.success,
                                ),
                          ),
                          Text(
                            '${data.length} readings • $_selectedTimeFilter • ${Helpers.getLocationDisplayName(location)}',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Charts - ready for future implementation
            _buildChartsPlaceholder(data.length),

            const SizedBox(height: 100), // Bottom padding
          ],
        ),
      ),
    );
  }

  Widget _buildChartsPlaceholder(int dataCount) {
    return Column(
      children: [
        // Temperature Chart
        _buildSimpleChartCard(
          title: AppStrings.temperature,
          color: AppColors.temperatureDark,
          icon: Icons.thermostat,
          dataCount: dataCount,
        ),

        const SizedBox(height: 16),

        // pH Chart
        _buildSimpleChartCard(
          title: AppStrings.ph,
          color: AppColors.phDark,
          icon: Icons.science,
          dataCount: dataCount,
        ),

        const SizedBox(height: 16),

        // DO and Turbidity Row
        Row(
          children: [
            Expanded(
              child: _buildSimpleChartCard(
                title: 'DO',
                color: AppColors.doDark,
                icon: Icons.air,
                dataCount: dataCount,
                isCompact: true,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildSimpleChartCard(
                title: 'Turbidity',
                color: AppColors.turbidityDark,
                icon: Icons.water,
                dataCount: dataCount,
                isCompact: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSimpleChartCard({
    required String title,
    required Color color,
    required IconData icon,
    required int dataCount,
    bool isCompact = false,
  }) {
    return Card(
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
                  child: Icon(
                    icon,
                    color: color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                      Text(
                        '$dataCount data points',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Ready',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Placeholder chart area
            Container(
              height: isCompact ? 80 : 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: color.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.timeline,
                      color: color.withValues(alpha: 0.7),
                      size: isCompact ? 24 : 32,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Chart Ready',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: color.withValues(alpha: 0.8),
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    if (!isCompact) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Phase 4: Syncfusion Charts',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textTertiary,
                              fontSize: 10,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
