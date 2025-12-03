import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../providers/providers.dart';
import '../widgets/progress_bar.dart';
import '../widgets/water_add_buttons.dart';
import '../widgets/motivational_message.dart';
import '../widgets/challenge_card.dart';

/// Home screen - Main screen showing today's progress
/// 
/// Modern, rounded aesthetic with excellent UX design
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = context.isDarkMode;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [AppColors.darkBackgroundStart, AppColors.darkBackgroundEnd]
                : [AppColors.backgroundStart, AppColors.backgroundEnd],
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppDimens.paddingXXL,
                    AppDimens.paddingL,
                    AppDimens.paddingXXL,
                    AppDimens.paddingS,
                  ),
                  child: _buildHeader(context, ref),
                ),
              ),
              
              // Main Content
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: AppDimens.paddingXXL),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    SizedBox(height: AppDimens.paddingXL),
                    
                    // Progress Card with gradient background
                    _buildProgressCard(context, isDark),
                    SizedBox(height: AppDimens.paddingXXL),
                    
                    // Active Challenge
                    const ChallengeCard(),
                    
                    // Motivational Message
                    const MotivationalMessage(),
                    SizedBox(height: AppDimens.paddingXL),
                    
                    // Streak Display
                    const StreakDisplay(),
                    SizedBox(height: AppDimens.paddingXXL),
                    
                    // Quick Add Section
                    _buildQuickAddSection(context, theme),
                    SizedBox(height: AppDimens.paddingXL),
                    
                    // Daily Tip
                    const MotivationalTip(),
                    SizedBox(height: AppDimens.bottomNavHeight + AppDimens.paddingXXL),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: const LargeAddButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final settings = ref.watch(settingsProvider);
    final userName = settings.userName;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _getGreeting(userName),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            SizedBox(height: AppDimens.paddingXS),
            Text(
              userName != null ? 'Stay Hydrated, ${userName.split(' ').first}! 💧' : 'Stay Hydrated 💧',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        // Date badge
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: AppDimens.paddingM,
            vertical: AppDimens.paddingS,
          ),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withOpacity(0.5),
            borderRadius: BorderRadius.circular(AppDimens.radiusCircle),
          ),
          child: Text(
            _getFormattedDate(),
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressCard(BuildContext context, bool isDark) {
    // Use RepaintBoundary to isolate expensive progress bar repaints
    return RepaintBoundary(
      child: Container(
        padding: EdgeInsets.all(AppDimens.paddingXXL),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [AppColors.cardDark, AppColors.cardDark.withOpacity(0.8)]
                : [Colors.white, Colors.white.withOpacity(0.9)],
          ),
          borderRadius: BorderRadius.circular(AppDimens.radiusXXL),
          boxShadow: isDark ? [] : AppShadows.large,
          border: isDark
              ? Border.all(color: Colors.white.withOpacity(0.1))
              : null,
        ),
        child: const Column(
          children: [
            WaterProgressBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAddSection(BuildContext context, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: AppDimens.paddingXS),
          child: Text(
            'My Containers',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(height: AppDimens.paddingM),
        const WaterAddButtons(),
      ],
    );
  }

  String _getGreeting(String? userName) {
    final hour = DateTime.now().hour;
    String greeting;
    if (hour < 12) {
      greeting = 'Good Morning';
    } else if (hour < 17) {
      greeting = 'Good Afternoon';
    } else {
      greeting = 'Good Evening';
    }
    
    if (userName != null && userName.isNotEmpty) {
      return '$greeting, ${userName.split(' ').first}';
    }
    return greeting;
  }

  String _getFormattedDate() {
    final now = DateTime.now();
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[now.month - 1]} ${now.day}';
  }
}

/// Today's Entries List
class TodayEntriesList extends ConsumerWidget {
  const TodayEntriesList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Center(
      child: Text('Today\'s entries will appear here'),
    );
  }
}
