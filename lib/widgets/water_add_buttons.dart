import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';
import '../theme/app_theme.dart';

/// Quick-add buttons for adding water intake
/// 
/// Provides pre-defined amounts for quick entry plus a custom input option.
class WaterAddButtons extends ConsumerWidget {
  const WaterAddButtons({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quickAmounts = ref.watch(quickAddAmountsProvider);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Quick add buttons
        Text(
          'Quick Add',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: AppDimens.paddingM),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: AppDimens.paddingM,
          runSpacing: AppDimens.paddingM,
          children: quickAmounts.map((amount) {
            return _QuickAddButton(
              label: amount.label,
              amountMl: amount.amountMl,
            );
          }).toList(),
        ),
        SizedBox(height: AppDimens.paddingXL),
        // Custom amount button
        Center(
          child: OutlinedButton.icon(
            onPressed: () => _showCustomAmountDialog(context, ref),
            icon: const Icon(Icons.add),
            label: const Text('Custom Amount'),
          ),
        ),
      ],
    );
  }

  void _showCustomAmountDialog(BuildContext context, WidgetRef ref) {
    final settings = ref.read(settingsProvider);
    final controller = TextEditingController();
    final useMetric = settings.useMetricUnits;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Custom Amount'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
          ],
          decoration: InputDecoration(
            labelText: 'Amount',
            suffixText: useMetric ? 'ml' : 'oz',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final value = double.tryParse(controller.text);
              if (value != null && value > 0) {
                // Convert to ml if using imperial units
                final amountMl = useMetric ? value : value / 0.033814;
                ref.read(todayEntriesProvider.notifier).addEntry(amountMl);
                Navigator.pop(context);
                
                // Show confirmation
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Added ${controller.text} ${useMetric ? "ml" : "oz"}'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

/// Individual quick-add button widget
class _QuickAddButton extends ConsumerWidget {
  final String label;
  final double amountMl;

  const _QuickAddButton({
    required this.label,
    required this.amountMl,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.primaryContainer,
      borderRadius: BorderRadius.circular(AppDimens.radiusL),
      child: InkWell(
        onTap: () {
          // Add haptic feedback
          HapticFeedback.lightImpact();
          
          // Add water entry
          ref.read(todayEntriesProvider.notifier).addEntry(amountMl);
          
          // Show confirmation snackbar
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Added $label of water 💧'),
              duration: const Duration(seconds: 2),
              action: SnackBarAction(
                label: 'Undo',
                onPressed: () {
                  // TODO: Implement undo functionality
                  // Need to track the last added entry ID and delete it
                },
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(AppDimens.radiusL),
        child: Container(
          width: AppDimens.quickAddButtonSize,
          height: AppDimens.quickAddButtonSize,
          padding: EdgeInsets.all(AppDimens.paddingS),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.water_drop,
                color: theme.colorScheme.primary,
                size: AppDimens.iconXL,
              ),
              SizedBox(height: AppDimens.paddingXS),
              Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Large add button for prominent placement
class LargeAddButton extends ConsumerWidget {
  const LargeAddButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final settings = ref.watch(settingsProvider);
    
    // Default amount: 250ml or 8oz
    final defaultAmount = settings.useMetricUnits ? 250.0 : 236.588;
    final defaultLabel = settings.useMetricUnits ? '250ml' : '8oz';

    return FloatingActionButton.extended(
      onPressed: () {
        HapticFeedback.mediumImpact();
        ref.read(todayEntriesProvider.notifier).addEntry(defaultAmount);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added $defaultLabel of water 💧'),
            duration: const Duration(seconds: 2),
          ),
        );
      },
      icon: const Icon(Icons.add),
      label: Text('Add $defaultLabel'),
      backgroundColor: theme.colorScheme.primary,
      foregroundColor: theme.colorScheme.onPrimary,
    );
  }
}
