import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';
import '../theme/app_theme.dart';

/// Widget displaying motivational messages based on progress
/// 
/// Shows encouraging messages that change based on how much water
/// the user has consumed relative to their daily goal.
class MotivationalMessage extends ConsumerWidget {
  const MotivationalMessage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Use select to only rebuild when these specific values change
    final message = ref.watch(motivationalMessageProvider);
    final progress = ref.watch(todayProgressUncappedProvider);
    final theme = Theme.of(context);
    final gradientColors = AppColors.getMotivationGradient(progress);

    // Wrap in RepaintBoundary to isolate repaints
    return RepaintBoundary(
      child: AnimatedSwitcher(
      duration: Duration(milliseconds: AppDimens.animationSlow),
      child: Container(
        key: ValueKey(message),
        padding: EdgeInsets.symmetric(
          horizontal: AppDimens.paddingXXL,
          vertical: AppDimens.paddingL,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppDimens.radiusL),
          boxShadow: [
            BoxShadow(
              color: gradientColors.first.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Animated icon
            _AnimatedMotivationalIcon(progress: progress),
            SizedBox(width: AppDimens.paddingL),
            // Message text
            Expanded(
              child: Text(
                message,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

/// Animated icon that changes based on progress
class _AnimatedMotivationalIcon extends StatelessWidget {
  final double progress;

  const _AnimatedMotivationalIcon({required this.progress});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.8, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.elasticOut,
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getIcon(),
              color: Colors.white,
              size: AppDimens.iconXL,
            ),
          ),
        );
      },
    );
  }

  IconData _getIcon() {
    if (progress >= 1.0) return Icons.emoji_events;
    if (progress >= 0.75) return Icons.star;
    if (progress >= 0.5) return Icons.thumb_up;
    if (progress >= 0.25) return Icons.water_drop;
    return Icons.play_arrow;
  }
}

/// Streak display widget
/// 
/// Shows current streak and longest streak information.
class StreakDisplay extends ConsumerWidget {
  const StreakDisplay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final theme = Theme.of(context);

    return Card(
      elevation: AppDimens.cardElevation,
      color: theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: EdgeInsets.all(AppDimens.paddingL),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // Current streak
            _StreakItem(
              icon: Icons.local_fire_department,
              iconColor: AppColors.streakFire,
              value: settings.currentStreak.toString(),
              label: 'Current Streak',
            ),
            // Divider
            Container(
              height: 40,
              width: 1,
              color: theme.colorScheme.outline.withOpacity(0.3),
            ),
            // Longest streak
            _StreakItem(
              icon: Icons.military_tech,
              iconColor: AppColors.streakGold,
              value: settings.longestStreak.toString(),
              label: 'Best Streak',
            ),
          ],
        ),
      ),
    );
  }
}

class _StreakItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  const _StreakItem({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: iconColor, size: AppDimens.iconL),
            SizedBox(width: AppDimens.paddingS),
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        SizedBox(height: AppDimens.paddingXS),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        Text(
          'days',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.4),
          ),
        ),
      ],
    );
  }
}

/// Small motivational tip cards for variety
class MotivationalTip extends StatelessWidget {
  const MotivationalTip({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tip = _getRandomTip();

    return Card(
      elevation: AppDimens.cardElevation,
      color: theme.colorScheme.tertiaryContainer.withOpacity(0.5),
      child: Padding(
        padding: EdgeInsets.all(AppDimens.paddingL),
        child: Row(
          children: [
            Icon(
              Icons.lightbulb_outline,
              color: theme.colorScheme.tertiary,
            ),
            SizedBox(width: AppDimens.paddingM),
            Expanded(
              child: Text(
                tip,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onTertiaryContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getRandomTip() {
    final tips = [
      'Drinking water before meals can help with digestion.',
      'Start your day with a glass of water to boost metabolism.',
      'Keep a water bottle at your desk for easy access.',
      'Herbal teas count towards your daily water intake!',
      'Fruits and vegetables also contribute to hydration.',
      'Room temperature water is easier for your body to absorb.',
      'Set hourly reminders to build a hydration habit.',
      'Dehydration can cause headaches and fatigue.',
    ];
    
    // Simple rotation based on day of year
    final dayOfYear = DateTime.now().difference(
      DateTime(DateTime.now().year, 1, 1)
    ).inDays;
    
    return tips[dayOfYear % tips.length];
  }
}
