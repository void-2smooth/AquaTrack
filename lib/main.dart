import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:confetti/confetti.dart';
import 'dart:math';
import 'services/storage_service.dart';
import 'services/notification_service.dart';
import 'providers/providers.dart';
import 'screens/home_screen.dart';
import 'screens/history_screen.dart';
import 'screens/achievements_screen.dart';
import 'screens/challenges_screen.dart';
import 'screens/shop_screen.dart';
import 'screens/analytics_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/login_screen.dart';
import 'screens/profile_setup_screen.dart';
import 'screens/splash_screen.dart';
import 'widgets/celebration.dart';
import 'theme/app_theme.dart';

/// AquaTrack - Daily Water Reminder App
/// 
/// Main entry point for the application.
/// Initializes services and sets up the app with Riverpod for state management.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize storage service
  final storageService = StorageService();
  await storageService.init();

  // Initialize notification service (not supported on web)
  final notificationService = NotificationService();
  if (!kIsWeb) {
    await notificationService.init();
  }

  // Set preferred orientations (not supported on web)
  if (!kIsWeb) {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  runApp(
    ProviderScope(
      observers: [ProviderLogger()],
      overrides: [
        // Override with initialized services
        storageServiceProvider.overrideWithValue(storageService),
        notificationServiceProvider.overrideWithValue(notificationService),
      ],
      child: const AquaTrackApp(),
    ),
  );
}

/// Provider observer for debugging and performance monitoring
class ProviderLogger extends ProviderObserver {
  static int updateCount = 0;
  static final Map<String, int> providerUpdateCounts = {};
  
  @override
  void didUpdateProvider(
    ProviderBase<Object?> provider,
    Object? previousValue,
    Object? newValue,
    ProviderContainer container,
  ) {
    updateCount++;
    final name = provider.name ?? provider.runtimeType.toString();
    providerUpdateCounts[name] = (providerUpdateCounts[name] ?? 0) + 1;
    
    // Uncomment for verbose logging during development:
    // debugPrint('[Provider] $name updated (total: ${providerUpdateCounts[name]})');
  }
  
  @override
  void didAddProvider(
    ProviderBase<Object?> provider,
    Object? value,
    ProviderContainer container,
  ) {
    // Provider was created
  }
  
  @override
  void didDisposeProvider(
    ProviderBase<Object?> provider,
    ProviderContainer container,
  ) {
    // Provider was disposed
  }
  
  /// Reset all counters
  static void reset() {
    updateCount = 0;
    providerUpdateCounts.clear();
  }
  
  /// Get most frequently updated providers
  static List<MapEntry<String, int>> getTopProviders({int limit = 5}) {
    final sorted = providerUpdateCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(limit).toList();
  }
}

/// Root application widget
class AquaTrackApp extends ConsumerWidget {
  const AquaTrackApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'AquaTrack',
      debugShowCheckedModeBanner: false,
      
      // Use centralized theme
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      
      // Always start with splash screen
      home: const SplashScreen(),
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/profile-setup': (context) => const ProfileSetupScreen(),
        '/home': (context) => const MainNavigationScreen(),
      },
    );
  }
}

/// Main navigation screen with bottom navigation bar
class MainNavigationScreen extends ConsumerStatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  ConsumerState<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends ConsumerState<MainNavigationScreen> {
  int _selectedIndex = 0;
  late ConfettiController _confettiController;

  // List of screens for navigation
  final List<Widget> _screens = const [
    HomeScreen(),
    HistoryScreen(),
    AnalyticsScreen(),
    ChallengesScreen(),
    ShopScreen(),
    AchievementsScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final celebrationState = ref.watch(celebrationProvider);
    
    // Listen for goal reached celebration
    ref.listen(celebrationProvider, (previous, next) {
      if (next.showGoalCelebration && !(previous?.showGoalCelebration ?? false)) {
        _confettiController.play();
      }
      if (next.showAchievementCelebration && !(previous?.showAchievementCelebration ?? false)) {
        _confettiController.play();
      }
    });

    // Get unseen achievements count for badge
    final unseenCount = ref.read(achievementsProvider.notifier).unseenCount;

    return Scaffold(
      body: Stack(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: AppDimens.animationNormal),
            child: _screens[_selectedIndex],
          ),
          
          // Confetti overlay
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: pi / 2,
              maxBlastForce: 5,
              minBlastForce: 2,
              emissionFrequency: 0.05,
              numberOfParticles: 25,
              gravity: 0.2,
              shouldLoop: false,
              colors: const [
                AppColors.waterLight,
                AppColors.waterMedium,
                AppColors.success,
                AppColors.streakGold,
                Color(0xFFFF6B6B),
                Color(0xFFAB47BC),
              ],
            ),
          ),
          
          // Goal celebration banner
          if (celebrationState.showGoalCelebration)
            SafeArea(
              child: GoalReachedBanner(
                onDismiss: () {
                  ref.read(celebrationProvider.notifier).dismissGoalCelebration();
                },
              ),
            ),
          
          // Achievement celebration popup
          if (celebrationState.showAchievementCelebration && celebrationState.achievement != null)
            Center(
              child: AchievementUnlockPopup(
                achievement: celebrationState.achievement!,
                onDismiss: () {
                  ref.read(celebrationProvider.notifier).dismissAchievementCelebration();
                },
              ),
            ),
          
          // Challenge completion popup
          if (celebrationState.showChallengeCelebration && 
              celebrationState.challengeDefinition != null &&
              celebrationState.challengeCompleted != null)
            Center(
              child: ChallengeCompletionPopup(
                definition: celebrationState.challengeDefinition!,
                challenge: celebrationState.challengeCompleted!,
                onDismiss: () {
                  ref.read(celebrationProvider.notifier).dismissChallengeCelebration();
                },
              ),
            ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.water_drop_outlined),
            selectedIcon: Icon(Icons.water_drop),
            label: 'Today',
          ),
          const NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'History',
          ),
          const NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights),
            label: 'Analytics',
          ),
          const NavigationDestination(
            icon: Icon(Icons.emoji_events_outlined),
            selectedIcon: Icon(Icons.emoji_events),
            label: 'Challenges',
          ),
          const NavigationDestination(
            icon: Icon(Icons.shopping_bag_outlined),
            selectedIcon: Icon(Icons.shopping_bag),
            label: 'Shop',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: unseenCount > 0,
              label: Text('$unseenCount'),
              child: const Icon(Icons.workspace_premium_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: unseenCount > 0,
              label: Text('$unseenCount'),
              child: const Icon(Icons.workspace_premium),
            ),
            label: 'Trophies',
          ),
          const NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
