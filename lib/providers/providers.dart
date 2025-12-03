import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/water_entry.dart';
import '../models/container.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';

// ==================== SERVICE PROVIDERS ====================

/// Provider for StorageService singleton
final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

/// Provider for NotificationService singleton
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

// ==================== SETTINGS PROVIDERS ====================

/// Provider for user settings
/// 
/// Manages all user preferences including theme, units, and goals.
final settingsProvider = StateNotifierProvider<SettingsNotifier, UserSettings>((ref) {
  final storageService = ref.watch(storageServiceProvider);
  return SettingsNotifier(storageService);
});

class SettingsNotifier extends StateNotifier<UserSettings> {
  final StorageService _storageService;

  SettingsNotifier(this._storageService) : super(UserSettings()) {
    _loadSettings();
  }

  void _loadSettings() {
    state = _storageService.getSettings();
  }

  /// Update daily water goal
  Future<void> updateDailyGoal(double goalMl) async {
    await _storageService.updateDailyGoal(goalMl);
    state = _storageService.getSettings();
  }

  /// Toggle dark mode
  Future<void> toggleDarkMode(bool isDark) async {
    await _storageService.toggleDarkMode(isDark);
    state = _storageService.getSettings();
  }

  /// Toggle unit system (metric/imperial)
  Future<void> toggleUnitSystem(bool useMetric) async {
    await _storageService.toggleUnitSystem(useMetric);
    state = _storageService.getSettings();
  }

  /// Update notification settings
  Future<void> updateNotificationSettings({
    required bool enabled,
    int intervalMinutes = 60,
  }) async {
    final current = state;
    final updated = UserSettings(
      dailyGoalMl: current.dailyGoalMl,
      useMetricUnits: current.useMetricUnits,
      notificationsEnabled: enabled,
      reminderIntervalMinutes: intervalMinutes,
      isDarkMode: current.isDarkMode,
      currentStreak: current.currentStreak,
      longestStreak: current.longestStreak,
      lastActiveDate: current.lastActiveDate,
    );
    await _storageService.updateSettings(updated);
    state = _storageService.getSettings();
  }

  /// Refresh settings from storage
  void refresh() {
    _loadSettings();
  }
}

// ==================== WATER ENTRIES PROVIDERS ====================

/// Provider for today's water entries
final todayEntriesProvider = StateNotifierProvider<WaterEntriesNotifier, List<WaterEntry>>((ref) {
  final storageService = ref.watch(storageServiceProvider);
  return WaterEntriesNotifier(storageService, ref);
});

class WaterEntriesNotifier extends StateNotifier<List<WaterEntry>> {
  final StorageService _storageService;
  final Ref _ref;

  WaterEntriesNotifier(this._storageService, this._ref) : super([]) {
    _loadTodayEntries();
  }

  void _loadTodayEntries() {
    state = _storageService.getTodayEntries();
  }

  /// Add a new water entry
  Future<void> addEntry(double amountMl, {String? note}) async {
    await _storageService.addWaterEntry(amountMl, note: note);
    _loadTodayEntries();
    
    // Update streak after adding entry
    await _storageService.updateStreak();
    _ref.read(settingsProvider.notifier).refresh();
  }

  /// Delete an entry
  Future<void> deleteEntry(String id) async {
    await _storageService.deleteEntry(id);
    _loadTodayEntries();
  }

  /// Refresh entries
  void refresh() {
    _loadTodayEntries();
  }
}

/// Provider for today's total water intake in ml
final todayTotalProvider = Provider<double>((ref) {
  final entries = ref.watch(todayEntriesProvider);
  return entries.fold(0.0, (sum, entry) => sum + entry.amountMl);
});

/// Provider for today's progress percentage (0.0 to 1.0)
final todayProgressProvider = Provider<double>((ref) {
  final total = ref.watch(todayTotalProvider);
  final settings = ref.watch(settingsProvider);
  if (settings.dailyGoalMl <= 0) return 0.0;
  return (total / settings.dailyGoalMl).clamp(0.0, 1.0);
});

/// Provider for today's progress percentage uncapped (can exceed 1.0)
final todayProgressUncappedProvider = Provider<double>((ref) {
  final total = ref.watch(todayTotalProvider);
  final settings = ref.watch(settingsProvider);
  if (settings.dailyGoalMl <= 0) return 0.0;
  return total / settings.dailyGoalMl;
});

// ==================== HISTORY PROVIDERS ====================

/// Provider for daily summaries (history)
final dailySummariesProvider = Provider<List<DailySummary>>((ref) {
  final storageService = ref.watch(storageServiceProvider);
  // Refresh when entries change
  ref.watch(todayEntriesProvider);
  return storageService.getDailySummaries(days: 30);
});

/// Provider for weekly chart data (last 7 days)
final weeklyChartDataProvider = Provider<WeeklyChartData>((ref) {
  final storageService = ref.watch(storageServiceProvider);
  final settings = ref.watch(settingsProvider);
  // Refresh when entries change
  ref.watch(todayEntriesProvider);
  
  final summaries = storageService.getDailySummaries(days: 7);
  final goal = settings.dailyGoalMl;
  
  // Calculate statistics
  final totalMl = summaries.fold(0.0, (sum, s) => sum + s.totalAmountMl);
  final daysWithData = summaries.where((s) => s.totalAmountMl > 0).length;
  final averageMl = daysWithData > 0 ? totalMl / daysWithData : 0.0;
  final goalsMet = summaries.where((s) => s.goalReached).length;
  final maxIntake = summaries.fold(0.0, (max, s) => s.totalAmountMl > max ? s.totalAmountMl : max);
  
  return WeeklyChartData(
    dailySummaries: summaries.reversed.toList(), // Oldest first for chart
    goalMl: goal,
    averageMl: averageMl,
    totalMl: totalMl,
    goalsMet: goalsMet,
    maxIntake: maxIntake,
  );
});

