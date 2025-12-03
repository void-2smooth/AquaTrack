import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/challenge.dart';
import '../providers/providers.dart';
import '../theme/app_theme.dart';

/// Challenge card widget showing active challenge progress
class ChallengeCard extends ConsumerWidget {
  const ChallengeCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final challenge = ref.watch(activeChallengeProvider);
    
    if (challenge == null) {
      return const SizedBox.shrink();
    }

    final definition = Challenges.getById(challenge.challengeId);
    if (definition == null) {
      return const SizedBox.shrink();
    }

    return _buildChallengeCard(context, ref, challenge, definition);
  }

  Widget _buildChallengeCard(
    BuildContext context,
    WidgetRef ref,
    ActiveChallenge challenge,
    ChallengeDefinition definition,
  ) {
    final theme = Theme.of(context);
    final isDark = context.isDarkMode;
    final progress = challenge.completionPercentage;
    final daysRemaining = challenge.daysRemaining;
    final daysCompleted = challenge.daysCompleted;

    Color difficultyColor;
    switch (definition.difficulty) {
      case ChallengeDifficulty.easy:
        difficultyColor = AppColors.success;
        break;
      case ChallengeDifficulty.medium:
        difficultyColor = AppColors.warning;
        break;
      case ChallengeDifficulty.hard:
        difficultyColor = Colors.red;
        break;
    }

    return Container(
      margin: EdgeInsets.only(bottom: AppDimens.paddingL),
      padding: EdgeInsets.all(AppDimens.paddingL),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  AppColors.cardDark,
                  AppColors.cardDark.withOpacity(0.8),
                ]
              : [
                  Colors.white,
                  Colors.white.withOpacity(0.95),
                ],
        ),
        borderRadius: BorderRadius.circular(AppDimens.radiusXL),
        boxShadow: isDark ? [] : AppShadows.medium,
        border: isDark
            ? Border.all(color: Colors.white.withOpacity(0.1))
            : Border.all(color: difficultyColor.withOpacity(0.3), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(AppDimens.paddingS),
                decoration: BoxDecoration(
                  color: difficultyColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(AppDimens.radiusM),
                ),
                child: Icon(
                  Icons.emoji_events_rounded,
                  color: difficultyColor,
                  size: 24,
                ),
              ),
              SizedBox(width: AppDimens.paddingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Weekly Challenge',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    SizedBox(height: AppDimens.paddingXS),
                    Text(
                      definition.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              // Difficulty badge
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppDimens.paddingS,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: difficultyColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(AppDimens.radiusXS),
                ),
                child: Text(
                  definition.difficultyName,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: difficultyColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: AppDimens.paddingM),
          
          // Description
          Text(
            definition.description,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          SizedBox(height: AppDimens.paddingL),
          
          // Progress
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Progress',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                        Text(
                          '${(progress * 100).toStringAsFixed(0)}%',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: difficultyColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: AppDimens.paddingXS),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppDimens.radiusS),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        backgroundColor: theme.colorScheme.outline.withOpacity(0.1),
                        valueColor: AlwaysStoppedAnimation<Color>(difficultyColor),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: AppDimens.paddingM),
          
          // Stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatItem(
                icon: Icons.check_circle_rounded,
                label: 'Completed',
                value: '$daysCompleted/${definition.targetDays}',
                color: AppColors.success,
              ),
              Container(
                height: 30,
                width: 1,
                color: theme.colorScheme.outline.withOpacity(0.2),
              ),
              _StatItem(
                icon: Icons.schedule_rounded,
                label: 'Days Left',
                value: '$daysRemaining',
                color: daysRemaining <= 2 ? Colors.red : theme.colorScheme.primary,
              ),
              Container(
                height: 30,
                width: 1,
                color: theme.colorScheme.outline.withOpacity(0.2),
              ),
              _StatItem(
                icon: Icons.stars_rounded,
                label: 'Reward',
                value: '${definition.rewardPoints} pts',
                color: AppColors.streakGold,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
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
            Icon(icon, color: color, size: 16),
            SizedBox(width: AppDimens.paddingXS),
            Text(
              value,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        SizedBox(height: 2),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.5),
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

