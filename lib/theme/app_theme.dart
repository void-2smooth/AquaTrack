import 'package:flutter/material.dart';

/// AquaTrack App Theme
/// 
/// Centralized theme configuration for consistent styling across the app.
/// Use [AppTheme.light] and [AppTheme.dark] for ThemeData.
/// Use [AppColors], [AppTextStyles], and [AppDimens] for specific values.

// ============================================================================
// COLORS
// ============================================================================

/// App color palette
class AppColors {
  AppColors._();

  // Primary Brand Colors
  static const Color primaryLight = Color(0xFF0EA5E9);  // Sky blue
  static const Color primaryDark = Color(0xFF38BDF8);   // Light sky blue
  
  // Water/Progress Colors
  static const Color waterBlue = Color(0xFF0EA5E9);
  static const Color waterBlueDark = Color(0xFF0284C7);
  
  // Progress Indicator Colors
  static const Color progressRed = Color(0xFFEF5350);
  static const Color progressOrange = Color(0xFFFFA726);
  static const Color progressYellow = Color(0xFFFFEE58);
  static const Color progressBlue = Color(0xFF29B6F6);
  static const Color progressGreen = Color(0xFF66BB6A);
  
  // Streak Colors
  static const Color streakFire = Color(0xFFFF9800);
  static const Color streakGold = Color(0xFFFFCA28);
  
  // Gradient Presets
  static const List<Color> motivationGradientLow = [Color(0xFFFF7043), Color(0xFFFFA726)];
  static const List<Color> motivationGradientMedium = [Color(0xFF42A5F5), Color(0xFF29B6F6)];
  static const List<Color> motivationGradientHigh = [Color(0xFF26A69A), Color(0xFF66BB6A)];
  static const List<Color> motivationGradientComplete = [Color(0xFF66BB6A), Color(0xFF26A69A)];
  
  // Semantic Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFC107);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);

  /// Get progress color based on completion percentage
  static Color getProgressColor(double progress) {
    if (progress < 0.25) return progressRed;
    if (progress < 0.5) return progressOrange;
    if (progress < 0.75) return progressYellow;
    if (progress < 1.0) return progressBlue;
    return progressGreen;
  }

  /// Get gradient colors based on completion percentage
  static List<Color> getMotivationGradient(double progress) {
    if (progress >= 1.0) return motivationGradientComplete;
    if (progress >= 0.5) return motivationGradientHigh;
    if (progress >= 0.25) return motivationGradientMedium;
    return motivationGradientLow;
  }
}

// ============================================================================
// DIMENSIONS
// ============================================================================

/// App dimension constants
class AppDimens {
  AppDimens._();

  // Padding & Margin
  static const double paddingXS = 4.0;
  static const double paddingS = 8.0;
  static const double paddingM = 12.0;
  static const double paddingL = 16.0;
  static const double paddingXL = 20.0;
  static const double paddingXXL = 24.0;
  static const double paddingXXXL = 32.0;

  // Border Radius
  static const double radiusXS = 4.0;
  static const double radiusS = 8.0;
  static const double radiusM = 12.0;
  static const double radiusL = 16.0;
  static const double radiusXL = 20.0;
  static const double radiusCircle = 100.0;

  // Icon Sizes
  static const double iconS = 16.0;
  static const double iconM = 20.0;
  static const double iconL = 24.0;
  static const double iconXL = 28.0;
  static const double iconXXL = 32.0;

  // Progress Bar
  static const double progressBarSize = 220.0;
  static const double progressBarLineWidth = 15.0;
  static const double progressBarCompactSize = 24.0;

  // Quick Add Button
  static const double quickAddButtonSize = 80.0;

  // Card
  static const double cardElevation = 0.0;

  // Bottom Navigation
  static const double bottomNavHeight = 80.0;

  // Animation Durations (in milliseconds)
  static const int animationFast = 200;
  static const int animationNormal = 300;
  static const int animationSlow = 500;
  static const int animationProgress = 800;
}

// ============================================================================
// TEXT STYLES
// ============================================================================

/// App text style presets (use with Theme.of(context).textTheme)
class AppTextStyles {
  AppTextStyles._();

