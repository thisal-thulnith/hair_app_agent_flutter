import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/app_user.dart';
import '../services/auth_service.dart';

class AppAuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  
  AppUser? _user;
  bool _isLoading = true;
  String? _error;

  AppUser? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  AppAuthProvider() {
    _init();
  }

  Future<void> _init() async {
    _isLoading = true;
    notifyListeners();

    _authService.authStateChanges.listen((User? firebaseUser) async {
      print('🔔 Auth state changed: ${firebaseUser?.email ?? "null"}');

      if (firebaseUser != null) {
        // Only fetch if _user is not already set with the correct uid
        if (_user == null || _user!.uid != firebaseUser.uid) {
          print('📥 Fetching user profile from Firestore...');
          final profile = await _authService.getUserProfile(firebaseUser.uid);

          if (profile != null) {
            _user = profile;
            print('✅ User profile loaded: ${profile.displayName}');
            print('✅ isAuthenticated: $isAuthenticated');
          } else {
            print('⚠️ No user profile found in Firestore (might be new user)');
          }

          _isLoading = false;
          notifyListeners();
        } else {
          print('✓ User already set, skipping fetch');
        }
      } else {
        print('👋 User signed out');
        _user = null;
        _isLoading = false;
        notifyListeners();
      }
    });
  }

  Future<void> signInWithGoogle() async {
    print('🚀 signInWithGoogle() called');
    _isLoading = true;
    _error = null;
    notifyListeners();
    print('   → Set isLoading=true, notified listeners');

    try {
      print('🔑 Calling AuthService.signInWithGoogle()...');
      final result = await _authService.signInWithGoogle();
      print('📦 Got result: ${result.keys}');

      // User profile is created automatically
      _user = result['user'] as AppUser;
      print('👤 Set _user: ${_user?.displayName} (${_user?.email})');

      _isLoading = false;
      print('   → Set isLoading=false');
      print('   → isAuthenticated=$isAuthenticated');
      print('   → About to call notifyListeners()...');

      notifyListeners();

      print('✅✅✅ SIGN-IN COMPLETE ✅✅✅');
      print('   User: ${_user?.displayName}');
      print('   Email: ${_user?.email}');
      print('   isAuthenticated: $isAuthenticated');
    } catch (e) {
      print('❌ Google sign-in error: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> completeRegistration({
    required User firebaseUser,
    required String userType,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('📝 Completing registration for: ${firebaseUser.email}');
      _user = await _authService.completeRegistration(
        firebaseUser: firebaseUser,
        userType: userType,
      );
      _isLoading = false;
      notifyListeners();
      print('✅ Registration completed: ${_user?.displayName}');
      print('✅ isAuthenticated: $isAuthenticated');
    } catch (e) {
      print('❌ Registration error: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.signOut();
      _user = null;
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // ============================================================================
  // EMAIL/PASSWORD AUTHENTICATION
  // ============================================================================

  Future<void> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('🔑 Starting email/password sign-in...');
      final result = await _authService.signInWithEmailPassword(
        email: email,
        password: password,
      );

      _user = result['user'] as AppUser;
      _isLoading = false;
      notifyListeners();
      print('✅ Email sign-in successful: ${_user?.displayName}');
      print('✅ isAuthenticated: $isAuthenticated');
    } catch (e) {
      print('❌ Email sign-in error: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> registerWithEmailPassword({
    required String email,
    required String password,
    required String displayName,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _authService.registerWithEmailPassword(
        email: email,
        password: password,
        displayName: displayName,
      );

      _user = result['user'] as AppUser;
      _isLoading = false;
      notifyListeners();
      print('✅ Registration successful: ${_user?.displayName}');
      print('✅ isAuthenticated: $isAuthenticated');
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.sendPasswordResetEmail(email);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }
}
