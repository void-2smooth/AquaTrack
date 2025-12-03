import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../providers/providers.dart';
import '../theme/app_theme.dart';

/// Circular progress bar widget showing daily water intake progress
/// 
/// Displays a beautiful circular progress indicator with:
/// - Dynamic percentage fill
/// - Current intake vs goal
/// - Animated transitions
class WaterProgressBar extends ConsumerWidget {
  final double size;
  final double lineWidth;

  const WaterProgressBar({
    super.key,
    this.size = AppDimens.progressBarSize,
    this.lineWidth = AppDimens.progressBarLineWidth,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(todayProgressProvider);
    final progressUncapped = ref.watch(todayProgressUncappedProvider);
    final totalMl = ref.watch(todayTotalProvider);
    final settings = ref.watch(settingsProvider);
    
    final theme = Theme.of(context);
    final percentComplete = (progressUncapped * 100).toInt();
    
    // Format display values based on unit preference
    final String currentAmount;
    final String goalAmount;
    
    if (settings.useMetricUnits) {
      if (totalMl >= 1000) {
        currentAmount = (totalMl / 1000).toStringAsFixed(1);
      } else {
        currentAmount = totalMl.toStringAsFixed(0);
      }
      
      if (settings.dailyGoalMl >= 1000) {
        goalAmount = (settings.dailyGoalMl / 1000).toStringAsFixed(1);
      } else {
        goalAmount = settings.dailyGoalMl.toStringAsFixed(0);
      }
    } else {
      currentAmount = (totalMl * 0.033814).toStringAsFixed(1);
      goalAmount = (settings.dailyGoalMl * 0.033814).toStringAsFixed(1);
    }

    // Use centralized progress color
    final progressColor = AppColors.getProgressColor(progress);

    return CircularPercentIndicator(
      radius: size / 2,
      lineWidth: lineWidth,
      percent: progress,
      animation: true,
      animationDuration: AppDimens.animationProgress,
      animateFromLastPercent: true,
      circularStrokeCap: CircularStrokeCap.round,
      progressColor: progressColor,
      backgroundColor: theme.colorScheme.surfaceContainerHighest,
      center: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Percentage display
          Text(
            '$percentComplete%',
            style: theme.textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: progressColor,
            ),
          ),
          SizedBox(height: AppDimens.paddingS),
          // Current / Goal display
          Text(
            '$currentAmount / $goalAmount',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          Text(
            settings.useMetricUnits ? 'Liters' : 'Ounces',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ],
      ),
      // Water drop icon as footer
      footer: Padding(
        padding: EdgeInsets.only(top: AppDimens.paddingL),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.water_drop,
              color: progressColor,
              size: AppDimens.iconM,
            ),
            SizedBox(width: AppDimens.paddingXS),
            Text(
              _getStatusText(progress),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getStatusText(double progress) {
    if (progress >= 1.0) return 'Goal Completed!';
    if (progress >= 0.75) return 'Almost there!';
    if (progress >= 0.5) return 'Halfway done';
    if (progress >= 0.25) return 'Good start';
    return 'Keep drinking';
  }
}

/// Compact progress indicator for use in app bar or cards
class CompactProgressIndicator extends ConsumerWidget {
  const CompactProgressIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(todayProgressProvider);
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: AppDimens.progressBarCompactSize,
          height: AppDimens.progressBarCompactSize,
          child: CircularProgressIndicator(
            value: progress,
            strokeWidth: 3,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(
              progress >= 1.0 ? AppColors.progressGreen : theme.colorScheme.primary,
            ),
          ),
        ),
        SizedBox(width: AppDimens.paddingS),
        Text(
          '${(progress * 100).toInt()}%',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
