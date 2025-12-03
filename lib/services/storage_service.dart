import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/water_entry.dart';

/// Service for managing local storage using Hive
/// 
/// Handles all CRUD operations for water entries and user settings.
/// Uses Hive boxes for efficient local storage.
class StorageService {
  static const String _waterEntriesBoxName = 'water_entries';
  static const String _settingsBoxName = 'user_settings';
  static const String _settingsKey = 'settings';

  late Box<WaterEntry> _waterEntriesBox;
  late Box<UserSettings> _settingsBox;

  final Uuid _uuid = const Uuid();

  /// Initialize Hive and open boxes
  /// 
  /// Call this method before using any other storage methods.
  /// Typically called in main.dart before runApp().
  Future<void> init() async {
    await Hive.initFlutter();
    
    // Register adapters
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(WaterEntryAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(UserSettingsAdapter());
    }

    // Open boxes
    _waterEntriesBox = await Hive.openBox<WaterEntry>(_waterEntriesBoxName);
    _settingsBox = await Hive.openBox<UserSettings>(_settingsBoxName);

    // Initialize default settings if not exists
    if (_settingsBox.get(_settingsKey) == null) {
      await _settingsBox.put(_settingsKey, UserSettings());
    }
  }

  // ==================== WATER ENTRIES ====================

  /// Add a new water entry
  Future<WaterEntry> addWaterEntry(double amountMl, {String? note}) async {
    final entry = WaterEntry(
      id: _uuid.v4(),
      amountMl: amountMl,
      timestamp: DateTime.now(),
      note: note,
    );
    
    await _waterEntriesBox.put(entry.id, entry);
    
    // TODO: Update streak calculation here
    // Call _updateStreak() after adding entry
    
    return entry;
  }

  /// Get all water entries
  List<WaterEntry> getAllEntries() {
    return _waterEntriesBox.values.toList();
  }

  /// Get water entries for a specific date
  List<WaterEntry> getEntriesForDate(DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _waterEntriesBox.values.where((entry) {
      return entry.timestamp.isAfter(startOfDay) && 
             entry.timestamp.isBefore(endOfDay);
    }).toList();
  }

  /// Get today's water entries
  List<WaterEntry> getTodayEntries() {
    return getEntriesForDate(DateTime.now());
  }

  /// Get total water intake for today in milliliters
  double getTodayTotalMl() {
    return getTodayEntries().fold(0.0, (sum, entry) => sum + entry.amountMl);
  }

  /// Get total water intake for a specific date
  double getTotalForDate(DateTime date) {
    return getEntriesForDate(date).fold(0.0, (sum, entry) => sum + entry.amountMl);
  }

  /// Delete a water entry
  Future<void> deleteEntry(String id) async {
    await _waterEntriesBox.delete(id);
  }

  /// Update a water entry
  Future<void> updateEntry(WaterEntry entry) async {
    await _waterEntriesBox.put(entry.id, entry);
  }

  /// Get daily summaries for history view
  /// Returns summaries for the last [days] days
  List<DailySummary> getDailySummaries({int days = 30}) {
    final summaries = <DailySummary>[];
    final settings = getSettings();
    final now = DateTime.now();

    for (int i = 0; i < days; i++) {
      final date = DateTime(now.year, now.month, now.day - i);
      final entries = getEntriesForDate(date);
      final totalMl = entries.fold(0.0, (sum, entry) => sum + entry.amountMl);

      summaries.add(DailySummary(
        date: date,
        totalAmountMl: totalMl,
        goalMl: settings.dailyGoalMl,
        entryCount: entries.length,
      ));
    }

    return summaries;
  }

  // ==================== USER SETTINGS ====================

  /// Get user settings
  UserSettings getSettings() {
    return _settingsBox.get(_settingsKey) ?? UserSettings();
  }

  /// Update user settings
  Future<void> updateSettings(UserSettings settings) async {
    await _settingsBox.put(_settingsKey, settings);
  }

