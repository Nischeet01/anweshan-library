import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class AuthService extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  String _userRole = 'viewer';
  String get userRole => _userRole;
  bool get isAdmin => _userRole == 'admin';

  AuthService() {
    _supabase.auth.onAuthStateChange.listen((data) {
      final Session? session = data.session;
      if (session != null) {
        _fetchUserRole(session.user.id);
      } else {
        _userRole = 'viewer';
        notifyListeners();
      }
    });
  }

  Future<void> _fetchUserRole(String userId) async {
    try {
      final data = await _supabase
          .from('users')
          .select('role')
          .eq('id', userId)
          .single();
      _userRole = data['role'] as String? ?? 'viewer';
      debugPrint('DEBUG: Fetched user role is $_userRole');
    } catch (e) {
      debugPrint('Error fetching role: $e');
      _userRole = 'viewer';
      debugPrint('DEBUG: Fetched user role is $_userRole');
    }
    notifyListeners();
  }

  User? get currentUser => _supabase.auth.currentUser;

  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  Future<bool> signIn(String email, String password) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (response.user != null) {
        await _fetchUserRole(response.user!.id);
      }
      notifyListeners();
      return response.user != null;
    } catch (e) {
      debugPrint('Sign in error: $e');
      rethrow;
    }
  }

  Future<void> signUp(String email, String password) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );
      if (response.user != null) {
        // Also create a default user record? Subabase might handle it, but we can just notify.
        await _fetchUserRole(response.user!.id);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Sign up error: $e');
      rethrow;
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: kIsWeb ? null : 'anweshanlibrary://login-callback/',
      );
    } catch (e) {
      debugPrint('Google Sign-In error: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
    _userRole = 'viewer';
    notifyListeners();
  }
}
