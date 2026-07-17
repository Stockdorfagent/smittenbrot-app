import 'package:smittenbrot_app/core/services/supabase_service.dart';
import 'package:smittenbrot_app/features/auth/models/app_user.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthState;

/// Repository for authentication operations.
/// Wraps SupabaseService and translates raw auth data into AppUser models.
class AuthRepository {
  final SupabaseService _supabase = SupabaseService();

  /// Sign in with email and password.
  Future<AppUser> signInWithEmail(String email, String password) async {
    final response = await _supabase.signInWithEmail(email, password);
    final user = response.user;
    if (user == null) {
      throw Exception('Anmeldung fehlgeschlagen: Kein Benutzer zurückgegeben.');
    }
    return AppUser.fromSupabase({
      'id': user.id,
      'email': user.email,
      'name': user.userMetadata?['name'],
      'phone': user.phone,
    });
  }

  /// Sign up with email and password.
  Future<AppUser> signUp(String email, String password) async {
    final response = await _supabase.signUp(email, password);
    final user = response.user;
    if (user == null) {
      throw Exception('Registrierung fehlgeschlagen: Kein Benutzer zurückgegeben.');
    }
    return AppUser.fromSupabase({
      'id': user.id,
      'email': user.email,
      'name': user.userMetadata?['name'],
      'phone': user.phone,
    });
  }

  /// Sign out the current user.
  Future<void> signOut() async {
    await _supabase.signOut();
  }

  /// Get the currently signed-in user.
  AppUser? get currentUser {
    final user = _supabase.currentUser;
    if (user == null) return null;
    return AppUser.fromSupabase({
      'id': user.id,
      'email': user.email,
      'name': user.userMetadata?['name'],
      'phone': user.phone,
    });
  }

  /// Check if a user is currently signed in.
  bool get isSignedIn => _supabase.currentUser != null;

  /// Stream of auth state changes.
  Stream<AuthState> get authStateChanges => _supabase.authStateChanges;
}
