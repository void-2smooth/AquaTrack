import 'package:hive/hive.dart';

part 'challenge.g.dart';

/// Challenge difficulty levels
enum ChallengeDifficulty {
  easy,
  medium,
  hard,
}

/// Challenge status
enum ChallengeStatus {
  active,      // Currently active challenge
  completed,   // Successfully completed
  failed,      // Failed to complete
  expired,     // Time ran out
}

/// Challenge definition (static data)
class ChallengeDefinition {
  final String id;
  final String title;
  final String description;
  final ChallengeDifficulty difficulty;
  final int targetDays; // How many days to complete
  final ChallengeType type;
  final Map<String, dynamic> parameters; // Type-specific parameters

  const ChallengeDefinition({
    required this.id,
    required this.title,
    required this.description,
    required this.difficulty,
    required this.targetDays,
    required this.type,
    required this.parameters,
  });

  /// Get difficulty color
  String get difficultyName {
    switch (difficulty) {
      case ChallengeDifficulty.easy:
        return 'Easy';
      case ChallengeDifficulty.medium:
        return 'Medium';
      case ChallengeDifficulty.hard:
        return 'Hard';
    }
  }

  /// Get reward points based on difficulty
  int get rewardPoints {
    switch (difficulty) {
      case ChallengeDifficulty.easy:
        return 10;
      case ChallengeDifficulty.medium:
        return 25;
      case ChallengeDifficulty.hard:
        return 50;
    }
  }
}

/// Challenge type enum
enum ChallengeType {
  earlyMorning,      // Drink X ml before Y time
  multipleLogs,      // Log at least X times per day
  exceedGoal,        // Exceed goal by X% for Y days
  perfectDays,       // Complete goal every day
  totalVolume,       // Drink X total liters this week
  consistency,       // Log at consistent times
}

/// Active challenge instance (stored in Hive)
@HiveType(typeId: 5)
class ActiveChallenge extends HiveObject {
  @HiveField(0)
  final String challengeId;

  @HiveField(1)
  final DateTime startDate;

  @HiveField(2)
  final DateTime endDate;

  @HiveField(3)
  final ChallengeStatus status;

  @HiveField(4)
  final Map<String, dynamic> progress; // Day-by-day progress

  @HiveField(5)
  final bool completed;

  @HiveField(6)
  final DateTime? completedAt;

  ActiveChallenge({
    required this.challengeId,
    required this.startDate,
    required this.endDate,
    this.status = ChallengeStatus.active,
    Map<String, dynamic>? progress,
    this.completed = false,
    this.completedAt,
  }) : progress = progress ?? {};

