import 'package:smittenbrot_app/core/services/supabase_service.dart';
import 'package:smittenbrot_app/features/subscriptions/models/subscription.dart';

/// Repository for subscription data from Supabase.
class SubscriptionRepository {
  final SupabaseService _supabase;

  SubscriptionRepository(this._supabase);

  /// Fetch all subscriptions for the current user from Supabase.
  Future<List<Subscription>> fetchSubscriptions() async {
    final user = _supabase.currentUser;
    if (user == null) return [];

    final response = await _supabase.client
        .from('subscriptions')
        .select('*, subscription_items(*, products(name, price_cents)), pickup_locations(name)')
        .eq('customer_id', user.id)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => _fromSupabase(json as Map<String, dynamic>))
        .toList();
  }

  /// Pause a subscription.
  Future<bool> pauseSubscription(String id, {String? until}) async {
    try {
      await _supabase.client
          .from('subscriptions')
          .update({'status': 'paused', 'paused_until': until, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', id);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Resume a paused subscription.
  Future<bool> resumeSubscription(String id) async {
    try {
      await _supabase.client
          .from('subscriptions')
          .update({'status': 'active', 'paused_until': null, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', id);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Cancel a subscription.
  Future<bool> cancelSubscription(String id) async {
    try {
      await _supabase.client
          .from('subscriptions')
          .update({'status': 'cancelled', 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', id);
      return true;
    } catch (_) {
      return false;
    }
  }

  Subscription _fromSupabase(Map<String, dynamic> json) {
    final itemsList = (json['subscription_items'] as List?) ?? [];
    final location = json['pickup_locations'];

    return Subscription(
      id: json['id'] as String? ?? '',
      status: _mapStatus(json['status'] as String? ?? 'active'),
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
      pausedUntil: json['paused_until'] as String?,
      pickupLocationId: json['pickup_location_id'] as String? ?? '',
      pickupLocationName: location is Map ? location['name'] as String? : null,
      items: itemsList.map((itemJson) => SubscriptionItem(
        productId: itemJson['product_id'] as String? ?? '',
        productName: itemJson['products']?['name'] as String? ?? '',
        quantity: (itemJson['quantity'] as num?)?.toInt() ?? 0,
        priceCents: (itemJson['products']?['price_cents'] as num?)?.toInt() ?? 0,
      )).toList(),
    );
  }

  SubscriptionStatus _mapStatus(String status) {
    switch (status) {
      case 'active': return SubscriptionStatus.active;
      case 'paused': return SubscriptionStatus.paused;
      case 'cancellation_pending': return SubscriptionStatus.cancellationPending;
      case 'cancelled': return SubscriptionStatus.cancelled;
      case 'payment_failed': return SubscriptionStatus.paymentFailed;
      default: return SubscriptionStatus.active;
    }
  }
}
