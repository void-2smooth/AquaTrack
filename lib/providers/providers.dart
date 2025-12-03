import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/water_entry.dart';
import '../models/container.dart';
import '../models/achievement.dart';
import '../models/challenge.dart';
import '../models/shop_item.dart';
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

  /// Update all settings at once (for debug)
  Future<void> updateSettings(UserSettings settings) async {
    await _storageService.updateSettings(settings);
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
  
  /// Track the last added entry for undo functionality
  WaterEntry? _lastAddedEntry;

  WaterEntriesNotifier(this._storageService, this._ref) : super([]) {
    _loadTodayEntries();
  }

  void _loadTodayEntries() {
    state = _storageService.getTodayEntries();
  }

  /// Get the last added entry (for undo)
  WaterEntry? get lastAddedEntry => _lastAddedEntry;

  /// Add a new water entry and track it for undo
  Future<WaterEntry> addEntry(double amountMl, {String? note}) async {
    // Get current total before adding (from state directly, not provider to avoid circular dep)
    final previousTotal = state.fold(0.0, (sum, e) => sum + e.amountMl);
    final settings = _ref.read(settingsProvider);
    final goal = settings.effectiveDailyGoalMl;
    final wasGoalReached = previousTotal >= goal;
    
    final entry = await _storageService.addWaterEntry(amountMl, note: note);
    _lastAddedEntry = entry;
    _loadTodayEntries();
    
    // Update streak after adding entry
    await _storageService.updateStreak();
    _ref.read(settingsProvider.notifier).refresh();
    
    // Notify undo provider of new entry
    _ref.read(undoProvider.notifier).setUndoableEntry(entry);
    
    // Check if goal was just reached (from state directly)
    final newTotal = state.fold(0.0, (sum, e) => sum + e.amountMl);
    if (!wasGoalReached && newTotal >= goal) {
      _ref.read(celebrationProvider.notifier).triggerGoalCelebration();
    }
    
    // Check and unlock achievements (defer to avoid blocking)
    _checkAchievementsAsync();
    
    // Check challenge progress
    _ref.read(activeChallengeProvider.notifier).checkProgress();
    
    return entry;
  }
  
  /// Check achievements asynchronously to avoid blocking the add flow
  void _checkAchievementsAsync() async {
    try {
      final newAchievements = await _ref.read(achievementsProvider.notifier).checkAndUnlockAchievements();
      if (newAchievements.isNotEmpty) {
        _ref.read(celebrationProvider.notifier).triggerAchievementCelebration(newAchievements.first);
      }
    } catch (e) {
      // Silently handle achievement check errors to not break the main flow
      debugPrint('Achievement check error: $e');
    }
  }

  /// Undo the last added entry
  Future<bool> undoLastEntry() async {
    if (_lastAddedEntry == null) return false;
    
    await _storageService.deleteEntry(_lastAddedEntry!.id);
    _lastAddedEntry = null;
    _loadTodayEntries();
    
    // Refresh settings (streak might change)
    _ref.read(settingsProvider.notifier).refresh();
    
    return true;
  }

  /// Delete an entry
  Future<void> deleteEntry(String id) async {
    await _storageService.deleteEntry(id);
    // Clear last added entry if it was the one deleted
    if (_lastAddedEntry?.id == id) {
      _lastAddedEntry = null;
    }
    _loadTodayEntries();
  }

  /// Refresh entries
  void refresh() {
    _loadTodayEntries();
  }
  
  /// Clear the last added entry reference (called when undo expires)
  void clearLastEntry() {
    _lastAddedEntry = null;
  }
}

// ==================== UNDO PROVIDER ====================

/// State for undo functionality
class UndoState {
  final WaterEntry? entry;
  final bool canUndo;
  final DateTime? addedAt;

  const UndoState({
    this.entry,
    this.canUndo = false,
    this.addedAt,
  });

  UndoState copyWith({
    WaterEntry? entry,
    bool? canUndo,
    DateTime? addedAt,
  }) {
    return UndoState(
      entry: entry ?? this.entry,
      canUndo: canUndo ?? this.canUndo,
      addedAt: addedAt ?? this.addedAt,
    );
  }
}

/// Provider for managing undo state
final undoProvider = StateNotifierProvider<UndoNotifier, UndoState>((ref) {
  return UndoNotifier(ref);
});

class UndoNotifier extends StateNotifier<UndoState> {
  final Ref _ref;
  static const Duration undoTimeout = Duration(seconds: 10);

