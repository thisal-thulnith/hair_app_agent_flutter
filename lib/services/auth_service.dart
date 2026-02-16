import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

class AuthService {
  // Backend URL for Beauty AI API via ngrok
  // This works on all platforms (Web, Android, iOS)
  static const String _baseUrl = 'https://4ee5-222-165-182-230.ngrok-free.app';

  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';

  /// Login with email and password
  /// Returns a map with 'token' and 'user' keys on success
  /// Throws an exception on failure
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['access_token'] as String;
        final user = User.fromJson(data['user']);

        // Save token and user data
        await _saveToken(token);
        await _saveUser(user);

        return {
          'token': token,
          'user': user,
        };
      } else if (response.statusCode == 401) {
        throw Exception('Invalid email or password');
      } else {
        throw Exception('Login failed: ${response.statusCode}');
      }
    } catch (e) {
      if (e.toString().contains('Invalid email or password')) {
        rethrow;
      }
      throw Exception('Network error. Please check your connection.');
    }
  }

  /// Register a new customer
  /// Returns a map with 'token' and 'user' keys on success
  /// Throws an exception on failure
  Future<Map<String, dynamic>> register(
    String email,
    String password,
    String fullName,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/auth/register-customer'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'full_name': fullName,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final token = data['access_token'] as String;
        final user = User.fromJson(data['user']);

        // Save token and user data
        await _saveToken(token);
        await _saveUser(user);

        return {
          'token': token,
          'user': user,
        };
      } else if (response.statusCode == 400) {
        final data = jsonDecode(response.body);
        throw Exception(data['detail'] ?? 'Registration failed');
      } else {
        throw Exception('Registration failed: ${response.statusCode}');
      }
    } catch (e) {
      if (e.toString().contains('Registration failed') ||
          e.toString().contains('already exists')) {
        rethrow;
      }
      throw Exception('Network error. Please check your connection.');
    }
  }

  /// Get the stored authentication token
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  /// Get the currently logged in user
  Future<User?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);

    if (userJson == null) return null;

    try {
      final data = jsonDecode(userJson);
      return User.fromJson(data);
    } catch (e) {
      return null;
    }
  }

  /// Check if user is authenticated
  Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  /// Logout - clear all stored authentication data
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }

  /// Save authentication token to storage
  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  /// Save user data to storage
  Future<void> _saveUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
  }
}