  ActiveChallenge copyWith({
    String? challengeId,
    DateTime? startDate,
    DateTime? endDate,
    ChallengeStatus? status,
    Map<String, dynamic>? progress,
    bool? completed,
    DateTime? completedAt,
  }) {
    return ActiveChallenge(
      challengeId: challengeId ?? this.challengeId,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      completed: completed ?? this.completed,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  /// Get days remaining
  int get daysRemaining {
    final now = DateTime.now();
    if (now.isAfter(endDate)) return 0;
    return endDate.difference(now).inDays + 1;
  }

  /// Get days completed
  int get daysCompleted {
    return progress.values.where((v) => v == true).length;
  }

  /// Get completion percentage
  double get completionPercentage {
    final definition = Challenges.getById(challengeId);
    if (definition == null) return 0.0;
    return (daysCompleted / definition.targetDays).clamp(0.0, 1.0);
  }
}

/// All challenge definitions
class Challenges {
  // Early Morning Challenges
  static const earlyBird500 = ChallengeDefinition(
    id: 'early_bird_500',
    title: 'Early Bird',
    description: 'Drink 500ml before 9am every day this week',
    difficulty: ChallengeDifficulty.medium,
    targetDays: 7,
    type: ChallengeType.earlyMorning,
    parameters: {
      'amountMl': 500,
      'beforeHour': 9,
    },
  );

  static const earlyBird250 = ChallengeDefinition(
    id: 'early_bird_250',
    title: 'Morning Starter',
    description: 'Drink 250ml before 8am every day this week',
    difficulty: ChallengeDifficulty.easy,
    targetDays: 7,
    type: ChallengeType.earlyMorning,
    parameters: {
      'amountMl': 250,
      'beforeHour': 8,
    },
  );

  // Multiple Logs Challenges
  static const frequentLogger = ChallengeDefinition(
    id: 'frequent_logger',
    title: 'Frequent Logger',
    description: 'Log water at least 5 times per day',
    difficulty: ChallengeDifficulty.medium,
    targetDays: 7,
    type: ChallengeType.multipleLogs,
    parameters: {
      'minLogsPerDay': 5,
    },
  );

  static const consistentLogger = ChallengeDefinition(
    id: 'consistent_logger',
    title: 'Consistent Logger',
    description: 'Log water at least 3 times per day',
    difficulty: ChallengeDifficulty.easy,
    targetDays: 7,
    type: ChallengeType.multipleLogs,
    parameters: {
      'minLogsPerDay': 3,
    },
  );

  // Exceed Goal Challenges
  static const overachiever20 = ChallengeDefinition(
    id: 'overachiever_20',
    title: 'Overachiever',
    description: 'Exceed your goal by 20% for 3 days',
    difficulty: ChallengeDifficulty.hard,
    targetDays: 3,
    type: ChallengeType.exceedGoal,
    parameters: {
      'excessPercent': 20,
      'requiredDays': 3,
    },
  );

  static const overachiever10 = ChallengeDefinition(
    id: 'overachiever_10',
    title: 'Goal Crusher',
    description: 'Exceed your goal by 10% for 5 days',
    difficulty: ChallengeDifficulty.medium,
    targetDays: 5,
    type: ChallengeType.exceedGoal,
    parameters: {
      'excessPercent': 10,
      'requiredDays': 5,
    },
  );

  // Perfect Days Challenges
  static const perfectWeek = ChallengeDefinition(
    id: 'perfect_week',
    title: 'Perfect Week',
    description: 'Complete your goal every day this week',
    difficulty: ChallengeDifficulty.hard,
    targetDays: 7,
    type: ChallengeType.perfectDays,
    parameters: {},
  );

  static const perfectHalfWeek = ChallengeDefinition(
    id: 'perfect_half_week',
    title: 'Perfect Half Week',
    description: 'Complete your goal for 4 consecutive days',
    difficulty: ChallengeDifficulty.medium,
    targetDays: 4,
    type: ChallengeType.perfectDays,
    parameters: {},
  );

  // Total Volume Challenges
  static const weeklyWarrior = ChallengeDefinition(
    id: 'weekly_warrior',
    title: 'Weekly Warrior',
    description: 'Drink 15 liters total this week',
    difficulty: ChallengeDifficulty.hard,
    targetDays: 7,
    type: ChallengeType.totalVolume,
    parameters: {
      'totalLiters': 15,
    },
  );

  static const weeklyChampion = ChallengeDefinition(
    id: 'weekly_champion',
    title: 'Weekly Champion',
    description: 'Drink 10 liters total this week',
    difficulty: ChallengeDifficulty.medium,
    targetDays: 7,
    type: ChallengeType.totalVolume,
    parameters: {
      'totalLiters': 10,
    },
  );

  static const weeklyHero = ChallengeDefinition(
    id: 'weekly_hero',
    title: 'Weekly Hero',
    description: 'Drink 8 liters total this week',
    difficulty: ChallengeDifficulty.easy,
    targetDays: 7,
    type: ChallengeType.totalVolume,
    parameters: {
      'totalLiters': 8,
    },
  );

  static const weeklyTitan = ChallengeDefinition(
    id: 'weekly_titan',
    title: 'Weekly Titan',
    description: 'Drink 20 liters total this week',
    difficulty: ChallengeDifficulty.hard,
    targetDays: 7,
    type: ChallengeType.totalVolume,
    parameters: {
      'totalLiters': 20,
    },
  );

  // Additional Early Morning Challenges
  static const sunriseHydration = ChallengeDefinition(
    id: 'sunrise_hydration',
    title: 'Sunrise Hydration',
    description: 'Drink 750ml before 7am every day this week',
    difficulty: ChallengeDifficulty.hard,
    targetDays: 7,
    type: ChallengeType.earlyMorning,
    parameters: {
      'amountMl': 750,
      'beforeHour': 7,
    },
  );

  static const dawnDrinker = ChallengeDefinition(
    id: 'dawn_drinker',
    title: 'Dawn Drinker',
    description: 'Drink 400ml before 10am every day this week',
    difficulty: ChallengeDifficulty.easy,
    targetDays: 7,
    type: ChallengeType.earlyMorning,
    parameters: {
      'amountMl': 400,
      'beforeHour': 10,
    },
  );

  // Additional Multiple Logs Challenges
  static const powerLogger = ChallengeDefinition(
    id: 'power_logger',
    title: 'Power Logger',
    description: 'Log water at least 8 times per day',
    difficulty: ChallengeDifficulty.hard,
    targetDays: 7,
    type: ChallengeType.multipleLogs,
    parameters: {
      'minLogsPerDay': 8,
    },
  );

  static const microLogger = ChallengeDefinition(
    id: 'micro_logger',
    title: 'Micro Logger',
    description: 'Log water at least 2 times per day',
    difficulty: ChallengeDifficulty.easy,
    targetDays: 5,
    type: ChallengeType.multipleLogs,
    parameters: {
      'minLogsPerDay': 2,
    },
  );

  static const superLogger = ChallengeDefinition(
    id: 'super_logger',
    title: 'Super Logger',
    description: 'Log water at least 10 times per day',
    difficulty: ChallengeDifficulty.hard,
    targetDays: 5,
    type: ChallengeType.multipleLogs,
    parameters: {
      'minLogsPerDay': 10,
    },
  );

  // Additional Exceed Goal Challenges
  static const overachiever30 = ChallengeDefinition(
    id: 'overachiever_30',
    title: 'Super Overachiever',
    description: 'Exceed your goal by 30% for 2 days',
    difficulty: ChallengeDifficulty.hard,
    targetDays: 2,
    type: ChallengeType.exceedGoal,
    parameters: {
      'excessPercent': 30,
      'requiredDays': 2,
    },
  );

  static const overachiever15 = ChallengeDefinition(
    id: 'overachiever_15',
    title: 'Goal Smasher',
    description: 'Exceed your goal by 15% for 4 days',
    difficulty: ChallengeDifficulty.medium,
    targetDays: 4,
    type: ChallengeType.exceedGoal,
    parameters: {
      'excessPercent': 15,
      'requiredDays': 4,
    },
  );

  static const overachiever5 = ChallengeDefinition(
    id: 'overachiever_5',
    title: 'Goal Beater',
    description: 'Exceed your goal by 5% for 7 days',
    difficulty: ChallengeDifficulty.easy,
    targetDays: 7,
    type: ChallengeType.exceedGoal,
    parameters: {
      'excessPercent': 5,
      'requiredDays': 7,
    },
  );

  // Additional Perfect Days Challenges
  static const perfect3Days = ChallengeDefinition(
    id: 'perfect_3_days',
    title: 'Perfect 3 Days',
    description: 'Complete your goal for 3 consecutive days',
    difficulty: ChallengeDifficulty.easy,
    targetDays: 3,
    type: ChallengeType.perfectDays,
    parameters: {},
  );

  static const perfect5Days = ChallengeDefinition(
    id: 'perfect_5_days',
    title: 'Perfect 5 Days',
    description: 'Complete your goal for 5 consecutive days',
    difficulty: ChallengeDifficulty.medium,
    targetDays: 5,
    type: ChallengeType.perfectDays,
    parameters: {},
  );

  static const perfect10Days = ChallengeDefinition(
    id: 'perfect_10_days',
    title: 'Perfect 10 Days',
    description: 'Complete your goal for 10 consecutive days',
    difficulty: ChallengeDifficulty.hard,
    targetDays: 10,
    type: ChallengeType.perfectDays,
    parameters: {},
  );

  // Consistency Challenges (new type)
  static const consistentMorning = ChallengeDefinition(
    id: 'consistent_morning',
    title: 'Consistent Morning',
    description: 'Log water between 7-9am for 5 days',
    difficulty: ChallengeDifficulty.medium,
    targetDays: 5,
    type: ChallengeType.consistency,
    parameters: {
      'startHour': 7,
      'endHour': 9,
    },
  );

  static const consistentAfternoon = ChallengeDefinition(
    id: 'consistent_afternoon',
    title: 'Consistent Afternoon',
    description: 'Log water between 12-2pm for 5 days',
    difficulty: ChallengeDifficulty.medium,
    targetDays: 5,
    type: ChallengeType.consistency,
    parameters: {
      'startHour': 12,
      'endHour': 14,
    },
  );

  /// Factory method to easily create new challenges
  /// Example: Challenges.create('my_challenge', 'My Challenge', 'Description', ChallengeDifficulty.easy, 7, ChallengeType.perfectDays, {})
  static ChallengeDefinition create(
    String id,
    String title,
    String description,
    ChallengeDifficulty difficulty,
    int targetDays,
    ChallengeType type,
    Map<String, dynamic> parameters,
  ) {
    return ChallengeDefinition(
      id: id,
      title: title,
      description: description,
      difficulty: difficulty,
      targetDays: targetDays,
      type: type,
      parameters: parameters,
    );
  }

  /// All challenges list - Easy to add more by just adding to this list
  static const List<ChallengeDefinition> all = [
    // Early Morning (4)
    earlyBird500,
    earlyBird250,
    sunriseHydration,
    dawnDrinker,
    // Multiple Logs (5)
    frequentLogger,
    consistentLogger,
    powerLogger,
    microLogger,
    superLogger,
    // Exceed Goal (5)
    overachiever20,
    overachiever10,
    overachiever30,
    overachiever15,
    overachiever5,
    // Perfect Days (5)
    perfectWeek,
    perfectHalfWeek,
    perfect3Days,
    perfect5Days,
    perfect10Days,
    // Total Volume (4)
    weeklyWarrior,
    weeklyChampion,
    weeklyHero,
    weeklyTitan,
    // Consistency (2)
    consistentMorning,
    consistentAfternoon,
  ];

  /// Get challenge by ID
  static ChallengeDefinition? getById(String id) {
    try {
      return all.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Get challenges by difficulty
  static List<ChallengeDefinition> byDifficulty(ChallengeDifficulty difficulty) {
    return all.where((c) => c.difficulty == difficulty).toList();
  }

  /// Get random challenge (for weekly rotation)
  static ChallengeDefinition getRandomChallenge() {
    final random = DateTime.now().millisecondsSinceEpoch % all.length;
    return all[random];
  }

  /// Get challenges by type
  static List<ChallengeDefinition> byType(ChallengeType type) {
    return all.where((c) => c.type == type).toList();
  }
}

