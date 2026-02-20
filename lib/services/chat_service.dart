import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class ChatService {
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

      print('Sending message to backend...');
      print('Session ID: $sessionId');

      http.Response response;

      // Use JSON endpoint for text-only, multipart for images
      if (imageBytes == null) {
        // Text-only message - use /chat endpoint with JSON
        response = await http
            .post(
              Uri.parse('$_baseUrl/chat'),
              headers: {
                'Content-Type': 'application/json',
                if (token != null) 'Authorization': 'Bearer $token',
              },
              body: jsonEncode({
                'message': message,
                'session_id': sessionId,
              }),
            )
            .timeout(const Duration(seconds: 60));
      } else {
        // Image upload - use /chat/upload endpoint with multipart
        print(
            'Sending image: ${imageName ?? 'upload.jpg'} (${imageBytes.length} bytes)');

        var request = http.MultipartRequest(
          'POST',
          Uri.parse('$_baseUrl/chat/upload'),
        );

        // Add authorization header if token exists
        if (token != null) {
          request.headers['Authorization'] = 'Bearer $token';
        }

        // Add form fields
        request.fields['message'] = message;
        request.fields['session_id'] = sessionId;

        // Add image file
        request.files.add(
          http.MultipartFile.fromBytes(
            'image',
            imageBytes,
            filename: imageName ?? 'upload.jpg',
          ),
        );

        // Send request
        final streamedResponse = await request.send().timeout(
              const Duration(seconds: 60),
            );
        response = await http.Response.fromStream(streamedResponse);
      }

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
        // Try to parse error detail from response
        try {
          final errorData = jsonDecode(response.body);
          final detail =
              errorData['detail'] ?? 'Server error: ${response.statusCode}';
          throw Exception(detail);
        } catch (_) {
          throw Exception('Server error: ${response.statusCode}');
        }
      }
    } catch (e) {
      if (e.toString().contains('Authentication expired')) {
        rethrow;
      }
      print('Failed to send message: $e');
      throw Exception('Failed to send message: $e');
    }
  }
}
