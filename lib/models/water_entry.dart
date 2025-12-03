import 'package:hive/hive.dart';

part 'water_entry.g.dart';

/// Represents a single water intake entry
/// 
/// Each entry records the amount of water consumed and when it was consumed.
/// The amount is stored in milliliters for consistency, and converted for display.
@HiveType(typeId: 0)
class WaterEntry extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final double amountMl; // Amount in milliliters

  @HiveField(2)
  final DateTime timestamp;

  @HiveField(3)
  final String? note; // Optional note for the entry

  WaterEntry({
    required this.id,
    required this.amountMl,
    required this.timestamp,
    this.note,
  });

  /// Create a copy with updated fields
  WaterEntry copyWith({
    String? id,
    double? amountMl,
    DateTime? timestamp,
    String? note,
  }) {
    return WaterEntry(
      id: id ?? this.id,
      amountMl: amountMl ?? this.amountMl,
      timestamp: timestamp ?? this.timestamp,
      note: note ?? this.note,
    );
  }

  /// Convert milliliters to liters
  double get amountLiters => amountMl / 1000;

  /// Convert milliliters to fluid ounces
  double get amountOz => amountMl * 0.033814;

  @override
  String toString() => 'WaterEntry(id: $id, amountMl: $amountMl, timestamp: $timestamp)';
}

/// Activity level for water goal calculation
enum ActivityLevel {
  sedentary,    // Little to no exercise
  light,        // Light exercise 1-3 days/week
  moderate,     // Moderate exercise 3-5 days/week
  active,       // Hard exercise 6-7 days/week
  veryActive,   // Very hard exercise, physical job
}

/// User settings model for storing preferences
@HiveType(typeId: 1)
class UserSettings extends HiveObject {
  @HiveField(0)
  double dailyGoalMl; // Daily goal in milliliters

  @HiveField(1)
  bool useMetricUnits; // true = liters, false = oz

  @HiveField(2)
  bool notificationsEnabled;

  @HiveField(3)
  int reminderIntervalMinutes;

  @HiveField(4)
  bool isDarkMode;

  @HiveField(5)
  int currentStreak; // Current streak in days

  @HiveField(6)
  int longestStreak; // Longest streak achieved

  @HiveField(7)
  DateTime? lastActiveDate; // Last date user added water

  @HiveField(8)
  String? userName; // User's name for personalization

  @HiveField(9)
  double? weightKg; // User's weight in kilograms

  @HiveField(10)
  int? activityLevel; // Activity level (0-4, maps to ActivityLevel enum)

  @HiveField(11)
  bool useCustomGoal; // If true, use dailyGoalMl; if false, calculate from profile

  @HiveField(12)
  double? calculatedGoalMl; // Calculated goal based on weight/activity

  UserSettings({
    this.dailyGoalMl = 2000, // Default 2L
    this.useMetricUnits = true,
    this.notificationsEnabled = false,
    this.reminderIntervalMinutes = 60,
    this.isDarkMode = false,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastActiveDate,
    this.userName,
    this.weightKg,
    this.activityLevel,
    this.useCustomGoal = true, // Default to custom until profile is set
    this.calculatedGoalMl,
  });

  /// Get activity level enum
  ActivityLevel? get activityLevelEnum {
    if (activityLevel == null) return null;
    return ActivityLevel.values[activityLevel!.clamp(0, ActivityLevel.values.length - 1)];
  }

  /// Set activity level from enum
  void setActivityLevel(ActivityLevel level) {
    activityLevel = level.index;
  }

  /// Get effective daily goal (custom or calculated)
  double get effectiveDailyGoalMl {
    if (useCustomGoal || calculatedGoalMl == null) {
      return dailyGoalMl;
    }
    return calculatedGoalMl!;
  }

  /// Get daily goal in liters
  double get dailyGoalLiters => effectiveDailyGoalMl / 1000;

  /// Get daily goal in fluid ounces
  double get dailyGoalOz => effectiveDailyGoalMl * 0.033814;

  /// Check if user has completed profile setup
  bool get hasCompletedProfile => userName != null && userName!.isNotEmpty;

  /// Create a copy with updated fields
  UserSettings copyWith({
    double? dailyGoalMl,
    bool? useMetricUnits,
    bool? notificationsEnabled,
    int? reminderIntervalMinutes,
    bool? isDarkMode,
    int? currentStreak,
    int? longestStreak,
    DateTime? lastActiveDate,
    String? userName,
    double? weightKg,
    int? activityLevel,
    ActivityLevel? activityLevelEnum,
    bool? useCustomGoal,
    double? calculatedGoalMl,
  }) {
    return UserSettings(
      dailyGoalMl: dailyGoalMl ?? this.dailyGoalMl,
      useMetricUnits: useMetricUnits ?? this.useMetricUnits,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      reminderIntervalMinutes: reminderIntervalMinutes ?? this.reminderIntervalMinutes,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastActiveDate: lastActiveDate ?? this.lastActiveDate,
      userName: userName ?? this.userName,
      weightKg: weightKg ?? this.weightKg,
      activityLevel: activityLevelEnum != null ? activityLevelEnum.index : (activityLevel ?? this.activityLevel),
      useCustomGoal: useCustomGoal ?? this.useCustomGoal,
      calculatedGoalMl: calculatedGoalMl ?? this.calculatedGoalMl,
    );
  }
}

/// Daily summary for history tracking
class DailySummary {
  final DateTime date;
  final double totalAmountMl;
  final double goalMl;
  final int entryCount;
  final bool goalReached;

  DailySummary({
    required this.date,
    required this.totalAmountMl,
    required this.goalMl,
    required this.entryCount,
  }) : goalReached = totalAmountMl >= goalMl;

  /// Get completion percentage (0.0 to 1.0+)
  double get completionPercentage => goalMl > 0 ? totalAmountMl / goalMl : 0;

  /// Get completion percentage capped at 100%
  double get completionPercentageCapped => completionPercentage.clamp(0.0, 1.0);
}


