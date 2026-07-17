import 'package:flutter/foundation.dart';
import '../../catalog/data/models/product.dart';
import '../models/cart_item.dart';

/// In-memory cart storage repository.
///
/// Singleton — Supabase-backed cart is overkill at MVP stage.
/// For a future server-backed cart, swap this class' implementation
/// (the interface stays the same).
class CartRepository {
  // ---------------------------------------------------------------------------
  // Singleton
  // ---------------------------------------------------------------------------
  CartRepository._internal();
  static final CartRepository _instance = CartRepository._internal();
  static CartRepository get instance => _instance;
  factory CartRepository() => _instance;

  // ---------------------------------------------------------------------------
  // State
  // ---------------------------------------------------------------------------
  final List<CartItem> _items = [];
  final ValueNotifier<List<CartItem>> _notifier =
      ValueNotifier<List<CartItem>>([]);

  /// Subscribe to cart changes (used by Riverpod or raw [Listenable]).
  ValueNotifier<List<CartItem>> get notifier => _notifier;

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Add [product] to the cart.
  ///
  /// If the same product (by [product.id]) already exists and the
  /// subscription/pickupDate match, the quantity is incremented instead of
  /// creating a duplicate line item.
  void addItem(
    Product product, {
    int quantity = 1,
    bool isSubscription = false,
    String? pickupDate,
  }) {
    final existingIndex = _items.indexWhere(
      (item) =>
          item.product.id == product.id &&
          item.isSubscription == isSubscription &&
          item.pickupDate == pickupDate,
    );

    if (existingIndex >= 0) {
      _items[existingIndex].quantity += quantity;
    } else {
      _items.add(CartItem(
        product: product,
        quantity: quantity,
        isSubscription: isSubscription,
        pickupDate: pickupDate,
      ));
    }

    _notify();
  }

  /// Remove the item identified by [productId].
  void removeItem(String productId) {
    _items.removeWhere((item) => item.product.id == productId);
    _notify();
  }

  /// Update the quantity of an existing cart item.
  ///
  /// If [quantity] is <= 0 the item is removed.
  void updateQuantity(String productId, int quantity) {
    final index = _items.indexWhere((item) => item.product.id == productId);
    if (index < 0) return;

    if (quantity <= 0) {
      _items.removeAt(index);
    } else {
      _items[index].quantity = quantity;
    }

    _notify();
  }

  /// Return a snapshot of the current items.
  List<CartItem> getItems() => List.unmodifiable(_items);

  /// Remove every item from the cart.
  void clear() {
    _items.clear();
    _notify();
  }

  /// Sum of all line-item totals.
  double getTotal() =>
      _items.fold<double>(0, (sum, item) => sum + item.totalPrice);

  /// Number of distinct line items (not total units).
  int getItemCount() => _items.length;

  /// Total number of physical units across all line items.
  int getTotalUnits() =>
      _items.fold<int>(0, (sum, item) => sum + item.quantity);

  /// Whether the cart is empty.
  bool get isEmpty => _items.isEmpty;

  // ---------------------------------------------------------------------------
  // Internals
  // ---------------------------------------------------------------------------
  void _notify() {
    _notifier.value = List.unmodifiable(_items);
  }
}
