import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/water_entry.dart';
import '../providers/providers.dart';
import '../theme/app_theme.dart';

/// Profile setup screen - Collect user info for personalized water goal
/// 
/// Allows users to:
/// - Set weight
/// - Select activity level
/// - Choose between calculated or custom goal
class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _weightController = TextEditingController();
  final _customGoalController = TextEditingController();
  
  bool _useMetricWeight = true;
  bool _useCustomGoal = false;
  ActivityLevel _selectedActivity = ActivityLevel.moderate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsProvider);
    _useMetricWeight = settings.useMetricUnits;
    _useCustomGoal = settings.useCustomGoal;
    if (settings.weightKg != null) {
      _weightController.text = settings.weightKg!.toStringAsFixed(1);
    }
    if (settings.activityLevel != null) {
      _selectedActivity = settings.activityLevelEnum!;
    }
    if (settings.dailyGoalMl > 0) {
      _customGoalController.text = settings.useMetricUnits
          ? (settings.dailyGoalMl / 1000).toStringAsFixed(1)
          : (settings.dailyGoalMl * 0.033814).toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _weightController.dispose();
    _customGoalController.dispose();
    super.dispose();
  }

  /// Calculate water goal based on weight and activity level
  double _calculateWaterGoal(double weightKg, ActivityLevel activity) {
    // Base calculation: 30-35ml per kg of body weight
    double baseMl = weightKg * 32.5; // Average of 30-35
    
    // Activity level multipliers
    double multiplier;
    switch (activity) {
      case ActivityLevel.sedentary:
        multiplier = 1.0;
        break;
      case ActivityLevel.light:
        multiplier = 1.1;
        break;
      case ActivityLevel.moderate:
        multiplier = 1.2;
        break;
      case ActivityLevel.active:
        multiplier = 1.35;
        break;
      case ActivityLevel.veryActive:
        multiplier = 1.5;
        break;
    }
    
    return (baseMl * multiplier).roundToDouble();
  }

  double? _getCalculatedGoal() {
    final weight = double.tryParse(_weightController.text);
    if (weight == null || weight <= 0) return null;
    
    // Convert to kg if needed
    final weightKg = _useMetricWeight ? weight : weight * 0.453592;
    return _calculateWaterGoal(weightKg, _selectedActivity);
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();

    final settings = ref.read(settingsProvider);
    final weight = double.tryParse(_weightController.text);
    
    // Convert weight to kg
    final weightKg = weight != null
        ? (_useMetricWeight ? weight : weight * 0.453592)
        : null;

    double? calculatedGoal;
    double customGoal = settings.dailyGoalMl;

    if (!_useCustomGoal && weightKg != null) {
      // Calculate goal
      calculatedGoal = _calculateWaterGoal(weightKg, _selectedActivity);
    } else {
      // Use custom goal
      final customValue = double.tryParse(_customGoalController.text);
      if (customValue != null) {
        customGoal = settings.useMetricUnits
            ? customValue * 1000 // Convert L to ml
            : customValue / 0.033814; // Convert oz to ml
      }
    }

    final updated = settings.copyWith(
      weightKg: weightKg,
      activityLevelEnum: _selectedActivity,
      useCustomGoal: _useCustomGoal,
      calculatedGoalMl: calculatedGoal,
      dailyGoalMl: _useCustomGoal ? customGoal : (calculatedGoal ?? settings.dailyGoalMl),
    );

    await ref.read(settingsProvider.notifier).updateSettings(updated);

    if (mounted) {
      // Navigate to splash for nice greeting animation
      Navigator.pushReplacementNamed(context, '/splash');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = context.isDarkMode;
    final settings = ref.read(settingsProvider);
    final calculatedGoal = _getCalculatedGoal();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile Setup'),
        elevation: 0,
      ),
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
          child: Form(
            key: _formKey,
            child: ListView(
              padding: EdgeInsets.all(AppDimens.paddingL),
              children: [
                // Header
                Text(
                  'Let\'s personalize your water goal',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: AppDimens.paddingS),
                Text(
                  'We\'ll calculate your daily water needs based on your profile',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                SizedBox(height: AppDimens.paddingXXL),

                // Weight Section
                _buildSectionCard(
                  context,
                  title: 'Weight',
                  icon: Icons.monitor_weight_rounded,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Unit toggle
                      Row(
                        children: [
                          Expanded(
                            child: ChoiceChip(
                              label: const Text('kg'),
                              selected: _useMetricWeight,
                              onSelected: (selected) {
                                setState(() => _useMetricWeight = selected);
                              },
                            ),
                          ),
                          SizedBox(width: AppDimens.paddingS),
                          Expanded(
                            child: ChoiceChip(
                              label: const Text('lbs'),
                              selected: !_useMetricWeight,
                              onSelected: (selected) {
                                setState(() => _useMetricWeight = !selected);
                              },
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: AppDimens.paddingM),
                      // Weight input
                      TextFormField(
                        controller: _weightController,
                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: 'Weight',
                          hintText: _useMetricWeight ? 'e.g., 70' : 'e.g., 154',
                          suffixText: _useMetricWeight ? 'kg' : 'lbs',
                          prefixIcon: const Icon(Icons.scale_rounded),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppDimens.radiusM),
                          ),
                        ),
                        validator: (value) {
                          if (!_useCustomGoal && (value == null || value.isEmpty)) {
                            return 'Please enter your weight';
                          }
                          final weight = double.tryParse(value ?? '');
                          if (value != null && value.isNotEmpty) {
                            if (weight == null || weight <= 0) {
                              return 'Please enter a valid weight';
                            }
                            if (_useMetricWeight && (weight < 20 || weight > 300)) {
                              return 'Please enter a weight between 20-300 kg';
                            }
                            if (!_useMetricWeight && (weight < 44 || weight > 660)) {
                              return 'Please enter a weight between 44-660 lbs';
                            }
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                SizedBox(height: AppDimens.paddingL),

                // Activity Level Section
                _buildSectionCard(
                  context,
                  title: 'Activity Level',
                  icon: Icons.fitness_center_rounded,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ...ActivityLevel.values.map((level) {
                        return RadioListTile<ActivityLevel>(
                          title: Text(_getActivityLabel(level)),
                          subtitle: Text(_getActivityDescription(level)),
                          value: level,
                          groupValue: _selectedActivity,
                          onChanged: (value) {
                            setState(() => _selectedActivity = value!);
                          },
                          contentPadding: EdgeInsets.zero,
                        );
                      }),
                    ],
                  ),
                ),
                SizedBox(height: AppDimens.paddingL),

                // Goal Type Toggle
                _buildSectionCard(
                  context,
                  title: 'Goal Type',
                  icon: Icons.flag_rounded,
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: const Text('Use Custom Goal'),
                        subtitle: Text(
                          _useCustomGoal
                              ? 'Set your own daily water goal'
                              : 'Goal calculated from your profile',
                        ),
                        value: _useCustomGoal,
                        onChanged: (value) {
                          setState(() => _useCustomGoal = value);
                        },
                      ),
                      if (!_useCustomGoal && calculatedGoal != null) ...[
                        SizedBox(height: AppDimens.paddingM),
                        Container(
                          padding: EdgeInsets.all(AppDimens.paddingM),
                          decoration: BoxDecoration(
                            color: AppColors.success.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(AppDimens.radiusM),
                            border: Border.all(
                              color: AppColors.success.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.calculate_rounded, color: AppColors.success),
                              SizedBox(width: AppDimens.paddingM),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Recommended Goal',
                                      style: theme.textTheme.labelSmall?.copyWith(
                                        color: AppColors.success,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      settings.useMetricUnits
                                          ? '${(calculatedGoal / 1000).toStringAsFixed(1)} L per day'
                                          : '${(calculatedGoal * 0.033814).toStringAsFixed(0)} oz per day',
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (_useCustomGoal) ...[
                        SizedBox(height: AppDimens.paddingM),
                        TextFormField(
                          controller: _customGoalController,
                          keyboardType: TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: 'Daily Goal',
                            hintText: settings.useMetricUnits ? 'e.g., 2.5' : 'e.g., 80',
                            suffixText: settings.useMetricUnits ? 'L' : 'oz',
                            prefixIcon: const Icon(Icons.water_drop_rounded),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppDimens.radiusM),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your daily goal';
                            }
                            final goal = double.tryParse(value);
                            if (goal == null || goal <= 0) {
                              return 'Please enter a valid goal';
                            }
                            return null;
                          },
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(height: AppDimens.paddingXXL),

                // Save button
                FilledButton(
                  onPressed: _isLoading ? null : _handleSave,
                  style: FilledButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: AppDimens.paddingL),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDimens.radiusL),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          'Save Profile',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
                SizedBox(height: AppDimens.paddingL),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    final theme = Theme.of(context);
    final isDark = context.isDarkMode;

    return Container(
      padding: EdgeInsets.all(AppDimens.paddingL),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(AppDimens.radiusL),
        boxShadow: isDark ? [] : AppShadows.medium,
        border: isDark
            ? Border.all(color: Colors.white.withOpacity(0.1))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: theme.colorScheme.primary),
              SizedBox(width: AppDimens.paddingS),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: AppDimens.paddingM),
          child,
        ],
      ),
    );
  }

  String _getActivityLabel(ActivityLevel level) {
    switch (level) {
      case ActivityLevel.sedentary:
        return 'Sedentary';
      case ActivityLevel.light:
        return 'Light Activity';
      case ActivityLevel.moderate:
        return 'Moderate Activity';
      case ActivityLevel.active:
        return 'Active';
      case ActivityLevel.veryActive:
        return 'Very Active';
    }
  }

  String _getActivityDescription(ActivityLevel level) {
    switch (level) {
      case ActivityLevel.sedentary:
        return 'Little to no exercise';
      case ActivityLevel.light:
        return 'Light exercise 1-3 days/week';
      case ActivityLevel.moderate:
        return 'Moderate exercise 3-5 days/week';
      case ActivityLevel.active:
        return 'Hard exercise 6-7 days/week';
      case ActivityLevel.veryActive:
        return 'Very hard exercise, physical job';
    }
  }
}

