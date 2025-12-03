import 'dart:math';
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import '../models/achievement.dart';
import '../models/challenge.dart';
import '../theme/app_theme.dart';

/// Celebration types
enum CelebrationType {
  goalReached,
  achievement,
  streak,
}

/// Celebration controller for managing animations
class CelebrationController {
  final ConfettiController confettiController;
  final List<AchievementDefinition> _pendingAchievements = [];
  bool _isShowingAchievement = false;
  VoidCallback? onAchievementDismissed;

  CelebrationController()
      : confettiController = ConfettiController(
          duration: const Duration(seconds: 3),
        );

  void dispose() {
    confettiController.dispose();
  }

  /// Play confetti animation
  void playConfetti() {
    confettiController.play();
  }

  /// Stop confetti animation
  void stopConfetti() {
    confettiController.stop();
  }

  /// Add achievement to show
  void showAchievement(AchievementDefinition achievement) {
    _pendingAchievements.add(achievement);
    _showNextAchievement();
  }

  void _showNextAchievement() {
    if (_isShowingAchievement || _pendingAchievements.isEmpty) return;
    _isShowingAchievement = true;
    playConfetti();
    onAchievementDismissed?.call();
  }

  AchievementDefinition? get currentAchievement =>
      _pendingAchievements.isNotEmpty ? _pendingAchievements.first : null;

  void dismissCurrentAchievement() {
    if (_pendingAchievements.isNotEmpty) {
      _pendingAchievements.removeAt(0);
    }
    _isShowingAchievement = false;
    _showNextAchievement();
  }

  bool get hasAchievement => _pendingAchievements.isNotEmpty;
}

/// Celebration overlay widget
class CelebrationOverlay extends StatelessWidget {
  final CelebrationController controller;
  final Widget child;

  const CelebrationOverlay({
    super.key,
    required this.controller,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        // Center confetti
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: controller.confettiController,
            blastDirection: pi / 2, // Down
            maxBlastForce: 5,
            minBlastForce: 2,
            emissionFrequency: 0.05,
            numberOfParticles: 20,
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
      ],
    );
  }
}

/// Achievement unlock popup
class AchievementUnlockPopup extends StatefulWidget {
  final AchievementDefinition achievement;
  final VoidCallback onDismiss;

  const AchievementUnlockPopup({
    super.key,
    required this.achievement,
    required this.onDismiss,
  });

  @override
  State<AchievementUnlockPopup> createState() => _AchievementUnlockPopupState();
}

