/// Order status matching the website.
enum OrderStatus {
  pending,
  confirmed,
  processing,
  ready,
  pickedUp,
  cancelled;

  String get displayName {
    switch (this) {
      case OrderStatus.pending: return 'Ausstehend';
      case OrderStatus.confirmed: return 'Bestätigt';
      case OrderStatus.processing: return 'In Produktion';
      case OrderStatus.ready: return 'Bereit zur Abholung';
      case OrderStatus.pickedUp: return 'Abgeholt';
      case OrderStatus.cancelled: return 'Storniert';
    }
  }

  bool get isActive => this == OrderStatus.pending || this == OrderStatus.confirmed || this == OrderStatus.processing;
}

/// A single item in an order.
class OrderItem {
  final String productName;
  final int quantity;
  final int priceCents;

  OrderItem({required this.productName, required this.quantity, required this.priceCents});

  double get price => priceCents / 100;
  double get total => price * quantity;

  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
    productName: json['product_name'] ?? json['products']?['name'] ?? '',
    quantity: json['quantity'] ?? 0,
    priceCents: (json['price_cents'] ?? json['unit_price_cents'] ?? 0).toInt(),
  );
}

/// Order model matching the Supabase `orders` table structure.
class Order {
  final String id;
  final OrderStatus status;
  final double totalAmount;
  final DateTime createdAt;
  final DateTime? pickupDate;
  final String? fulfillmentDate;
  final String? pickupLocation;
  final List<OrderItem> items;
  final String? paymentMethod;
  final String? paymentStatus;
  final String? orderNumber;
  final String? invoiceNumber;

  Order({
    required this.id,
    required this.status,
    required this.totalAmount,
    required this.createdAt,
    this.pickupDate,
    this.fulfillmentDate,
    this.pickupLocation,
    this.items = const [],
    this.paymentMethod,
    this.paymentStatus,
    this.orderNumber,
    this.invoiceNumber,
  });

  factory Order.fromJson(Map<String, dynamic> json) => Order(
    id: json['id'] ?? '',
    status: OrderStatus.values.firstWhere(
      (s) => s.name == json['status'],
      orElse: () => OrderStatus.pending,
    ),
    totalAmount: (json['total_amount'] ?? 0.0).toDouble(),
    createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    pickupDate: json['pickup_date'] != null ? DateTime.tryParse(json['pickup_date']) : null,
    fulfillmentDate: json['fulfillment_date'] as String?,
    pickupLocation: json['pickup_location'] ?? json['pickup_locations']?['name'] as String?,
    items: (json['items'] as List?)?.map((i) => OrderItem.fromJson(i)).toList() ?? [],
    paymentMethod: json['payment_method'],
    paymentStatus: json['payment_status'],
    orderNumber: json['order_number'] as String?,
    invoiceNumber: json['invoice_number'] as String?,
  );

  String get formattedTotal => '\u20AC${totalAmount.toStringAsFixed(2).replaceAll('.', ',')}';
  String get formattedDate => '${createdAt.day}.${createdAt.month}.${createdAt.year}';
  String get displayId => orderNumber ?? '#${id.substring(0, 8).toUpperCase()}';
}
