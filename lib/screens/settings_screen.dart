import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/water_entry.dart';
import '../providers/providers.dart';
import '../theme/app_theme.dart';
import 'debug_screen.dart';

/// Settings screen - Configure app preferences
/// 
/// Allows users to:
/// - Set daily water goal
/// - Choose measurement units (L/oz)
/// - Toggle dark mode
/// - Configure notifications
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
        elevation: 0,
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.all(AppDimens.paddingL),
        children: [
          // Daily Goal Section
          const _SectionHeader(title: 'Daily Goal'),
          _buildDailyGoalCard(context, ref, settings),
          SizedBox(height: AppDimens.paddingXXL),

          // Units Section
          const _SectionHeader(title: 'Measurement Units'),
          _buildUnitsCard(context, ref, settings),
          SizedBox(height: AppDimens.paddingXXL),

          // Appearance Section
          const _SectionHeader(title: 'Appearance'),
          _buildAppearanceCard(context, ref, settings),
          SizedBox(height: AppDimens.paddingXXL),

          // Notifications Section
          const _SectionHeader(title: 'Notifications'),
          _buildNotificationsCard(context, ref, settings),
          SizedBox(height: AppDimens.paddingXXL),

          // Data Section
          const _SectionHeader(title: 'Data'),
          _buildDataCard(context, ref),
          SizedBox(height: AppDimens.paddingXXL),

          // About Section
          const _SectionHeader(title: 'About'),
          _buildAboutCard(context),
          SizedBox(height: AppDimens.paddingXXXL),
        ],
      ),
    );
  }

  Widget _buildDailyGoalCard(
    BuildContext context, 
    WidgetRef ref, 
    UserSettings settings,
  ) {
    final theme = Theme.of(context);
    
    // Display goal in user's preferred units
    final displayGoal = settings.useMetricUnits 
        ? (settings.dailyGoalMl / 1000) 
        : (settings.dailyGoalMl * 0.033814);
    final unit = settings.useMetricUnits ? 'L' : 'oz';

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Current Goal',
                  style: theme.textTheme.titleMedium,
                ),
                Text(
                  '${displayGoal.toStringAsFixed(1)} $unit',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Preset buttons
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _GoalPresetButton(
                  label: settings.useMetricUnits ? '1.5L' : '50oz',
                  goalMl: settings.useMetricUnits ? 1500 : 1478.67,
                  isSelected: (settings.dailyGoalMl - (settings.useMetricUnits ? 1500 : 1478.67)).abs() < 10,
                ),
                _GoalPresetButton(
                  label: settings.useMetricUnits ? '2L' : '64oz',
                  goalMl: settings.useMetricUnits ? 2000 : 1892.71,
                  isSelected: (settings.dailyGoalMl - (settings.useMetricUnits ? 2000 : 1892.71)).abs() < 10,
                ),
                _GoalPresetButton(
                  label: settings.useMetricUnits ? '2.5L' : '84oz',
                  goalMl: settings.useMetricUnits ? 2500 : 2485.49,
                  isSelected: (settings.dailyGoalMl - (settings.useMetricUnits ? 2500 : 2485.49)).abs() < 10,
                ),
                _GoalPresetButton(
                  label: settings.useMetricUnits ? '3L' : '100oz',
                  goalMl: settings.useMetricUnits ? 3000 : 2957.35,
                  isSelected: (settings.dailyGoalMl - (settings.useMetricUnits ? 3000 : 2957.35)).abs() < 10,
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Custom goal button
            OutlinedButton.icon(
              onPressed: () => _showCustomGoalDialog(context, ref, settings),
              icon: const Icon(Icons.edit),
              label: const Text('Set Custom Goal'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnitsCard(
    BuildContext context, 
    WidgetRef ref, 
    UserSettings settings,
  ) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            RadioListTile<bool>(
              title: const Text('Metric (Liters, ml)'),
              subtitle: const Text('Standard in most countries'),
              value: true,
              groupValue: settings.useMetricUnits,
              onChanged: (value) {
                if (value != null) {
                  ref.read(settingsProvider.notifier).toggleUnitSystem(value);
                }
              },
            ),
            RadioListTile<bool>(
              title: const Text('Imperial (Ounces, oz)'),
              subtitle: const Text('Used in US'),
              value: false,
              groupValue: settings.useMetricUnits,
              onChanged: (value) {
                if (value != null) {
                  ref.read(settingsProvider.notifier).toggleUnitSystem(value);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppearanceCard(
    BuildContext context, 
    WidgetRef ref, 
    UserSettings settings,
  ) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest,
      child: SwitchListTile(
        title: const Text('Dark Mode'),
        subtitle: Text(settings.isDarkMode ? 'Dark theme enabled' : 'Light theme enabled'),
        secondary: Icon(
          settings.isDarkMode ? Icons.dark_mode : Icons.light_mode,
          color: theme.colorScheme.primary,
        ),
        value: settings.isDarkMode,
        onChanged: (value) {
          ref.read(settingsProvider.notifier).toggleDarkMode(value);
        },
      ),
    );
  }

  Widget _buildNotificationsCard(
    BuildContext context, 
    WidgetRef ref, 
    UserSettings settings,
  ) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest,
      child: Column(
        children: [
          SwitchListTile(
            title: const Text('Water Reminders'),
            subtitle: Text(
              settings.notificationsEnabled 
                  ? 'Reminders every ${settings.reminderIntervalMinutes} minutes'
                  : 'Reminders disabled',
            ),
            secondary: Icon(
              settings.notificationsEnabled 
                  ? Icons.notifications_active 
                  : Icons.notifications_off,
              color: theme.colorScheme.primary,
            ),
            value: settings.notificationsEnabled,
            onChanged: (value) async {
              if (value) {
                // Request permission first
                final notificationService = ref.read(notificationServiceProvider);
                final granted = await notificationService.requestPermissions();
                
                if (granted) {
                  await ref.read(settingsProvider.notifier).updateNotificationSettings(
                    enabled: true,
                    intervalMinutes: settings.reminderIntervalMinutes,
                  );
                  
                  // Schedule reminders
                  await notificationService.scheduleReminders(
                    intervalMinutes: settings.reminderIntervalMinutes,
                  );
                } else {
                  // Show permission denied message
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Notification permission denied'),
                      ),
                    );
                  }
                }
              } else {
                // Disable notifications
                await ref.read(settingsProvider.notifier).updateNotificationSettings(
                  enabled: false,
                );
                final notificationService = ref.read(notificationServiceProvider);
                await notificationService.cancelAllReminders();
              }
            },
          ),
          if (settings.notificationsEnabled)
            ListTile(
              title: const Text('Reminder Interval'),
              subtitle: Text('Every ${settings.reminderIntervalMinutes} minutes'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showReminderIntervalDialog(context, ref, settings),
            ),
          // Test notification button
          ListTile(
            title: const Text('Test Notification'),
            subtitle: const Text('Send a test notification'),
            leading: const Icon(Icons.send),
            onTap: () async {
              final notificationService = ref.read(notificationServiceProvider);
              await notificationService.showTestNotification();
              
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Test notification sent!')),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDataCard(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest,
      child: Column(
        children: [
          ListTile(
            title: const Text('Export Data'),
            subtitle: const Text('Export your water tracking history'),
            leading: const Icon(Icons.download),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Implement data export
              // Export as CSV or JSON
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Export feature coming soon!')),
              );
            },
          ),
          ListTile(
            title: Text(
              'Clear All Data',
              style: TextStyle(color: theme.colorScheme.error),
            ),
            subtitle: const Text('Delete all entries and reset settings'),
            leading: Icon(Icons.delete_forever, color: theme.colorScheme.error),
            onTap: () => _showClearDataDialog(context, ref),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutCard(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest,
      child: Column(
        children: [
          _VersionTile(),
          const ListTile(
            title: Text('Made with 💙'),
            subtitle: Text('Stay hydrated, stay healthy!'),
          ),
        ],
      ),
    );
  }


  void _showCustomGoalDialog(
    BuildContext context, 
    WidgetRef ref, 
    UserSettings settings,
  ) {
    final controller = TextEditingController();
    final useMetric = settings.useMetricUnits;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Custom Goal'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'Daily Goal',
            suffixText: useMetric ? 'L' : 'oz',
            border: const OutlineInputBorder(),
            hintText: useMetric ? 'e.g., 2.5' : 'e.g., 64',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final value = double.tryParse(controller.text);
              if (value != null && value > 0) {
                // Convert to ml
                final goalMl = useMetric ? value * 1000 : value / 0.033814;
                ref.read(settingsProvider.notifier).updateDailyGoal(goalMl);
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showReminderIntervalDialog(
    BuildContext context, 
    WidgetRef ref, 
    UserSettings settings,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reminder Interval'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _IntervalOption(interval: 30, currentInterval: settings.reminderIntervalMinutes, ref: ref),
            _IntervalOption(interval: 60, currentInterval: settings.reminderIntervalMinutes, ref: ref),
            _IntervalOption(interval: 90, currentInterval: settings.reminderIntervalMinutes, ref: ref),
            _IntervalOption(interval: 120, currentInterval: settings.reminderIntervalMinutes, ref: ref),
          ],
        ),
      ),
    );
  }

  void _showClearDataDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data?'),
        content: const Text(
          'This will permanently delete all your water tracking history and reset settings. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () async {
              final storageService = ref.read(storageServiceProvider);
              await storageService.clearAllData();
              
              // Refresh providers
              ref.read(settingsProvider.notifier).refresh();
              ref.read(todayEntriesProvider.notifier).refresh();
              
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All data cleared')),
                );
              }
            },
            child: const Text('Clear Data'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _GoalPresetButton extends ConsumerWidget {
  final String label;
  final double goalMl;
  final bool isSelected;

  const _GoalPresetButton({
    required this.label,
    required this.goalMl,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          ref.read(settingsProvider.notifier).updateDailyGoal(goalMl);
        }
      },
      selectedColor: theme.colorScheme.primaryContainer,
      labelStyle: TextStyle(
        color: isSelected 
            ? theme.colorScheme.onPrimaryContainer 
            : theme.colorScheme.onSurface,
      ),
    );
  }
}

class _IntervalOption extends StatelessWidget {
  final int interval;
  final int currentInterval;
  final WidgetRef ref;

  const _IntervalOption({
    required this.interval,
    required this.currentInterval,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    return RadioListTile<int>(
      title: Text('Every $interval minutes'),
      value: interval,
      groupValue: currentInterval,
      onChanged: (value) async {
        if (value != null) {
          await ref.read(settingsProvider.notifier).updateNotificationSettings(
            enabled: true,
            intervalMinutes: value,
          );
          
          // Reschedule notifications
          final notificationService = ref.read(notificationServiceProvider);
          await notificationService.scheduleReminders(intervalMinutes: value);
          
          if (context.mounted) {
            Navigator.pop(context);
          }
        }
      },
    );
  }
}

/// Version tile that unlocks debug menu after tapping 7 times
class _VersionTile extends StatefulWidget {
  @override
  State<_VersionTile> createState() => _VersionTileState();
}

class _VersionTileState extends State<_VersionTile> {
  int _tapCount = 0;
  bool _debugUnlocked = false;
  DateTime? _lastTap;

  void _handleTap() {
    final now = DateTime.now();
    
    // Reset count if more than 2 seconds since last tap
    if (_lastTap != null && now.difference(_lastTap!) > const Duration(seconds: 2)) {
      _tapCount = 0;
    }
    _lastTap = now;
    
    setState(() {
      _tapCount++;
    });

    if (_tapCount >= 7 && !_debugUnlocked) {
      setState(() {
        _debugUnlocked = true;
      });
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🔧 Debug menu unlocked!'),
          duration: Duration(seconds: 2),
        ),
      );
    } else if (_tapCount >= 4 && !_debugUnlocked) {
      HapticFeedback.lightImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${7 - _tapCount} more taps to unlock debug menu'),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        ListTile(
          title: const Text('AquaTrack'),
          subtitle: Text(_debugUnlocked ? 'Version 1.0.0 (Debug)' : 'Version 1.0.0'),
          leading: Icon(
            Icons.water_drop,
            color: theme.colorScheme.primary,
          ),
          onTap: _handleTap,
        ),
        if (_debugUnlocked)
          ListTile(
            title: const Text('🔧 Debug Menu'),
            subtitle: const Text('Developer tools & testing'),
            leading: const Icon(
              Icons.bug_report_rounded,
              color: Colors.orange,
            ),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const DebugScreen()),
              );
            },
          ),
      ],
    );
  }
}

