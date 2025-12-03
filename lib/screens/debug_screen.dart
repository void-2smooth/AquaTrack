import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/achievement.dart';
import '../models/water_entry.dart';
import '../providers/providers.dart';
import '../theme/app_theme.dart';
import '../main.dart' show ProviderLogger;

/// Debug/Cheat menu for testing app features
/// 
/// Access this screen by long-pressing the app title or through settings.
/// Only use for development and testing purposes.
class DebugScreen extends ConsumerStatefulWidget {
  const DebugScreen({super.key});

  @override
  ConsumerState<DebugScreen> createState() => _DebugScreenState();
}

class _DebugScreenState extends ConsumerState<DebugScreen> {
  // Performance tracking
  late Ticker _ticker;
  int _frameCount = 0;
  double _fps = 0;
  DateTime _lastFpsUpdate = DateTime.now();
  int _buildCount = 0;
  final Stopwatch _buildStopwatch = Stopwatch();
  double _lastBuildTime = 0;
  
  @override
  void initState() {
    super.initState();
    _ticker = Ticker(_onTick)..start();
  }
  
  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }
  
  void _onTick(Duration elapsed) {
    _frameCount++;
    final now = DateTime.now();
    final diff = now.difference(_lastFpsUpdate);
    if (diff.inMilliseconds >= 1000) {
      setState(() {
        _fps = _frameCount / (diff.inMilliseconds / 1000);
        _frameCount = 0;
        _lastFpsUpdate = now;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    _buildCount++;
    _buildStopwatch.reset();
    _buildStopwatch.start();
    
    final theme = Theme.of(context);
    final settings = ref.watch(settingsProvider);
    final achievementsState = ref.watch(achievementsProvider);
    final todayTotal = ref.watch(todayTotalProvider);
    final entries = ref.watch(todayEntriesProvider);
    final containers = ref.watch(containersProvider);
    
    // Calculate storage stats
    final storageService = ref.read(storageServiceProvider);
    final totalEntries = storageService.getTotalEntryCount();
    final totalWater = storageService.getTotalWaterLogged();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _buildStopwatch.stop();
      if (mounted) {
        setState(() {
          _lastBuildTime = _buildStopwatch.elapsedMicroseconds / 1000;
        });
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('🔧 Debug Menu'),
        backgroundColor: Colors.orange.withOpacity(0.2),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => setState(() {}),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.all(AppDimens.paddingL),
        children: [
          // Warning banner
          Container(
            padding: EdgeInsets.all(AppDimens.paddingM),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.15),
              borderRadius: BorderRadius.circular(AppDimens.radiusM),
              border: Border.all(color: Colors.orange.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                SizedBox(width: AppDimens.paddingM),
                Expanded(
                  child: Text(
                    'Debug menu for development only.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.orange.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: AppDimens.paddingXL),

          // Performance Stats Section
          _buildSectionHeader(context, '⚡ Performance'),
          _PerformanceCard(
            fps: _fps,
            buildCount: _buildCount,
            lastBuildTime: _lastBuildTime,
          ),
          SizedBox(height: AppDimens.paddingXL),

          // Provider Stats Section
          _buildSectionHeader(context, '🔄 Provider Stats'),
          _ProviderStatsCard(),
          SizedBox(height: AppDimens.paddingXL),

          // Storage Stats Section
          _buildSectionHeader(context, '💾 Storage Stats'),
          _buildStatCard(context, [
            _StatItem('Total Entries', '$totalEntries'),
            _StatItem('Total Water Logged', '${(totalWater / 1000).toStringAsFixed(1)} L'),
            _StatItem('Containers', '${containers.length}'),
            _StatItem('Achievements Unlocked', '${achievementsState.totalUnlocked}'),
            _StatItem('Unseen Achievements', '${ref.read(achievementsProvider.notifier).unseenCount}'),
          ]),
          SizedBox(height: AppDimens.paddingXL),

          // Current Stats Section
          _buildSectionHeader(context, '📊 App State'),
          _buildStatCard(context, [
            _StatItem('Today Total', '${todayTotal.toStringAsFixed(0)} ml'),
            _StatItem('Today Entries', '${entries.length}'),
            _StatItem('Current Streak', '${settings.currentStreak} days'),
            _StatItem('Longest Streak', '${settings.longestStreak} days'),
            _StatItem('Daily Goal', '${settings.dailyGoalMl.toStringAsFixed(0)} ml'),
            _StatItem('Goal Progress', '${((todayTotal / settings.dailyGoalMl) * 100).toStringAsFixed(1)}%'),
          ]),
          SizedBox(height: AppDimens.paddingXL),

          // Water Actions Section
          _buildSectionHeader(context, '💧 Water Actions'),
          _buildActionGrid(context, [
            _DebugAction(
              icon: Icons.add_circle_rounded,
              label: 'Add 100ml',
              color: Colors.blue,
              onTap: () => _addWater(ref, 100),
            ),
            _DebugAction(
              icon: Icons.add_circle_rounded,
              label: 'Add 500ml',
              color: Colors.blue,
              onTap: () => _addWater(ref, 500),
            ),
            _DebugAction(
              icon: Icons.add_circle_rounded,
              label: 'Add 1L',
              color: Colors.blue,
              onTap: () => _addWater(ref, 1000),
            ),
            _DebugAction(
              icon: Icons.flag_rounded,
              label: 'Complete Goal',
              color: Colors.green,
              onTap: () => _completeGoal(ref, settings),
            ),
            _DebugAction(
              icon: Icons.flag_rounded,
              label: '150% Goal',
              color: Colors.teal,
              onTap: () => _exceed150Goal(ref, settings),
            ),
            _DebugAction(
              icon: Icons.delete_sweep_rounded,
              label: 'Clear Today',
              color: Colors.red,
              onTap: () => _clearTodayEntries(ref, context),
            ),
          ]),
          SizedBox(height: AppDimens.paddingXL),

          // Streak Actions Section
          _buildSectionHeader(context, '🔥 Streak Actions'),
          _buildActionGrid(context, [
            _DebugAction(
              icon: Icons.local_fire_department_rounded,
              label: 'Set 3 days',
              color: Colors.orange,
              onTap: () => _setStreak(ref, 3),
            ),
            _DebugAction(
              icon: Icons.local_fire_department_rounded,
              label: 'Set 7 days',
              color: Colors.orange,
              onTap: () => _setStreak(ref, 7),
            ),
            _DebugAction(
              icon: Icons.local_fire_department_rounded,
              label: 'Set 14 days',
              color: Colors.deepOrange,
              onTap: () => _setStreak(ref, 14),
            ),
            _DebugAction(
              icon: Icons.local_fire_department_rounded,
              label: 'Set 30 days',
              color: Colors.deepOrange,
              onTap: () => _setStreak(ref, 30),
            ),
            _DebugAction(
              icon: Icons.local_fire_department_rounded,
              label: 'Set 100 days',
              color: Colors.red,
              onTap: () => _setStreak(ref, 100),
            ),
            _DebugAction(
              icon: Icons.restart_alt_rounded,
              label: 'Reset Streak',
              color: Colors.grey,
              onTap: () => _setStreak(ref, 0),
            ),
          ]),
          SizedBox(height: AppDimens.paddingXL),

          // Celebration Actions Section
          _buildSectionHeader(context, '🎉 Celebration Actions'),
          _buildActionGrid(context, [
            _DebugAction(
              icon: Icons.celebration_rounded,
              label: 'Goal Banner',
              color: Colors.green,
              onTap: () => _triggerGoalCelebration(ref),
            ),
            _DebugAction(
              icon: Icons.emoji_events_rounded,
              label: 'Achievement',
              color: Colors.amber,
              onTap: () => _showAchievementDialog(context, ref),
            ),
            _DebugAction(
              icon: Icons.cancel_rounded,
              label: 'Dismiss All',
              color: Colors.grey,
              onTap: () => _dismissAllCelebrations(ref),
            ),
          ]),
          SizedBox(height: AppDimens.paddingXL),

          // Achievement Actions Section
          _buildSectionHeader(context, '🏆 Achievement Actions'),
          _buildActionGrid(context, [
            _DebugAction(
              icon: Icons.lock_open_rounded,
              label: 'Unlock Random',
              color: Colors.purple,
              onTap: () => _unlockRandomAchievement(ref, context),
            ),
            _DebugAction(
              icon: Icons.lock_open_rounded,
              label: 'Unlock All',
              color: Colors.purple,
              onTap: () => _unlockAllAchievements(ref, context),
            ),
            _DebugAction(
              icon: Icons.lock_rounded,
              label: 'Lock All',
              color: Colors.grey,
              onTap: () => _lockAllAchievements(ref, context),
            ),
            _DebugAction(
              icon: Icons.checklist_rounded,
              label: 'Check Unlock',
              color: Colors.blue,
              onTap: () => _checkAchievements(ref, context),
            ),
          ]),
          SizedBox(height: AppDimens.paddingXL),

          // Data Actions Section
          _buildSectionHeader(context, '💾 Data Actions'),
          _buildActionGrid(context, [
            _DebugAction(
              icon: Icons.delete_forever_rounded,
              label: 'Reset ALL',
              color: Colors.red,
              onTap: () => _resetAllData(ref, context),
            ),
            _DebugAction(
              icon: Icons.refresh_rounded,
              label: 'Refresh State',
              color: Colors.blue,
              onTap: () => _refreshAllState(ref),
            ),
          ]),
          SizedBox(height: AppDimens.paddingXXL),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppDimens.paddingM),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, List<_StatItem> stats) {
    final theme = Theme.of(context);
    final isDark = context.isDarkMode;

    return Container(
      padding: EdgeInsets.all(AppDimens.paddingL),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(AppDimens.radiusL),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade200,
        ),
      ),
      child: Column(
        children: stats.map((stat) => Padding(
          padding: EdgeInsets.symmetric(vertical: AppDimens.paddingXS),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                stat.label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              Text(
                stat.value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildActionGrid(BuildContext context, List<_DebugAction> actions) {
    return Wrap(
      spacing: AppDimens.paddingS,
      runSpacing: AppDimens.paddingS,
      children: actions.map((action) => _DebugActionButton(action: action)).toList(),
    );
  }

  // ============ Action Methods ============

  void _addWater(WidgetRef ref, double amount) {
    HapticFeedback.lightImpact();
    ref.read(todayEntriesProvider.notifier).addEntry(amount);
  }

  void _completeGoal(WidgetRef ref, UserSettings settings) {
    HapticFeedback.lightImpact();
    final todayTotal = ref.read(todayTotalProvider);
    final remaining = settings.dailyGoalMl - todayTotal;
    if (remaining > 0) {
      ref.read(todayEntriesProvider.notifier).addEntry(remaining);
    }
  }

  void _exceed150Goal(WidgetRef ref, UserSettings settings) {
    HapticFeedback.lightImpact();
    final todayTotal = ref.read(todayTotalProvider);
    final target = settings.dailyGoalMl * 1.5;
    final remaining = target - todayTotal;
    if (remaining > 0) {
      ref.read(todayEntriesProvider.notifier).addEntry(remaining);
    }
  }

  void _clearTodayEntries(WidgetRef ref, BuildContext context) async {
    HapticFeedback.lightImpact();
    final entries = ref.read(todayEntriesProvider);
    for (final entry in entries) {
      await ref.read(todayEntriesProvider.notifier).deleteEntry(entry.id);
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cleared today\'s entries')),
      );
    }
  }

  void _setStreak(WidgetRef ref, int days) {
    HapticFeedback.lightImpact();
    final settings = ref.read(settingsProvider);
    final updated = UserSettings(
      dailyGoalMl: settings.dailyGoalMl,
      useMetricUnits: settings.useMetricUnits,
      notificationsEnabled: settings.notificationsEnabled,
      reminderIntervalMinutes: settings.reminderIntervalMinutes,
      isDarkMode: settings.isDarkMode,
      currentStreak: days,
      longestStreak: days > settings.longestStreak ? days : settings.longestStreak,
      lastActiveDate: settings.lastActiveDate,
    );
    ref.read(settingsProvider.notifier).updateSettings(updated);
  }

  void _triggerGoalCelebration(WidgetRef ref) {
    HapticFeedback.mediumImpact();
    // Reset the daily flag first to allow re-triggering
    ref.read(celebrationProvider.notifier).resetDaily();
    ref.read(celebrationProvider.notifier).triggerGoalCelebration();
  }

  void _showAchievementDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => _AchievementPickerDialog(ref: ref),
    );
  }

  void _dismissAllCelebrations(WidgetRef ref) {
    HapticFeedback.lightImpact();
    ref.read(celebrationProvider.notifier).dismissGoalCelebration();
    ref.read(celebrationProvider.notifier).dismissAchievementCelebration();
    ref.read(celebrationProvider.notifier).dismissStreakCelebration();
  }

  void _unlockRandomAchievement(WidgetRef ref, BuildContext context) async {
    HapticFeedback.mediumImpact();
    final state = ref.read(achievementsProvider);
    final locked = Achievements.all.where(
      (a) => !state.isUnlocked(a.id)
    ).toList();
    
    if (locked.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All achievements already unlocked!')),
      );
      return;
    }
    
    final random = locked[DateTime.now().millisecondsSinceEpoch % locked.length];
    final storage = ref.read(storageServiceProvider);
    await storage.unlockAchievement(random.id);
    ref.read(achievementsProvider.notifier).checkAndUnlockAchievements();
    ref.read(celebrationProvider.notifier).triggerAchievementCelebration(random);
  }

  void _unlockAllAchievements(WidgetRef ref, BuildContext context) async {
    HapticFeedback.mediumImpact();
    final storage = ref.read(storageServiceProvider);
    for (final achievement in Achievements.all) {
      await storage.unlockAchievement(achievement.id);
    }
    ref.read(achievementsProvider.notifier).checkAndUnlockAchievements();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All achievements unlocked!')),
    );
  }

  void _lockAllAchievements(WidgetRef ref, BuildContext context) async {
    HapticFeedback.mediumImpact();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Lock All Achievements?'),
        content: const Text('This will reset all your achievement progress.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Lock All'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      final storage = ref.read(storageServiceProvider);
      // Clear achievements box by clearing and reinitializing
      await storage.clearAllData();
      ref.read(achievementsProvider.notifier).checkAndUnlockAchievements();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All achievements locked!')),
        );
      }
    }
  }

  void _checkAchievements(WidgetRef ref, BuildContext context) async {
    HapticFeedback.lightImpact();
    final newAchievements = await ref.read(achievementsProvider.notifier).checkAndUnlockAchievements();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Checked! ${newAchievements.length} new achievements unlocked.')),
    );
  }

  void _resetAllData(WidgetRef ref, BuildContext context) async {
    HapticFeedback.heavyImpact();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ Reset ALL Data?'),
        content: const Text(
          'This will permanently delete all your water entries, achievements, settings, and containers. This cannot be undone!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete Everything'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      final storage = ref.read(storageServiceProvider);
      await storage.clearAllData();
      ref.read(settingsProvider.notifier).refresh();
      ref.read(todayEntriesProvider.notifier).refresh();
      ref.read(containersProvider.notifier).refresh();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All data has been reset!')),
        );
        Navigator.pop(context);
      }
    }
  }

  void _refreshAllState(WidgetRef ref) {
    HapticFeedback.lightImpact();
    ref.read(settingsProvider.notifier).refresh();
    ref.read(todayEntriesProvider.notifier).refresh();
    ref.read(containersProvider.notifier).refresh();
    ref.read(achievementsProvider.notifier).checkAndUnlockAchievements();
  }
}

