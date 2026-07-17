import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smittenbrot_app/core/theme/app_colors.dart';
import 'package:smittenbrot_app/features/catalog/data/models/product.dart';
import 'package:smittenbrot_app/features/catalog/presentation/providers/product_provider.dart';

/// Full product detail screen.
class ProductDetailScreen extends ConsumerWidget {
  final String productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productAsync = ref.watch(productByIdProvider(productId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: productAsync.when(
          data: (product) => Text(product?.name ?? 'Produkt'),
          loading: () => const Text('Produkt'),
          error: (_, __) => const Text('Fehler'),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: productAsync.when(
        data: (product) {
          if (product == null) {
            return _buildErrorView(
                context, 'Produkt nicht gefunden.', () {});
          }
          return _ProductDetailContent(product: product);
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (error, _) => _buildErrorView(
          context,
          'Fehler beim Laden: $error',
          () => ref.invalidate(productByIdProvider(productId)),
        ),
      ),
    );
  }

  Widget _buildErrorView(
      BuildContext context, String message, VoidCallback onRetry) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text(message, style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onRetry, child: const Text('Erneut versuchen')),
          ],
        ),
      ),
    );
  }
}

class _ProductDetailContent extends StatelessWidget {
  final Product product;
  const _ProductDetailContent({required this.product});

  static const _colors = [
    Color(0xFF8B5E3C),
    Color(0xFF6B8E4E),
    Color(0xFFC17A2B),
    Color(0xFF7B5B3A),
    Color(0xFFA0522D),
  ];

  static const _icons = [
    Icons.bakery_dining,
    Icons.breakfast_dining,
    Icons.cake,
    Icons.straighten,
    Icons.flatware,
  ];

  @override
  Widget build(BuildContext context) {
    final ci = product.colorIndex;
    final color = _colors[ci];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero image area
          Container(
            width: double.infinity,
            height: 280,
            decoration: BoxDecoration(
              color: color,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [color, color.withValues(alpha: 0.7)],
              ),
            ),
            child: Center(
              child: Icon(_icons[ci], size: 100, color: Colors.white38),
            ),
          ),

          // Product info
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(product.name,
                          style: Theme.of(context).textTheme.headlineSmall),
                    ),
                    const SizedBox(width: 16),
                    Text(product.formattedPrice,
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w800)),
                  ],
                ),
                const SizedBox(height: 20),
                Text(product.description,
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(height: 1.6)),
                const SizedBox(height: 24),
                // Add to cart button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              '${product.name} wurde in den Warenkorb gelegt.'),
                          backgroundColor: AppColors.success,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      );
                    },
                    icon: const Icon(Icons.shopping_cart_outlined),
                    label: const Text('In den Warenkorb',
                        style: TextStyle(fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
