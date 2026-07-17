import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:smittenbrot_app/core/constants/app_constants.dart';
import 'package:smittenbrot_app/core/services/supabase_service.dart';
import 'package:smittenbrot_app/features/orders/models/order.dart';

/// Repository for order data.
/// Queries Supabase directly — same data as the website.
class OrderRepository {
  final SupabaseService _supabase;

  OrderRepository(this._supabase);

  /// Fetch all orders for the current user from Supabase.
  Future<List<Order>> fetchOrders() async {
    final user = _supabase.currentUser;
    if (user == null) return [];

    final response = await _supabase.client
        .from('orders')
        .select('*, order_items(*, products(name)), pickup_locations(name)')
        .eq('customer_id', user.id)
        .order('created_at', ascending: false);

    return (response as List).map((json) => _orderFromSupabase(json)).toList();
  }

  /// Fetch a single order by ID.
  Future<Order?> fetchOrderById(String id) async {
    final response = await _supabase.client
        .from('orders')
        .select('*, order_items(*, products(name)), pickup_locations(name)')
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return _orderFromSupabase(response as Map<String, dynamic>);
  }

  /// Cancel an order via the website API (Stripe refund + credit note).
  Future<bool> cancelOrder(String id) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.websiteBaseUrl}/api/refund-order'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'orderId': id}),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Order _orderFromSupabase(Map<String, dynamic> json) {
    final itemsList = (json['order_items'] as List?) ?? [];
    final location = json['pickup_locations'];
    return Order(
      id: json['id'] as String? ?? '',
      status: _mapStatus(json['status'] as String? ?? ''),
      totalAmount: ((json['total_cents'] as num?)?.toDouble() ?? 0) / 100,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
      fulfillmentDate: json['fulfillment_date'] as String?,
      pickupLocation: location is Map ? location['name'] as String? : null,
      orderNumber: json['order_number'] as String?,
      invoiceNumber: json['invoice_number'] as String?,
      paymentStatus: json['payment_status'] as String?,
      items: itemsList.map((itemJson) => OrderItem(
        productName: itemJson['products']?['name'] as String? ?? '',
        quantity: (itemJson['quantity'] as num?)?.toInt() ?? 0,
        priceCents: (itemJson['unit_price_cents'] as num?)?.toInt() ?? 0,
      )).toList(),
    );
  }

  OrderStatus _mapStatus(String status) {
    switch (status) {
      case 'fulfilled': return OrderStatus.pickedUp;
      case 'cancelled':
      case 'refunded': return OrderStatus.cancelled;
      case 'locked_for_production': return OrderStatus.processing;
      default: return OrderStatus.pending;
    }
  }
}
