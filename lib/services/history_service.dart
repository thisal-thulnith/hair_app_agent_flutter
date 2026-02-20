import 'dart:convert';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:http/http.dart' as http;
import '../models/consultation.dart';
import 'auth_service.dart';

class HistoryService {
  // Backend URL for Beauty AI API on localhost:8000
  static String get _baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8000';
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000';
    }
    return 'http://localhost:8000';
  }

  final AuthService _authService = AuthService();

  /// Fetch user's consultation history
  /// Returns a list of past consultations
  /// Throws exception on failure or if authentication expires
  Future<List<Consultation>> getConsultationHistory({
    int skip = 0,
    int limit = 20,
  }) async {
    try {
      // Get authentication token
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('Authentication expired');
      }

      // Make request
      final response = await http.get(
        Uri.parse('$_baseUrl/api/user/consultation-history?skip=$skip&limit=$limit'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Consultation.fromJson(json)).toList();
      } else if (response.statusCode == 401) {
        throw Exception('Authentication expired');
      } else {
        throw Exception('Failed to load history: ${response.statusCode}');
      }
    } catch (e) {
      if (e.toString().contains('Authentication expired')) {
        rethrow;
      }
      throw Exception('Network error. Please check your connection.');
    }
  }
}
