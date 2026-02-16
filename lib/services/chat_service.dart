import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class ChatService {
  // Backend URL for Beauty AI API via ngrok
  // This works on all platforms (Web, Android, iOS)
  static const String _baseUrl = 'https://4ee5-222-165-182-230.ngrok-free.app';

  final AuthService _authService = AuthService();

  /// Sends a chat message (text + optional image) to the backend.
  /// Requires authentication token and session ID for conversation context.
  /// Returns a Map with 'response', 'generated_image', and 'session_id'.
  Future<Map<String, dynamic>> sendMessage({
    required String message,
    required String sessionId,
    Uint8List? imageBytes,
    String? imageName,
  }) async {
    try {
      // Get authentication token (optional for now)
      final token = await _authService.getToken();

      // Create multipart request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/chat/upload'),
      );

      // Add authorization header if token exists
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      // Required for ngrok free URLs to bypass browser warning
      request.headers['ngrok-skip-browser-warning'] = 'true';

      // Add form fields
      request.fields['message'] = message;
      request.fields['session_id'] = sessionId;

      // Add image file if present
      if (imageBytes != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'image',
            imageBytes,
            filename: imageName ?? 'upload.jpg',
          ),
        );
        print('Sending image: ${imageName ?? 'upload.jpg'} (${imageBytes.length} bytes)');
      }

      print('Sending message to backend...');
      print('Session ID: $sessionId');

      // Send request
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 60),
      );
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        print('Backend Response received');

        // Return normalized response
        return {
          'response': data['response'] ?? '',
          'image': data['generated_image'], // Hair styling results
          'session_id': data['session_id'] ?? sessionId,
        };
      } else if (response.statusCode == 401) {
        print('Authentication expired (401)');
        throw Exception('Authentication expired');
      } else {
        print('Server error: ${response.statusCode} - ${response.body}');
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      if (e.toString().contains('Authentication expired')) {
        rethrow;
      }
      print('Failed to send message: $e');
      throw Exception('Network error. Please check your connection.');
    }
  }
}
