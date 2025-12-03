import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/challenge.dart';
import '../providers/providers.dart';
import '../theme/app_theme.dart';
import '../widgets/challenge_card.dart';

/// Challenges screen - View and start weekly challenges
class ChallengesScreen extends ConsumerWidget {
  const ChallengesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeChallenge = ref.watch(activeChallengeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Weekly Challenges'),
        actions: [
          if (activeChallenge != null)
            IconButton(
              icon: const Icon(Icons.info_outline_rounded),
              onPressed: () => _showActiveChallengeInfo(context, activeChallenge),
              tooltip: 'Active Challenge Info',
            ),
        ],
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.all(AppDimens.paddingL),
        children: [
          // Active Challenge Section
          if (activeChallenge != null) ...[
            _buildSectionHeader(context, '🔥 Active Challenge'),
            ChallengeCard(),
            SizedBox(height: AppDimens.paddingXL),
          ],

          // Available Challenges Section
          _buildSectionHeader(
            context,
            activeChallenge == null ? '🎯 Start a Challenge' : '📋 Available Challenges',
          ),
          SizedBox(height: AppDimens.paddingM),
          
          // Challenges grouped by difficulty
          ...ChallengeDifficulty.values.map((difficulty) {
            final challenges = Challenges.byDifficulty(difficulty);
            return _ChallengeDifficultySection(
              difficulty: difficulty,
              challenges: challenges,
              activeChallengeId: activeChallenge?.challengeId,
            );
          }),
          
          SizedBox(height: AppDimens.paddingXXL),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: AppDimens.paddingM),
      child: Text(
        title,
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showActiveChallengeInfo(BuildContext context, ActiveChallenge challenge) {
    final definition = Challenges.getById(challenge.challengeId);
    if (definition == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(definition.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(definition.description),
            SizedBox(height: AppDimens.paddingM),
            Text(
              'Progress: ${challenge.daysCompleted}/${definition.targetDays} days',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text('Days remaining: ${challenge.daysRemaining}'),
            Text('Reward: ${definition.rewardPoints} points'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _ChallengeDifficultySection extends ConsumerWidget {
  final ChallengeDifficulty difficulty;
  final List<ChallengeDefinition> challenges;
  final String? activeChallengeId;

  const _ChallengeDifficultySection({
    required this.difficulty,
    required this.challenges,
    this.activeChallengeId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    String difficultyLabel;
    Color difficultyColor;
    IconData difficultyIcon;

    switch (difficulty) {
      case ChallengeDifficulty.easy:
        difficultyLabel = 'Easy';
        difficultyColor = AppColors.success;
        difficultyIcon = Icons.sentiment_satisfied_rounded;
        break;
      case ChallengeDifficulty.medium:
        difficultyLabel = 'Medium';
        difficultyColor = AppColors.warning;
        difficultyIcon = Icons.sentiment_neutral_rounded;
        break;
      case ChallengeDifficulty.hard:
        difficultyLabel = 'Hard';
        difficultyColor = Colors.red;
        difficultyIcon = Icons.sentiment_very_dissatisfied_rounded;
        break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Difficulty header
        Padding(
          padding: EdgeInsets.only(bottom: AppDimens.paddingS),
          child: Row(
            children: [
              Icon(difficultyIcon, color: difficultyColor, size: 20),
              SizedBox(width: AppDimens.paddingXS),
              Text(
                difficultyLabel,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: difficultyColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        // Challenge cards
        ...challenges.map((challenge) => _ChallengeListItem(
          challenge: challenge,
          isActive: challenge.id == activeChallengeId,
          difficultyColor: difficultyColor,
        )),
        SizedBox(height: AppDimens.paddingL),
      ],
    );
  }
}

class _ChallengeListItem extends ConsumerWidget {
  final ChallengeDefinition challenge;
  final bool isActive;
  final Color difficultyColor;

  const _ChallengeListItem({
    required this.challenge,
    required this.isActive,
    required this.difficultyColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = context.isDarkMode;

    return Container(
      margin: EdgeInsets.only(bottom: AppDimens.paddingS),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(AppDimens.radiusL),
        boxShadow: isDark ? [] : AppShadows.small,
        border: isActive
            ? Border.all(color: difficultyColor, width: 2)
            : (isDark
                ? Border.all(color: Colors.white.withOpacity(0.1))
                : null),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.all(AppDimens.paddingM),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: difficultyColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(AppDimens.radiusM),
          ),
          child: Icon(
            Icons.emoji_events_rounded,
            color: difficultyColor,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                challenge.title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (isActive)
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppDimens.paddingS,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(AppDimens.radiusXS),
                ),
                child: Text(
                  'Active',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: AppDimens.paddingXS),
            Text(
              challenge.description,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            SizedBox(height: AppDimens.paddingS),
            Row(
              children: [
                _InfoChip(
                  icon: Icons.calendar_today_rounded,
                  label: '${challenge.targetDays} days',
                  color: theme.colorScheme.primary,
                ),
                SizedBox(width: AppDimens.paddingS),
                _InfoChip(
                  icon: Icons.stars_rounded,
                  label: '${challenge.rewardPoints} pts',
                  color: AppColors.streakGold,
                ),
              ],
            ),
          ],
        ),
        trailing: isActive
            ? Icon(Icons.check_circle_rounded, color: AppColors.success)
            : Icon(Icons.arrow_forward_ios_rounded, size: 16),
        onTap: isActive
            ? null
            : () => _startChallenge(context, ref, challenge),
      ),
    );
  }

  void _startChallenge(
    BuildContext context,
    WidgetRef ref,
    ChallengeDefinition challenge,
  ) async {
    final activeChallenge = ref.read(activeChallengeProvider);
    
    if (activeChallenge != null) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Replace Active Challenge?'),
          content: const Text(
            'You already have an active challenge. Starting a new one will replace it.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Replace'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;
    }

    HapticFeedback.mediumImpact();
    final started = await ref.read(activeChallengeProvider.notifier).startChallenge(challenge.id);
    
    if (context.mounted && started != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.emoji_events_rounded, color: AppColors.streakGold, size: 20),
              SizedBox(width: AppDimens.paddingS),
              Text('Challenge started: ${challenge.title}'),
            ],
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppDimens.paddingS,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppDimens.radiusXS),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

