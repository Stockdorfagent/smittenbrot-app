/// Product model matching Supabase `products` table schema.
class Product {
  final String id;
  final String name;
  final String description;
  final int priceCents;
  final bool active;
  final bool availableWed;
  final bool availableSat;
  final String cycle; // 'permanent', 'week_a', 'week_b'
  final int capacity;
  final int sortOrder;
  final String? coverImageUrl;
  final List<String> images;
  final double taxRate;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.priceCents,
    this.active = true,
    this.availableWed = true,
    this.availableSat = true,
    this.cycle = 'permanent',
    this.capacity = 0,
    this.sortOrder = 0,
    this.coverImageUrl,
    this.images = const [],
    this.taxRate = 0.07,
  });

  factory Product.fromSupabase(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      priceCents: (json['price_cents'] as num?)?.toInt() ?? 0,
      active: json['active'] as bool? ?? true,
      availableWed: json['available_wed'] as bool? ?? true,
      availableSat: json['available_sat'] as bool? ?? true,
      cycle: json['cycle'] as String? ?? 'permanent',
      capacity: (json['capacity'] as num?)?.toInt() ?? 0,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      coverImageUrl: json['cover_image_url'] as String?,
      images: (json['images'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      taxRate: (json['tax_rate'] as num?)?.toDouble() ?? 0.07,
    );
  }

  String get formattedPrice => '\u20AC${(priceCents / 100).toStringAsFixed(2).replaceAll('.', ',')}';

  /// Whether this product is available for the given pickup day.
  bool availableForPickup(String pickupDay) =>
      pickupDay == 'wednesday' ? availableWed : availableSat;

  /// Whether this product should appear given the current week cycle.
  bool matchesCycle(String currentWeek) {
    if (cycle == 'permanent') return true;
    if (cycle == 'week_a') return currentWeek == 'A';
    if (cycle == 'week_b') return currentWeek == 'B';
    return false;
  }

  /// Deterministic color index for consistent card styling.
  int get colorIndex {
    var hash = 0;
    for (var i = 0; i < id.length; i++) {
      hash = 31 * hash + id.codeUnitAt(i);
    }
    return hash.abs() % 5;
  }
}
