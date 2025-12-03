import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

part 'achievement.g.dart';

/// Achievement rarity levels
enum AchievementRarity {
  common,
  rare,
  epic,
  legendary,
}

/// Achievement category
enum AchievementCategory {
  hydration,
  streak,
  consistency,
  milestone,
  special,
}

/// Definition of an achievement (static data)
class AchievementDefinition {
  final String id;
  final String name;
  final String description;
  final String icon;
  final AchievementRarity rarity;
  final AchievementCategory category;
  final Color color;
  
  const AchievementDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.rarity,
    required this.category,
    required this.color,
  });

  /// Get icon data from icon name
  IconData get iconData {
    return _iconMap[icon] ?? Icons.emoji_events;
  }

  /// Color based on rarity
  Color get rarityColor {
    switch (rarity) {
      case AchievementRarity.common:
        return const Color(0xFF78909C); // Blue grey
      case AchievementRarity.rare:
        return const Color(0xFF42A5F5); // Blue
      case AchievementRarity.epic:
        return const Color(0xFFAB47BC); // Purple
      case AchievementRarity.legendary:
        return const Color(0xFFFFB300); // Amber
    }
  }

  String get rarityName {
    switch (rarity) {
      case AchievementRarity.common:
        return 'Common';
      case AchievementRarity.rare:
        return 'Rare';
      case AchievementRarity.epic:
        return 'Epic';
      case AchievementRarity.legendary:
        return 'Legendary';
    }
  }

  static const Map<String, IconData> _iconMap = {
    'water_drop': Icons.water_drop_rounded,
    'local_fire_department': Icons.local_fire_department_rounded,
    'emoji_events': Icons.emoji_events_rounded,
    'star': Icons.star_rounded,
    'bolt': Icons.bolt_rounded,
    'trending_up': Icons.trending_up_rounded,
    'calendar_month': Icons.calendar_month_rounded,
    'celebration': Icons.celebration_rounded,
    'rocket_launch': Icons.rocket_launch_rounded,
    'diamond': Icons.diamond_rounded,
    'workspace_premium': Icons.workspace_premium_rounded,
    'military_tech': Icons.military_tech_rounded,
    'fitness_center': Icons.fitness_center_rounded,
    'auto_awesome': Icons.auto_awesome_rounded,
    'wb_sunny': Icons.wb_sunny_rounded,
    'nightlight': Icons.nightlight_rounded,
    'coffee': Icons.coffee_rounded,
    'speed': Icons.speed_rounded,
  };
}

/// Unlocked achievement (stored in Hive)
@HiveType(typeId: 4)
class UnlockedAchievement extends HiveObject {
  @HiveField(0)
  final String achievementId;

  @HiveField(1)
  final DateTime unlockedAt;

  @HiveField(2)
  final bool seen;

  UnlockedAchievement({
    required this.achievementId,
    required this.unlockedAt,
    this.seen = false,
  });

  UnlockedAchievement copyWith({
    String? achievementId,
    DateTime? unlockedAt,
    bool? seen,
  }) {
    return UnlockedAchievement(
      achievementId: achievementId ?? this.achievementId,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      seen: seen ?? this.seen,
    );
  }
}

/// All achievement definitions
class Achievements {
  // ============ HYDRATION ACHIEVEMENTS ============
  static const firstDrop = AchievementDefinition(
    id: 'first_drop',
    name: 'First Drop',
    description: 'Log your first water intake',
    icon: 'water_drop',
    rarity: AchievementRarity.common,
    category: AchievementCategory.hydration,
    color: Color(0xFF42A5F5),
  );

  static const hydrationHero = AchievementDefinition(
    id: 'hydration_hero',
    name: 'Hydration Hero',
    description: 'Complete your daily goal for the first time',
    icon: 'emoji_events',
    rarity: AchievementRarity.common,
    category: AchievementCategory.hydration,
    color: Color(0xFF66BB6A),
  );

  static const overachiever = AchievementDefinition(
    id: 'overachiever',
    name: 'Overachiever',
    description: 'Exceed your daily goal by 50%',
    icon: 'rocket_launch',
    rarity: AchievementRarity.rare,
    category: AchievementCategory.hydration,
    color: Color(0xFF26C6DA),
  );

  static const hydrationMaster = AchievementDefinition(
    id: 'hydration_master',
    name: 'Hydration Master',
    description: 'Drink 100 liters total',
    icon: 'workspace_premium',
    rarity: AchievementRarity.epic,
    category: AchievementCategory.milestone,
    color: Color(0xFFAB47BC),
  );

  // ============ STREAK ACHIEVEMENTS ============
  static const streak3 = AchievementDefinition(
    id: 'streak_3',
    name: 'Getting Started',
    description: 'Maintain a 3-day streak',
    icon: 'local_fire_department',
    rarity: AchievementRarity.common,
    category: AchievementCategory.streak,
    color: Color(0xFFFF7043),
  );

