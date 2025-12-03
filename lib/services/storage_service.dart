import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/water_entry.dart';
import '../models/container.dart';
import '../models/achievement.dart';
import '../models/challenge.dart';
import '../models/shop_item.dart';

/// Service for managing local storage using Hive
/// 
/// Handles all CRUD operations for water entries, user settings, containers, and achievements.
/// Uses Hive boxes for efficient local storage.
class StorageService {
  static const String _waterEntriesBoxName = 'water_entries';
  static const String _settingsBoxName = 'user_settings';
  static const String _containersBoxName = 'containers';
  static const String _achievementsBoxName = 'achievements';
  static const String _challengesBoxName = 'challenges';
  static const String _purchasedItemsBoxName = 'purchased_items';
  static const String _settingsKey = 'settings';

  late Box<WaterEntry> _waterEntriesBox;
  late Box<UserSettings> _settingsBox;
  late Box<WaterContainer> _containersBox;
  late Box<UnlockedAchievement> _achievementsBox;
  late Box<ActiveChallenge> _challengesBox;
  late Box<PurchasedItem> _purchasedItemsBox;

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
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(WaterContainerAdapter());
    }
    if (!Hive.isAdapterRegistered(4)) {
      Hive.registerAdapter(UnlockedAchievementAdapter());
    }
    if (!Hive.isAdapterRegistered(5)) {
      Hive.registerAdapter(ActiveChallengeAdapter());
    }
    if (!Hive.isAdapterRegistered(6)) {
      Hive.registerAdapter(ShopItemAdapter());
    }
    if (!Hive.isAdapterRegistered(7)) {
      Hive.registerAdapter(PurchasedItemAdapter());
    }

    // Open boxes
    _waterEntriesBox = await Hive.openBox<WaterEntry>(_waterEntriesBoxName);
    _settingsBox = await Hive.openBox<UserSettings>(_settingsBoxName);
    _containersBox = await Hive.openBox<WaterContainer>(_containersBoxName);
    _achievementsBox = await Hive.openBox<UnlockedAchievement>(_achievementsBoxName);
    _challengesBox = await Hive.openBox<ActiveChallenge>(_challengesBoxName);
    _purchasedItemsBox = await Hive.openBox<PurchasedItem>(_purchasedItemsBoxName);

    // Initialize default settings if not exists
    if (_settingsBox.get(_settingsKey) == null) {
      await _settingsBox.put(_settingsKey, UserSettings());
    }

    // Initialize default containers if none exist
    if (_containersBox.isEmpty) {
      await _initializeDefaultContainers();
    }
  }

  /// Initialize default containers for new users
  Future<void> _initializeDefaultContainers() async {
    final defaults = DefaultContainers.getDefaults();
    for (final container in defaults) {
      await _containersBox.put(container.id, container);
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
    
    // Update streak after adding entry
    await updateStreak();
    
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

  // ==================== CONTAINERS ====================

  /// Get all saved containers
  List<WaterContainer> getAllContainers() {
    return _containersBox.values.toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  /// Get only default/quick-add containers
  List<WaterContainer> getQuickAddContainers() {
    return _containersBox.values
        .where((c) => c.isDefault)
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  /// Get a container by ID
  WaterContainer? getContainer(String id) {
    return _containersBox.get(id);
  }

  /// Add a new container
  Future<WaterContainer> addContainer({
    required String name,
    required double amountMl,
    String icon = 'local_drink',
    int colorValue = 0xFF00B4D8,
    bool isDefault = true,
  }) async {
    final container = WaterContainer(
      id: _uuid.v4(),
      name: name,
      amountMl: amountMl,
      icon: icon,
      colorValue: colorValue,
      isDefault: isDefault,
    );
    
    await _containersBox.put(container.id, container);
    return container;
  }

  /// Update an existing container
  Future<void> updateContainer(WaterContainer container) async {
    await _containersBox.put(container.id, container);
  }

  /// Delete a container
  Future<void> deleteContainer(String id) async {
    await _containersBox.delete(id);
  }

  /// Toggle container as quick-add default
  Future<void> toggleContainerDefault(String id, bool isDefault) async {
    final container = _containersBox.get(id);
    if (container != null) {
      final updated = container.copyWith(isDefault: isDefault);
      await _containersBox.put(id, updated);
    }
  }

  /// Reset containers to defaults
  Future<void> resetContainersToDefault() async {
    await _containersBox.clear();
    await _initializeDefaultContainers();
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
          newStreak = settings.currentStreak + 1;
        } else {
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

  // ==================== ACHIEVEMENTS ====================

  /// Get all unlocked achievements
  List<UnlockedAchievement> getUnlockedAchievements() {
    return _achievementsBox.values.toList();
  }

  /// Check if an achievement is unlocked
  bool isAchievementUnlocked(String achievementId) {
    return _achievementsBox.values.any((a) => a.achievementId == achievementId);
  }

  /// Unlock an achievement
  Future<UnlockedAchievement?> unlockAchievement(String achievementId) async {
    // Don't unlock if already unlocked
    if (isAchievementUnlocked(achievementId)) {
      return null;
    }

    final unlocked = UnlockedAchievement(
      achievementId: achievementId,
      unlockedAt: DateTime.now(),
      seen: false,
    );

    await _achievementsBox.put(achievementId, unlocked);
    return unlocked;
  }

  /// Mark an achievement as seen
  Future<void> markAchievementSeen(String achievementId) async {
    final existing = _achievementsBox.get(achievementId);
    if (existing != null) {
      final updated = existing.copyWith(seen: true);
      await _achievementsBox.put(achievementId, updated);
    }
  }

  /// Mark all achievements as seen
  Future<void> markAllAchievementsSeen() async {
    for (final key in _achievementsBox.keys) {
      final existing = _achievementsBox.get(key);
      if (existing != null && !existing.seen) {
        final updated = existing.copyWith(seen: true);
        await _achievementsBox.put(key, updated);
      }
    }
  }

  /// Get unseen achievements count
  int getUnseenAchievementsCount() {
    return _achievementsBox.values.where((a) => !a.seen).length;
  }

  /// Get total water logged (all time) in ml
  double getTotalWaterLogged() {
    return _waterEntriesBox.values.fold(0.0, (sum, entry) => sum + entry.amountMl);
  }

  /// Get total number of water entries
  int getTotalEntryCount() {
    return _waterEntriesBox.length;
  }

  // ==================== CHALLENGES ====================

  /// Get active challenge
  ActiveChallenge? getActiveChallenge() {
    final challenges = _challengesBox.values.where((c) => 
      c.status == ChallengeStatus.active && 
      DateTime.now().isBefore(c.endDate)
    ).toList();
    
    if (challenges.isEmpty) return null;
    // Return the most recent active challenge
    challenges.sort((a, b) => b.startDate.compareTo(a.startDate));
    return challenges.first;
  }

  /// Get all challenges (active, completed, failed)
  List<ActiveChallenge> getAllChallenges() {
    return _challengesBox.values.toList()
      ..sort((a, b) => b.startDate.compareTo(a.startDate));
  }

  /// Get completed challenges
  List<ActiveChallenge> getCompletedChallenges() {
    return _challengesBox.values
        .where((c) => c.completed)
        .toList()
      ..sort((a, b) => (b.completedAt ?? b.endDate).compareTo(a.completedAt ?? a.endDate));
  }

  /// Start a new challenge
  Future<ActiveChallenge> startChallenge(String challengeId) async {
    final definition = Challenges.getById(challengeId);
    if (definition == null) {
      throw Exception('Challenge not found: $challengeId');
    }

    // End any existing active challenge
    final existing = getActiveChallenge();
    if (existing != null) {
      await updateChallenge(existing.copyWith(
        status: ChallengeStatus.expired,
      ));
    }

    final now = DateTime.now();
    final endDate = now.add(Duration(days: definition.targetDays));

    final challenge = ActiveChallenge(
      challengeId: challengeId,
      startDate: now,
      endDate: endDate,
      status: ChallengeStatus.active,
    );

    await _challengesBox.put(challengeId, challenge);
    return challenge;
  }

  /// Update challenge progress
  Future<void> updateChallenge(ActiveChallenge challenge) async {
    await _challengesBox.put(challenge.challengeId, challenge);
  }

  /// Mark challenge as completed
  Future<void> completeChallenge(String challengeId) async {
    final challenge = _challengesBox.get(challengeId);
    if (challenge != null) {
      final updated = challenge.copyWith(
        completed: true,
        completedAt: DateTime.now(),
        status: ChallengeStatus.completed,
      );
      await _challengesBox.put(challengeId, updated);
    }
  }

  // ==================== SHOP ====================

  /// Get purchased items
  List<PurchasedItem> getPurchasedItems() {
    return _purchasedItemsBox.values.toList();
  }

  /// Check if item is purchased
  bool isItemPurchased(String itemId) {
    return _purchasedItemsBox.values.any((item) => item.itemId == itemId);
  }

  /// Purchase an item
  Future<void> purchaseItem(String itemId) async {
    if (isItemPurchased(itemId)) return;
    
    final purchased = PurchasedItem(
      itemId: itemId,
      purchasedAt: DateTime.now(),
    );
    await _purchasedItemsBox.put(itemId, purchased);
  }

  /// Equip an item (for themes, icons, etc.)
  Future<void> equipItem(String itemId) async {
    // Unequip all items of the same category
    final item = ShopCatalog.getById(itemId);
    if (item == null) return;

    final sameCategory = _purchasedItemsBox.values
        .where((p) => ShopCatalog.getById(p.itemId)?.category == item.category)
        .toList();

    for (final purchased in sameCategory) {
      if (purchased.itemId != itemId) {
        final updated = purchased.copyWith(isEquipped: false);
        await _purchasedItemsBox.put(purchased.itemId, updated);
      }
    }

    // Equip the selected item
    final purchased = _purchasedItemsBox.get(itemId);
    if (purchased != null) {
      final updated = purchased.copyWith(isEquipped: true);
      await _purchasedItemsBox.put(itemId, updated);
    }
  }

  /// Get equipped item for category
  String? getEquippedItemId(ShopItemCategory category) {
    final equipped = _purchasedItemsBox.values
        .where((p) => p.isEquipped && ShopCatalog.getById(p.itemId)?.category == category)
        .firstOrNull;
    return equipped?.itemId;
  }

  /// Add points to user
  Future<void> addPoints(int points) async {
    final settings = getSettings();
    settings.points += points;
    await _settingsBox.put(_settingsKey, settings);
  }

  /// Spend points
  Future<bool> spendPoints(int points) async {
    final settings = getSettings();
    if (settings.points < points) return false;
    settings.points -= points;
    await _settingsBox.put(_settingsKey, settings);
    return true;
  }

  /// Clear all data (for testing or reset)
  Future<void> clearAllData() async {
    await _waterEntriesBox.clear();
    await _settingsBox.clear();
    await _containersBox.clear();
    await _achievementsBox.clear();
    await _challengesBox.clear();
    await _purchasedItemsBox.clear();
    await _settingsBox.put(_settingsKey, UserSettings());
    await _initializeDefaultContainers();
  }
}
