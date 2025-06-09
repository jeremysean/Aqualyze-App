import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/strings.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/helpers.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/water_quality_provider.dart';
import '../../../data/providers/connectivity_provider.dart';
import '../../../data/providers/prediction_provider.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/common/error_widget.dart';
import '../../widgets/cards/animated_sensor_card.dart';
import '../../widgets/cards/clean_prediction_card.dart'; 
import '../auth/login_page.dart';
import '../analytics/enhanced_analytics_page.dart';
import '../profile/profile_page.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  int _currentIndex = 0;
  final GlobalKey<RefreshIndicatorState> _refreshKey =
      GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    super.initState();
    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
      // Trigger auto prediction when data is available
      ref.read(autoPredictionProvider);
    });
  }

  void _loadData() {
    final location = ref.read(currentLocationProvider);
    ref.read(waterQualityControllerProvider.notifier).loadData(location);
  }

  Future<void> _onRefresh() async {
    final location = ref.read(currentLocationProvider);
    await ref
        .read(waterQualityControllerProvider.notifier)
        .refreshData(location);
  }

  void _onBottomNavTap(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isConnected = ref.watch(isConnectedProvider);

    // Listen to auth state changes
    ref.listen<AsyncValue<User?>>(authStateProvider, (previous, next) {
      next.whenData((user) {
        if (user == null) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const LoginPage()),
          );
        }
      });
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Offline Warning Banner
          if (!isConnected)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.defaultPadding,
                vertical: AppConstants.smallPadding,
              ),
              color: AppColors.offlineBackground,
              child: SafeArea(
                bottom: false,
                child: Row(
                  children: [
                    Icon(
                      Icons.wifi_off,
                      color: AppColors.offlineText,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        AppStrings.offlineWarning,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.offlineText,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Main Content
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: [
                _buildHomePage(),
                const EnhancedAnalyticsPage(),
                const ProfilePage(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onBottomNavTap,
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        elevation: 8,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: AppStrings.home,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: AppStrings.analytics,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: AppStrings.profile,
          ),
        ],
      ),
    );
  }

  Widget _buildHomePage() {
    final waterQualityState = ref.watch(waterQualityControllerProvider);
    // FIXED: Watch both providers to ensure UI updates when location changes
    final location = ref.watch(currentLocationProvider);
    final user = ref.watch(
        localUserProvider); // Also watch user to catch preference changes

    return RefreshIndicator(
      key: _refreshKey,
      onRefresh: _onRefresh,
      color: AppColors.primary,
      child: CustomScrollView(
        slivers: [
          // App Bar with reduced height
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            backgroundColor: AppColors.primary,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: AppColors.primaryGradient,
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(AppConstants.defaultPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Greeting and My Crab House with location toggle in same row
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    Helpers.getGreeting(),
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.copyWith(
                                          color: Colors.white
                                              .withValues(alpha: 0.9),
                                        ),
                                  ),
                                  Text(
                                    AppStrings.myCrabHouse,
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            // FIXED: Location Toggle Button - force rebuild on location change
                            _buildLocationToggle(
                                location, user?.locationPreference),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // FIXED: Much tighter spacing - reduced from 8 to 4
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppConstants.defaultPadding,
              4, // FIXED: Reduced from 8 to 4
              AppConstants.defaultPadding,
              AppConstants.defaultPadding,
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Overall Condition Card
                _buildOverallConditionCard(waterQualityState),

                const SizedBox(height: 4), // FIXED: Reduced from 8 to 4

                // CHANGED: Use clean prediction card (no debug)
                const CleanPredictionCard(),

                const SizedBox(height: 4), // FIXED: Reduced from 8 to 4

                // Sensor Cards Grid
                _buildSensorGrid(waterQualityState),

                const SizedBox(height: 16), // FIXED: Reduced from 24 to 16
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // FIXED: Location Toggle with proper state management and force rebuild
  Widget _buildLocationToggle(String currentLocation, String? userPreference) {
    // FIXED: Use the actual user preference as the source of truth
    final displayLocation = userPreference ?? currentLocation;

    return PopupMenuButton<String>(
      key: ValueKey(
          displayLocation), // FIXED: Force rebuild when location changes
      onSelected: (String newLocation) async {
        if (newLocation != displayLocation) {
          try {
            // Show loading state
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                        'Switching to ${Helpers.getLocationDisplayName(newLocation)}...'),
                  ],
                ),
                backgroundColor: AppColors.primary,
                duration: const Duration(seconds: 3),
              ),
            );

            // FIXED: Update location preference first - this will trigger UI rebuild
            await ref
                .read(authControllerProvider.notifier)
                .updateLocationPreference(newLocation);

            // FIXED: Additional delay to ensure provider update
            await Future.delayed(const Duration(milliseconds: 200));

            // Force reload data for the new location
            await ref
                .read(waterQualityControllerProvider.notifier)
                .loadData(newLocation, forceRefresh: true);

            // Clear and regenerate predictions for new location
            ref.read(predictionControllerProvider.notifier).clearPrediction();

            // Trigger auto prediction for new location
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ref.read(autoPredictionProvider);
            });

            // Show success feedback
            if (mounted) {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '✅ Switched to ${Helpers.getLocationDisplayName(newLocation)} data',
                  ),
                  backgroundColor: AppColors.success,
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          } catch (e) {
            // Show error feedback
            if (mounted) {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to switch location: $e'),
                  backgroundColor: AppColors.error,
                  duration: const Duration(seconds: 3),
                ),
              );
            }
          }
        }
      },
      itemBuilder: (BuildContext context) {
        return AppConstants.availableLocations.map((String location) {
          final isSelected =
              location == displayLocation; // FIXED: Use displayLocation
          return PopupMenuItem<String>(
            value: location,
            child: Row(
              children: [
                Icon(
                  Icons.location_on,
                  color:
                      isSelected ? AppColors.primary : AppColors.textSecondary,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  Helpers.getLocationDisplayName(location),
                  style: TextStyle(
                    color:
                        isSelected ? AppColors.primary : AppColors.textPrimary,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
                if (isSelected) ...[
                  const Spacer(),
                  Icon(
                    Icons.check,
                    color: AppColors.primary,
                    size: 16,
                  ),
                ],
              ],
            ),
          );
        }).toList();
      },
      child: Container(
        key: ValueKey(
            'location_button_$displayLocation'), // FIXED: Another key to force rebuild
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.location_on,
              color: Colors.white,
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              Helpers.getLocationDisplayName(
                  displayLocation), // FIXED: Use displayLocation
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.keyboard_arrow_down,
              color: Colors.white,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverallConditionCard(WaterQualityState state) {
    if (state.status == WaterQualityStatus.loading) {
      return const LoadingWidget();
    }

    if (state.status == WaterQualityStatus.error) {
      return CustomErrorWidget(
        message: state.errorMessage ?? AppStrings.errorDataLoad,
        onRetry: _loadData,
      );
    }

    final latestReading = state.latestReading;
    if (latestReading == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            children: [
              Icon(
                Icons.info_outline,
                color: AppColors.textSecondary,
                size: 48,
              ),
              const SizedBox(height: 8),
              Text(
                AppStrings.noDataAvailable,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Calculate overall condition using helper methods
    final isGoodCondition = latestReading.ph >= AppConstants.phMin &&
        latestReading.ph <= AppConstants.phMax &&
        latestReading.temperature >= AppConstants.temperatureMin &&
        latestReading.temperature <= AppConstants.temperatureMax &&
        latestReading.dissolvedOxygen >= AppConstants.doMin;

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    AppStrings.overallCondition,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isGoodCondition
                        ? AppColors.success.withValues(alpha: 0.1)
                        : AppColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isGoodCondition
                          ? AppColors.success.withValues(alpha: 0.3)
                          : AppColors.warning.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    isGoodCondition ? AppStrings.good : AppStrings.warning,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isGoodCondition
                              ? AppColors.success
                              : AppColors.warning,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color:
                        isGoodCondition ? AppColors.success : AppColors.warning,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isGoodCondition
                        ? AppStrings.waterQualityGood
                        : AppStrings.waterQualityBad,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // FIXED: Improved sensor grid with better aspect ratio and spacing
  Widget _buildSensorGrid(WaterQualityState state) {
    final latestReading = state.latestReading;

    if (latestReading == null) {
      return const SizedBox.shrink();
    }

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 8, // FIXED: Reduced from 12 to 8 for tighter layout
      mainAxisSpacing: 8, // FIXED: Reduced from 12 to 8 for tighter layout
      childAspectRatio:
          1.1, // FIXED: Better aspect ratio for more content space
      children: [
        AnimatedSensorCard(
          title: AppStrings.temperature,
          value: latestReading.temperature,
          unit: AppStrings.celsiusUnit,
          icon: Icons.thermostat,
          color: AppColors.temperatureDark,
          timestamp: latestReading.timestamp,
          animationDelay: 0,
        ),
        AnimatedSensorCard(
          title: AppStrings.ph,
          value: latestReading.ph,
          unit: AppStrings.phUnit,
          icon: Icons.science,
          color: AppColors.phDark,
          timestamp: latestReading.timestamp,
          animationDelay: 100,
        ),
        AnimatedSensorCard(
          title: AppStrings.dissolvedOxygen,
          value: latestReading.dissolvedOxygen,
          unit: AppStrings.doUnit,
          icon: Icons.air,
          color: AppColors.doDark,
          timestamp: latestReading.timestamp,
          animationDelay: 200,
        ),
        AnimatedSensorCard(
          title: AppStrings.turbidity,
          value: latestReading.turbidity,
          unit: AppStrings.turbidityUnit,
          icon: Icons.water,
          color: AppColors.turbidityDark,
          timestamp: latestReading.timestamp,
          animationDelay: 300,
        ),
      ],
    );
  }
}
