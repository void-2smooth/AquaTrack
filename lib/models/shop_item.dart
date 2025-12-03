import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

part 'shop_item.g.dart';

/// Shop item categories
enum ShopItemCategory {
  theme,        // App themes
  icon,         // App icons
  badge,        // Profile badges
  container,    // Custom containers
  animation,    // Celebration animations
  widget,       // UI widgets
}

/// Shop item rarity
enum ShopItemRarity {
  common,
  rare,
  epic,
  legendary,
}

/// Shop item model
@HiveType(typeId: 6)
class ShopItem extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String description;

  @HiveField(3)
  final ShopItemCategory category;

  @HiveField(4)
  final int price; // Points cost

  @HiveField(5)
  final ShopItemRarity rarity;

  @HiveField(6)
  final String icon; // Icon identifier or emoji

  @HiveField(7)
  final Map<String, dynamic>? data; // Category-specific data

  ShopItem({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.price,
    required this.rarity,
    required this.icon,
    this.data,
  });

  Color get rarityColor {
    switch (rarity) {
      case ShopItemRarity.common:
        return Colors.grey;
      case ShopItemRarity.rare:
        return Colors.blue;
      case ShopItemRarity.epic:
        return Colors.purple;
      case ShopItemRarity.legendary:
        return Colors.orange;
    }
  }

  String get rarityName {
    switch (rarity) {
      case ShopItemRarity.common:
        return 'Common';
      case ShopItemRarity.rare:
        return 'Rare';
      case ShopItemRarity.epic:
        return 'Epic';
      case ShopItemRarity.legendary:
        return 'Legendary';
    }
  }
}

/// User's purchased items
@HiveType(typeId: 7)
class PurchasedItem extends HiveObject {
  @HiveField(0)
  final String itemId;

  @HiveField(1)
  final DateTime purchasedAt;

  @HiveField(2)
  final bool isEquipped; // If applicable (themes, icons, etc.)

  PurchasedItem({
    required this.itemId,
    required this.purchasedAt,
    this.isEquipped = false,
  });

  PurchasedItem copyWith({
    String? itemId,
    DateTime? purchasedAt,
    bool? isEquipped,
  }) {
    return PurchasedItem(
      itemId: itemId ?? this.itemId,
      purchasedAt: purchasedAt ?? this.purchasedAt,
      isEquipped: isEquipped ?? this.isEquipped,
    );
  }
}

/// Shop catalog - all available items
class ShopCatalog {
  // Themes
  static final oceanTheme = ShopItem(
    id: 'theme_ocean',
    name: 'Ocean Theme',
    description: 'Deep blue ocean colors',
    category: ShopItemCategory.theme,
    price: 50,
    rarity: ShopItemRarity.common,
    icon: '🌊',
    data: {'themeId': 'ocean'},
  );

  static final forestTheme = ShopItem(
    id: 'theme_forest',
    name: 'Forest Theme',
    description: 'Green nature theme',
    category: ShopItemCategory.theme,
    price: 75,
    rarity: ShopItemRarity.rare,
    icon: '🌲',
    data: {'themeId': 'forest'},
  );

  static final sunsetTheme = ShopItem(
    id: 'theme_sunset',
    name: 'Sunset Theme',
    description: 'Warm orange and pink colors',
    category: ShopItemCategory.theme,
    price: 100,
    rarity: ShopItemRarity.epic,
    icon: '🌅',
    data: {'themeId': 'sunset'},
  );

  static final darkModePro = ShopItem(
    id: 'theme_dark_pro',
    name: 'Dark Mode Pro',
    description: 'Premium dark theme with glow effects',
    category: ShopItemCategory.theme,
    price: 150,
    rarity: ShopItemRarity.legendary,
    icon: '🌙',
    data: {'themeId': 'dark_pro'},
  );

  // Icons
  static final iconGold = ShopItem(
    id: 'icon_gold',
    name: 'Gold Water Drop',
    description: 'Shiny gold app icon',
    category: ShopItemCategory.icon,
    price: 200,
    rarity: ShopItemRarity.epic,
    icon: '💧',
    data: {'iconId': 'gold'},
  );

  static final iconCrystal = ShopItem(
    id: 'icon_crystal',
    name: 'Crystal Drop',
    description: 'Crystal clear water icon',
    category: ShopItemCategory.icon,
    price: 300,
    rarity: ShopItemRarity.legendary,
    icon: '💎',
    data: {'iconId': 'crystal'},
  );

  // Badges
  static final badgeHydrationMaster = ShopItem(
    id: 'badge_master',
    name: 'Hydration Master',
    description: 'Show off your expertise',
    category: ShopItemCategory.badge,
    price: 100,
    rarity: ShopItemRarity.rare,
    icon: '👑',
    data: {'badgeId': 'master'},
  );

  static final badgeStreakKing = ShopItem(
    id: 'badge_streak_king',
    name: 'Streak King',
    description: 'For maintaining long streaks',
    category: ShopItemCategory.badge,
    price: 150,
    rarity: ShopItemRarity.epic,
    icon: '🔥',
    data: {'badgeId': 'streak_king'},
  );

  static final badgeChampion = ShopItem(
    id: 'badge_champion',
    name: 'Champion',
    description: 'Ultimate achievement badge',
    category: ShopItemCategory.badge,
    price: 500,
    rarity: ShopItemRarity.legendary,
    icon: '🏆',
    data: {'badgeId': 'champion'},
  );

  // Containers
  static final containerMega = ShopItem(
    id: 'container_mega',
    name: 'Mega Bottle',
    description: '2L mega water bottle',
    category: ShopItemCategory.container,
    price: 50,
    rarity: ShopItemRarity.common,
    icon: '🥤',
    data: {'amountMl': 2000, 'name': 'Mega Bottle'},
  );

  static final containerSports = ShopItem(
    id: 'container_sports',
    name: 'Sports Bottle',
    description: '750ml sports bottle',
    category: ShopItemCategory.container,
    price: 30,
    rarity: ShopItemRarity.common,
    icon: '🏃',
    data: {'amountMl': 750, 'name': 'Sports Bottle'},
  );

  // Animations
  static final animationRainbow = ShopItem(
    id: 'animation_rainbow',
    name: 'Rainbow Confetti',
    description: 'Colorful rainbow celebration',
    category: ShopItemCategory.animation,
    price: 200,
    rarity: ShopItemRarity.epic,
    icon: '🌈',
    data: {'animationId': 'rainbow'},
  );

  static final animationFireworks = ShopItem(
    id: 'animation_fireworks',
    name: 'Fireworks',
    description: 'Explosive celebration effect',
    category: ShopItemCategory.animation,
    price: 300,
    rarity: ShopItemRarity.legendary,
    icon: '🎆',
    data: {'animationId': 'fireworks'},
  );

  /// All shop items
  static final List<ShopItem> all = [
    // Themes
    oceanTheme,
    forestTheme,
    sunsetTheme,
    darkModePro,
    // Icons
    iconGold,
    iconCrystal,
    // Badges
    badgeHydrationMaster,
    badgeStreakKing,
    badgeChampion,
    // Containers
    containerMega,
    containerSports,
    // Animations
    animationRainbow,
    animationFireworks,
  ];

  /// Get item by ID
  static ShopItem? getById(String id) {
    try {
      return all.firstWhere((item) => item.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Get items by category
  static List<ShopItem> byCategory(ShopItemCategory category) {
    return all.where((item) => item.category == category).toList();
  }

  /// Get items by rarity
  static List<ShopItem> byRarity(ShopItemRarity rarity) {
    return all.where((item) => item.rarity == rarity).toList();
  }
}

