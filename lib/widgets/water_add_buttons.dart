import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';
import '../theme/app_theme.dart';

/// Modern quick-add buttons with smooth animations
class WaterAddButtons extends ConsumerWidget {
  const WaterAddButtons({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quickAmounts = ref.watch(quickAddAmountsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Quick add button grid
        Row(
          children: quickAmounts.map((amount) {
            return Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: AppDimens.paddingXS),
                child: _QuickAddButton(
                  label: amount.label,
                  amountMl: amount.amountMl,
                ),
              ),
            );
          }).toList(),
        ),
        SizedBox(height: AppDimens.paddingL),
        // Custom amount button
        _CustomAmountButton(),
      ],
    );
  }
}

/// Individual quick-add button with modern design
class _QuickAddButton extends ConsumerStatefulWidget {
  final String label;
  final double amountMl;

  const _QuickAddButton({
    required this.label,
    required this.amountMl,
  });

  @override
  ConsumerState<_QuickAddButton> createState() => _QuickAddButtonState();
}

class _QuickAddButtonState extends ConsumerState<_QuickAddButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = context.isDarkMode;

    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        _handleTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: Container(
          height: AppDimens.quickAddButtonSize,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [AppColors.cardDark, AppColors.cardDark.withOpacity(0.8)]
                  : [Colors.white, Colors.white.withOpacity(0.95)],
            ),
            borderRadius: BorderRadius.circular(AppDimens.radiusL),
            boxShadow: isDark ? [] : AppShadows.small,
            border: Border.all(
              color: isDark 
                  ? Colors.white.withOpacity(0.1) 
                  : Colors.grey.shade200,
              width: 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(AppDimens.paddingS),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.water_drop_rounded,
                  color: AppColors.primaryLight,
                  size: AppDimens.iconL,
                ),
              ),
              SizedBox(height: AppDimens.paddingS),
              Text(
                widget.label,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleTap() {
    HapticFeedback.lightImpact();
    ref.read(todayEntriesProvider.notifier).addEntry(widget.amountMl);
    
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20),
            SizedBox(width: AppDimens.paddingS),
            Text('Added ${widget.label} 💧'),
          ],
        ),
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            // TODO: Implement undo
          },
        ),
      ),
    );
  }
}

/// Custom amount button with modern design
class _CustomAmountButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = context.isDarkMode;

    return GestureDetector(
      onTap: () => _showCustomAmountDialog(context, ref),
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: AppDimens.paddingM,
          horizontal: AppDimens.paddingL,
        ),
        decoration: BoxDecoration(
          color: isDark 
              ? AppColors.primaryDark.withOpacity(0.15) 
              : AppColors.primaryLight.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppDimens.radiusM),
          border: Border.all(
            color: isDark 
                ? AppColors.primaryDark.withOpacity(0.3) 
                : AppColors.primaryLight.withOpacity(0.3),
            width: 1.5,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_rounded,
              color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
              size: AppDimens.iconM,
            ),
            SizedBox(width: AppDimens.paddingS),
            Text(
              'Custom Amount',
              style: theme.textTheme.labelLarge?.copyWith(
                color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCustomAmountDialog(BuildContext context, WidgetRef ref) {
    final settings = ref.read(settingsProvider);
    final controller = TextEditingController();
    final useMetric = settings.useMetricUnits;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppDimens.radiusXXL),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(AppDimens.paddingXXL),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              SizedBox(height: AppDimens.paddingXXL),
              Text(
                'Add Custom Amount',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppDimens.paddingXXL),
              TextField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: '0',
                  suffixText: useMetric ? 'ml' : 'oz',
                  suffixStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimens.radiusL),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                ),
                autofocus: true,
              ),
              SizedBox(height: AppDimens.paddingXXL),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  SizedBox(width: AppDimens.paddingM),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: () {
                        final value = double.tryParse(controller.text);
                        if (value != null && value > 0) {
                          final amountMl = useMetric ? value : value / 0.033814;
                          ref.read(todayEntriesProvider.notifier).addEntry(amountMl);
                          Navigator.pop(context);
                          
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  Icon(Icons.check_circle_rounded, 
                                       color: AppColors.success, size: 20),
                                  SizedBox(width: AppDimens.paddingS),
                                  Text('Added ${controller.text} ${useMetric ? "ml" : "oz"}'),
                                ],
                              ),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Add Water'),
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppDimens.paddingL),
            ],
          ),
        ),
      ),
    );
  }
}

/// Large floating add button
class LargeAddButton extends ConsumerWidget {
  const LargeAddButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final isDark = context.isDarkMode;
    
    final defaultAmount = settings.useMetricUnits ? 250.0 : 236.588;
    final defaultLabel = settings.useMetricUnits ? '250ml' : '8oz';

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppDimens.radiusL),
        boxShadow: AppShadows.colored(
          isDark ? AppColors.primaryDark : AppColors.primaryLight,
        ),
      ),
      child: FloatingActionButton.extended(
        onPressed: () {
          HapticFeedback.mediumImpact();
          ref.read(todayEntriesProvider.notifier).addEntry(defaultAmount);
          
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20),
                  SizedBox(width: AppDimens.paddingS),
                  Text('Added $defaultLabel 💧'),
                ],
              ),
            ),
          );
        },
        icon: const Icon(Icons.add_rounded),
        label: Text('Add $defaultLabel'),
      ),
    );
  }
}
