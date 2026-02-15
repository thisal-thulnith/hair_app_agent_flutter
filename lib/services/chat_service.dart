import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class ChatService {
  // Change this to your backend URL
  // For Android emulator use 10.0.2.2 instead of localhost
  // For web, use localhost
  static const String _baseUrl = 'https://4ee5-222-165-182-230.ngrok-free.app';

  /// Sends a chat message (text + optional image) to the backend.
  /// Returns a Map with 'response' (String) and optionally 'image' (String URL).
  Future<Map<String, dynamic>> sendMessage({
    required String message,
    Uint8List? imageBytes,
    String? imageName,
  }) async {
    try {
      final Map<String, dynamic> body = {
        'message': message,
      };

      // If image is provided, encode as base64
      if (imageBytes != null) {
        final base64Image = base64Encode(imageBytes);
        final dataUri = 'data:image/jpeg;base64,$base64Image';
        
        // Try multiple formats to ensure backend recognition
        body['image'] = base64Image;
        body['image_data'] = base64Image;
        body['images'] = [base64Image]; // List format
        body['image_url'] = dataUri; // Data URI format
        
        body['file'] = base64Image;
        body['filename'] = imageName ?? 'upload.jpg';
      }

      print('Sending message to backend (JSON)...');
      print('Request keys: ${body.keys.toList()}');
      if (body.containsKey('image')) {
        print('Image payload size: ${(body['image'] as String).length} chars');
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/chat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        print('Backend Response: $data'); // Debug log
        
        // Normalize response for UI
        if (data.containsKey('generated_image') && data['generated_image'] != null) {
          data['image'] = data['generated_image'];
        }
        
        return data;
      } else {
        print('Server error: ${response.statusCode} - ${response.body}');
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      print('Failed to send message: $e');
      throw Exception('Failed to send message: $e');
    }
  }
}
