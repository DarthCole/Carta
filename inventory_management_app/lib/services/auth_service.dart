import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'database_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;

  Future<AuthResponse> signUp({required String email, required String password}) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );
      return response;
    } catch (e) {
      debugPrint('AuthService signUp error: $e');
      rethrow;
    }
  }

  Future<AuthResponse> signIn({required String email, required String password}) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response;
    } catch (e) {
      debugPrint('AuthService signIn error: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      // Clear all local SQLite data so it doesn't leak to the next user logging in on this device
      await DatabaseService().clearAllData();
      await _supabase.auth.signOut();
    } catch (e) {
      debugPrint('AuthService signOut error: $e');
      rethrow;
    }
  }

  Session? get currentSession => _supabase.auth.currentSession;
}
