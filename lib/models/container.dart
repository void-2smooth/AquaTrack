import 'package:hive/hive.dart';

part 'container.g.dart';

/// Represents a saved water container/bottle preset
/// 
/// Users can create custom containers like "My Water Bottle - 750ml"
/// for quick access when logging water intake.
@HiveType(typeId: 2)
class WaterContainer extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  double amountMl;

  @HiveField(3)
  String icon; // Icon name from Material Icons

  @HiveField(4)
  int colorValue; // Color stored as int

  @HiveField(5)
  DateTime createdAt;

  @HiveField(6)
  bool isDefault; // If true, show in quick-add section

  WaterContainer({
    required this.id,
    required this.name,
    required this.amountMl,
    this.icon = 'local_drink',
    this.colorValue = 0xFF00B4D8, // Default to primary color
    DateTime? createdAt,
    this.isDefault = true,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Get the color as a Color object
  int get color => colorValue;

  /// Create a copy with updated fields
  WaterContainer copyWith({
    String? id,
    String? name,
    double? amountMl,
    String? icon,
    int? colorValue,
    DateTime? createdAt,
    bool? isDefault,
  }) {
    return WaterContainer(
      id: id ?? this.id,
      name: name ?? this.name,
      amountMl: amountMl ?? this.amountMl,
      icon: icon ?? this.icon,
      colorValue: colorValue ?? this.colorValue,
      createdAt: createdAt ?? this.createdAt,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  /// Format amount for display based on unit preference
  String formatAmount(bool useMetric) {
    if (useMetric) {
      if (amountMl >= 1000) {
        return '${(amountMl / 1000).toStringAsFixed(1)}L';
      }
      return '${amountMl.toStringAsFixed(0)}ml';
    } else {
      return '${(amountMl * 0.033814).toStringAsFixed(1)}oz';
    }
  }

  @override
  String toString() => 'WaterContainer(id: $id, name: $name, amountMl: $amountMl)';
}

/// Available container icons
class ContainerIcons {
  ContainerIcons._();

  static const List<String> icons = [
    'local_drink',
    'water_drop',
    'coffee',
    'sports_bar',
    'emoji_food_beverage',
    'free_breakfast',
    'local_cafe',
    'liquor',
    'wine_bar',
    'nightlife',
    'water',
    'opacity',
  ];

  /// Map icon name to IconData (used in UI)
  static const Map<String, int> iconCodePoints = {
    'local_drink': 0xe24e,
    'water_drop': 0xe798,
    'coffee': 0xe176,
    'sports_bar': 0xea69,
    'emoji_food_beverage': 0xe7ba,
    'free_breakfast': 0xe49d,
    'local_cafe': 0xe541,
    'liquor': 0xea60,
    'wine_bar': 0xf1e8,
    'nightlife': 0xea62,
    'water': 0xf084,
    'opacity': 0xe91c,
  };
}

/// Available container colors
class ContainerColors {
  ContainerColors._();

  static const List<int> colors = [
    0xFF00B4D8, // Primary cyan
    0xFF0077B6, // Deep blue
    0xFF48CAE4, // Light cyan
    0xFF4DD4AC, // Mint green
    0xFF6BCB77, // Fresh green
    0xFFFFD93D, // Golden yellow
    0xFFFF9F43, // Orange
    0xFFFF6B6B, // Coral
    0xFFEE5A24, // Red orange
    0xFF9B59B6, // Purple
    0xFFE91E63, // Pink
    0xFF607D8B, // Blue grey
  ];
}

/// Default containers for new users
class DefaultContainers {
  DefaultContainers._();

  static List<WaterContainer> getDefaults() {
    return [
      WaterContainer(
        id: 'default_glass',
        name: 'Glass',
        amountMl: 250,
        icon: 'local_drink',
        colorValue: 0xFF00B4D8,
        isDefault: true,
      ),
      WaterContainer(
        id: 'default_bottle',
        name: 'Bottle',
        amountMl: 500,
        icon: 'water_drop',
        colorValue: 0xFF0077B6,
        isDefault: true,
      ),
      WaterContainer(
        id: 'default_large_bottle',
        name: 'Large Bottle',
        amountMl: 750,
        icon: 'opacity',
        colorValue: 0xFF48CAE4,
        isDefault: true,
      ),
      WaterContainer(
        id: 'default_mug',
        name: 'Mug',
        amountMl: 350,
        icon: 'coffee',
        colorValue: 0xFF6BCB77,
        isDefault: true,
      ),
    ];
  }
}

