import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';
import '../theme/app_theme.dart';
import '../widgets/hydration_score_card.dart';
import '../widgets/score_history_chart.dart';

/// Analytics screen - Detailed hydration score and trends
class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = context.isDarkMode;
    final weeklyAvg = ref.watch(weeklyAverageScoreProvider);
    final trend = ref.watch(scoreTrendProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.all(AppDimens.paddingL),
        children: [
          // Today's Score Card
          const HydrationScoreCard(),
          SizedBox(height: AppDimens.paddingXL),

          // Score History Section
          _buildSectionHeader(context, '📈 Score History'),
          SizedBox(height: AppDimens.paddingM),
          Container(
            padding: EdgeInsets.all(AppDimens.paddingM),
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : Colors.white,
              borderRadius: BorderRadius.circular(AppDimens.radiusXL),
              boxShadow: isDark ? [] : AppShadows.small,
              border: isDark
                  ? Border.all(color: Colors.white.withOpacity(0.1))
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Last 30 Days',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: AppDimens.paddingM),
                const ScoreHistoryChart(),
              ],
            ),
          ),
          SizedBox(height: AppDimens.paddingXL),

          // Statistics Section
          _buildSectionHeader(context, '📊 Statistics'),
          SizedBox(height: AppDimens.paddingM),
          _StatisticsGrid(),
          SizedBox(height: AppDimens.paddingXL),

          // Trend Analysis
          _buildSectionHeader(context, '📉 Trend Analysis'),
          SizedBox(height: AppDimens.paddingM),
          _TrendAnalysisCard(trend: trend, weeklyAvg: weeklyAvg),
          SizedBox(height: AppDimens.paddingXL),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: AppDimens.paddingM),
      child: Text(
        title,
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _StatisticsGrid extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analytics = ref.watch(analyticsServiceProvider);
    final avg7Days = analytics.getAverageDailyIntake(7);
    final avg30Days = analytics.getAverageDailyIntake(30);
    final completionRate7 = analytics.getGoalCompletionRate(7);
    final completionRate30 = analytics.getGoalCompletionRate(30);
    final totalWater = analytics.getTotalWaterConsumed();
    final daysTracked = analytics.getDaysTracked();
    final settings = ref.watch(settingsProvider);

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: AppDimens.paddingM,
      mainAxisSpacing: AppDimens.paddingM,
      childAspectRatio: 1.5,
      children: [
        _StatCard(
          icon: Icons.trending_up_rounded,
          label: '7-Day Average',
          value: settings.useMetricUnits
              ? '${(avg7Days / 1000).toStringAsFixed(1)}L'
              : '${(avg7Days * 0.033814).toStringAsFixed(1)}oz',
          color: AppColors.success,
        ),
        _StatCard(
          icon: Icons.calendar_month_rounded,
          label: '30-Day Average',
          value: settings.useMetricUnits
              ? '${(avg30Days / 1000).toStringAsFixed(1)}L'
              : '${(avg30Days * 0.033814).toStringAsFixed(1)}oz',
          color: AppColors.warning,
        ),
        _StatCard(
          icon: Icons.check_circle_rounded,
          label: '7-Day Completion',
          value: '${completionRate7.toStringAsFixed(0)}%',
          color: AppColors.waterMedium,
        ),
        _StatCard(
          icon: Icons.assessment_rounded,
          label: '30-Day Completion',
          value: '${completionRate30.toStringAsFixed(0)}%',
          color: AppColors.waterDark,
        ),
        _StatCard(
          icon: Icons.water_drop_rounded,
          label: 'Total Water',
          value: settings.useMetricUnits
              ? '${(totalWater / 1000).toStringAsFixed(1)}L'
              : '${(totalWater * 0.033814).toStringAsFixed(1)}oz',
          color: AppColors.streakGold,
        ),
        _StatCard(
          icon: Icons.calendar_today_rounded,
          label: 'Days Tracked',
          value: '$daysTracked',
          color: AppColors.waterMedium,
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.all(AppDimens.paddingM),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(AppDimens.radiusL),
        boxShadow: isDark ? [] : AppShadows.small,
        border: isDark
            ? Border.all(color: Colors.white.withOpacity(0.1))
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 32),
          SizedBox(height: AppDimens.paddingS),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: AppDimens.paddingXS),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _TrendAnalysisCard extends StatelessWidget {
  final String trend;
  final double weeklyAvg;

  const _TrendAnalysisCard({
    required this.trend,
    required this.weeklyAvg,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    String title;
    String description;
    IconData icon;
    Color color;

    switch (trend) {
      case 'improving':
        title = '📈 Improving!';
        description = 'Your hydration score is trending upward. Keep up the great work!';
        icon = Icons.trending_up_rounded;
        color = AppColors.success;
        break;
      case 'declining':
        title = '📉 Needs Attention';
        description = 'Your hydration score has been declining. Try to be more consistent!';
        icon = Icons.trending_down_rounded;
        color = Colors.red;
        break;
      default:
        title = '📊 Stable';
        description = 'Your hydration score is stable. Try to push for improvement!';
        icon = Icons.trending_flat_rounded;
        color = theme.colorScheme.onSurface.withOpacity(0.5);
    }

    return Container(
      padding: EdgeInsets.all(AppDimens.paddingL),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.15),
            color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(AppDimens.radiusXL),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(AppDimens.paddingM),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          SizedBox(width: AppDimens.paddingL),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: AppDimens.paddingXS),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                SizedBox(height: AppDimens.paddingS),
                Text(
                  'Weekly Average: ${weeklyAvg.toStringAsFixed(0)}/100',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