  // Custom text styles that complement the theme
  static TextStyle progressPercentage(Color color) => TextStyle(
    fontSize: 48,
    fontWeight: FontWeight.bold,
    color: color,
  );

  static TextStyle streakValue = const TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
  );

  static TextStyle quickAddLabel = const TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.bold,
  );

  static TextStyle sectionHeader(Color color) => TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.bold,
    color: color,
  );
}

// ============================================================================
// THEME DATA
// ============================================================================

/// Main theme class
class AppTheme {
  AppTheme._();

  /// Light theme
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryLight,
        brightness: Brightness.light,
      ),
      
      // AppBar
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      
      // Card
      cardTheme: CardThemeData(
        elevation: AppDimens.cardElevation,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusL),
        ),
      ),
      
      // Bottom Navigation
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusL),
        ),
      ),
      
      // Floating Action Button
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusL),
        ),
      ),
      
      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusM),
        ),
        filled: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimens.paddingL,
          vertical: AppDimens.paddingM,
        ),
      ),
      
      // Elevated Button
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.paddingXL,
            vertical: AppDimens.paddingM,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimens.radiusM),
          ),
        ),
      ),
      
      // Outlined Button
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.paddingXL,
            vertical: AppDimens.paddingM,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimens.radiusM),
          ),
        ),
      ),
      
      // Filled Button
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.paddingXL,
            vertical: AppDimens.paddingM,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimens.radiusM),
          ),
        ),
      ),
      
      // Snackbar
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusM),
        ),
      ),
      
      // Dialog
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusXL),
        ),
      ),
      
      // Bottom Sheet
      bottomSheetTheme: const BottomSheetThemeData(
        showDragHandle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppDimens.radiusXL),
          ),
        ),
      ),
      
      // Chip
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusS),
        ),
      ),
      
      // List Tile
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusM),
        ),
      ),
      
      // Switch
      switchTheme: SwitchThemeData(
        thumbIcon: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const Icon(Icons.check, size: 14);
          }
          return null;
        }),
      ),
    );
  }

  /// Dark theme
  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryDark,
        brightness: Brightness.dark,
      ),
      
      // AppBar
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      
      // Card
      cardTheme: CardThemeData(
        elevation: AppDimens.cardElevation,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusL),
        ),
      ),
      
      // Bottom Navigation
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusL),
        ),
      ),
      
      // Floating Action Button
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusL),
        ),
      ),
      
      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusM),
        ),
        filled: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimens.paddingL,
          vertical: AppDimens.paddingM,
        ),
      ),
      
      // Elevated Button
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.paddingXL,
            vertical: AppDimens.paddingM,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimens.radiusM),
          ),
        ),
      ),
      
      // Outlined Button
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.paddingXL,
            vertical: AppDimens.paddingM,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimens.radiusM),
          ),
        ),
      ),
      
      // Filled Button
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.paddingXL,
            vertical: AppDimens.paddingM,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimens.radiusM),
          ),
        ),
      ),
      
      // Snackbar
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusM),
        ),
      ),
      
      // Dialog
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusXL),
        ),
      ),
      
      // Bottom Sheet
      bottomSheetTheme: const BottomSheetThemeData(
        showDragHandle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppDimens.radiusXL),
          ),
        ),
      ),
      
      // Chip
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusS),
        ),
      ),
      
      // List Tile
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusM),
        ),
      ),
      
      // Switch
      switchTheme: SwitchThemeData(
        thumbIcon: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const Icon(Icons.check, size: 14);
          }
          return null;
        }),
      ),
    );
  }
}

// ============================================================================
// EXTENSIONS
// ============================================================================

/// Extension for easier access to app colors from BuildContext
extension AppColorsExtension on BuildContext {
  /// Get progress color based on completion percentage
  Color progressColor(double progress) => AppColors.getProgressColor(progress);
  
  /// Get motivation gradient based on completion percentage
  List<Color> motivationGradient(double progress) => AppColors.getMotivationGradient(progress);
}

/// Extension for common spacing widgets
extension SpacingExtension on num {
  SizedBox get heightBox => SizedBox(height: toDouble());
  SizedBox get widthBox => SizedBox(width: toDouble());
}