  /// Update daily goal
  Future<void> updateDailyGoal(double goalMl) async {
    final settings = getSettings();
    final updated = UserSettings(
      dailyGoalMl: goalMl,
      useMetricUnits: settings.useMetricUnits,
      notificationsEnabled: settings.notificationsEnabled,
      reminderIntervalMinutes: settings.reminderIntervalMinutes,
      isDarkMode: settings.isDarkMode,
      currentStreak: settings.currentStreak,
      longestStreak: settings.longestStreak,
      lastActiveDate: settings.lastActiveDate,
    );
    await updateSettings(updated);
  }

  /// Toggle dark mode
  Future<void> toggleDarkMode(bool isDark) async {
    final settings = getSettings();
    final updated = UserSettings(
      dailyGoalMl: settings.dailyGoalMl,
      useMetricUnits: settings.useMetricUnits,
      notificationsEnabled: settings.notificationsEnabled,
      reminderIntervalMinutes: settings.reminderIntervalMinutes,
      isDarkMode: isDark,
      currentStreak: settings.currentStreak,
      longestStreak: settings.longestStreak,
      lastActiveDate: settings.lastActiveDate,
    );
    await updateSettings(updated);
  }

  /// Toggle unit system (metric/imperial)
  Future<void> toggleUnitSystem(bool useMetric) async {
    final settings = getSettings();
    final updated = UserSettings(
      dailyGoalMl: settings.dailyGoalMl,
      useMetricUnits: useMetric,
      notificationsEnabled: settings.notificationsEnabled,
      reminderIntervalMinutes: settings.reminderIntervalMinutes,
      isDarkMode: settings.isDarkMode,
      currentStreak: settings.currentStreak,
      longestStreak: settings.longestStreak,
      lastActiveDate: settings.lastActiveDate,
    );
    await updateSettings(updated);
  }

  // ==================== STREAK MANAGEMENT ====================

  /// Update streak based on current activity
  /// 
  /// TODO: Implement full streak logic:
  /// 1. Check if today's goal was reached
  /// 2. Check if yesterday's goal was reached (for streak continuity)
  /// 3. Update currentStreak and longestStreak accordingly
  /// 4. Store lastActiveDate
  Future<void> updateStreak() async {
    final settings = getSettings();
    final todayTotal = getTodayTotalMl();
    final goalReached = todayTotal >= settings.dailyGoalMl;

    if (goalReached) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final lastActive = settings.lastActiveDate;

      int newStreak = settings.currentStreak;

      if (lastActive == null) {
        // First time reaching goal
        newStreak = 1;
      } else {
        final lastActiveDay = DateTime(
          lastActive.year, 
          lastActive.month, 
          lastActive.day
        );
        final difference = today.difference(lastActiveDay).inDays;

        if (difference == 0) {
          // Same day, streak unchanged
        } else if (difference == 1) {
          // Consecutive day, increment streak
          newStreak = settings.currentStreak + 1;
        } else {
          // Streak broken, reset to 1
          newStreak = 1;
        }
      }

      final newLongest = newStreak > settings.longestStreak 
          ? newStreak 
          : settings.longestStreak;

      final updated = UserSettings(
        dailyGoalMl: settings.dailyGoalMl,
        useMetricUnits: settings.useMetricUnits,
        notificationsEnabled: settings.notificationsEnabled,
        reminderIntervalMinutes: settings.reminderIntervalMinutes,
        isDarkMode: settings.isDarkMode,
        currentStreak: newStreak,
        longestStreak: newLongest,
        lastActiveDate: today,
      );
      await updateSettings(updated);
    }
  }

  /// Clear all data (for testing or reset)
  Future<void> clearAllData() async {
    await _waterEntriesBox.clear();
    await _settingsBox.clear();
    await _settingsBox.put(_settingsKey, UserSettings());
  }
}

