import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:smittenbrot_app/core/constants/app_constants.dart';
import 'package:smittenbrot_app/core/services/supabase_service.dart';
import 'package:smittenbrot_app/features/cart/models/cart_item.dart';
import 'package:smittenbrot_app/features/orders/models/order.dart';

/// Payment repository that calls the Smittenbrot website API
/// and uses flutter_stripe for native payment confirmation.
class PaymentRepository {
  PaymentRepository._internal();
  static final PaymentRepository _instance = PaymentRepository._internal();
  static PaymentRepository get instance => _instance;
  factory PaymentRepository() => _instance;

  /// Calls POST /api/create-payment-intent on the website backend.
  /// Returns the client secret for Stripe payment confirmation.
  Future<String> createPaymentIntent({
    required List<CartItem> items,
    required String fulfillmentDate,
    required String? pickupLocationId,
    required String? customerEmail,
    required String? customerName,
    required String? customerId,
    String? discountCode,
  }) async {
    final body = {
      'items': items.map((item) => {
        'product_id': item.product.id,
        'price_cents': item.product.priceCents,
        'quantity': item.quantity,
      }).toList(),
      'fulfillment_date': fulfillmentDate,
      'pickup_location_id': pickupLocationId,
      'customer_email': customerEmail ?? '',
      'customer_name': customerName ?? '',
      'customer_id': customerId,
      'discount_code': discountCode,
    };

    final response = await http.post(
      Uri.parse('${AppConstants.websiteBaseUrl}/api/create-payment-intent'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode != 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(data['error'] ?? 'Payment intent creation failed');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return data['clientSecret'] as String;
  }

  /// Confirms payment using flutter_stripe.
  /// Returns the order ID on success.
  Future<String> confirmPayment(String clientSecret) async {
    try {
      final result = await Stripe.instance.confirmPayment(
        paymentIntentClientSecret: clientSecret,
        data: PaymentMethodParams.card(
          paymentMethodData: PaymentMethodData(
            billingDetails: const BillingDetails(
              address: Address(
                city: '',
                country: 'DE',
                line1: '',
                line2: '',
                postalCode: '',
                state: '',
              ),
            ),
          ),
        ),
      );

      if (result.status == PaymentIntentsStatus.Succeeded) {
        return result.id;
      }

      throw Exception('Zahlung wurde nicht abgeschlossen.');
    } catch (e) {
      if (e is StripeException) {
        throw Exception(
            'Zahlung fehlgeschlagen: ${e.error.localizedMessage}');
      }
      rethrow;
    }
  }

  /// Fetch orders from Supabase for the current user.
  Future<List<Order>> fetchOrders(String userId) async {
    final supabase = SupabaseService().client;
    final response = await supabase
        .from('orders')
        .select('*, order_items(*, products(name))')
        .eq('customer_id', userId)
        .order('created_at', ascending: false);

    return (response as List).map((json) {
      final itemsList = (json['order_items'] as List?) ?? [];
      return Order(
        id: json['id'] as String? ?? '',
        status: _mapStatus(json['status'] as String? ?? ''),
        totalAmount: ((json['total_cents'] as num?)?.toDouble() ?? 0) / 100,
        createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
        fulfillmentDate: json['fulfillment_date'] as String?,
        pickupLocation: json['pickup_locations']?['name'] as String? ?? '',
        invoiceNumber: json['invoice_number'] as String?,
        orderNumber: json['order_number'] as String?,
        paymentStatus: json['payment_status'] as String?,
        items: itemsList.map((itemJson) => OrderItem(
          productName: itemJson['products']?['name'] as String? ?? '',
          quantity: (itemJson['quantity'] as num?)?.toInt() ?? 0,
          priceCents: (itemJson['unit_price_cents'] as num?)?.toInt() ?? 0,
        )).toList(),
      );
    }).toList();
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
