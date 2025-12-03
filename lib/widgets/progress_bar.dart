import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../providers/providers.dart';
import '../theme/app_theme.dart';

/// Modern circular progress bar widget
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
    
    final isDark = context.isDarkMode;
    final percentComplete = (progressUncapped * 100).toInt();
    
    // Format display values
    final String currentAmount;
    final String goalAmount;
    
    final effectiveGoal = settings.effectiveDailyGoalMl;
    
    if (settings.useMetricUnits) {
      currentAmount = totalMl >= 1000 
          ? '${(totalMl / 1000).toStringAsFixed(1)}' 
          : '${totalMl.toStringAsFixed(0)}';
      goalAmount = effectiveGoal >= 1000 
          ? '${(effectiveGoal / 1000).toStringAsFixed(1)}L' 
          : '${effectiveGoal.toStringAsFixed(0)}ml';
    } else {
      currentAmount = (totalMl * 0.033814).toStringAsFixed(1);
      goalAmount = '${(effectiveGoal * 0.033814).toStringAsFixed(0)}oz';
    }

    final progressColor = AppColors.getProgressColor(progress);
    
    // Create gradient effect
    final gradientColors = [
      progressColor,
      progressColor.withOpacity(0.7),
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Progress indicator with glow effect
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: progressColor.withOpacity(0.2),
                blurRadius: 40,
                spreadRadius: 10,
              ),
            ],
          ),
          child: CircularPercentIndicator(
            radius: size / 2,
            lineWidth: lineWidth,
            percent: progress,
            animation: true,
            animationDuration: AppDimens.animationProgress,
            animateFromLastPercent: true,
            circularStrokeCap: CircularStrokeCap.round,
            linearGradient: LinearGradient(
              colors: gradientColors,
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            backgroundColor: isDark 
                ? Colors.white.withOpacity(0.1) 
                : Colors.grey.shade200,
            center: _buildCenterContent(
              context,
              percentComplete,
              currentAmount,
              goalAmount,
              progressColor,
              settings.useMetricUnits,
            ),
          ),
        ),
        SizedBox(height: AppDimens.paddingXL),
        // Status pill
        _buildStatusPill(context, progress, progressColor),
      ],
    );
  }

  Widget _buildCenterContent(
    BuildContext context,
    int percentComplete,
    String currentAmount,
    String goalAmount,
    Color progressColor,
    bool useMetric,
  ) {
    final theme = Theme.of(context);
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Water drop icon
        Container(
          padding: EdgeInsets.all(AppDimens.paddingS),
          decoration: BoxDecoration(
            color: progressColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.water_drop_rounded,
            color: progressColor,
            size: AppDimens.iconXL,
          ),
        ),
        SizedBox(height: AppDimens.paddingM),
        // Percentage
        Text(
          '$percentComplete%',
          style: TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.w700,
            color: progressColor,
            height: 1,
            letterSpacing: -2,
          ),
        ),
        SizedBox(height: AppDimens.paddingS),
        // Current amount
        Text(
          currentAmount,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        Text(
          'of $goalAmount',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.5),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusPill(BuildContext context, double progress, Color color) {
    final theme = Theme.of(context);
    final isDark = context.isDarkMode;
    
    String statusText;
    IconData statusIcon;
    
    if (progress >= 1.0) {
      statusText = 'Goal Achieved!';
      statusIcon = Icons.celebration_rounded;
    } else if (progress >= 0.75) {
      statusText = 'Almost there!';
      statusIcon = Icons.trending_up_rounded;
    } else if (progress >= 0.5) {
      statusText = 'Halfway done';
      statusIcon = Icons.autorenew_rounded;
    } else if (progress >= 0.25) {
      statusText = 'Good start';
      statusIcon = Icons.thumb_up_rounded;
    } else {
      statusText = 'Keep drinking';
      statusIcon = Icons.water_drop_outlined;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppDimens.paddingL,
        vertical: AppDimens.paddingS,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(AppDimens.radiusCircle),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusIcon, color: color, size: AppDimens.iconM),
          SizedBox(width: AppDimens.paddingS),
          Text(
            statusText,
            style: theme.textTheme.labelLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact progress indicator
class CompactProgressIndicator extends ConsumerWidget {
  const CompactProgressIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(todayProgressProvider);
    final theme = Theme.of(context);
    final progressColor = AppColors.getProgressColor(progress);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppDimens.paddingM,
        vertical: AppDimens.paddingS,
      ),
      decoration: BoxDecoration(
        color: progressColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppDimens.radiusCircle),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: AppDimens.progressBarCompactSize,
            height: AppDimens.progressBarCompactSize,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 3,
              backgroundColor: progressColor.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              strokeCap: StrokeCap.round,
            ),
          ),
          SizedBox(width: AppDimens.paddingS),
          Text(
            '${(progress * 100).toInt()}%',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: progressColor,
            ),
          ),
        ],
      ),
    );
  }
}
