/// Subscription status matching the Supabase schema.
enum SubscriptionStatus {
  active,
  paused,
  cancellationPending,
  cancelled,
  paymentFailed;

  String get displayName {
    switch (this) {
      case SubscriptionStatus.active: return 'Aktiv';
      case SubscriptionStatus.paused: return 'Pausiert';
      case SubscriptionStatus.cancellationPending: return 'Kündigung läuft';
      case SubscriptionStatus.cancelled: return 'Gekündigt';
      case SubscriptionStatus.paymentFailed: return 'Zahlung fehlgeschlagen';
    }
  }

  bool get isActive =>
      this == SubscriptionStatus.active ||
      this == SubscriptionStatus.cancellationPending;
}

/// A product item within a subscription.
class SubscriptionItem {
  final String productId;
  final String productName;
  final int quantity;
  final int priceCents;

  SubscriptionItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.priceCents,
  });

  double get price => priceCents / 100;
  double get total => price * quantity;
  String get formattedPrice => '\u20AC${price.toStringAsFixed(2).replaceAll('.', ',')}';
}

/// Subscription model matching the Supabase `subscriptions` table.
class Subscription {
  final String id;
  final SubscriptionStatus status;
  final DateTime createdAt;
  final String? pausedUntil;
  final String pickupLocationId;
  final String? pickupLocationName;
  final List<SubscriptionItem> items;

  Subscription({
    required this.id,
    required this.status,
    required this.createdAt,
    this.pausedUntil,
    required this.pickupLocationId,
    this.pickupLocationName,
    this.items = const [],
  });

  String get formattedPrice {
    final total = items.fold<int>(0, (sum, item) => sum + (item.priceCents * item.quantity));
    return '\u20AC${(total / 100).toStringAsFixed(2).replaceAll('.', ',')}';
  }

  String get productNames =>
      items.map((i) => '${i.quantity}× ${i.productName}').join(', ');

  /// Estimated next pickup date based on the website's schedule logic.
  String? get nextPickupLabel {
    if (status == SubscriptionStatus.paused || status == SubscriptionStatus.cancelled) return null;
    final now = DateTime.now().toUtc().add(const Duration(hours: 2));
    final day = now.weekday;
    final minutes = now.hour * 60 + now.minute;
    const cutoff = 22 * 60;

    if (day == DateTime.monday && minutes < cutoff) return 'Mittwoch';
    if ((day == DateTime.monday && minutes >= cutoff) ||
        day == DateTime.tuesday || day == DateTime.wednesday) return 'Samstag';
    if (day == DateTime.thursday && minutes < cutoff) return 'Samstag';
    return 'Mittwoch';
  }
}
