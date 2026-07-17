import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smittenbrot_app/core/providers/app_providers.dart';
import 'package:smittenbrot_app/core/services/supabase_service.dart';
import 'package:smittenbrot_app/features/catalog/data/models/product.dart';
import 'package:smittenbrot_app/features/catalog/data/product_repository.dart';

/// Repository provider.
final productRepositoryProvider = Provider<ProductRepository>((ref) {
  final supabase = ref.read(supabaseServiceProvider);
  return ProductRepository(supabase);
});

/// All active products from Supabase.
final productsProvider = FutureProvider<List<Product>>((ref) async {
  final repository = ref.read(productRepositoryProvider);
  return repository.fetchProducts();
});

/// Products filtered for current pickup day + week cycle.
final availableProductsProvider = FutureProvider<List<Product>>((ref) async {
  final repository = ref.read(productRepositoryProvider);
  return repository.fetchAvailableProducts();
});

/// Current pickup day label.
final pickupDayProvider = Provider<String>((ref) {
  return ProductRepository.getPickupLabel();
});

/// Single product by ID.
final productByIdProvider =
    FutureProvider.family<Product?, String>((ref, productId) async {
  final repository = ref.read(productRepositoryProvider);
  return repository.fetchProductById(productId);
});
