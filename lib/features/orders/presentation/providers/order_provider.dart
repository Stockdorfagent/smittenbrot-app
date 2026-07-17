import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smittenbrot_app/core/providers/app_providers.dart';
import 'package:smittenbrot_app/features/orders/data/order_repository.dart';
import 'package:smittenbrot_app/features/orders/models/order.dart';

/// Repository provider (uses Supabase).
final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  final supabase = ref.read(supabaseServiceProvider);
  return OrderRepository(supabase);
});

/// State class for order async data.
class OrderListState {
  final List<Order> orders;
  final bool isLoading;
  final String? error;

  const OrderListState({
    this.orders = const [],
    this.isLoading = false,
    this.error,
  });

  OrderListState copyWith({
    List<Order>? orders,
    bool? isLoading,
    String? error,
  }) {
    return OrderListState(
      orders: orders ?? this.orders,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notifier that manages order list state.
class OrderListNotifier extends StateNotifier<OrderListState> {
  final OrderRepository _repository;

  OrderListNotifier(this._repository) : super(const OrderListState());

  Future<void> fetchOrders() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final orders = await _repository.fetchOrders();
      state = OrderListState(orders: orders, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> cancelOrder(String id) async {
    try {
      final success = await _repository.cancelOrder(id);
      if (success) {
        await fetchOrders();
      }
      return success;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }
}

/// Provider for order list actions and state.
final orderListProvider =
    StateNotifierProvider<OrderListNotifier, OrderListState>((ref) {
  final repository = ref.read(orderRepositoryProvider);
  return OrderListNotifier(repository);
});

/// Provider that filters orders by a given status.
final filteredOrdersByStatusProvider =
    Provider.family<List<Order>, OrderStatus?>((ref, status) {
  final orderState = ref.watch(orderListProvider);
  if (status == null) return orderState.orders;
  return orderState.orders.where((o) => o.status == status).toList();
});

/// Providers that split orders into active and past.
final activeOrdersProvider = Provider<List<Order>>((ref) {
  final orderState = ref.watch(orderListProvider);
  return orderState.orders.where((o) => o.status.isActive).toList();
});

final pastOrdersProvider = Provider<List<Order>>((ref) {
  final orderState = ref.watch(orderListProvider);
  return orderState.orders.where((o) => !o.status.isActive).toList();
});

/// Provider for a single order by ID (fetches fresh).
final orderByIdProvider = FutureProvider.family<Order?, String>((ref, id) async {
  final repository = ref.read(orderRepositoryProvider);
  return repository.fetchOrderById(id);
});
