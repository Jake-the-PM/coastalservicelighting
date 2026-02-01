import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// User role in the Coastal Services ecosystem
enum UserRole {
  installer,
  homeowner,
}

/// Extended user profile with role information
class CoastalUser {
  final String uid;
  final String email;
  final String? fullName;
  final UserRole role;
  final DateTime createdAt;

  CoastalUser({
    required this.uid,
    required this.email,
    this.fullName,
    required this.role,
    required this.createdAt,
  });

  factory CoastalUser.fromMap(Map<String, dynamic> data) {
    return CoastalUser(
      uid: data['id'] ?? '',
      email: data['email'] ?? '',
      fullName: data['full_name'], // DB Column
      role: data['role'] == 'installer' ? UserRole.installer : UserRole.homeowner,
      createdAt: DateTime.tryParse(data['created_at'] ?? '') ?? DateTime.now(),
    );
  }

  bool get isInstaller => role == UserRole.installer;
}

/// Authentication service wrapping Supabase Auth + user profiles
class AuthService extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  User? _supabaseUser;
  CoastalUser? _coastalUser;
  bool _isLoading = true;

  // Getters
  User? get supabaseUser => _supabaseUser;
  CoastalUser? get currentUser => _coastalUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _supabaseUser != null && _coastalUser != null;
  bool get isInstaller => _coastalUser?.isInstaller ?? false;

  AuthService() {
    // Check current session
    _initializeAuth();
    
    // Listen to auth state changes
    _supabase.auth.onAuthStateChange.listen(_onAuthStateChanged);
  }

  Future<void> _initializeAuth() async {
    final session = _supabase.auth.currentSession;
    if (session != null) {
      _supabaseUser = session.user;
      await _loadUserProfile(session.user.id);
    }
    _isLoading = false;
    notifyListeners();
  }

  void _onAuthStateChanged(AuthState state) async {
    _supabaseUser = state.session?.user;
    
    if (_supabaseUser != null) {
      await _loadUserProfile(_supabaseUser!.id);
    } else {
      _coastalUser = null;
    }
    
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadUserProfile(String uid) async {
    try {
      final response = await _supabase
          .from('users')
          .select()
          .eq('id', uid)
          .single();
      
      _coastalUser = CoastalUser.fromMap(response);
    } catch (e) {
      print('Error loading user profile: $e');
      _coastalUser = null;
    }
  }

  /// Register a new user with email, password, and role
  Future<String?> register({
    required String email,
    required String password,
    required UserRole role,
  }) async {
    try {
      // Create Supabase Auth user with role in metadata
      // The database trigger will create the profile automatically
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'role': role == UserRole.installer ? 'installer' : 'homeowner',
        },
      );

      if (response.user == null) {
        return 'Registration failed';
      }

      _supabaseUser = response.user;
      
      // Wait a moment for the trigger to create the profile
      await Future.delayed(const Duration(milliseconds: 500));
      await _loadUserProfile(response.user!.id);
      notifyListeners();
      
      return null; // Success
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  /// Sign in with email and password
  Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      if (response.user != null) {
        _supabaseUser = response.user;
        await _loadUserProfile(response.user!.id);
        notifyListeners();
      }
      
      return null; // Success
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  /// Sign out
  Future<void> signOut() async {
    await _supabase.auth.signOut();
    _supabaseUser = null;
    _coastalUser = null;
    notifyListeners();
  }

  /// Reset password
  Future<String?> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }
}
