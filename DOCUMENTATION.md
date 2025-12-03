# AquaTrack Documentation

> Complete technical documentation for the AquaTrack Flutter application

---

## Table of Contents

1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Data Models](#data-models)
4. [State Management](#state-management)
5. [Services](#services)
6. [Screens](#screens)
7. [Widgets](#widgets)
8. [Theming](#theming)
9. [Storage](#storage)
10. [Notifications](#notifications)
11. [API Reference](#api-reference)
12. [Testing](#testing)
13. [Troubleshooting](#troubleshooting)

---

## Overview

AquaTrack is a cross-platform mobile application built with Flutter that helps users track their daily water intake. The app follows clean architecture principles with clear separation of concerns between UI, business logic, and data layers.

### Key Technologies

| Technology | Version | Purpose |
|------------|---------|---------|
| Flutter | 3.0+ | UI Framework |
| Dart | 3.0+ | Programming Language |
| Riverpod | 2.4.9 | State Management |
| Hive | 2.2.3 | Local Storage |
| flutter_local_notifications | 16.3.0 | Push Notifications |
| percent_indicator | 4.2.3 | Progress Visualization |

---

## Architecture

### Directory Structure

```
lib/
├── main.dart                 # Application entry point
├── models/                   # Data models & entities
├── providers/                # Riverpod state providers
├── screens/                  # Full-page UI components
├── services/                 # Business logic & external services
└── widgets/                  # Reusable UI components
```

### Data Flow

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   Widgets   │ ←── │  Providers  │ ←── │  Services   │
│   (UI)      │     │  (State)    │     │  (Logic)    │
└─────────────┘     └─────────────┘     └─────────────┘
                           ↑                   ↑
                           │                   │
                    ┌─────────────┐     ┌─────────────┐
                    │   Models    │     │    Hive     │
                    │   (Data)    │     │  (Storage)  │
                    └─────────────┘     └─────────────┘
```

---

## Data Models

### WaterEntry

Represents a single water intake record.

**Location:** `lib/models/water_entry.dart`

```dart
@HiveType(typeId: 0)
class WaterEntry extends HiveObject {
  @HiveField(0) final String id;
  @HiveField(1) final double amountMl;
  @HiveField(2) final DateTime timestamp;
  @HiveField(3) final String? note;
}
```

| Field | Type | Description |
|-------|------|-------------|
| `id` | `String` | Unique identifier (UUID) |
| `amountMl` | `double` | Water amount in milliliters |
| `timestamp` | `DateTime` | When the entry was recorded |
| `note` | `String?` | Optional note for the entry |

**Computed Properties:**
- `amountLiters` - Converts ml to liters
- `amountOz` - Converts ml to fluid ounces

---

### UserSettings

Stores user preferences, profile data, and streak information.

```dart
@HiveType(typeId: 1)
class UserSettings extends HiveObject {
  @HiveField(0) double dailyGoalMl;
  @HiveField(1) bool useMetricUnits;
  @HiveField(2) bool notificationsEnabled;
  @HiveField(3) int reminderIntervalMinutes;
  @HiveField(4) bool isDarkMode;
  @HiveField(5) int currentStreak;
  @HiveField(6) int longestStreak;
  @HiveField(7) DateTime? lastActiveDate;
  @HiveField(8) String? userName;              // User's name for personalization
  @HiveField(9) double? weightKg;              // Weight in kilograms
  @HiveField(10) int? activityLevel;           // Activity level (0-4)
  @HiveField(11) bool useCustomGoal;            // Use custom vs calculated goal
  @HiveField(12) double? calculatedGoalMl;      // Calculated goal from profile
}
```

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `dailyGoalMl` | `double` | 2000 | Daily goal in milliliters |
| `useMetricUnits` | `bool` | true | true = Liters, false = Ounces |
| `notificationsEnabled` | `bool` | false | Enable/disable reminders |
| `reminderIntervalMinutes` | `int` | 60 | Minutes between reminders |
| `isDarkMode` | `bool` | false | Theme preference |
| `currentStreak` | `int` | 0 | Current consecutive days |
| `longestStreak` | `int` | 0 | Best streak achieved |
| `lastActiveDate` | `DateTime?` | null | Last goal completion date |
| `userName` | `String?` | null | User's name for personalization |
| `weightKg` | `double?` | null | Weight in kilograms for goal calculation |
| `activityLevel` | `int?` | null | Activity level enum index (0-4) |
| `useCustomGoal` | `bool` | true | If false, use calculated goal |
| `calculatedGoalMl` | `double?` | null | Auto-calculated goal from weight/activity |

**Computed Properties:**
- `effectiveDailyGoalMl` - Returns custom or calculated goal
- `activityLevelEnum` - Converts int to ActivityLevel enum
- `hasCompletedProfile` - Checks if user has set name

**Activity Levels:**
- `sedentary` - Little to no exercise (1.0x multiplier)
- `light` - Light exercise 1-3 days/week (1.1x)
- `moderate` - Moderate exercise 3-5 days/week (1.2x)
- `active` - Hard exercise 6-7 days/week (1.35x)
- `veryActive` - Very hard exercise, physical job (1.5x)

---

### DailySummary

Aggregated data for a single day (not persisted).

```dart
class DailySummary {
  final DateTime date;
  final double totalAmountMl;
  final double goalMl;
  final int entryCount;
  final bool goalReached;
}
```

**Computed Properties:**
- `completionPercentage` - Progress as decimal (can exceed 1.0)
- `completionPercentageCapped` - Progress clamped to 0.0-1.0

---

### WaterContainer

Saved container presets for quick water entry.

**Location:** `lib/models/container.dart`

```dart
@HiveType(typeId: 2)
class WaterContainer extends HiveObject {
  @HiveField(0) final String id;
  @HiveField(1) final String name;
  @HiveField(2) final double amountMl;
  @HiveField(3) final bool isDefault;
  @HiveField(4) final int colorValue;
  @HiveField(5) final String iconName;
}
```

---

### Achievement Models

**Location:** `lib/models/achievement.dart`

#### AchievementDefinition

Static achievement data with rarity, category, and visual properties.

```dart
class AchievementDefinition {
  final String id;
  final String name;
  final String description;
  final String icon;
  final AchievementRarity rarity;
  final AchievementCategory category;
  final Color color;
}
```

**Rarity Levels:**
- `common` - Basic achievements (grey)
- `rare` - Uncommon achievements (blue)
- `epic` - Special achievements (purple)
- `legendary` - Ultimate achievements (gold)

**Categories:**
- `hydration` - Water intake milestones
- `streak` - Consecutive day achievements
- `consistency` - Regular habit achievements
- `milestone` - Total count achievements

#### UnlockedAchievement

Stored achievement unlock record.

```dart
@HiveType(typeId: 4)
class UnlockedAchievement extends HiveObject {
  @HiveField(0) final String achievementId;
  @HiveField(1) final DateTime unlockedAt;
  @HiveField(2) final bool seen;
}
```

**Total Achievements:** 18 unique achievements across all categories

---

## State Management

AquaTrack uses **Riverpod** for state management. All providers are defined in `lib/providers/providers.dart`.

### Provider Hierarchy

```
storageServiceProvider (Provider)
       ↓
settingsProvider (StateNotifierProvider)
       ↓
todayEntriesProvider (StateNotifierProvider)
       ↓
┌──────┴──────┬──────────────┬─────────────────┐
↓             ↓              ↓                 ↓
todayTotal    todayProgress  motivational      quickAddAmounts
Provider      Provider       MessageProvider   Provider
```

### Core Providers

#### storageServiceProvider

```dart
final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});
```

Provides singleton access to the storage service.

---

#### settingsProvider

```dart
final settingsProvider = StateNotifierProvider<SettingsNotifier, UserSettings>((ref) {
  final storageService = ref.watch(storageServiceProvider);
  return SettingsNotifier(storageService);
});
```

**Available Actions:**
- `updateDailyGoal(double goalMl)`
- `toggleDarkMode(bool isDark)`
- `toggleUnitSystem(bool useMetric)`
- `updateNotificationSettings({required bool enabled, int intervalMinutes})`
- `refresh()`

---

#### todayEntriesProvider

```dart
final todayEntriesProvider = StateNotifierProvider<WaterEntriesNotifier, List<WaterEntry>>((ref) {
  final storageService = ref.watch(storageServiceProvider);
  return WaterEntriesNotifier(storageService, ref);
});
```

**Available Actions:**
- `addEntry(double amountMl, {String? note})`
- `deleteEntry(String id)`
- `refresh()`

---

#### Computed Providers

| Provider | Type | Description |
|----------|------|-------------|
| `todayTotalProvider` | `double` | Total ml consumed today |
| `todayProgressProvider` | `double` | Progress 0.0-1.0 (capped) |
| `todayProgressUncappedProvider` | `double` | Progress (can exceed 1.0) |
| `themeModeProvider` | `ThemeMode` | Current theme mode |
| `motivationalMessageProvider` | `String` | Dynamic message based on progress |
| `quickAddAmountsProvider` | `List<QuickAddAmount>` | Quick-add button values |
| `dailySummariesProvider` | `List<DailySummary>` | Last 30 days history |

---

## Services

### StorageService

**Location:** `lib/services/storage_service.dart`

Handles all Hive database operations.

#### Initialization

```dart
final storageService = StorageService();
await storageService.init();
```

#### Water Entry Methods

| Method | Parameters | Returns | Description |
|--------|------------|---------|-------------|
| `addWaterEntry` | `double amountMl, {String? note}` | `Future<WaterEntry>` | Creates new entry |
| `getAllEntries` | - | `List<WaterEntry>` | All entries |
| `getEntriesForDate` | `DateTime date` | `List<WaterEntry>` | Entries for specific date |
| `getTodayEntries` | - | `List<WaterEntry>` | Today's entries |
| `getTodayTotalMl` | - | `double` | Today's total intake |
| `getTotalForDate` | `DateTime date` | `double` | Total for specific date |
| `deleteEntry` | `String id` | `Future<void>` | Removes entry |
| `updateEntry` | `WaterEntry entry` | `Future<void>` | Updates entry |
| `getDailySummaries` | `{int days = 30}` | `List<DailySummary>` | Historical summaries |

#### Settings Methods

| Method | Parameters | Returns | Description |
|--------|------------|---------|-------------|
| `getSettings` | - | `UserSettings` | Current settings |
| `updateSettings` | `UserSettings settings` | `Future<void>` | Save settings |
| `updateDailyGoal` | `double goalMl` | `Future<void>` | Update goal |
| `toggleDarkMode` | `bool isDark` | `Future<void>` | Toggle theme |
| `toggleUnitSystem` | `bool useMetric` | `Future<void>` | Toggle units |

#### Streak Methods

| Method | Description |
|--------|-------------|
| `updateStreak()` | Calculates and updates streak based on goal completion |

---

### NotificationService

**Location:** `lib/services/notification_service.dart`

Manages local push notifications for water reminders.

> **Note:** Notifications are not supported on web platform.

#### Initialization

```dart
final notificationService = NotificationService();
await notificationService.init(); // Skip on web
```

#### Methods

| Method | Parameters | Returns | Description |
|--------|------------|---------|-------------|
| `init` | - | `Future<void>` | Initialize notification system |
| `requestPermissions` | - | `Future<bool>` | Request OS permissions |
| `scheduleReminders` | `{required int intervalMinutes, int startHour, int endHour}` | `Future<void>` | Set up periodic reminders |
| `scheduleReminderAt` | `DateTime scheduledTime` | `Future<void>` | One-time reminder |
| `cancelAllReminders` | - | `Future<void>` | Cancel all notifications |
| `cancelReminder` | `int id` | `Future<void>` | Cancel specific notification |
| `showTestNotification` | - | `Future<void>` | Send test notification |
| `areNotificationsEnabled` | - | `Future<bool>` | Check permission status |

---

## Screens

### SplashScreen

**Location:** `lib/screens/splash_screen.dart`

App startup screen with personalized greeting and loading animation.

**Features:**
- Personalized greeting with user's name
- Time-based greetings (Good Morning/Afternoon/Evening/Night)
- Animated logo display
- Status message cycling ("Getting things ready...", etc.)
- Floating water particle animations
- 5-second delay before navigation
- Automatic routing based on user state

**Navigation Flow:**
- No name → Login screen
- Name but no weight → Profile setup
- Complete profile → Home screen

---

### LoginScreen

**Location:** `lib/screens/login_screen.dart`

Simple name-based login (no password required).

**Features:**
- Name input with validation
- Beautiful gradient background
- Animated water drop icon
- Navigates to profile setup or home after login
- Name persists in Hive storage

---

### ProfileSetupScreen

**Location:** `lib/screens/profile_setup_screen.dart`

User profile configuration for personalized water goals.

**Features:**
- Weight input (kg or lbs)
- Activity level selection (5 levels)
- Automatic goal calculation based on:
  - Weight: 30-35ml per kg base
  - Activity multiplier: 1.0x to 1.5x
- Toggle between calculated and custom goal
- Real-time goal preview
- Saves profile and navigates to home

**Goal Calculation Formula:**
```
Base = Weight (kg) × 32.5ml
Goal = Base × Activity Multiplier
```

---

### HomeScreen

**Location:** `lib/screens/home_screen.dart`

Main dashboard showing today's progress.

**Components:**
- Personalized header with greeting and user's name
- `WaterProgressBar` - Circular progress indicator
- `MotivationalMessage` - Dynamic encouragement
- `StreakDisplay` - Current and best streaks
- `WaterAddButtons` - Container presets and quick-add
- `MotivationalTip` - Daily hydration tips
- `LargeAddButton` - FAB for default amount

---

### HistoryScreen

**Location:** `lib/screens/history_screen.dart`

Historical view of water intake with visualizations.

**Features:**
- Weekly bar chart visualization (7 days)
- 30-day statistics header (goals met, success rate, daily average)
- List of daily summaries
- Visual indicators for goal completion
- Tap to view day details
- Goal line indicator on chart

---

### AchievementsScreen

**Location:** `lib/screens/achievements_screen.dart`

Achievement gallery showing all available and unlocked achievements.

**Features:**
- Progress header with unlock count
- Category organization (Hydration, Streaks, Consistency, Milestones)
- Rarity badges (Common, Rare, Epic, Legendary)
- Locked/unlocked visual states
- Achievement details and descriptions
- Auto-marks achievements as seen when viewed

---

### SettingsScreen

**Location:** `lib/screens/settings_screen.dart`

App configuration and preferences.

**Sections:**
1. **Daily Goal** - Preset buttons (1.5L, 2L, 2.5L, 3L) + custom input
2. **Measurement Units** - Metric (L/ml) or Imperial (oz)
3. **Appearance** - Dark mode toggle
4. **Notifications** - Enable/disable, interval selection, test button
5. **Data** - Export (coming soon), clear all data
6. **About** - App version with debug menu unlock (tap 7 times)

**Debug Menu Access:**
- Tap version text 7 times quickly
- Shows progress ("X more taps to unlock")
- Unlocks debug menu in About section

---

### DebugScreen

**Location:** `lib/screens/debug_screen.dart`

Comprehensive developer tools and testing utilities.

**Sections:**
1. **⚡ Performance** - FPS, build count, build time
2. **🔄 Provider Stats** - State update tracking
3. **💾 Storage Stats** - Data statistics
4. **📊 App State** - Current app state values
5. **💧 Water Actions** - Add water, complete goals
6. **🔥 Streak Actions** - Set streak values
7. **🎉 Celebrations** - Trigger animations
8. **🏆 Achievements** - Unlock/lock achievements
9. **💾 Data Actions** - Restart app, reset data

**Features:**
- Real-time performance monitoring
- Provider update analytics
- Quick testing actions
- Restart app functionality
- Reset all data option

---

## Widgets

### WaterProgressBar

**Location:** `lib/widgets/progress_bar.dart`

Circular progress indicator showing daily intake.

```dart
const WaterProgressBar({
  double size = 220.0,
  double lineWidth = 15.0,
});
```

**Features:**
- Animated percentage fill
- Dynamic color (red → orange → yellow → blue → green)
- Current/goal amount display
- Status text footer

---

### CompactProgressIndicator

Small progress indicator for app bars or cards.

```dart
const CompactProgressIndicator();
```

---

### WaterAddButtons

**Location:** `lib/widgets/water_add_buttons.dart`

Quick-add buttons for logging water intake.

**Features:**
- 4 preset amounts (adapts to metric/imperial)
- Custom amount dialog
- Haptic feedback
- Snackbar confirmation

---

### LargeAddButton

Floating action button for quick default entry.

```dart
const LargeAddButton();
```

Adds 250ml (metric) or 8oz (imperial) with one tap.

---

### MotivationalMessage

**Location:** `lib/widgets/motivational_message.dart`

Dynamic message card based on progress.

**Message Thresholds:**
| Progress | Message Example |
|----------|-----------------|
| 0% | "Start your hydration journey today! 💧" |
| 1-24% | "Great start! Keep drinking! 🌱" |
| 25-49% | "You're making progress! Stay hydrated! 💪" |
| 50-74% | "Halfway there! You're doing amazing! 🌟" |
| 75-99% | "Almost at your goal! Keep it up! 🎯" |
| 100% | "🎉 Goal reached! You're a hydration champion!" |
| >100% | "🏆 Exceeding expectations! Incredible work!" |

---

### StreakDisplay

Shows current and longest streak.

---

### WeeklyChart

**Location:** `lib/widgets/weekly_chart.dart`

Beautiful animated bar chart showing 7-day water intake.

**Features:**
- Interactive bar chart with touch tooltips
- Goal line indicator (dashed)
- Color-coded bars (green for goal met)
- Day labels (M, T, W, T, F, S, S)
- Weekly statistics summary
- Animated transitions

**Usage:**
```dart
const WeeklyChart()
```

**Components:**
- `WeeklyChart` - Full chart with stats
- `WeeklyMiniChart` - Compact version for home screen

---

### Celebration Widgets

**Location:** `lib/widgets/celebration.dart`

Celebration animations and popups for achievements and milestones.

**Widgets:**
- `AchievementUnlockPopup` - Full-screen achievement unlock animation
- `GoalReachedBanner` - Slide-down banner for goal completion
- `StreakMilestoneBanner` - Special streak celebration
- `CelebrationOverlay` - Confetti animation wrapper

**Features:**
- Confetti animations
- Glow effects
- Auto-dismiss timers
- Smooth animations

```dart
const StreakDisplay();
```

---

### MotivationalTip

Daily hydration tips carousel.

```dart
const MotivationalTip();
```

---

## Theming

### Light Theme

```dart
ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFF0EA5E9), // Sky blue
    brightness: Brightness.light,
  ),
);
```

### Dark Theme

```dart
ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFF38BDF8), // Light sky blue
    brightness: Brightness.dark,
  ),
);
```

### Theme Toggle

Toggle is controlled via `settingsProvider`:

```dart
ref.read(settingsProvider.notifier).toggleDarkMode(true);
```

---

## Storage

### Hive Boxes

| Box Name | Type | Purpose |
|----------|------|---------|
| `water_entries` | `Box<WaterEntry>` | All water intake records |
| `user_settings` | `Box<UserSettings>` | User preferences |

### Type Adapters

Adapters are pre-generated in `water_entry.g.dart`:
- `WaterEntryAdapter` (typeId: 0)
- `UserSettingsAdapter` (typeId: 1)

### Regenerating Adapters

If you modify the models:

```bash
flutter packages pub run build_runner build
```

---

## Notifications

### Android Setup

The app uses `@mipmap/ic_launcher` as the notification icon. For a custom icon:

1. Add icon to `android/app/src/main/res/drawable/`
2. Update `AndroidNotificationDetails` in `notification_service.dart`

### iOS Setup

Add to `ios/Runner/Info.plist`:

```xml
<key>UIBackgroundModes</key>
<array>
  <string>fetch</string>
  <string>remote-notification</string>
</array>
```

### Notification Channel

- **ID:** `aquatrack_reminders`
- **Name:** `Water Reminders`
- **Importance:** High

---

## API Reference

### Unit Conversions

```dart
// Milliliters to Liters
double liters = ml / 1000;

// Milliliters to Fluid Ounces
double oz = ml * 0.033814;

// Fluid Ounces to Milliliters
double ml = oz / 0.033814;
```

### Quick Add Amounts

**Metric:**
| Label | Amount (ml) |
|-------|-------------|
| 100ml | 100 |
| 250ml | 250 |
| 500ml | 500 |
| 1L | 1000 |

**Imperial:**
| Label | Amount (ml) |
|-------|-------------|
| 4oz | 118.294 |
| 8oz | 236.588 |
| 16oz | 473.176 |
| 32oz | 946.353 |

---

## Testing

### Running Tests

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage
```

### Test Structure (Recommended)

```
test/
├── models/
│   └── water_entry_test.dart
├── providers/
│   └── providers_test.dart
├── services/
│   ├── storage_service_test.dart
│   └── notification_service_test.dart
└── widgets/
    └── progress_bar_test.dart
```

---

## Troubleshooting

### Common Issues

#### App doesn't load on web

**Cause:** Platform-specific code failing on web

**Solution:** Ensure `kIsWeb` checks are in place for:
- `SystemChrome.setPreferredOrientations`
- Notification service initialization

#### Hive not initialized error

**Cause:** Accessing storage before `init()` completes

**Solution:** Ensure `await storageService.init()` completes in `main()` before `runApp()`

#### Notifications not showing (Android)

**Cause:** Missing permissions on Android 13+

**Solution:** The app requests permissions at runtime. Check device notification settings.

#### Notifications not showing (iOS)

**Cause:** Missing Info.plist configuration

**Solution:** Add background modes to Info.plist (see [iOS Setup](#ios-setup))

### Debug Mode

To enable verbose logging:

```dart
// In main.dart
import 'dart:developer';

log('Storage initialized');
log('Settings loaded: ${settings.dailyGoalMl}');
```

---

## Future Enhancements

The codebase includes TODO comments for planned features:

- [ ] Undo last water entry
- [ ] Export data as CSV/JSON
- [ ] Individual entry view for each day
- [ ] Custom notification sounds
- [ ] Widget for home screen
- [ ] Apple Watch / Wear OS support
- [ ] Cloud sync with Firebase
- [ ] Social sharing of achievements

---

<p align="center">
  <i>Documentation last updated: December 2024</i>
</p>

