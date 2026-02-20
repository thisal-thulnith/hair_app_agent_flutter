import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

class BeautyAuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  UserModel? _user;
  bool _isLoading = false;
  bool _isAuthenticated = false;
  String? _error;

  // Getters
  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  String? get error => _error;

  /// Initialize auth state
  Future<void> initialize() async {
    _setLoading(true);
    try {
      final hasToken = await _apiService.hasToken();
      if (hasToken) {
        _isAuthenticated = true;
      }
    } catch (e) {
      _error = 'Initialization failed: $e';
    } finally {
      _setLoading(false);
    }
  }

  /// Sign in with Google
  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    _error = null;

    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        _setLoading(false);
        return false;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await _firebaseAuth.signInWithCredential(credential);
      final String? idToken = googleAuth.idToken;

      if (idToken == null) {
        throw Exception('Failed to get Google ID token');
      }

      try {
        final response = await _apiService.authenticateWithGoogle(idToken: idToken);
        await _apiService.saveToken(response['access_token']);
        _user = UserModel.fromJson(response['user']);
        _isAuthenticated = true;
        _setLoading(false);
        return true;
      } on NewUserException catch (e) {
        _setLoading(false);
        throw e;
      }
    } catch (e) {
      _error = 'Sign in failed: $e';
      _setLoading(false);
      rethrow;
    }
  }

  /// Complete registration for new user
  Future<bool> completeRegistration({
    required String idToken,
    required String userType,
  }) async {
    _setLoading(true);
    _error = null;

    try {
      final response = await _apiService.authenticateWithGoogle(
        idToken: idToken,
        userType: userType,
      );

      await _apiService.saveToken(response['access_token']);
      _user = UserModel.fromJson(response['user']);
      _isAuthenticated = true;
      _setLoading(false);
      return true;
    } catch (e) {
      _error = 'Registration failed: $e';
      _setLoading(false);
      return false;
    }
  }

  /// Register with email and password
  Future<bool> registerWithEmail({
    required String email,
    required String password,
    required String name,
    required String userType,
  }) async {
    _setLoading(true);
    _error = null;

    try {
      final response = await _apiService.registerWithEmail(
        email: email,
        password: password,
        name: name,
        userType: userType,
      );

      await _apiService.saveToken(response['access_token']);
      _user = UserModel.fromJson(response['user']);
      _isAuthenticated = true;
      _setLoading(false);
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _setLoading(false);
      return false;
    }
  }

  /// Login with email and password
  Future<bool> loginWithEmail({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _error = null;

    try {
      final response = await _apiService.loginWithEmail(
        email: email,
        password: password,
      );

      await _apiService.saveToken(response['access_token']);
      _user = UserModel.fromJson(response['user']);
      _isAuthenticated = true;
      _setLoading(false);
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _setLoading(false);
      return false;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    _setLoading(true);

    try {
      await Future.wait([
        _googleSignIn.signOut(),
        _firebaseAuth.signOut(),
        _apiService.clearToken(),
      ]);

      _user = null;
      _isAuthenticated = false;
      _error = null;
    } catch (e) {
      _error = 'Sign out failed: $e';
    } finally {
      _setLoading(false);
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