  static const streak7 = AchievementDefinition(
    id: 'streak_7',
    name: 'Week Warrior',
    description: 'Maintain a 7-day streak',
    icon: 'local_fire_department',
    rarity: AchievementRarity.rare,
    category: AchievementCategory.streak,
    color: Color(0xFFFF5722),
  );

  static const streak14 = AchievementDefinition(
    id: 'streak_14',
    name: 'Fortnight Fighter',
    description: 'Maintain a 14-day streak',
    icon: 'local_fire_department',
    rarity: AchievementRarity.rare,
    category: AchievementCategory.streak,
    color: Color(0xFFE64A19),
  );

  static const streak30 = AchievementDefinition(
    id: 'streak_30',
    name: 'Monthly Master',
    description: 'Maintain a 30-day streak',
    icon: 'local_fire_department',
    rarity: AchievementRarity.epic,
    category: AchievementCategory.streak,
    color: Color(0xFFD84315),
  );

  static const streak100 = AchievementDefinition(
    id: 'streak_100',
    name: 'Century Champion',
    description: 'Maintain a 100-day streak',
    icon: 'diamond',
    rarity: AchievementRarity.legendary,
    category: AchievementCategory.streak,
    color: Color(0xFFFFD700),
  );

  // ============ CONSISTENCY ACHIEVEMENTS ============
  static const earlyBird = AchievementDefinition(
    id: 'early_bird',
    name: 'Early Bird',
    description: 'Log water before 7 AM',
    icon: 'wb_sunny',
    rarity: AchievementRarity.common,
    category: AchievementCategory.consistency,
    color: Color(0xFFFFA726),
  );

  static const nightOwl = AchievementDefinition(
    id: 'night_owl',
    name: 'Night Owl',
    description: 'Log water after 10 PM',
    icon: 'nightlight',
    rarity: AchievementRarity.common,
    category: AchievementCategory.consistency,
    color: Color(0xFF5C6BC0),
  );

  static const speedDrinker = AchievementDefinition(
    id: 'speed_drinker',
    name: 'Speed Drinker',
    description: 'Complete daily goal before noon',
    icon: 'speed',
    rarity: AchievementRarity.rare,
    category: AchievementCategory.consistency,
    color: Color(0xFF26A69A),
  );

  static const perfectWeek = AchievementDefinition(
    id: 'perfect_week',
    name: 'Perfect Week',
    description: 'Complete your goal every day for a week',
    icon: 'star',
    rarity: AchievementRarity.rare,
    category: AchievementCategory.consistency,
    color: Color(0xFFFFCA28),
  );

  static const perfectMonth = AchievementDefinition(
    id: 'perfect_month',
    name: 'Perfect Month',
    description: 'Complete your goal every day for a month',
    icon: 'military_tech',
    rarity: AchievementRarity.legendary,
    category: AchievementCategory.consistency,
    color: Color(0xFFFFD700),
  );

  // ============ MILESTONE ACHIEVEMENTS ============
  static const logs10 = AchievementDefinition(
    id: 'logs_10',
    name: 'Just Getting Started',
    description: 'Log water 10 times',
    icon: 'trending_up',
    rarity: AchievementRarity.common,
    category: AchievementCategory.milestone,
    color: Color(0xFF78909C),
  );

  static const logs100 = AchievementDefinition(
    id: 'logs_100',
    name: 'Dedicated Drinker',
    description: 'Log water 100 times',
    icon: 'trending_up',
    rarity: AchievementRarity.rare,
    category: AchievementCategory.milestone,
    color: Color(0xFF42A5F5),
  );

  static const logs500 = AchievementDefinition(
    id: 'logs_500',
    name: 'Hydration Habit',
    description: 'Log water 500 times',
    icon: 'auto_awesome',
    rarity: AchievementRarity.epic,
    category: AchievementCategory.milestone,
    color: Color(0xFFAB47BC),
  );

  static const logs1000 = AchievementDefinition(
    id: 'logs_1000',
    name: 'Legendary Logger',
    description: 'Log water 1000 times',
    icon: 'diamond',
    rarity: AchievementRarity.legendary,
    category: AchievementCategory.milestone,
    color: Color(0xFFFFD700),
  );

  /// All achievements list
  static const List<AchievementDefinition> all = [
    // Hydration
    firstDrop,
    hydrationHero,
    overachiever,
    hydrationMaster,
    // Streak
    streak3,
    streak7,
    streak14,
    streak30,
    streak100,
    // Consistency
    earlyBird,
    nightOwl,
    speedDrinker,
    perfectWeek,
    perfectMonth,
    // Milestone
    logs10,
    logs100,
    logs500,
    logs1000,
  ];

  /// Get achievement by ID
  static AchievementDefinition? getById(String id) {
    try {
      return all.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Get achievements by category
  static List<AchievementDefinition> byCategory(AchievementCategory category) {
    return all.where((a) => a.category == category).toList();
  }

  /// Get achievements by rarity
  static List<AchievementDefinition> byRarity(AchievementRarity rarity) {
    return all.where((a) => a.rarity == rarity).toList();
  }
}

