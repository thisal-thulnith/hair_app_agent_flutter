import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/consultation.dart';
import 'auth_service.dart';

class HistoryService {
  // Backend URL for Beauty AI API via ngrok
  // This works on all platforms (Web, Android, iOS)
  static const String _baseUrl = 'https://4ee5-222-165-182-230.ngrok-free.app';

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