  UndoNotifier(this._ref) : super(const UndoState());

  /// Set a new undoable entry
  void setUndoableEntry(WaterEntry entry) {
    state = UndoState(
      entry: entry,
      canUndo: true,
      addedAt: DateTime.now(),
    );
  }

  /// Check if undo is still valid (within timeout)
  bool get isUndoValid {
    if (!state.canUndo || state.addedAt == null) return false;
    return DateTime.now().difference(state.addedAt!) < undoTimeout;
  }

  /// Perform undo action
  Future<bool> undo() async {
    if (!isUndoValid) {
      clearUndo();
      return false;
    }

    final success = await _ref.read(todayEntriesProvider.notifier).undoLastEntry();
    if (success) {
      clearUndo();
    }
    return success;
  }

  /// Clear undo state
  void clearUndo() {
    state = const UndoState();
    _ref.read(todayEntriesProvider.notifier).clearLastEntry();
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
  final goal = settings.effectiveDailyGoalMl;
  if (goal <= 0) return 0.0;
  return (total / goal).clamp(0.0, 1.0);
});

/// Provider for today's progress percentage uncapped (can exceed 1.0)
final todayProgressUncappedProvider = Provider<double>((ref) {
  final total = ref.watch(todayTotalProvider);
  final settings = ref.watch(settingsProvider);
  final goal = settings.effectiveDailyGoalMl;
  if (goal <= 0) return 0.0;
  return total / goal;
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
  final goal = settings.effectiveDailyGoalMl;
  
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

// ==================== ACHIEVEMENTS PROVIDERS ====================

/// Provider for achievements state
final achievementsProvider = StateNotifierProvider<AchievementsNotifier, AchievementsState>((ref) {
  final storageService = ref.watch(storageServiceProvider);
  return AchievementsNotifier(storageService, ref);
});

/// State class for achievements
class AchievementsState {
  final List<UnlockedAchievement> unlockedAchievements;
  final AchievementDefinition? newlyUnlocked;
  final bool showingCelebration;

  const AchievementsState({
    this.unlockedAchievements = const [],
    this.newlyUnlocked,
    this.showingCelebration = false,
  });

  AchievementsState copyWith({
    List<UnlockedAchievement>? unlockedAchievements,
    AchievementDefinition? newlyUnlocked,
    bool? showingCelebration,
    bool clearNewlyUnlocked = false,
  }) {
    return AchievementsState(
      unlockedAchievements: unlockedAchievements ?? this.unlockedAchievements,
      newlyUnlocked: clearNewlyUnlocked ? null : (newlyUnlocked ?? this.newlyUnlocked),
      showingCelebration: showingCelebration ?? this.showingCelebration,
    );
  }

  int get totalUnlocked => unlockedAchievements.length;
  int get totalAchievements => Achievements.all.length;
  double get progressPercentage => totalAchievements > 0 
      ? (totalUnlocked / totalAchievements) * 100 
      : 0;

  bool isUnlocked(String achievementId) {
    return unlockedAchievements.any((a) => a.achievementId == achievementId);
  }
}

class AchievementsNotifier extends StateNotifier<AchievementsState> {
  final StorageService _storageService;
  final Ref _ref;

  AchievementsNotifier(this._storageService, this._ref) : super(const AchievementsState()) {
    _loadAchievements();
  }

  void _loadAchievements() {
    final unlocked = _storageService.getUnlockedAchievements();
    state = state.copyWith(unlockedAchievements: unlocked);
  }

  /// Check and unlock achievements based on current stats
  Future<List<AchievementDefinition>> checkAndUnlockAchievements() async {
    final newlyUnlocked = <AchievementDefinition>[];
    
    final settings = _ref.read(settingsProvider);
    // Get entries directly from storage to avoid circular dependencies
    final entries = _storageService.getTodayEntries();
    final todayTotal = entries.fold(0.0, (sum, e) => sum + e.amountMl);
    final totalLogged = _storageService.getTotalWaterLogged();
    final entryCount = _storageService.getTotalEntryCount();
    final streak = settings.currentStreak;
    final goalMl = settings.effectiveDailyGoalMl;

    // Check first drop
    if (entryCount >= 1) {
      final unlocked = await _tryUnlock(Achievements.firstDrop);
      if (unlocked != null) newlyUnlocked.add(unlocked);
    }

    // Check hydration hero (first goal completion)
    if (todayTotal >= goalMl) {
      final unlocked = await _tryUnlock(Achievements.hydrationHero);
      if (unlocked != null) newlyUnlocked.add(unlocked);
    }

    // Check overachiever (150% of goal)
    if (todayTotal >= goalMl * 1.5) {
      final unlocked = await _tryUnlock(Achievements.overachiever);
      if (unlocked != null) newlyUnlocked.add(unlocked);
    }

    // Check hydration master (100L total)
    if (totalLogged >= 100000) {
      final unlocked = await _tryUnlock(Achievements.hydrationMaster);
      if (unlocked != null) newlyUnlocked.add(unlocked);
    }

    // Check streak achievements
    if (streak >= 3) {
      final unlocked = await _tryUnlock(Achievements.streak3);
      if (unlocked != null) newlyUnlocked.add(unlocked);
    }
    if (streak >= 7) {
      final unlocked = await _tryUnlock(Achievements.streak7);
      if (unlocked != null) newlyUnlocked.add(unlocked);
    }
    if (streak >= 14) {
      final unlocked = await _tryUnlock(Achievements.streak14);
      if (unlocked != null) newlyUnlocked.add(unlocked);
    }
    if (streak >= 30) {
      final unlocked = await _tryUnlock(Achievements.streak30);
      if (unlocked != null) newlyUnlocked.add(unlocked);
    }
    if (streak >= 100) {
      final unlocked = await _tryUnlock(Achievements.streak100);
      if (unlocked != null) newlyUnlocked.add(unlocked);
    }

    // Check time-based achievements
    if (entries.isNotEmpty) {
      final now = DateTime.now();
      final hasEarlyEntry = entries.any((e) => e.timestamp.hour < 7);
      final hasLateEntry = entries.any((e) => e.timestamp.hour >= 22);
      final completedBeforeNoon = todayTotal >= goalMl && now.hour < 12;

      if (hasEarlyEntry) {
        final unlocked = await _tryUnlock(Achievements.earlyBird);
        if (unlocked != null) newlyUnlocked.add(unlocked);
      }
      if (hasLateEntry) {
        final unlocked = await _tryUnlock(Achievements.nightOwl);
        if (unlocked != null) newlyUnlocked.add(unlocked);
      }
      if (completedBeforeNoon) {
        final unlocked = await _tryUnlock(Achievements.speedDrinker);
        if (unlocked != null) newlyUnlocked.add(unlocked);
      }
    }

    // Check milestone achievements
    if (entryCount >= 10) {
      final unlocked = await _tryUnlock(Achievements.logs10);
      if (unlocked != null) newlyUnlocked.add(unlocked);
    }
    if (entryCount >= 100) {
      final unlocked = await _tryUnlock(Achievements.logs100);
      if (unlocked != null) newlyUnlocked.add(unlocked);
    }
    if (entryCount >= 500) {
      final unlocked = await _tryUnlock(Achievements.logs500);
      if (unlocked != null) newlyUnlocked.add(unlocked);
    }
    if (entryCount >= 1000) {
      final unlocked = await _tryUnlock(Achievements.logs1000);
      if (unlocked != null) newlyUnlocked.add(unlocked);
    }

    // Check perfect week/month based on streak
    if (streak >= 7) {
      final unlocked = await _tryUnlock(Achievements.perfectWeek);
      if (unlocked != null) newlyUnlocked.add(unlocked);
    }
    if (streak >= 30) {
      final unlocked = await _tryUnlock(Achievements.perfectMonth);
      if (unlocked != null) newlyUnlocked.add(unlocked);
    }

    // Update state with first newly unlocked achievement
    if (newlyUnlocked.isNotEmpty) {
      _loadAchievements();
      state = state.copyWith(
        newlyUnlocked: newlyUnlocked.first,
        showingCelebration: true,
      );
    }

    return newlyUnlocked;
  }

  Future<AchievementDefinition?> _tryUnlock(AchievementDefinition achievement) async {
    if (state.isUnlocked(achievement.id)) return null;
    
    final unlocked = await _storageService.unlockAchievement(achievement.id);
    if (unlocked != null) {
      return achievement;
    }
    return null;
  }

  /// Clear the newly unlocked achievement (after showing celebration)
  void clearNewlyUnlocked() {
    state = state.copyWith(clearNewlyUnlocked: true, showingCelebration: false);
  }

  /// Mark achievement as seen
  Future<void> markSeen(String achievementId) async {
    await _storageService.markAchievementSeen(achievementId);
    _loadAchievements();
  }

  /// Mark all as seen
  Future<void> markAllSeen() async {
    await _storageService.markAllAchievementsSeen();
    _loadAchievements();
  }

  /// Get unseen count
  int get unseenCount => _storageService.getUnseenAchievementsCount();
}

// ==================== CELEBRATION PROVIDER ====================

/// Celebration state
class CelebrationState {
  final bool showGoalCelebration;
  final bool showAchievementCelebration;
  final bool showChallengeCelebration;
  final AchievementDefinition? achievement;
  final ChallengeDefinition? challengeDefinition;
  final ActiveChallenge? challengeCompleted;
  final int? streakMilestone;

  const CelebrationState({
    this.showGoalCelebration = false,
    this.showAchievementCelebration = false,
    this.showChallengeCelebration = false,
    this.achievement,
    this.challengeDefinition,
    this.challengeCompleted,
    this.streakMilestone,
  });

  CelebrationState copyWith({
    bool? showGoalCelebration,
    bool? showAchievementCelebration,
    bool? showChallengeCelebration,
    AchievementDefinition? achievement,
    ChallengeDefinition? challengeDefinition,
    ActiveChallenge? challengeCompleted,
    int? streakMilestone,
    bool clearAchievement = false,
    bool clearChallenge = false,
    bool clearStreak = false,
  }) {
    return CelebrationState(
      showGoalCelebration: showGoalCelebration ?? this.showGoalCelebration,
      showAchievementCelebration: showAchievementCelebration ?? this.showAchievementCelebration,
      showChallengeCelebration: showChallengeCelebration ?? this.showChallengeCelebration,
      achievement: clearAchievement ? null : (achievement ?? this.achievement),
      challengeDefinition: clearChallenge ? null : (challengeDefinition ?? this.challengeDefinition),
      challengeCompleted: clearChallenge ? null : (challengeCompleted ?? this.challengeCompleted),
      streakMilestone: clearStreak ? null : (streakMilestone ?? this.streakMilestone),
    );
  }
}

final celebrationProvider = StateNotifierProvider<CelebrationNotifier, CelebrationState>((ref) {
  return CelebrationNotifier();
});

class CelebrationNotifier extends StateNotifier<CelebrationState> {
  bool _hasShownGoalCelebrationToday = false;

  CelebrationNotifier() : super(const CelebrationState());

  /// Trigger goal reached celebration
  void triggerGoalCelebration() {
    if (_hasShownGoalCelebrationToday) return;
    _hasShownGoalCelebrationToday = true;
    state = state.copyWith(showGoalCelebration: true);
  }

  /// Trigger achievement celebration
  void triggerAchievementCelebration(AchievementDefinition achievement) {
    state = state.copyWith(
      showAchievementCelebration: true,
      achievement: achievement,
    );
  }

  /// Trigger streak milestone celebration
  void triggerStreakCelebration(int days) {
    state = state.copyWith(streakMilestone: days);
  }

  /// Dismiss goal celebration
  void dismissGoalCelebration() {
    state = state.copyWith(showGoalCelebration: false);
  }

  /// Dismiss achievement celebration
  void dismissAchievementCelebration() {
    state = state.copyWith(
      showAchievementCelebration: false,
      clearAchievement: true,
    );
  }

  /// Dismiss streak celebration
  void dismissStreakCelebration() {
    state = state.copyWith(clearStreak: true);
  }

  /// Trigger challenge completion celebration
  void triggerChallengeCelebration(
    ChallengeDefinition definition,
    ActiveChallenge challenge,
  ) {
    state = state.copyWith(
      showChallengeCelebration: true,
      challengeDefinition: definition,
      challengeCompleted: challenge,
    );
  }

  /// Dismiss challenge celebration
  void dismissChallengeCelebration() {
    state = state.copyWith(
      showChallengeCelebration: false,
      clearChallenge: true,
    );
  }

  /// Reset daily flags (call at midnight or app start)
  void resetDaily() {
    _hasShownGoalCelebrationToday = false;
  }
}

// ==================== CHALLENGES PROVIDERS ====================

/// Provider for active challenge
final activeChallengeProvider = StateNotifierProvider<ChallengeNotifier, ActiveChallenge?>((ref) {
  final storageService = ref.watch(storageServiceProvider);
  return ChallengeNotifier(storageService, ref);
});

/// Challenge state
class ChallengeState {
  final ActiveChallenge? activeChallenge;
  final ChallengeDefinition? definition;
  final bool isChecking;

  const ChallengeState({
    this.activeChallenge,
    this.definition,
    this.isChecking = false,
  });

  ChallengeState copyWith({
    ActiveChallenge? activeChallenge,
    ChallengeDefinition? definition,
    bool? isChecking,
    bool clearChallenge = false,
  }) {
    return ChallengeState(
      activeChallenge: clearChallenge ? null : (activeChallenge ?? this.activeChallenge),
      definition: definition ?? this.definition,
      isChecking: isChecking ?? this.isChecking,
    );
  }

  bool get hasActiveChallenge => activeChallenge != null;
  double get progress => activeChallenge?.completionPercentage ?? 0.0;
  int get daysRemaining => activeChallenge?.daysRemaining ?? 0;
  int get daysCompleted => activeChallenge?.daysCompleted ?? 0;
}

class ChallengeNotifier extends StateNotifier<ActiveChallenge?> {
  final StorageService _storageService;
  final Ref _ref;

  ChallengeNotifier(this._storageService, this._ref) : super(null) {
    _loadActiveChallenge();
    _checkAndAutoStart();
  }

  void _loadActiveChallenge() {
    state = _storageService.getActiveChallenge();
  }

  /// Check if we need to auto-start a new weekly challenge
  Future<void> _checkAndAutoStart() async {
    final active = _storageService.getActiveChallenge();
    
    // If no active challenge, start a random one
    if (active == null) {
      await startRandomChallenge();
    } else {
      // Check if challenge expired
      if (DateTime.now().isAfter(active.endDate)) {
        // Mark as expired and start new one
        await _storageService.updateChallenge(active.copyWith(
          status: ChallengeStatus.expired,
        ));
        await startRandomChallenge();
      }
    }
  }

  /// Start a new challenge
  Future<ActiveChallenge?> startChallenge(String challengeId) async {
    try {
      final challenge = await _storageService.startChallenge(challengeId);
      state = challenge;
      return challenge;
    } catch (e) {
      debugPrint('Error starting challenge: $e');
      return null;
    }
  }

  /// Start a random weekly challenge
  Future<ActiveChallenge?> startRandomChallenge() async {
    final challenge = Challenges.getRandomChallenge();
    return await startChallenge(challenge.id);
  }

  /// Check and update challenge progress
  Future<void> checkProgress() async {
    if (state == null) return;

    final challenge = state!;
    final definition = Challenges.getById(challenge.challengeId);
    if (definition == null) return;

    final today = DateTime.now();
    final todayKey = '${today.year}-${today.month}-${today.day}';

    // Skip if already checked today
    if (challenge.progress[todayKey] == true) return;

    bool dayCompleted = false;

    switch (definition.type) {
      case ChallengeType.earlyMorning:
        dayCompleted = _checkEarlyMorning(definition);
        break;
      case ChallengeType.multipleLogs:
        dayCompleted = _checkMultipleLogs(definition);
        break;
      case ChallengeType.exceedGoal:
        dayCompleted = _checkExceedGoal(definition);
        break;
      case ChallengeType.perfectDays:
        dayCompleted = _checkPerfectDays(definition);
        break;
      case ChallengeType.totalVolume:
        // Total volume challenges are checked at end of period
        // Check if we're at the end date
        if (DateTime.now().isAfter(challenge.endDate.subtract(const Duration(hours: 1)))) {
          dayCompleted = _checkTotalVolume(definition, challenge);
        }
        break;
      case ChallengeType.consistency:
        dayCompleted = _checkConsistency(definition);
        break;
    }

    if (dayCompleted) {
      final updatedProgress = Map<String, dynamic>.from(challenge.progress);
      updatedProgress[todayKey] = true;

      final updated = challenge.copyWith(progress: updatedProgress);
      await _storageService.updateChallenge(updated);
      state = updated;

      // Check if challenge is complete
      if (updated.daysCompleted >= definition.targetDays) {
        await _completeChallenge(updated);
      }
    }
  }

  bool _checkEarlyMorning(ChallengeDefinition definition) {
    final entries = _storageService.getTodayEntries();
    final beforeHour = definition.parameters['beforeHour'] as int;
    final amountMl = definition.parameters['amountMl'] as int;

    final earlyEntries = entries.where((e) => e.timestamp.hour < beforeHour).toList();
    final totalEarly = earlyEntries.fold(0.0, (sum, e) => sum + e.amountMl);

    return totalEarly >= amountMl;
  }

  bool _checkMultipleLogs(ChallengeDefinition definition) {
    final entries = _storageService.getTodayEntries();
    final minLogs = definition.parameters['minLogsPerDay'] as int;
    return entries.length >= minLogs;
  }

  bool _checkExceedGoal(ChallengeDefinition definition) {
    final settings = _ref.read(settingsProvider);
    final todayTotal = _ref.read(todayTotalProvider);
    final goal = settings.effectiveDailyGoalMl;
    final excessPercent = definition.parameters['excessPercent'] as int;

    final target = goal * (1 + excessPercent / 100);
    return todayTotal >= target;
  }

  bool _checkPerfectDays(ChallengeDefinition definition) {
    final settings = _ref.read(settingsProvider);
    final todayTotal = _ref.read(todayTotalProvider);
    final goal = settings.effectiveDailyGoalMl;
    return todayTotal >= goal;
  }

  bool _checkTotalVolume(ChallengeDefinition definition, ActiveChallenge challenge) {
    // Check total volume for the challenge period
    final totalLiters = definition.parameters['totalLiters'] as int;
    final targetMl = totalLiters * 1000;
    
    // Get all entries from challenge start date to end date
    final allEntries = _storageService.getAllEntries();
    final weekEntries = allEntries.where((e) => 
      e.timestamp.isAfter(challenge.startDate.subtract(const Duration(days: 1))) &&
      e.timestamp.isBefore(challenge.endDate.add(const Duration(days: 1)))
    ).toList();
    
    final totalMl = weekEntries.fold(0.0, (sum, e) => sum + e.amountMl);
    
    // Mark as complete if target reached
    return totalMl >= targetMl;
  }

  bool _checkConsistency(ChallengeDefinition definition) {
    final entries = _storageService.getTodayEntries();
    final startHour = definition.parameters['startHour'] as int;
    final endHour = definition.parameters['endHour'] as int;
    
    // Check if there's at least one entry in the time window
    return entries.any((e) => 
      e.timestamp.hour >= startHour && e.timestamp.hour < endHour
    );
  }

  Future<void> _completeChallenge(ActiveChallenge challenge) async {
    final definition = Challenges.getById(challenge.challengeId);
    if (definition == null) return;

    await _storageService.completeChallenge(challenge.challengeId);
    state = challenge.copyWith(
      completed: true,
      completedAt: DateTime.now(),
      status: ChallengeStatus.completed,
    );

    // Award points
    await _storageService.addPoints(definition.rewardPoints);
    _ref.read(settingsProvider.notifier).refresh();

    // Trigger challenge completion celebration
    _ref.read(celebrationProvider.notifier).triggerChallengeCelebration(
      definition,
      challenge,
    );
  }

  /// Refresh challenge state
  void refresh() {
    _loadActiveChallenge();
  }

  /// Award points for challenge completion
  Future<void> awardPoints(int points) async {
    await _storageService.addPoints(points);
    _ref.read(settingsProvider.notifier).refresh();
  }
}

// ==================== SHOP PROVIDERS ====================

/// Provider for shop items
final shopItemsProvider = Provider<List<ShopItem>>((ref) {
  return ShopCatalog.all;
});

/// Provider for purchased items
final purchasedItemsProvider = StateNotifierProvider<PurchasedItemsNotifier, List<PurchasedItem>>((ref) {
  final storageService = ref.watch(storageServiceProvider);
  return PurchasedItemsNotifier(storageService);
});

class PurchasedItemsNotifier extends StateNotifier<List<PurchasedItem>> {
  final StorageService _storageService;

  PurchasedItemsNotifier(this._storageService) : super([]) {
    _loadPurchasedItems();
  }

  void _loadPurchasedItems() {
    state = _storageService.getPurchasedItems();
  }

  Future<bool> purchaseItem(String itemId) async {
    final item = ShopCatalog.getById(itemId);
    if (item == null) return false;

    final settings = _storageService.getSettings();
    if (settings.points < item.price) return false;

    final success = await _storageService.spendPoints(item.price);
    if (!success) return false;

    await _storageService.purchaseItem(itemId);
    _loadPurchasedItems();
    return true;
  }

  Future<void> equipItem(String itemId) async {
    await _storageService.equipItem(itemId);
    _loadPurchasedItems();
  }

  bool isPurchased(String itemId) {
    return _storageService.isItemPurchased(itemId);
  }

  bool isEquipped(String itemId) {
    try {
      final purchased = state.firstWhere((p) => p.itemId == itemId);
      return purchased.isEquipped;
    } catch (_) {
      return false;
    }
  }

  void refresh() {
    _loadPurchasedItems();
  }
}
