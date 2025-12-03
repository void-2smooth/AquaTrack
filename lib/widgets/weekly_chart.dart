import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../providers/providers.dart';
import '../theme/app_theme.dart';

/// Weekly water intake bar chart
/// 
/// Displays a beautiful animated bar chart showing daily water intake
/// for the past 7 days with goal line indicator.
class WeeklyChart extends ConsumerWidget {
  const WeeklyChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chartData = ref.watch(weeklyChartDataProvider);
    final settings = ref.watch(settingsProvider);
    final theme = Theme.of(context);
    final isDark = context.isDarkMode;

    return Container(
      padding: EdgeInsets.all(AppDimens.paddingXL),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [AppColors.cardDark, AppColors.cardDark.withOpacity(0.8)]
              : [Colors.white, Colors.white.withOpacity(0.95)],
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Weekly Overview',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: AppDimens.paddingXS),
                  Text(
                    'Last 7 days',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
              // Stats badge
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppDimens.paddingM,
                  vertical: AppDimens.paddingS,
                ),
                decoration: BoxDecoration(
                  color: chartData.goalsMet >= 5
                      ? AppColors.success.withOpacity(0.15)
                      : theme.colorScheme.primaryContainer.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(AppDimens.radiusCircle),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      size: 16,
                      color: chartData.goalsMet >= 5
                          ? AppColors.success
                          : theme.colorScheme.primary,
                    ),
                    SizedBox(width: AppDimens.paddingXS),
                    Text(
                      '${chartData.goalsMet}/7 goals',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: chartData.goalsMet >= 5
                            ? AppColors.success
                            : theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: AppDimens.paddingXXL),
          
          // Chart
          SizedBox(
            height: 200,
            child: _WeeklyBarChart(
              chartData: chartData,
              useMetric: settings.useMetricUnits,
              isDark: isDark,
            ),
          ),
          
          SizedBox(height: AppDimens.paddingL),
          
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LegendItem(
                color: theme.colorScheme.primary,
                label: 'Daily Intake',
              ),
              SizedBox(width: AppDimens.paddingXL),
              _LegendItem(
                color: AppColors.success,
                label: 'Goal Met',
                isDashed: false,
              ),
              SizedBox(width: AppDimens.paddingXL),
              _LegendItem(
                color: AppColors.warning,
                label: 'Goal Line',
                isDashed: true,
              ),
            ],
          ),
          
          SizedBox(height: AppDimens.paddingXL),
          
          // Weekly stats
          _WeeklyStats(chartData: chartData, useMetric: settings.useMetricUnits),
        ],
      ),
    );
  }
}

/// The actual bar chart widget
class _WeeklyBarChart extends StatelessWidget {
  final WeeklyChartData chartData;
  final bool useMetric;
  final bool isDark;

  const _WeeklyBarChart({
    required this.chartData,
    required this.useMetric,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: chartData.chartMaxY,
        minY: 0,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            tooltipBgColor: isDark ? AppColors.cardDark : Colors.white,
            tooltipRoundedRadius: AppDimens.radiusS,
            tooltipPadding: EdgeInsets.all(AppDimens.paddingS),
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final summary = chartData.dailySummaries[group.x];
              final amount = _formatAmount(summary.totalAmountMl);
              final date = DateFormat('EEE, MMM d').format(summary.date);
              return BarTooltipItem(
                '$date\n$amount',
                TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) => _getBottomTitle(value, context),
              reservedSize: 30,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) => _getLeftTitle(value, context),
              reservedSize: 45,
              interval: _getYInterval(),
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: _getYInterval(),
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: theme.colorScheme.outline.withOpacity(0.1),
              strokeWidth: 1,
            );
          },
        ),
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            HorizontalLine(
              y: chartData.goalMl,
              color: AppColors.warning,
              strokeWidth: 2,
              dashArray: [8, 4],
              label: HorizontalLineLabel(
                show: false,
              ),
            ),
          ],
        ),
        barGroups: _buildBarGroups(context),
      ),
      swapAnimationDuration: const Duration(milliseconds: 500),
      swapAnimationCurve: Curves.easeOutCubic,
    );
  }

  List<BarChartGroupData> _buildBarGroups(BuildContext context) {
    final theme = Theme.of(context);
    
    return List.generate(chartData.dailySummaries.length, (index) {
      final summary = chartData.dailySummaries[index];
      final isGoalMet = summary.goalReached;
      final isToday = _isToday(summary.date);
      
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: summary.totalAmountMl,
            width: 28,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppDimens.radiusS),
            ),
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: isGoalMet
                  ? [AppColors.success.withOpacity(0.8), AppColors.success]
                  : [
                      theme.colorScheme.primary.withOpacity(0.6),
                      theme.colorScheme.primary,
                    ],
            ),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: chartData.chartMaxY,
              color: theme.colorScheme.outline.withOpacity(0.05),
            ),
          ),
        ],
        showingTooltipIndicators: isToday ? [0] : [],
      );
    });
  }

  Widget _getBottomTitle(double value, BuildContext context) {
    final theme = Theme.of(context);
    final index = value.toInt();
    
    if (index < 0 || index >= chartData.dailySummaries.length) {
      return const SizedBox.shrink();
    }
    
    final date = chartData.dailySummaries[index].date;
    final dayName = DateFormat('E').format(date).substring(0, 1);
    final isToday = _isToday(date);
    
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        dayName,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
          color: isToday 
              ? theme.colorScheme.primary 
              : theme.colorScheme.onSurface.withOpacity(0.6),
        ),
      ),
    );
  }

  Widget _getLeftTitle(double value, BuildContext context) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Text(
        _formatAxisValue(value),
        style: TextStyle(
          fontSize: 10,
          color: theme.colorScheme.onSurface.withOpacity(0.5),
        ),
      ),
    );
  }

  double _getYInterval() {
    final maxY = chartData.chartMaxY;
    if (maxY <= 1000) return 250;
    if (maxY <= 2000) return 500;
    if (maxY <= 4000) return 1000;
    return 1500;
  }

  String _formatAxisValue(double ml) {
    if (useMetric) {
      if (ml >= 1000) {
        return '${(ml / 1000).toStringAsFixed(1)}L';
      }
      return '${ml.toInt()}';
    } else {
      return '${(ml * 0.033814).toStringAsFixed(0)}';
    }
  }

  String _formatAmount(double ml) {
    if (useMetric) {
      if (ml >= 1000) {
        return '${(ml / 1000).toStringAsFixed(1)}L';
      }
      return '${ml.toStringAsFixed(0)}ml';
    } else {
      return '${(ml * 0.033814).toStringAsFixed(1)}oz';
    }
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && 
           date.month == now.month && 
           date.day == now.day;
  }
}

