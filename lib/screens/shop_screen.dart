import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/shop_item.dart';
import '../providers/providers.dart';
import '../theme/app_theme.dart';

/// Shop screen - Purchase items with points
class ShopScreen extends ConsumerWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(shopItemsProvider);
    final purchasedItems = ref.watch(purchasedItemsProvider);
    final settings = ref.watch(settingsProvider);
    final theme = Theme.of(context);
    final isDark = context.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shop'),
        actions: [
          Container(
            margin: EdgeInsets.only(right: AppDimens.paddingM),
            padding: EdgeInsets.symmetric(
              horizontal: AppDimens.paddingM,
              vertical: AppDimens.paddingS,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.streakGold,
                  AppColors.streakGold.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(AppDimens.radiusCircle),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.stars_rounded, color: Colors.white, size: 20),
                SizedBox(width: AppDimens.paddingXS),
                Text(
                  '${settings.points}',
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
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.all(AppDimens.paddingL),
        children: [
          // Points balance card
          _buildPointsCard(context, settings.points),
          SizedBox(height: AppDimens.paddingXL),

          // Items by category
          ...ShopItemCategory.values.map((category) {
            final categoryItems = items.where((item) => item.category == category).toList();
            if (categoryItems.isEmpty) return const SizedBox.shrink();
            return _CategorySection(
              category: category,
              items: categoryItems,
              purchasedItems: purchasedItems,
            );
          }),

          SizedBox(height: AppDimens.paddingXXL),
        ],
      ),
    );
  }

  Widget _buildPointsCard(BuildContext context, int points) {
    final theme = Theme.of(context);
    final isDark = context.isDarkMode;

    return Container(
      padding: EdgeInsets.all(AppDimens.paddingL),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.streakGold.withOpacity(0.2),
            AppColors.streakGold.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(AppDimens.radiusXL),
        border: Border.all(
          color: AppColors.streakGold.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(AppDimens.paddingM),
            decoration: BoxDecoration(
              color: AppColors.streakGold.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.stars_rounded,
              color: AppColors.streakGold,
              size: 32,
            ),
          ),
          SizedBox(width: AppDimens.paddingL),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Points',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                SizedBox(height: AppDimens.paddingXS),
                Text(
                  '$points',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.streakGold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategorySection extends ConsumerWidget {
  final ShopItemCategory category;
  final List<ShopItem> items;
  final List<PurchasedItem> purchasedItems;

  const _CategorySection({
    required this.category,
    required this.items,
    required this.purchasedItems,
  });

  String _getCategoryName() {
    switch (category) {
      case ShopItemCategory.theme:
        return '🎨 Themes';
      case ShopItemCategory.icon:
        return '🖼️ Icons';
      case ShopItemCategory.badge:
        return '🏅 Badges';
      case ShopItemCategory.container:
        return '🥤 Containers';
      case ShopItemCategory.animation:
        return '✨ Animations';
      case ShopItemCategory.widget:
        return '🎯 Widgets';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: AppDimens.paddingM),
          child: Text(
            _getCategoryName(),
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.85,
            crossAxisSpacing: AppDimens.paddingM,
            mainAxisSpacing: AppDimens.paddingM,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            return _ShopItemCard(
              item: items[index],
              purchasedItems: purchasedItems,
            );
          },
        ),
        SizedBox(height: AppDimens.paddingXL),
      ],
    );
  }
}

class _ShopItemCard extends ConsumerWidget {
  final ShopItem item;
  final List<PurchasedItem> purchasedItems;

  const _ShopItemCard({
    required this.item,
    required this.purchasedItems,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = context.isDarkMode;
    final settings = ref.watch(settingsProvider);
    final purchasedNotifier = ref.read(purchasedItemsProvider.notifier);
    
    final isPurchased = purchasedNotifier.isPurchased(item.id);
    final isEquipped = purchasedNotifier.isEquipped(item.id);
    final canAfford = settings.points >= item.price;

    return GestureDetector(
      onTap: () => _handleTap(context, ref, isPurchased, isEquipped, canAfford),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(AppDimens.radiusL),
          boxShadow: isDark ? [] : AppShadows.small,
          border: isEquipped
              ? Border.all(color: item.rarityColor, width: 2)
              : (isDark
                  ? Border.all(color: Colors.white.withOpacity(0.1))
                  : null),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Icon/Image
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      item.rarityColor.withOpacity(0.2),
                      item.rarityColor.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(AppDimens.radiusL),
                    topRight: Radius.circular(AppDimens.radiusL),
                  ),
                ),
                child: Center(
                  child: Text(
                    item.icon,
                    style: const TextStyle(fontSize: 48),
                  ),
                ),
              ),
            ),
            // Info
            Padding(
              padding: EdgeInsets.all(AppDimens.paddingM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.name,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isEquipped)
                        Icon(
                          Icons.check_circle_rounded,
                          color: item.rarityColor,
                          size: 16,
                        ),
                    ],
                  ),
                  SizedBox(height: AppDimens.paddingXS),
                  Text(
                    item.description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: AppDimens.paddingS),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppDimens.paddingS,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: item.rarityColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(AppDimens.radiusXS),
                        ),
                        child: Text(
                          item.rarityName,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: item.rarityColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 9,
                          ),
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.stars_rounded,
                            size: 14,
                            color: canAfford || isPurchased
                                ? AppColors.streakGold
                                : Colors.grey,
                          ),
                          SizedBox(width: 2),
                          Text(
                            '${item.price}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: canAfford || isPurchased
                                  ? AppColors.streakGold
                                  : Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleTap(
    BuildContext context,
    WidgetRef ref,
    bool isPurchased,
    bool isEquipped,
    bool canAfford,
  ) async {
    HapticFeedback.mediumImpact();

    if (isPurchased) {
      // Equip/Unequip
      if (item.category == ShopItemCategory.theme ||
          item.category == ShopItemCategory.icon ||
          item.category == ShopItemCategory.badge) {
        if (!isEquipped) {
          await ref.read(purchasedItemsProvider.notifier).equipItem(item.id);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${item.name} equipped!')),
            );
          }
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Item already purchased')),
          );
        }
      }
    } else {
      // Purchase
      if (!canAfford) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Not enough points! Need ${item.price} points.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Purchase ${item.name}?'),
          content: Text('Spend ${item.price} points?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Purchase'),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        final success = await ref.read(purchasedItemsProvider.notifier).purchaseItem(item.id);
        if (context.mounted) {
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${item.name} purchased!')),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Purchase failed'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    }
  }
}

