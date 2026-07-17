import 'package:smittenbrot_app/core/services/supabase_service.dart';
import 'package:smittenbrot_app/features/catalog/data/models/product.dart';

/// Repository that fetches products from Supabase.
/// Matches the same query logic as the website:
/// - Only active products
/// - Filtered by available_wed/available_sat based on pickup day
/// - Filtered by week cycle (permanent/week_a/week_b)
/// - Ordered by sort_order
class ProductRepository {
  final SupabaseService _supabase;

  ProductRepository(this._supabase);

  /// Fetch all active products ordered by sort_order.
  Future<List<Product>> fetchProducts() async {
    final response = await _supabase.client
        .from('products')
        .select('*')
        .eq('active', true)
        .order('sort_order', ascending: true);

    return (response as List)
        .map((json) => Product.fromSupabase(json as Map<String, dynamic>))
        .toList();
  }

  /// Fetch a single product by its UUID.
  Future<Product?> fetchProductById(String id) async {
    final response = await _supabase.client
        .from('products')
        .select('*')
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return Product.fromSupabase(response);
  }

  /// Fetch the current week cycle from Supabase.
  Future<String> fetchCurrentWeek() async {
    final response = await _supabase.client
        .from('week_cycle')
        .select('current_week')
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (response == null) return 'A';
    return (response as Map<String, dynamic>)['current_week'] as String? ?? 'A';
  }

  /// Pickup day determination matching the website logic.
  /// Returns 'wednesday' or 'saturday'.
  static String getPickupDay() {
    final berlin = DateTime.now().toUtc().add(const Duration(hours: 2));
    final day = berlin.weekday; // 1=Mon, 7=Sun
    final minutes = berlin.hour * 60 + berlin.minute;
    const cutoff = 22 * 60;

    // Monday before 22:00 -> Wednesday
    if (day == DateTime.monday && minutes < cutoff) return 'wednesday';
    // Monday after 22:00, or Tue/Wed -> Saturday
    if ((day == DateTime.monday && minutes >= cutoff) ||
        day == DateTime.tuesday ||
        day == DateTime.wednesday) {
      return 'saturday';
    }
    // Thursday before 22:00 -> Saturday
    if (day == DateTime.thursday && minutes < cutoff) return 'saturday';
    // Thursday after 22:00, or Fri/Sat/Sun -> next Wednesday
    return 'wednesday';
  }

  /// Human-readable pickup label.
  static String getPickupLabel() {
    final day = getPickupDay();
    return day == 'wednesday' ? 'Mittwoch' : 'Samstag';
  }

  /// Products filtered for the current pickup day and week.
  Future<List<Product>> fetchAvailableProducts() async {
    final allProducts = await fetchProducts();
    final pickupDay = getPickupDay();
    final currentWeek = await fetchCurrentWeek();

    return allProducts.where((p) {
      if (!p.availableForPickup(pickupDay)) return false;
      if (!p.matchesCycle(currentWeek)) return false;
      return true;
    }).toList();
  }
}
