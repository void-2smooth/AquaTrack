import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/achievement.dart';
import '../providers/providers.dart';
import '../theme/app_theme.dart';

/// Screen showing all achievements and their unlock status
class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final achievementsState = ref.watch(achievementsProvider);
    final theme = Theme.of(context);

    // Mark all as seen when viewing
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(achievementsProvider.notifier).markAllSeen();
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Achievements'),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: AppDimens.paddingM),
            child: Center(
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppDimens.paddingM,
                  vertical: AppDimens.paddingXS,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(AppDimens.radiusCircle),
                ),
                child: Text(
                  '${achievementsState.totalUnlocked}/${achievementsState.totalAchievements}',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.all(AppDimens.paddingL),
        children: [
          // Progress header
          _ProgressHeader(
            unlocked: achievementsState.totalUnlocked,
            total: achievementsState.totalAchievements,
            percentage: achievementsState.progressPercentage,
          ),
          SizedBox(height: AppDimens.paddingXL),
          
          // Categories
          _AchievementCategory(
            title: '💧 Hydration',
            achievements: Achievements.byCategory(AchievementCategory.hydration),
            unlockedIds: achievementsState.unlockedAchievements
                .map((a) => a.achievementId)
                .toSet(),
          ),
          
          _AchievementCategory(
            title: '🔥 Streaks',
            achievements: Achievements.byCategory(AchievementCategory.streak),
            unlockedIds: achievementsState.unlockedAchievements
                .map((a) => a.achievementId)
                .toSet(),
          ),
          
          _AchievementCategory(
            title: '⏰ Consistency',
            achievements: Achievements.byCategory(AchievementCategory.consistency),
            unlockedIds: achievementsState.unlockedAchievements
                .map((a) => a.achievementId)
                .toSet(),
          ),
          
          _AchievementCategory(
            title: '🏆 Milestones',
            achievements: Achievements.byCategory(AchievementCategory.milestone),
            unlockedIds: achievementsState.unlockedAchievements
                .map((a) => a.achievementId)
                .toSet(),
          ),
          
          SizedBox(height: AppDimens.paddingXXL),
        ],
      ),
    );
  }
}

class _ProgressHeader extends StatelessWidget {
  final int unlocked;
  final int total;
  final double percentage;

  const _ProgressHeader({
    required this.unlocked,
    required this.total,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = context.isDarkMode;

    return Container(
      padding: EdgeInsets.all(AppDimens.paddingXL),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [AppColors.cardDark, AppColors.cardDark.withOpacity(0.8)]
              : [Colors.white, Colors.grey.shade50],
        ),
        borderRadius: BorderRadius.circular(AppDimens.radiusXL),
        boxShadow: isDark ? [] : AppShadows.medium,
        border: isDark
            ? Border.all(color: Colors.white.withOpacity(0.1))
            : null,
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Trophy icon
              Container(
                padding: EdgeInsets.all(AppDimens.paddingL),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.streakGold, AppColors.streakGold.withOpacity(0.8)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: AppShadows.colored(AppColors.streakGold),
                ),
                child: const Icon(
                  Icons.emoji_events_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              SizedBox(width: AppDimens.paddingL),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$unlocked of $total',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Achievements Unlocked',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              // Percentage badge
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppDimens.paddingM,
                  vertical: AppDimens.paddingS,
                ),
                decoration: BoxDecoration(
                  color: _getPercentageColor(percentage).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(AppDimens.radiusCircle),
                ),
                child: Text(
                  '${percentage.toStringAsFixed(0)}%',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: _getPercentageColor(percentage),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: AppDimens.paddingL),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(AppDimens.radiusS),
            child: LinearProgressIndicator(
              value: percentage / 100,
              minHeight: 8,
              backgroundColor: theme.colorScheme.outline.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation(_getPercentageColor(percentage)),
            ),
          ),
        ],
      ),
    );
  }

  Color _getPercentageColor(double percentage) {
    if (percentage >= 80) return AppColors.success;
    if (percentage >= 50) return AppColors.waterMedium;
    if (percentage >= 25) return AppColors.warning;
    return AppColors.waterLight;
  }
}

class _AchievementCategory extends StatelessWidget {
  final String title;
  final List<AchievementDefinition> achievements;
  final Set<String> unlockedIds;

  const _AchievementCategory({
    required this.title,
    required this.achievements,
    required this.unlockedIds,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    final unlockedInCategory = achievements.where((a) => unlockedIds.contains(a.id)).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: AppDimens.paddingM),
          child: Row(
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '$unlockedInCategory/${achievements.length}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
            ],
          ),
        ),
        ...achievements.map((achievement) => _AchievementTile(
          achievement: achievement,
          isUnlocked: unlockedIds.contains(achievement.id),
        )),
        SizedBox(height: AppDimens.paddingM),
      ],
    );
  }
}

class _AchievementTile extends StatelessWidget {
  final AchievementDefinition achievement;
  final bool isUnlocked;

  const _AchievementTile({
    required this.achievement,
    required this.isUnlocked,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = context.isDarkMode;

    return Container(
      margin: EdgeInsets.only(bottom: AppDimens.paddingS),
      decoration: BoxDecoration(
        color: isDark
            ? (isUnlocked ? AppColors.cardDark : Colors.grey.shade900.withOpacity(0.5))
            : (isUnlocked ? Colors.white : Colors.grey.shade100),
        borderRadius: BorderRadius.circular(AppDimens.radiusL),
        boxShadow: isUnlocked && !isDark ? AppShadows.small : [],
        border: isDark
            ? Border.all(
                color: isUnlocked 
                    ? achievement.rarityColor.withOpacity(0.3)
                    : Colors.white.withOpacity(0.05),
              )
            : (isUnlocked
                ? Border.all(color: achievement.rarityColor.withOpacity(0.3))
                : null),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.all(AppDimens.paddingM),
        leading: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: isUnlocked
                ? achievement.rarityColor.withOpacity(0.15)
                : (isDark ? Colors.grey.shade800 : Colors.grey.shade200),
            borderRadius: BorderRadius.circular(AppDimens.radiusM),
            border: isUnlocked
                ? Border.all(color: achievement.rarityColor.withOpacity(0.3))
                : null,
          ),
          child: Icon(
            isUnlocked ? achievement.iconData : Icons.lock_rounded,
            color: isUnlocked
                ? achievement.rarityColor
                : (isDark ? Colors.grey.shade600 : Colors.grey.shade400),
            size: 28,
          ),
        ),
        title: Text(
          achievement.name,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: isUnlocked
                ? theme.colorScheme.onSurface
                : theme.colorScheme.onSurface.withOpacity(0.5),
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: AppDimens.paddingXS),
            Text(
              achievement.description,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isUnlocked
                    ? theme.colorScheme.onSurface.withOpacity(0.7)
                    : theme.colorScheme.onSurface.withOpacity(0.4),
              ),
            ),
            SizedBox(height: AppDimens.paddingS),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppDimens.paddingS,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: isUnlocked
                    ? achievement.rarityColor.withOpacity(0.15)
                    : (isDark ? Colors.grey.shade800 : Colors.grey.shade200),
                borderRadius: BorderRadius.circular(AppDimens.radiusXS),
              ),
              child: Text(
                achievement.rarityName,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: isUnlocked
                      ? achievement.rarityColor
                      : (isDark ? Colors.grey.shade500 : Colors.grey.shade500),
                  fontWeight: FontWeight.w600,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
        trailing: isUnlocked
            ? Icon(
                Icons.check_circle_rounded,
                color: AppColors.success,
              )
            : null,
      ),
    );
  }
}

