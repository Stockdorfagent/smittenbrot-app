import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smittenbrot_app/features/catalog/data/models/product.dart';
import 'package:smittenbrot_app/features/cart/data/cart_repository.dart';
import 'package:smittenbrot_app/features/cart/models/cart_item.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

/// Immutable snapshot of the cart used by Riverpod.
class CartState {
  final List<CartItem> items;
  final double totalPrice;
  final int itemCount;
  final bool isEmpty;

  const CartState({
    required this.items,
    required this.totalPrice,
    required this.itemCount,
    required this.isEmpty,
  });

  CartState copyWith({
    List<CartItem>? items,
    double? totalPrice,
    int? itemCount,
    bool? isEmpty,
  }) =>
      CartState(
        items: items ?? this.items,
        totalPrice: totalPrice ?? this.totalPrice,
        itemCount: itemCount ?? this.itemCount,
        isEmpty: isEmpty ?? this.isEmpty,
      );
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

/// Riverpod [Notifier] that wraps [CartRepository].
///
/// Every mutation calls [CartRepository] and then rebuilds [CartState] so
/// all consumers are notified automatically.
class CartNotifier extends Notifier<CartState> {
  late final CartRepository _repo;

  @override
  CartState build() {
    _repo = CartRepository.instance;
    _repo.notifier.addListener(_onDataChanged);
    return _buildState();
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  void addItem(
    Product product, {
    int quantity = 1,
    bool isSubscription = false,
    String? pickupDate,
  }) {
    _repo.addItem(product,
        quantity: quantity,
        isSubscription: isSubscription,
        pickupDate: pickupDate);
    // State is rebuilt by the listener below.
  }

  void removeItem(String productId) {
    _repo.removeItem(productId);
  }

  void updateQuantity(String productId, int quantity) {
    _repo.updateQuantity(productId, quantity);
  }

  void clear() {
    _repo.clear();
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  void _onDataChanged() {
    state = _buildState();
  }

  CartState _buildState() {
    return CartState(
      items: _repo.getItems(),
      totalPrice: _repo.getTotal(),
      itemCount: _repo.getTotalUnits(),
      isEmpty: _repo.isEmpty,
    );
  }
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final cartProvider = NotifierProvider<CartNotifier, CartState>(
  CartNotifier.new,
);