class _AchievementUnlockPopupState extends State<AchievementUnlockPopup>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.forward();

    // Auto-dismiss after 4 seconds
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        _dismiss();
      }
    });
  }

  void _dismiss() async {
    await _controller.reverse();
    widget.onDismiss();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTap: _dismiss,
        child: Container(
          margin: EdgeInsets.all(AppDimens.paddingXL),
          padding: EdgeInsets.all(AppDimens.paddingXL),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                widget.achievement.rarityColor.withOpacity(0.9),
                widget.achievement.rarityColor.withOpacity(0.7),
              ],
            ),
            borderRadius: BorderRadius.circular(AppDimens.radiusXL),
            boxShadow: [
              BoxShadow(
                color: widget.achievement.rarityColor.withOpacity(0.4),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Text(
                '🎉 Achievement Unlocked!',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: Colors.white.withOpacity(0.9),
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: AppDimens.paddingL),
              
              // Icon with glow
              Container(
                padding: EdgeInsets.all(AppDimens.paddingL),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.3),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(
                  widget.achievement.iconData,
                  size: 48,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: AppDimens.paddingL),
              
              // Name
              Text(
                widget.achievement.name,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppDimens.paddingS),
              
              // Description
              Text(
                widget.achievement.description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withOpacity(0.9),
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppDimens.paddingM),
              
              // Rarity badge
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppDimens.paddingM,
                  vertical: AppDimens.paddingXS,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppDimens.radiusCircle),
                ),
                child: Text(
                  widget.achievement.rarityName,
                  style: theme.textTheme.labelSmall?.copyWith(
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

/// Goal reached celebration banner
class GoalReachedBanner extends StatefulWidget {
  final VoidCallback? onDismiss;

  const GoalReachedBanner({super.key, this.onDismiss});

  @override
  State<GoalReachedBanner> createState() => _GoalReachedBannerState();
}

class _GoalReachedBannerState extends State<GoalReachedBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.forward();

    // Auto-dismiss after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _dismiss();
      }
    });
  }

  void _dismiss() async {
    await _controller.reverse();
    widget.onDismiss?.call();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTap: _dismiss,
        child: Container(
          margin: EdgeInsets.all(AppDimens.paddingL),
          padding: EdgeInsets.all(AppDimens.paddingL),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.success,
                AppColors.success.withGreen(200),
              ],
            ),
            borderRadius: BorderRadius.circular(AppDimens.radiusL),
            boxShadow: AppShadows.colored(AppColors.success),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(AppDimens.paddingS),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.emoji_events_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              SizedBox(width: AppDimens.paddingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '🎉 Goal Reached!',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Great job staying hydrated today!',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.close_rounded,
                color: Colors.white.withOpacity(0.7),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Streak milestone celebration
class StreakMilestoneBanner extends StatefulWidget {
  final int streakDays;
  final VoidCallback? onDismiss;

  const StreakMilestoneBanner({
    super.key,
    required this.streakDays,
    this.onDismiss,
  });

  @override
  State<StreakMilestoneBanner> createState() => _StreakMilestoneBannerState();
}

class _StreakMilestoneBannerState extends State<StreakMilestoneBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    _controller.forward();

    // Auto-dismiss after 4 seconds
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        _dismiss();
      }
    });
  }

  void _dismiss() async {
    await _controller.reverse();
    widget.onDismiss?.call();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        );
      },
      child: GestureDetector(
        onTap: _dismiss,
        child: Container(
          margin: EdgeInsets.all(AppDimens.paddingL),
          padding: EdgeInsets.all(AppDimens.paddingXL),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.streakGold,
                AppColors.streakGold.withRed(255),
              ],
            ),
            borderRadius: BorderRadius.circular(AppDimens.radiusXL),
            boxShadow: AppShadows.colored(AppColors.streakGold),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '🔥',
                style: TextStyle(fontSize: 48),
              ),
              SizedBox(height: AppDimens.paddingS),
              Text(
                '${widget.streakDays} Day Streak!',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: AppDimens.paddingXS),
              Text(
                'You\'re on fire! Keep it up!',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Challenge completion popup
class ChallengeCompletionPopup extends StatefulWidget {
  final ChallengeDefinition definition;
  final ActiveChallenge challenge;
  final VoidCallback onDismiss;

  const ChallengeCompletionPopup({
    super.key,
    required this.definition,
    required this.challenge,
    required this.onDismiss,
  });

  @override
  State<ChallengeCompletionPopup> createState() => _ChallengeCompletionPopupState();
}

class _ChallengeCompletionPopupState extends State<ChallengeCompletionPopup>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.forward();

    // Auto-dismiss after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        _dismiss();
      }
    });
  }

  void _dismiss() async {
    await _controller.reverse();
    widget.onDismiss();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getDifficultyColor() {
    switch (widget.definition.difficulty) {
      case ChallengeDifficulty.easy:
        return AppColors.success;
      case ChallengeDifficulty.medium:
        return AppColors.warning;
      case ChallengeDifficulty.hard:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final difficultyColor = _getDifficultyColor();

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTap: _dismiss,
        child: Container(
          margin: EdgeInsets.all(AppDimens.paddingXL),
          padding: EdgeInsets.all(AppDimens.paddingXL),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                difficultyColor.withOpacity(0.9),
                difficultyColor.withOpacity(0.7),
              ],
            ),
            borderRadius: BorderRadius.circular(AppDimens.radiusXL),
            boxShadow: [
              BoxShadow(
                color: difficultyColor.withOpacity(0.4),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Text(
                '🏆 Challenge Complete!',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: AppDimens.paddingL),
              
              // Trophy icon
              Container(
                padding: EdgeInsets.all(AppDimens.paddingL),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.3),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.emoji_events_rounded,
                  size: 48,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: AppDimens.paddingL),
              
              // Challenge name
              Text(
                widget.definition.title,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppDimens.paddingS),
              
              // Description
              Text(
                widget.definition.description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withOpacity(0.9),
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppDimens.paddingL),
              
              // Reward
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppDimens.paddingL,
                  vertical: AppDimens.paddingM,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppDimens.radiusM),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.stars_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                    SizedBox(width: AppDimens.paddingS),
                    Text(
                      '${widget.definition.rewardPoints} Points Earned!',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

