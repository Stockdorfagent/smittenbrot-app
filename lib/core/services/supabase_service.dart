import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/app_constants.dart';

/// Singleton Supabase client service.
/// Access via Riverpod provider `supabaseServiceProvider`.
class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  bool _initialized = false;

  SupabaseClient get client => Supabase.instance.client;

  Future<void> initialize() async {
    if (_initialized) return;
    await Supabase.initialize(
      url: AppConstants.supabaseUrl,
      publishableKey: AppConstants.supabaseAnonKey,
    );
    _initialized = true;
  }

  // ── Auth ──
  Future<AuthResponse> signInWithEmail(String email, String password) =>
      client.auth.signInWithPassword(email: email, password: password);

  Future<AuthResponse> signUp(String email, String password,
          {String? fullName}) =>
      client.auth.signUp(
        email: email,
        password: password,
        data: fullName != null ? {'full_name': fullName} : null,
      );

  Future<void> signInWithMagicLink(String email) =>
      client.auth.signInWithOtp(email: email);

  Future<void> signOut() => client.auth.signOut();

  User? get currentUser => client.auth.currentUser;

  Stream<AuthState> get authStateChanges => client.auth.onAuthStateChange;
}
