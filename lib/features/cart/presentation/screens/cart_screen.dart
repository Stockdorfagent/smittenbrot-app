import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smittenbrot_app/core/theme/app_colors.dart';
import 'package:smittenbrot_app/core/constants/app_constants.dart';
import 'package:smittenbrot_app/features/cart/models/cart_item.dart';
import 'package:smittenbrot_app/features/cart/presentation/providers/cart_provider.dart';

// =============================================================================
// Cart Screen
// =============================================================================

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartState = ref.watch(cartProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Warenkorb'),
        actions: [
          if (!cartState.isEmpty)
            TextButton(
              onPressed: () => ref.read(cartProvider.notifier).clear(),
              child: const Text(
                'Leeren',
                style: TextStyle(color: AppColors.error),
              ),
            ),
        ],
      ),
      body: cartState.isEmpty
          ? const _EmptyCartView()
          : _CartBody(items: cartState.items),
      bottomNavigationBar: cartState.isEmpty
          ? null
          : _CartBottomBar(totalPrice: cartState.totalPrice),
    );
  }
}

// =============================================================================
// Empty State
// =============================================================================

class _EmptyCartView extends StatelessWidget {
  const _EmptyCartView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding * 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Placeholder illustration — replaces with an SVG/asset later
            Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                color: AppColors.accentLight.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(80),
              ),
              child: const Icon(
                Icons.shopping_bag_outlined,
                size: 72,
                color: AppColors.textHint,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Ihr Warenkorb ist leer',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Entdecken Sie unser Sortiment an\nhandgemachten Backwaren.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => context.go('/catalog'),
                icon: const Icon(Icons.store_outlined),
                label: const Text('Zum Sortiment'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Cart Body (filled)
// =============================================================================

class _CartBody extends ConsumerWidget {
  final List<CartItem> items;

  const _CartBody({required this.items});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.separated(
      padding: const EdgeInsets.only(
        top: AppConstants.defaultPadding,
        bottom: AppConstants.defaultPadding * 2,
      ),
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(indent: 72, endIndent: 16),
      itemBuilder: (context, index) => _CartItemTile(item: items[index]),
    );
  }
}

// =============================================================================
// Cart Item Tile
// =============================================================================

class _CartItemTile extends ConsumerWidget {
  final CartItem item;

  const _CartItemTile({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(cartProvider.notifier);

    return Dismissible(
      key: ValueKey('${item.product.id}_${item.pickupDate}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        color: AppColors.error,
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
      ),
      onDismissed: (_) => notifier.removeItem(item.product.id),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.defaultPadding,
          vertical: 8,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image placeholder
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 56,
                height: 56,
                color: AppColors.accentLight.withValues(alpha: 0.4),
                child: const Icon(
                  Icons.restaurant_outlined,
                  color: AppColors.textHint,
                  size: 28,
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Name & details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.product.name,
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${item.product.formattedPrice} / Stück',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  if (item.isSubscription)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.info.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Abonnement',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.info,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Quantity controls
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.accentLight),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: () => notifier.updateQuantity(
                      item.product.id,
                      item.quantity - 1,
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(10),
                      bottomLeft: Radius.circular(10),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      child: Icon(Icons.remove, size: 18, color: AppColors.primary),
                    ),
                  ),
                  SizedBox(
                    width: 36,
                    child: Text(
                      '${item.quantity}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () => notifier.updateQuantity(
                      item.product.id,
                      item.quantity + 1,
                    ),
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(10),
                      bottomRight: Radius.circular(10),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      child: Icon(Icons.add, size: 18, color: AppColors.primary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // Line total
            SizedBox(
              width: 64,
              child: Text(
                item.product.formattedPrice,
                textAlign: TextAlign.right,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.primary,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Bottom Bar
// =============================================================================

class _CartBottomBar extends ConsumerWidget {
  final double totalPrice;

  const _CartBottomBar({required this.totalPrice});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formattedTotal =
        '€${totalPrice.toStringAsFixed(2).replaceAll('.', ',')}';

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppConstants.defaultPadding,
        AppConstants.defaultPadding,
        AppConstants.defaultPadding,
        AppConstants.defaultPadding + 8,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Total label
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Gesamtsumme',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  formattedTotal,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: AppColors.primary,
                      ),
                ),
              ],
            ),
            const Spacer(),
            // Checkout button
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () => context.push('/checkout'),
                icon: const Icon(Icons.arrow_forward_ios, size: 16),
                label: const Text('Zur Kasse'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
