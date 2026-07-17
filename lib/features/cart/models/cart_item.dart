import '../../catalog/data/models/product.dart';

class CartItem {
  final Product product;
  int quantity;
  final bool isSubscription;
  final String? pickupDate;

  CartItem({
    required this.product,
    this.quantity = 1,
    this.isSubscription = false,
    this.pickupDate,
  });

  int get totalCents => product.priceCents * quantity;
  double get totalPrice => totalCents / 100;

  Map<String, dynamic> toJson() => {
    'product_id': product.id,
    'quantity': quantity,
    'name': product.name,
    'price_cents': product.priceCents,
    'total_cents': totalCents,
    'is_subscription': isSubscription,
    'pickup_date': pickupDate,
  };
}