/// Weekly chart data model
class WeeklyChartData {
  final List<DailySummary> dailySummaries;
  final double goalMl;
  final double averageMl;
  final double totalMl;
  final int goalsMet;
  final double maxIntake;

  WeeklyChartData({
    required this.dailySummaries,
    required this.goalMl,
    required this.averageMl,
    required this.totalMl,
    required this.goalsMet,
    required this.maxIntake,
  });

  /// Get completion rate as percentage
  double get completionRate => dailySummaries.isNotEmpty 
      ? (goalsMet / dailySummaries.length) * 100 
      : 0;

  /// Get the max value for chart Y-axis (goal or max intake, whichever is higher)
  double get chartMaxY {
    final maxValue = maxIntake > goalMl ? maxIntake : goalMl;
    return (maxValue * 1.2).ceilToDouble(); // Add 20% padding
  }
}

// ==================== THEME PROVIDER ====================

/// Provider for app theme mode
final themeModeProvider = Provider<ThemeMode>((ref) {
  final settings = ref.watch(settingsProvider);
  return settings.isDarkMode ? ThemeMode.dark : ThemeMode.light;
});

// ==================== MOTIVATIONAL MESSAGE PROVIDER ====================

/// Provider for motivational message based on progress
final motivationalMessageProvider = Provider<String>((ref) {
  final progress = ref.watch(todayProgressUncappedProvider);
  final percentComplete = (progress * 100).toInt();

  if (percentComplete == 0) {
    return 'Start your hydration journey today! 💧';
  } else if (percentComplete < 25) {
    return 'Great start! Keep drinking! 🌱';
  } else if (percentComplete < 50) {
    return "You're making progress! Stay hydrated! 💪";
  } else if (percentComplete < 75) {
    return "Halfway there! You're doing amazing! 🌟";
  } else if (percentComplete < 100) {
    return 'Almost at your goal! Keep it up! 🎯';
  } else if (percentComplete == 100) {
    return "🎉 Goal reached! You're a hydration champion!";
  } else {
    return '🏆 Exceeding expectations! Incredible work!';
  }
});

// ==================== CONTAINER PROVIDERS ====================

/// Provider for all saved containers
final containersProvider = StateNotifierProvider<ContainersNotifier, List<WaterContainer>>((ref) {
  final storageService = ref.watch(storageServiceProvider);
  return ContainersNotifier(storageService);
});

class ContainersNotifier extends StateNotifier<List<WaterContainer>> {
  final StorageService _storageService;

  ContainersNotifier(this._storageService) : super([]) {
    _loadContainers();
  }

  void _loadContainers() {
    state = _storageService.getAllContainers();
  }

  /// Add a new container
  Future<WaterContainer> addContainer({
    required String name,
    required double amountMl,
    String icon = 'local_drink',
    int colorValue = 0xFF00B4D8,
    bool isDefault = true,
  }) async {
    final container = await _storageService.addContainer(
      name: name,
      amountMl: amountMl,
      icon: icon,
      colorValue: colorValue,
      isDefault: isDefault,
    );
    _loadContainers();
    return container;
  }

  /// Update an existing container
  Future<void> updateContainer(WaterContainer container) async {
    await _storageService.updateContainer(container);
    _loadContainers();
  }

  /// Delete a container
  Future<void> deleteContainer(String id) async {
    await _storageService.deleteContainer(id);
    _loadContainers();
  }

  /// Toggle container as quick-add default
  Future<void> toggleDefault(String id, bool isDefault) async {
    await _storageService.toggleContainerDefault(id, isDefault);
    _loadContainers();
  }

  /// Reset to default containers
  Future<void> resetToDefaults() async {
    await _storageService.resetContainersToDefault();
    _loadContainers();
  }

  /// Refresh containers
  void refresh() {
    _loadContainers();
  }
}

/// Provider for quick-add containers only
final quickAddContainersProvider = Provider<List<WaterContainer>>((ref) {
  final containers = ref.watch(containersProvider);
  return containers.where((c) => c.isDefault).toList();
});

// ==================== QUICK ADD AMOUNTS (Legacy - keeping for compatibility) ====================

/// Provider for quick-add button amounts based on unit preference
/// Note: Consider migrating to containersProvider for user-customizable amounts
final quickAddAmountsProvider = Provider<List<QuickAddAmount>>((ref) {
  final settings = ref.watch(settingsProvider);
  
  if (settings.useMetricUnits) {
    return [
      QuickAddAmount(label: '100ml', amountMl: 100),
      QuickAddAmount(label: '250ml', amountMl: 250),
      QuickAddAmount(label: '500ml', amountMl: 500),
      QuickAddAmount(label: '1L', amountMl: 1000),
    ];
  } else {
    return [
      QuickAddAmount(label: '4oz', amountMl: 118.294),
      QuickAddAmount(label: '8oz', amountMl: 236.588),
      QuickAddAmount(label: '16oz', amountMl: 473.176),
      QuickAddAmount(label: '32oz', amountMl: 946.353),
    ];
  }
});

/// Model for quick-add button amounts
class QuickAddAmount {
  final String label;
  final double amountMl;

  QuickAddAmount({required this.label, required this.amountMl});
}
