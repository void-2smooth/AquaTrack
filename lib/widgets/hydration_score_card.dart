import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';
import '../theme/app_theme.dart';

/// Hydration score card widget
class HydrationScoreCard extends ConsumerWidget {
  const HydrationScoreCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dailyScore = ref.watch(dailyScoreProvider);
    final weeklyAvg = ref.watch(weeklyAverageScoreProvider);
    final trend = ref.watch(scoreTrendProvider);
    final theme = Theme.of(context);
    final isDark = context.isDarkMode;

    return Container(
      margin: EdgeInsets.only(bottom: AppDimens.paddingL),
      padding: EdgeInsets.all(AppDimens.paddingL),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  AppColors.cardDark,
                  AppColors.cardDark.withOpacity(0.8),
                ]
              : [
                  Colors.white,
                  Colors.white.withOpacity(0.95),
                ],
        ),
        borderRadius: BorderRadius.circular(AppDimens.radiusXL),
        boxShadow: isDark ? [] : AppShadows.medium,
        border: isDark
            ? Border.all(color: Colors.white.withOpacity(0.1))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(AppDimens.paddingS),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _getScoreColor(dailyScore).withOpacity(0.2),
                      _getScoreColor(dailyScore).withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(AppDimens.radiusM),
                ),
                child: Icon(
                  Icons.insights_rounded,
                  color: _getScoreColor(dailyScore),
                  size: 24,
                ),
              ),
              SizedBox(width: AppDimens.paddingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hydration Score',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: AppDimens.paddingXS),
                    Text(
                      'Today\'s Performance',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              _TrendIndicator(trend: trend),
            ],
          ),
          SizedBox(height: AppDimens.paddingXL),

          // Score Display
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Daily Score
              Expanded(
                child: _ScoreDisplay(
                  label: 'Today',
                  score: dailyScore,
                  color: _getScoreColor(dailyScore),
                ),
              ),
              Container(
                height: 60,
                width: 1,
                color: theme.colorScheme.outline.withOpacity(0.2),
              ),
              // Weekly Average
              Expanded(
                child: _ScoreDisplay(
                  label: 'Weekly Avg',
                  score: weeklyAvg,
                  color: _getScoreColor(weeklyAvg),
                ),
              ),
            ],
          ),
          SizedBox(height: AppDimens.paddingL),

          // Score Breakdown
          _ScoreBreakdown(),
        ],
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 80) return AppColors.success;
    if (score >= 60) return AppColors.warning;
    return Colors.red;
  }
}

class _TrendIndicator extends StatelessWidget {
  final String trend;

  const _TrendIndicator({required this.trend});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    IconData icon;
    Color color;
    String label;

    switch (trend) {
      case 'improving':
        icon = Icons.trending_up_rounded;
        color = AppColors.success;
        label = 'Up';
        break;
      case 'declining':
        icon = Icons.trending_down_rounded;
        color = Colors.red;
        label = 'Down';
        break;
      default:
        icon = Icons.trending_flat_rounded;
        color = theme.colorScheme.onSurface.withOpacity(0.5);
        label = 'Stable';
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 16),
        SizedBox(width: 4),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _ScoreDisplay extends StatelessWidget {
  final String label;
  final double score;
  final Color color;

  const _ScoreDisplay({
    required this.label,
    required this.score,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        SizedBox(height: AppDimens.paddingXS),
        Text(
          score.toStringAsFixed(0),
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        SizedBox(height: AppDimens.paddingXS),
        Container(
          width: 60,
          height: 4,
          decoration: BoxDecoration(
            color: theme.colorScheme.outline.withOpacity(0.1),
            borderRadius: BorderRadius.circular(2),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: score / 100,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ScoreBreakdown extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final todayTotal = ref.watch(todayTotalProvider);
    final goal = settings.effectiveDailyGoalMl;
    final goalCompletion = (todayTotal / goal).clamp(0.0, 1.0) * 100;
    final streak = settings.currentStreak;
    final theme = Theme.of(context);

    // Calculate consistency (simplified)
    final entries = ref.watch(todayEntriesProvider);
    final consistency = entries.length > 1 
        ? (entries.length / 8.0 * 100).clamp(0.0, 100.0) // Max 8 entries = 100%
        : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Score Breakdown',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: AppDimens.paddingM),
        _BreakdownItem(
          label: 'Goal Completion',
          value: goalCompletion,
          weight: '50%',
          color: AppColors.success,
        ),
        SizedBox(height: AppDimens.paddingS),
        _BreakdownItem(
          label: 'Consistency',
          value: consistency,
          weight: '30%',
          color: AppColors.warning,
        ),
        SizedBox(height: AppDimens.paddingS),
        _BreakdownItem(
          label: 'Streak Bonus',
          value: (streak / 30.0 * 100).clamp(0.0, 100.0),
          weight: '20%',
          color: AppColors.streakGold,
        ),
      ],
    );
  }
}

class _BreakdownItem extends StatelessWidget {
  final String label;
  final double value;
  final String weight;
  final Color color;

  const _BreakdownItem({
    required this.label,
    required this.value,
    required this.weight,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: AppDimens.paddingS),
              Text(
                label,
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
        Expanded(
          child: Text(
            weight,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
            textAlign: TextAlign.right,
          ),
        ),
        SizedBox(width: AppDimens.paddingS),
        SizedBox(
          width: 60,
          child: Text(
            '${value.toStringAsFixed(0)}%',
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}

