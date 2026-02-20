import 'dart:convert';
import 'package:http/http.dart' as http;

class SalonService {
  // Backend URL for Beauty AI API via ngrok
  static const String _baseUrl = 'https://4ee5-222-165-182-230.ngrok-free.app';

  /// Get list of available salons
  /// Returns paginated list of salons for booking
  Future<List<Map<String, dynamic>>> getSalons({
    int skip = 0,
    int limit = 20,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/salons?skip=$skip&limit=$limit'),
        headers: {
          'ngrok-skip-browser-warning': 'true',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Backend returns a dict with salons list
        if (data is Map && data.containsKey('salons')) {
          return List<Map<String, dynamic>>.from(data['salons']);
        } else if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        }
        return [];
      } else {
        throw Exception('Failed to load salons: ${response.statusCode}');
      }
    } catch (e) {
      print('Failed to get salons: $e');
      throw Exception('Network error. Please check your connection.');
    }
  }

  /// Register a new salon (for salon owners/admins)
  Future<Map<String, dynamic>> registerSalon({
    required String salonName,
    required String adminEmail,
    required String adminPassword,
    required String adminFullName,
    required String salonAddress,
    required String salonCity,
    required String salonCountry,
    String? salonState,
    String? salonPhone,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/auth/register-salon'),
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
        body: jsonEncode({
          'salon_name': salonName,
          'admin_email': adminEmail,
          'admin_password': adminPassword,
          'admin_full_name': adminFullName,
          'salon_address': salonAddress,
          'salon_city': salonCity,
          'salon_country': salonCountry,
          if (salonState != null) 'salon_state': salonState,
          if (salonPhone != null) 'salon_phone': salonPhone,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['detail'] ?? 'Failed to register salon');
      }
    } catch (e) {
      if (e.toString().contains('Failed to register salon')) {
        rethrow;
      }
      print('Failed to register salon: $e');
      throw Exception('Network error. Please check your connection.');
    }
  }
}
