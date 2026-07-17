import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smittenbrot_app/core/services/supabase_service.dart';

/// Riverpod provider for the singleton SupabaseService.
final supabaseServiceProvider = Provider<SupabaseService>((ref) {
  return SupabaseService();
});
