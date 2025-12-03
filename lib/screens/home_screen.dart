import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../widgets/progress_bar.dart';
import '../widgets/water_add_buttons.dart';
import '../widgets/motivational_message.dart';

/// Home screen - Main screen showing today's progress
/// 
/// Displays:
/// - Circular progress bar with percentage
/// - Quick-add buttons for water intake
/// - Motivational messages
/// - Current streak info
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.all(AppDimens.paddingXL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Header
              Text(
                'Today\'s Progress',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: AppDimens.paddingS),
              Text(
                _getFormattedDate(),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              SizedBox(height: AppDimens.paddingXXXL),

              // Progress Circle
              const WaterProgressBar(),
              SizedBox(height: AppDimens.paddingXXXL),

              // Motivational Message
              const MotivationalMessage(),
              SizedBox(height: AppDimens.paddingXXL),

              // Streak Display
              const StreakDisplay(),
              SizedBox(height: AppDimens.paddingXXL),

              // Quick Add Buttons
              const WaterAddButtons(),
              SizedBox(height: AppDimens.paddingXXL),

              // Daily Tip
              const MotivationalTip(),
              SizedBox(height: AppDimens.bottomNavHeight), // Space for FAB
            ],
          ),
        ),
      ),
      // Floating action button for quick add
      floatingActionButton: const LargeAddButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  String _getFormattedDate() {
    final now = DateTime.now();
    final weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    
    return '${weekdays[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}';
  }
}

/// Today's Entries List - Shows individual entries for today
/// 
/// Can be used as a bottom sheet or separate view
class TodayEntriesList extends ConsumerWidget {
  const TodayEntriesList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: Implement today's entries list
    // - Show list of all water entries for today
    // - Allow deleting individual entries
    // - Show timestamp and amount for each entry
    
    return const Center(
      child: Text('Today\'s entries will appear here'),
    );
  }
}
