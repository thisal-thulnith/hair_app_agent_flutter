import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class HairStyleService {
  // Backend URL for Beauty AI API via ngrok
  static const String _baseUrl = 'https://4ee5-222-165-182-230.ngrok-free.app';

  /// Get available hair style options (male/female styles and colors)
  Future<Map<String, dynamic>> getHairStyleOptions() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/hair-style/options'),
        headers: {
          'ngrok-skip-browser-warning': 'true',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Failed to load hair style options: ${response.statusCode}');
      }
    } catch (e) {
      print('Failed to get hair style options: $e');
      throw Exception('Network error. Please check your connection.');
    }
  }

  /// Get AI-powered hair style suggestions based on uploaded photo
  /// Analyzes face shape and recommends suitable styles
  Future<Map<String, dynamic>> getHairStyleSuggestions({
    required Uint8List imageBytes,
    String? imageName,
    String? sessionId,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/hair-style/suggestions'),
      );

      // Add ngrok header
      request.headers['ngrok-skip-browser-warning'] = 'true';

      // Add image file
      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          imageBytes,
          filename: imageName ?? 'photo.jpg',
        ),
      );

      // Add session ID if provided
      if (sessionId != null) {
        request.fields['session_id'] = sessionId;
      }

      print('Requesting hair style suggestions...');

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 60),
      );
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        print('Hair style suggestions received');
        return data;
      } else {
        print('Server error: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to get suggestions: ${response.statusCode}');
      }
    } catch (e) {
      print('Failed to get hair style suggestions: $e');
      throw Exception('Network error. Please check your connection.');
    }
  }

  /// Generate hair style visualization
  /// Applies selected style and color to uploaded photo
  Future<Map<String, dynamic>> generateHairStyle({
    required Uint8List imageBytes,
    required String gender,
    required String sessionId,
    String? imageName,
    String? style,
    String? color,
    String? customDescription,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/hair-style/generate'),
      );

      // Add ngrok header
      request.headers['ngrok-skip-browser-warning'] = 'true';

      // Add image file
      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          imageBytes,
          filename: imageName ?? 'photo.jpg',
        ),
      );

      // Add form fields
      request.fields['gender'] = gender;
      request.fields['session_id'] = sessionId;

      if (style != null && style.isNotEmpty) {
        request.fields['style'] = style;
      }

      if (color != null && color.isNotEmpty) {
        request.fields['color'] = color;
      }

      if (customDescription != null && customDescription.isNotEmpty) {
        request.fields['custom_description'] = customDescription;
      }

      print('Generating hair style...');
      print('Gender: $gender, Style: $style, Color: $color');

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 90),
      );
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        print('Hair style generated successfully');
        return data;
      } else {
        print('Server error: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to generate style: ${response.statusCode}');
      }
    } catch (e) {
      print('Failed to generate hair style: $e');
      throw Exception('Network error. Please check your connection.');
    }
  }
}