class _StatItem {
  final String label;
  final String value;
  _StatItem(this.label, this.value);
}

class _DebugAction {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  _DebugAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
}

class _DebugActionButton extends StatelessWidget {
  final _DebugAction action;

  const _DebugActionButton({required this.action});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: action.color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(AppDimens.radiusM),
      child: InkWell(
        onTap: action.onTap,
        borderRadius: BorderRadius.circular(AppDimens.radiusM),
        child: Container(
          width: 100,
          padding: EdgeInsets.all(AppDimens.paddingM),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(action.icon, color: action.color, size: 28),
              SizedBox(height: AppDimens.paddingXS),
              Text(
                action.label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: action.color,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AchievementPickerDialog extends StatelessWidget {
  final WidgetRef ref;

  const _AchievementPickerDialog({required this.ref});

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(achievementsProvider);

    return AlertDialog(
      title: const Text('Trigger Achievement'),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: ListView.builder(
          itemCount: Achievements.all.length,
          itemBuilder: (context, index) {
            final achievement = Achievements.all[index];
            final isUnlocked = state.isUnlocked(achievement.id);

            return ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: achievement.rarityColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  achievement.iconData,
                  color: achievement.rarityColor,
                  size: 24,
                ),
              ),
              title: Text(
                achievement.name,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  decoration: isUnlocked ? TextDecoration.lineThrough : null,
                ),
              ),
              subtitle: Text(
                achievement.rarityName,
                style: TextStyle(
                  color: achievement.rarityColor,
                  fontSize: 12,
                ),
              ),
              trailing: isUnlocked
                  ? const Icon(Icons.check_circle, color: Colors.green)
                  : null,
              onTap: () {
                Navigator.pop(context);
                ref.read(celebrationProvider.notifier).triggerAchievementCelebration(achievement);
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}

/// Performance statistics card
class _PerformanceCard extends StatelessWidget {
  final double fps;
  final int buildCount;
  final double lastBuildTime;

  const _PerformanceCard({
    required this.fps,
    required this.buildCount,
    required this.lastBuildTime,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = context.isDarkMode;

    Color fpsColor;
    String fpsStatus;
    if (fps >= 55) {
      fpsColor = Colors.green;
      fpsStatus = 'Excellent';
    } else if (fps >= 45) {
      fpsColor = Colors.orange;
      fpsStatus = 'Good';
    } else if (fps >= 30) {
      fpsColor = Colors.deepOrange;
      fpsStatus = 'Fair';
    } else {
      fpsColor = Colors.red;
      fpsStatus = 'Poor';
    }

    return Container(
      padding: EdgeInsets.all(AppDimens.paddingL),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(AppDimens.radiusL),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade200,
        ),
      ),
      child: Column(
        children: [
          // FPS Indicator
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: fpsColor.withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: fpsColor, width: 3),
                ),
                child: Center(
                  child: Text(
                    fps.toStringAsFixed(0),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: fpsColor,
                    ),
                  ),
                ),
              ),
              SizedBox(width: AppDimens.paddingL),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Frame Rate',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: AppDimens.paddingXS),
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: AppDimens.paddingS,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: fpsColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(AppDimens.radiusXS),
                          ),
                          child: Text(
                            fpsStatus,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: fpsColor,
                            ),
                          ),
                        ),
                        SizedBox(width: AppDimens.paddingS),
                        Text(
                          'Target: 60 FPS',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: AppDimens.paddingL),
          Divider(height: 1, color: theme.colorScheme.outline.withOpacity(0.1)),
          SizedBox(height: AppDimens.paddingL),
          // Build Stats
          Row(
            children: [
              Expanded(
                child: _PerfMetric(
                  icon: Icons.architecture_rounded,
                  label: 'Builds',
                  value: '$buildCount',
                  color: Colors.blue,
                ),
              ),
              Container(
                height: 40,
                width: 1,
                color: theme.colorScheme.outline.withOpacity(0.1),
              ),
              Expanded(
                child: _PerfMetric(
                  icon: Icons.timer_rounded,
                  label: 'Build Time',
                  value: '${lastBuildTime.toStringAsFixed(2)}ms',
                  color: lastBuildTime < 16 ? Colors.green : Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PerfMetric extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _PerfMetric({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        SizedBox(height: AppDimens.paddingXS),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }
}

/// Provider statistics card
class _ProviderStatsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = context.isDarkMode;
    final topProviders = ProviderLogger.getTopProviders(limit: 5);
    final totalUpdates = ProviderLogger.updateCount;

    return Container(
      padding: EdgeInsets.all(AppDimens.paddingL),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(AppDimens.radiusL),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.sync_rounded, color: Colors.purple, size: 20),
                  SizedBox(width: AppDimens.paddingS),
                  Text(
                    'Total Updates: $totalUpdates',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: () {
                  ProviderLogger.reset();
                },
                icon: const Icon(Icons.restart_alt_rounded, size: 16),
                label: const Text('Reset'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.orange,
                  padding: EdgeInsets.symmetric(
                    horizontal: AppDimens.paddingS,
                  ),
                ),
              ),
            ],
          ),
          if (topProviders.isNotEmpty) ...[
            SizedBox(height: AppDimens.paddingM),
            Divider(height: 1, color: theme.colorScheme.outline.withOpacity(0.1)),
            SizedBox(height: AppDimens.paddingM),
            Text(
              'Most Active Providers',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
            SizedBox(height: AppDimens.paddingS),
            ...topProviders.map((entry) => Padding(
              padding: EdgeInsets.only(bottom: AppDimens.paddingXS),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _formatProviderName(entry.key),
                      style: theme.textTheme.bodySmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppDimens.paddingS,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: _getUpdateColor(entry.value).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(AppDimens.radiusXS),
                    ),
                    child: Text(
                      '${entry.value}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _getUpdateColor(entry.value),
                      ),
                    ),
                  ),
                ],
              ),
            )),
          ] else
            Padding(
              padding: EdgeInsets.symmetric(vertical: AppDimens.paddingM),
              child: Text(
                'No provider updates yet',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatProviderName(String name) {
    // Remove 'Provider' suffix and format
    return name
        .replaceAll('Provider', '')
        .replaceAll('AutoDispose', '')
        .replaceAll('<', '')
        .replaceAll('>', '');
  }

  Color _getUpdateColor(int count) {
    if (count > 50) return Colors.red;
    if (count > 20) return Colors.orange;
    if (count > 10) return Colors.amber;
    return Colors.green;
  }
}