/// Legend item for the chart
class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final bool isDashed;

  const _LegendItem({
    required this.color,
    required this.label,
    this.isDashed = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isDashed)
          CustomPaint(
            size: const Size(16, 3),
            painter: _DashedLinePainter(color: color),
          )
        else
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        SizedBox(width: AppDimens.paddingXS),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }
}

/// Dashed line painter for legend
class _DashedLinePainter extends CustomPainter {
  final Color color;

  _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    const dashWidth = 4.0;
    const dashSpace = 2.0;
    double startX = 0;
    
    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, size.height / 2),
        Offset(startX + dashWidth, size.height / 2),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Weekly stats summary
class _WeeklyStats extends StatelessWidget {
  final WeeklyChartData chartData;
  final bool useMetric;

  const _WeeklyStats({
    required this.chartData,
    required this.useMetric,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = context.isDarkMode;

    return Container(
      padding: EdgeInsets.all(AppDimens.paddingL),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.05)
            : theme.colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(AppDimens.radiusM),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(
            icon: Icons.water_drop_rounded,
            value: _formatAmount(chartData.totalMl),
            label: 'Total',
            color: AppColors.waterLight,
          ),
          Container(
            height: 40,
            width: 1,
            color: theme.colorScheme.outline.withOpacity(0.2),
          ),
          _StatItem(
            icon: Icons.trending_up_rounded,
            value: _formatAmount(chartData.averageMl),
            label: 'Daily Avg',
            color: theme.colorScheme.primary,
          ),
          Container(
            height: 40,
            width: 1,
            color: theme.colorScheme.outline.withOpacity(0.2),
          ),
          _StatItem(
            icon: Icons.emoji_events_rounded,
            value: '${chartData.completionRate.toStringAsFixed(0)}%',
            label: 'Success',
            color: AppColors.streakGold,
          ),
        ],
      ),
    );
  }

  String _formatAmount(double ml) {
    if (useMetric) {
      if (ml >= 1000) {
        return '${(ml / 1000).toStringAsFixed(1)}L';
      }
      return '${ml.toStringAsFixed(0)}ml';
    } else {
      return '${(ml * 0.033814).toStringAsFixed(1)}oz';
    }
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 18),
            SizedBox(width: AppDimens.paddingXS),
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
        SizedBox(height: AppDimens.paddingXS),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }
}

/// Compact weekly mini chart for home screen
class WeeklyMiniChart extends ConsumerWidget {
  const WeeklyMiniChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chartData = ref.watch(weeklyChartDataProvider);
    final theme = Theme.of(context);
    final isDark = context.isDarkMode;

    return Container(
      padding: EdgeInsets.all(AppDimens.paddingL),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.cardDark
            : Colors.white,
        borderRadius: BorderRadius.circular(AppDimens.radiusL),
        boxShadow: isDark ? [] : AppShadows.small,
        border: isDark
            ? Border.all(color: Colors.white.withOpacity(0.1))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'This Week',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${chartData.goalsMet}/7',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: chartData.goalsMet >= 5
                      ? AppColors.success
                      : theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: AppDimens.paddingM),
          // Mini bar representation
          Row(
            children: List.generate(7, (index) {
              if (index >= chartData.dailySummaries.length) {
                return Expanded(
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: 2),
                    height: 40,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.outline.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                );
              }
              
              final summary = chartData.dailySummaries[index];
              final progress = summary.goalMl > 0 
                  ? (summary.totalAmountMl / summary.goalMl).clamp(0.0, 1.0)
                  : 0.0;
              final isGoalMet = summary.goalReached;
              
              return Expanded(
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 2),
                  height: 40,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outline.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: FractionallySizedBox(
                      heightFactor: progress,
                      child: Container(
                        decoration: BoxDecoration(
                          color: isGoalMet
                              ? AppColors.success
                              : theme.colorScheme.primary.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          SizedBox(height: AppDimens.paddingS),
          // Day labels
          Row(
            children: ['M', 'T', 'W', 'T', 'F', 'S', 'S'].asMap().entries.map((entry) {
              final isToday = entry.key == 6; // Last one is today
              return Expanded(
                child: Text(
                  entry.value,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: isToday
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface.withOpacity(0.4),
                    fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

