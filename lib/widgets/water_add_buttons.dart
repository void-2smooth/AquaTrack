import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/container.dart';
import '../providers/providers.dart';
import '../theme/app_theme.dart';

/// Modern quick-add buttons using saved container presets
class WaterAddButtons extends ConsumerWidget {
  const WaterAddButtons({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final containers = ref.watch(quickAddContainersProvider);
    final settings = ref.watch(settingsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Container preset buttons
        if (containers.isNotEmpty) ...[
          Wrap(
            alignment: WrapAlignment.center,
            spacing: AppDimens.paddingM,
            runSpacing: AppDimens.paddingM,
            children: containers.map((container) {
              return _ContainerButton(
                container: container,
                useMetric: settings.useMetricUnits,
              );
            }).toList(),
          ),
          SizedBox(height: AppDimens.paddingL),
        ],
        // Action buttons row
        Row(
          children: [
            Expanded(
              child: _CustomAmountButton(),
            ),
            SizedBox(width: AppDimens.paddingM),
            _ManageContainersButton(),
          ],
        ),
      ],
    );
  }
}

/// Individual container preset button with modern design
class _ContainerButton extends ConsumerStatefulWidget {
  final WaterContainer container;
  final bool useMetric;

  const _ContainerButton({
    required this.container,
    required this.useMetric,
  });

  @override
  ConsumerState<_ContainerButton> createState() => _ContainerButtonState();
}

class _ContainerButtonState extends ConsumerState<_ContainerButton>
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
    final containerColor = Color(widget.container.colorValue);

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
          width: AppDimens.quickAddButtonSize,
          height: AppDimens.quickAddButtonSize + 8,
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
              color: containerColor.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon with colored background
              Container(
                padding: EdgeInsets.all(AppDimens.paddingS),
                decoration: BoxDecoration(
                  color: containerColor.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getIconData(widget.container.icon),
                  color: containerColor,
                  size: AppDimens.iconL,
                ),
              ),
              SizedBox(height: AppDimens.paddingXS),
              // Container name
              Text(
                widget.container.name,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              // Amount
              Text(
                widget.container.formatAmount(widget.useMetric),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: containerColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIconData(String iconName) {
    final codePoint = ContainerIcons.iconCodePoints[iconName];
    if (codePoint != null) {
      return IconData(codePoint, fontFamily: 'MaterialIcons');
    }
    return Icons.local_drink;
  }

  void _handleTap() async {
    HapticFeedback.lightImpact();
    await ref.read(todayEntriesProvider.notifier).addEntry(widget.container.amountMl);
    
    final settings = ref.read(settingsProvider);
    final amountDisplay = widget.container.formatAmount(settings.useMetricUnits);
    
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20),
            SizedBox(width: AppDimens.paddingS),
            Text('Added ${widget.container.name} ($amountDisplay) 💧'),
          ],
        ),
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () async {
            final success = await ref.read(undoProvider.notifier).undo();
            if (success && mounted) {
              HapticFeedback.mediumImpact();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      Icon(Icons.undo_rounded, color: AppColors.warning, size: 20),
                      SizedBox(width: AppDimens.paddingS),
                      const Text('Entry removed'),
                    ],
                  ),
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          },
        ),
      ),
    );
  }
}

/// Custom amount button
class _CustomAmountButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = context.isDarkMode;

    return GestureDetector(
      onTap: () => _showCustomAmountSheet(context, ref),
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
              'Custom',
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

  void _showCustomAmountSheet(BuildContext context, WidgetRef ref) {
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
                      onPressed: () async {
                        final value = double.tryParse(controller.text);
                        if (value != null && value > 0) {
                          final amountMl = useMetric ? value : value / 0.033814;
                          final displayText = '${controller.text} ${useMetric ? "ml" : "oz"}';
                          await ref.read(todayEntriesProvider.notifier).addEntry(amountMl);
                          Navigator.pop(context);
                          
                          ScaffoldMessenger.of(context).clearSnackBars();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  Icon(Icons.check_circle_rounded, 
                                       color: AppColors.success, size: 20),
                                  SizedBox(width: AppDimens.paddingS),
                                  Text('Added $displayText 💧'),
                                ],
                              ),
                              duration: const Duration(seconds: 5),
                              action: SnackBarAction(
                                label: 'Undo',
                                onPressed: () async {
                                  final success = await ref.read(undoProvider.notifier).undo();
                                  if (success) {
                                    HapticFeedback.mediumImpact();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Row(
                                          children: [
                                            Icon(Icons.undo_rounded, color: AppColors.warning, size: 20),
                                            SizedBox(width: AppDimens.paddingS),
                                            const Text('Entry removed'),
                                          ],
                                        ),
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                  }
                                },
                              ),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Add'),
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

/// Button to manage containers
class _ManageContainersButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = context.isDarkMode;

    return GestureDetector(
      onTap: () => _showContainerManager(context, ref),
      child: Container(
        padding: EdgeInsets.all(AppDimens.paddingM),
        decoration: BoxDecoration(
          color: isDark 
              ? Colors.white.withOpacity(0.1) 
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(AppDimens.radiusM),
        ),
        child: Icon(
          Icons.edit_rounded,
          color: theme.colorScheme.onSurface.withOpacity(0.6),
          size: AppDimens.iconM,
        ),
      ),
    );
  }

  void _showContainerManager(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ContainerManagerSheet(),
    );
  }
}

