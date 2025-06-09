import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/providers/prediction_provider.dart';
import '../../../data/providers/water_quality_provider.dart';
import '../../../data/models/prediction_model.dart';

class CleanPredictionCard extends ConsumerWidget {
  const CleanPredictionCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final predictionState = ref.watch(predictionControllerProvider);
    final canMakePrediction = ref.watch(canMakePredictionProvider);
    final waterQualityState = ref.watch(waterQualityControllerProvider);

    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Clean Header (No Debug Menu)
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.info.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.psychology,
                    color: AppColors.info,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI Predictions',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      Text(
                        _getSubtitle(predictionState, canMakePrediction,
                            waterQualityState.data.length),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
                _buildStatusIndicator(predictionState),
              ],
            ),

            const SizedBox(height: 16),

            // Content based on state
            _buildContent(context, ref, predictionState, canMakePrediction),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(PredictionState state) {
    switch (state.status) {
      case PredictionStatus.loading:
        return const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.info),
          ),
        );
      case PredictionStatus.loaded:
        return Icon(
          Icons.check_circle,
          color: AppColors.success,
          size: 20,
        );
      case PredictionStatus.error:
        return Icon(
          Icons.error,
          color: AppColors.error,
          size: 20,
        );
      default:
        return Icon(
          Icons.science,
          color: AppColors.textSecondary,
          size: 20,
        );
    }
  }

  String _getSubtitle(
      PredictionState state, bool canMakePrediction, int dataCount) {
    if (!canMakePrediction) {
      return 'Need more data (have $dataCount/5 readings)';
    }

    switch (state.status) {
      case PredictionStatus.loading:
        return 'Generating predictions...';
      case PredictionStatus.loaded:
        return 'Next values predicted';
      case PredictionStatus.error:
        return 'Prediction failed';
      default:
        return 'Ready to predict ($dataCount readings)';
    }
  }

  Widget _buildContent(BuildContext context, WidgetRef ref,
      PredictionState state, bool canMakePrediction) {
    if (!canMakePrediction) {
      return _buildInsufficientDataMessage(context, ref);
    }

    switch (state.status) {
      case PredictionStatus.loading:
        return _buildLoadingState(context);
      case PredictionStatus.loaded:
        return _buildPredictionResults(context, ref, state.prediction!);
      case PredictionStatus.error:
        return _buildErrorState(
            context, ref, state.errorMessage ?? 'Unknown error');
      default:
        return _buildInitialState(context, ref);
    }
  }

  Widget _buildInsufficientDataMessage(BuildContext context, WidgetRef ref) {
    final dataCount = ref.watch(waterQualityControllerProvider).data.length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.warning.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: AppColors.warning,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Insufficient Data for AI Prediction',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.warning,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Need at least 5 recent readings to generate AI predictions.\nCurrently have: $dataCount readings.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: dataCount / 5.0,
            backgroundColor: AppColors.warning.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.warning),
          ),
          const SizedBox(height: 4),
          Text(
            '${dataCount}/5 readings',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.warning,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 12),
          Text(
            'AI is analyzing data...',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildInitialState(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          final waterQualityState = ref.read(waterQualityControllerProvider);
          ref.read(predictionControllerProvider.notifier).makePrediction(
                waterQualityState.data,
              );
        },
        icon: const Icon(Icons.psychology, size: 18),
        label: const Text('Generate Predictions'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.info,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, WidgetRef ref, String error) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.error.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.error_outline,
                color: AppColors.error,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Prediction Failed',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            error,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                final waterQualityState =
                    ref.read(waterQualityControllerProvider);
                ref.read(predictionControllerProvider.notifier).makePrediction(
                      waterQualityState.data,
                    );
              },
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Retry'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.info,
                side: BorderSide(color: AppColors.info),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPredictionResults(
      BuildContext context, WidgetRef ref, PredictionResponse prediction) {
    return Column(
      children: [
        // Prediction grid
        Row(
          children: [
            Expanded(
              child: _buildPredictionItem(
                context,
                'Temp',
                prediction.predictions['temperature'],
                AppColors.temperatureDark,
                Icons.thermostat,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildPredictionItem(
                context,
                'pH',
                prediction.predictions['ph'],
                AppColors.phDark,
                Icons.science,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildPredictionItem(
                context,
                'DO',
                prediction.predictions['do'],
                AppColors.doDark,
                Icons.air,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildPredictionItem(
                context,
                'Turbidity',
                prediction.predictions['turbidity'],
                AppColors.turbidityDark,
                Icons.water,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Info about prediction
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            'Prediction for next reading • Based on last 5 measurements',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.success,
                  fontWeight: FontWeight.w500,
                ),
            textAlign: TextAlign.center,
          ),
        ),

        const SizedBox(height: 8),

        // Refresh button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              final waterQualityState =
                  ref.read(waterQualityControllerProvider);
              ref.read(predictionControllerProvider.notifier).makePrediction(
                    waterQualityState.data,
                  );
            },
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Update Predictions'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.info,
              side: BorderSide(color: AppColors.info),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPredictionItem(
    BuildContext context,
    String label,
    SensorPrediction? prediction,
    Color color,
    IconData icon,
  ) {
    if (prediction == null) {
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.textTertiary, size: 16),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textTertiary,
                  ),
            ),
            const SizedBox(height: 2),
            Text(
              'N/A',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textTertiary,
                  ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 4),
              Icon(
                prediction.confidenceIcon,
                color: prediction.confidenceColor,
                size: 12,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            '${prediction.value.toStringAsFixed(1)}${prediction.unit}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            prediction.modelConfidence.toUpperCase(),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: prediction.confidenceColor,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
