import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/providers.dart';
import '../theme/app_theme.dart';

/// Score history chart widget
class ScoreHistoryChart extends ConsumerWidget {
  const ScoreHistoryChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(scoreHistoryProvider);
    final theme = Theme.of(context);
    final isDark = context.isDarkMode;

    if (history.isEmpty) {
      return Container(
        padding: EdgeInsets.all(AppDimens.paddingXL),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.insights_outlined,
                size: 48,
                color: theme.colorScheme.onSurface.withOpacity(0.3),
              ),
              SizedBox(height: AppDimens.paddingM),
              Text(
                'Not enough data yet',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
              SizedBox(height: AppDimens.paddingXS),
              Text(
                'Keep logging water to see your score history!',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.4),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      height: 200,
      padding: EdgeInsets.all(AppDimens.paddingM),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 20,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: theme.colorScheme.outline.withOpacity(0.1),
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: history.length > 7 ? (history.length / 7).ceil().toDouble() : 1,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= history.length) return const Text('');
                  final date = history[value.toInt()]['date'] as DateTime;
                  return Padding(
                    padding: EdgeInsets.only(top: AppDimens.paddingXS),
                    child: Text(
                      '${date.day}/${date.month}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                        fontSize: 10,
                      ),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                interval: 20,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                      fontSize: 10,
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border(
              bottom: BorderSide(
                color: theme.colorScheme.outline.withOpacity(0.2),
                width: 1,
              ),
              left: BorderSide(
                color: theme.colorScheme.outline.withOpacity(0.2),
                width: 1,
              ),
            ),
          ),
          minX: 0,
          maxX: (history.length - 1).toDouble(),
          minY: 0,
          maxY: 100,
          lineBarsData: [
            LineChartBarData(
              spots: history.asMap().entries.map((entry) {
                return FlSpot(
                  entry.key.toDouble(),
                  (entry.value['score'] as double),
                );
              }).toList(),
              isCurved: true,
              color: AppColors.waterMedium,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: AppColors.waterMedium,
                    strokeWidth: 2,
                    strokeColor: isDark ? AppColors.cardDark : Colors.white,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                color: AppColors.waterMedium.withOpacity(0.1),
              ),
            ),
            // Average line
            LineChartBarData(
              spots: [
                FlSpot(0, history.map((e) => e['score'] as double).reduce((a, b) => a + b) / history.length),
                FlSpot((history.length - 1).toDouble(), history.map((e) => e['score'] as double).reduce((a, b) => a + b) / history.length),
              ],
              isCurved: false,
              color: AppColors.warning.withOpacity(0.5),
              barWidth: 2,
              dashArray: [5, 5],
              dotData: const FlDotData(show: false),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              tooltipRoundedRadius: AppDimens.radiusM,
              tooltipPadding: EdgeInsets.all(AppDimens.paddingS),
              tooltipBgColor: isDark 
                  ? AppColors.cardDark 
                  : Colors.white,
              tooltipBorder: BorderSide(
                color: theme.colorScheme.outline.withOpacity(0.2),
                width: 1,
              ),
            ),
            handleBuiltInTouches: true,
            getTouchedSpotIndicator: (barData, spotIndexes) {
              return spotIndexes.map((index) {
                return TouchedSpotIndicatorData(
                  FlLine(
                    color: AppColors.waterMedium,
                    strokeWidth: 2,
                    dashArray: [3, 3],
                  ),
                  FlDotData(
                    getDotPainter: (spot, percent, barData, index) {
                      return FlDotCirclePainter(
                        radius: 6,
                        color: AppColors.waterMedium,
                        strokeWidth: 2,
                        strokeColor: isDark ? AppColors.cardDark : Colors.white,
                      );
                    },
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }
}