/// Container management bottom sheet
class ContainerManagerSheet extends ConsumerWidget {
  const ContainerManagerSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final containers = ref.watch(containersProvider);
    final settings = ref.watch(settingsProvider);
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppDimens.radiusXXL),
          ),
        ),
        child: Column(
          children: [
            // Handle
            Padding(
              padding: EdgeInsets.all(AppDimens.paddingM),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Header
            Padding(
              padding: EdgeInsets.symmetric(horizontal: AppDimens.paddingXXL),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'My Containers',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => _showAddContainerDialog(context, ref),
                    icon: Container(
                      padding: EdgeInsets.all(AppDimens.paddingS),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.add,
                        color: theme.colorScheme.onPrimary,
                        size: AppDimens.iconM,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: AppDimens.paddingM),
            // Container list
            Expanded(
              child: containers.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.local_drink_outlined,
                            size: 64,
                            color: theme.colorScheme.onSurface.withOpacity(0.3),
                          ),
                          SizedBox(height: AppDimens.paddingL),
                          Text(
                            'No containers yet',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                          SizedBox(height: AppDimens.paddingS),
                          TextButton.icon(
                            onPressed: () => _showAddContainerDialog(context, ref),
                            icon: const Icon(Icons.add),
                            label: const Text('Add Container'),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: scrollController,
                      padding: EdgeInsets.symmetric(horizontal: AppDimens.paddingL),
                      itemCount: containers.length,
                      itemBuilder: (context, index) {
                        final container = containers[index];
                        return _ContainerListItem(
                          container: container,
                          useMetric: settings.useMetricUnits,
                          onEdit: () => _showEditContainerDialog(context, ref, container),
                          onDelete: () => _confirmDelete(context, ref, container),
                          onToggleDefault: (value) {
                            ref.read(containersProvider.notifier)
                                .toggleDefault(container.id, value);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddContainerDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => ContainerEditorDialog(
        onSave: (name, amount, icon, color) async {
          await ref.read(containersProvider.notifier).addContainer(
            name: name,
            amountMl: amount,
            icon: icon,
            colorValue: color,
          );
          if (context.mounted) Navigator.pop(context);
        },
      ),
    );
  }

  void _showEditContainerDialog(BuildContext context, WidgetRef ref, WaterContainer container) {
    showDialog(
      context: context,
      builder: (context) => ContainerEditorDialog(
        container: container,
        onSave: (name, amount, icon, color) async {
          final updated = container.copyWith(
            name: name,
            amountMl: amount,
            icon: icon,
            colorValue: color,
          );
          await ref.read(containersProvider.notifier).updateContainer(updated);
          if (context.mounted) Navigator.pop(context);
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, WaterContainer container) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Container?'),
        content: Text('Are you sure you want to delete "${container.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              ref.read(containersProvider.notifier).deleteContainer(container.id);
              Navigator.pop(context);
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

/// Container list item
class _ContainerListItem extends StatelessWidget {
  final WaterContainer container;
  final bool useMetric;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<bool> onToggleDefault;

  const _ContainerListItem({
    required this.container,
    required this.useMetric,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleDefault,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final containerColor = Color(container.colorValue);

    return Card(
      margin: EdgeInsets.only(bottom: AppDimens.paddingS),
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(AppDimens.paddingS),
          decoration: BoxDecoration(
            color: containerColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(AppDimens.radiusS),
          ),
          child: Icon(
            IconData(
              ContainerIcons.iconCodePoints[container.icon] ?? 0xe24e,
              fontFamily: 'MaterialIcons',
            ),
            color: containerColor,
          ),
        ),
        title: Text(
          container.name,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          container.formatAmount(useMetric),
          style: theme.textTheme.bodySmall?.copyWith(
            color: containerColor,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Quick-add toggle
            Switch(
              value: container.isDefault,
              onChanged: onToggleDefault,
            ),
            // Edit button
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: onEdit,
            ),
            // Delete button
            IconButton(
              icon: Icon(Icons.delete_outline, color: AppColors.error),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

/// Container editor dialog
class ContainerEditorDialog extends StatefulWidget {
  final WaterContainer? container;
  final Future<void> Function(String name, double amount, String icon, int color) onSave;

  const ContainerEditorDialog({
    super.key,
    this.container,
    required this.onSave,
  });

  @override
  State<ContainerEditorDialog> createState() => _ContainerEditorDialogState();
}

class _ContainerEditorDialogState extends State<ContainerEditorDialog> {
  late TextEditingController _nameController;
  late TextEditingController _amountController;
  late String _selectedIcon;
  late int _selectedColor;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.container?.name ?? '');
    _amountController = TextEditingController(
      text: widget.container?.amountMl.toStringAsFixed(0) ?? '',
    );
    _selectedIcon = widget.container?.icon ?? 'local_drink';
    _selectedColor = widget.container?.colorValue ?? ContainerColors.colors.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.container != null;

    return AlertDialog(
      title: Text(isEditing ? 'Edit Container' : 'New Container'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Name field
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'e.g., My Water Bottle',
              ),
              textCapitalization: TextCapitalization.words,
            ),
            SizedBox(height: AppDimens.paddingL),
            // Amount field
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Amount (ml)',
                hintText: 'e.g., 500',
              ),
            ),
            SizedBox(height: AppDimens.paddingXL),
            // Icon selector
            Text(
              'Icon',
              style: theme.textTheme.labelLarge,
            ),
            SizedBox(height: AppDimens.paddingS),
            Wrap(
              spacing: AppDimens.paddingS,
              runSpacing: AppDimens.paddingS,
              children: ContainerIcons.icons.map((iconName) {
                final isSelected = iconName == _selectedIcon;
                final codePoint = ContainerIcons.iconCodePoints[iconName]!;
                return GestureDetector(
                  onTap: () => setState(() => _selectedIcon = iconName),
                  child: Container(
                    padding: EdgeInsets.all(AppDimens.paddingS),
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? Color(_selectedColor).withOpacity(0.2) 
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(AppDimens.radiusS),
                      border: Border.all(
                        color: isSelected 
                            ? Color(_selectedColor) 
                            : Colors.grey.shade300,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Icon(
                      IconData(codePoint, fontFamily: 'MaterialIcons'),
                      color: isSelected ? Color(_selectedColor) : Colors.grey,
                    ),
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: AppDimens.paddingXL),
            // Color selector
            Text(
              'Color',
              style: theme.textTheme.labelLarge,
            ),
            SizedBox(height: AppDimens.paddingS),
            Wrap(
              spacing: AppDimens.paddingS,
              runSpacing: AppDimens.paddingS,
              children: ContainerColors.colors.map((colorValue) {
                final isSelected = colorValue == _selectedColor;
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = colorValue),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Color(colorValue),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.white : Colors.transparent,
                        width: 3,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: Color(colorValue).withOpacity(0.5),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ]
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white, size: 20)
                        : null,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _handleSave,
          child: Text(isEditing ? 'Save' : 'Create'),
        ),
      ],
    );
  }

  void _handleSave() {
    final name = _nameController.text.trim();
    final amount = double.tryParse(_amountController.text) ?? 0;

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a name')),
      );
      return;
    }

    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    widget.onSave(name, amount, _selectedIcon, _selectedColor);
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
        onPressed: () async {
          HapticFeedback.mediumImpact();
          await ref.read(todayEntriesProvider.notifier).addEntry(defaultAmount);
          
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
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'Undo',
                onPressed: () async {
                  final success = await ref.read(undoProvider.notifier).undo();
                  if (success) {
                    HapticFeedback.mediumImpact();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            Icon(Icons.undo_rounded, color: AppColors.warning, size: 20),
                            SizedBox(width: AppDimens.paddingS),
                            const Text('Entry removed'),
                          ],
                        ),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                },
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
