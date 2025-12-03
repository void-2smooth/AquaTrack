import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/providers.dart';
import '../models/water_entry.dart';
import '../theme/app_theme.dart';

/// History screen - Shows past daily water intake records
/// 
/// Displays:
/// - List of daily summaries
/// - Visual indicators for goal completion
/// - Ability to tap into specific days for details
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dailySummaries = ref.watch(dailySummariesProvider);
    final theme = Theme.of(context);
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
      ),
      body: dailySummaries.isEmpty
          ? _buildEmptyState(theme)
          : ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.all(AppDimens.paddingL),
              itemCount: dailySummaries.length + 1, // +1 for stats header
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _buildStatsHeader(context, dailySummaries, settings);
                }
                
                final summary = dailySummaries[index - 1];
                return _DailySummaryCard(
                  summary: summary,
                  useMetricUnits: settings.useMetricUnits,
                );
              },
            ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 64,
            color: theme.colorScheme.onSurface.withOpacity(0.3),
          ),
          SizedBox(height: AppDimens.paddingL),
          Text(
            'No history yet',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          SizedBox(height: AppDimens.paddingS),
          Text(
            'Start tracking your water intake!',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsHeader(
    BuildContext context,
    List<DailySummary> summaries,
    UserSettings settings,
  ) {
    final theme = Theme.of(context);
    
    // Calculate stats
    final daysWithEntries = summaries.where((s) => s.entryCount > 0).length;
    final goalsReached = summaries.where((s) => s.goalReached).length;
    final totalMl = summaries.fold(0.0, (sum, s) => sum + s.totalAmountMl);
    
    final averageMl = daysWithEntries > 0 ? totalMl / daysWithEntries : 0.0;
    final successRate = daysWithEntries > 0 
        ? (goalsReached / daysWithEntries * 100).toInt() 
        : 0;

    return Card(
      elevation: AppDimens.cardElevation,
      color: theme.colorScheme.primaryContainer,
      margin: EdgeInsets.only(bottom: AppDimens.paddingL),
      child: Padding(
        padding: EdgeInsets.all(AppDimens.paddingXL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Last 30 Days',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            SizedBox(height: AppDimens.paddingL),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatItem(
                  icon: Icons.check_circle,
                  value: goalsReached.toString(),
                  label: 'Goals Met',
                  color: AppColors.success,
                ),
                _StatItem(
                  icon: Icons.percent,
                  value: '$successRate%',
                  label: 'Success Rate',
                  color: theme.colorScheme.primary,
                ),
                _StatItem(
                  icon: Icons.water_drop,
                  value: _formatAmount(averageMl, settings.useMetricUnits),
                  label: 'Daily Avg',
                  color: AppColors.waterBlue,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatAmount(double ml, bool useMetric) {
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
      children: [
        Icon(icon, color: color, size: AppDimens.iconXL),
        SizedBox(height: AppDimens.paddingS),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onPrimaryContainer.withOpacity(0.7),
          ),
        ),
      ],
    );
  }
}

/// Card showing a single day's summary
class _DailySummaryCard extends StatelessWidget {
  final DailySummary summary;
  final bool useMetricUnits;

  const _DailySummaryCard({
    required this.summary,
    required this.useMetricUnits,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isToday = _isToday(summary.date);
    final dateFormat = DateFormat('EEE, MMM d');

    return Card(
      elevation: AppDimens.cardElevation,
      color: isToday 
          ? theme.colorScheme.secondaryContainer
          : theme.colorScheme.surfaceContainerHighest,
      margin: EdgeInsets.only(bottom: AppDimens.paddingS),
      child: InkWell(
        onTap: () {
          _showDayDetails(context, summary);
        },
        borderRadius: BorderRadius.circular(AppDimens.radiusM),
        child: Padding(
          padding: EdgeInsets.all(AppDimens.paddingL),
          child: Row(
            children: [
              // Date and status
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (isToday)
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: AppDimens.paddingS,
                              vertical: 2,
                            ),
                            margin: EdgeInsets.only(right: AppDimens.paddingS),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              borderRadius: BorderRadius.circular(AppDimens.radiusS),
                            ),
                            child: Text(
                              'Today',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onPrimary,
                              ),
                            ),
                          ),
                        Text(
                          dateFormat.format(summary.date),
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: AppDimens.paddingXS),
                    Text(
                      '${summary.entryCount} ${summary.entryCount == 1 ? 'entry' : 'entries'}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              // Amount display
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatAmount(summary.totalAmountMl),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: summary.goalReached 
                          ? AppColors.success 
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                  SizedBox(height: AppDimens.paddingXS),
                  // Progress bar
                  SizedBox(
                    width: 80,
                    child: LinearProgressIndicator(
                      value: summary.completionPercentageCapped,
                      backgroundColor: theme.colorScheme.outline.withOpacity(0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        summary.goalReached ? AppColors.success : theme.colorScheme.primary,
                      ),
                      borderRadius: BorderRadius.circular(AppDimens.radiusXS),
                    ),
                  ),
                ],
              ),
              // Goal indicator icon
              SizedBox(width: AppDimens.paddingM),
              Icon(
                summary.goalReached 
                    ? Icons.check_circle 
                    : Icons.radio_button_unchecked,
                color: summary.goalReached 
                    ? AppColors.success 
                    : theme.colorScheme.outline,
                size: AppDimens.iconXL,
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && 
           date.month == now.month && 
           date.day == now.day;
  }

  String _formatAmount(double ml) {
    if (useMetricUnits) {
      if (ml >= 1000) {
        return '${(ml / 1000).toStringAsFixed(1)}L';
      }
      return '${ml.toStringAsFixed(0)}ml';
    } else {
      return '${(ml * 0.033814).toStringAsFixed(1)}oz';
    }
  }

  void _showDayDetails(BuildContext context, DailySummary summary) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(AppDimens.paddingXXL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DateFormat('EEEE, MMMM d, yyyy').format(summary.date),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: AppDimens.paddingL),
            Text(
              'Total: ${_formatAmount(summary.totalAmountMl)}',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            Text(
              '${summary.entryCount} entries',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            SizedBox(height: AppDimens.paddingL),
            // TODO: Add list of individual entries for this day
            const Text('Individual entries would be listed here'),
          ],
        ),
      ),
    );
  }
}
