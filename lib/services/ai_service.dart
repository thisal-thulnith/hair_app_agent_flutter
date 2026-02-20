import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:typed_data';
import '../config/environment.dart';

/// Response model for AI chat endpoint
class AIResponse {
  final String response;
  final String? generatedImage; // Base64 encoded image
  final String? orchestratorReasoning;
  final List<String>? agentsUsed;
  final String sessionId;
  final String? error;

  AIResponse({
    required this.response,
    this.generatedImage,
    this.orchestratorReasoning,
    this.agentsUsed,
    required this.sessionId,
    this.error,
  });

  factory AIResponse.fromJson(Map<String, dynamic> json) {
    return AIResponse(
      response: json['response'] ?? '',
      generatedImage: json['generated_image'],
      orchestratorReasoning: json['orchestrator_reasoning'],
      agentsUsed: json['agents_used'] != null
          ? List<String>.from(json['agents_used'])
          : null,
      sessionId: json['session_id'] ?? '',
      error: json['error'],
    );
  }
}

class AIService {
  late final Dio _dio;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  AIService() {
    _dio = Dio(BaseOptions(
      baseUrl: Environment.aiBackendUrl,
      connectTimeout: Environment.connectionTimeout,
      receiveTimeout: Environment.receiveTimeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // Add interceptor for logging (debug only)
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      logPrint: (obj) => print('🌐 $obj'),
    ));
  }

  /// Send message to Beauty AI backend with optional Firebase authentication
  Future<AIResponse> sendMessage({
    required String message,
    required String sessionId,
    String? userId,
    String? imageUrl,
    Uint8List? imageBytes,
    String? imageName,
  }) async {
    try {
      // Get Firebase ID token for optional authentication
      String? idToken;
      try {
        final currentUser = _auth.currentUser;
        if (currentUser != null) {
          idToken = await currentUser.getIdToken();
        }
      } catch (e) {
        print('⚠️  Failed to get Firebase ID token: $e');
        // Continue without token - backend will work without auth
      }

      // Prepare headers with optional Firebase token
      final headers = <String, String>{};
      if (idToken != null) {
        headers['Authorization'] = 'Bearer $idToken';
      }

      Response response;
      if (imageBytes != null) {
        final formData = FormData.fromMap({
          'message': message,
          'session_id': sessionId,
          if (userId != null) 'user_id': userId,
          'image': MultipartFile.fromBytes(
            imageBytes,
            filename: imageName ?? 'upload.jpg',
          ),
        });
        response = await _dio.post(
          '/chat/upload',
          data: formData,
          options: Options(headers: headers),
        );
      } else {
        response = await _dio.post(
          '/chat',
          data: {
            'message': message,
            'session_id': sessionId,
            if (userId != null) 'user_id': userId,
            if (imageUrl != null) 'image_url': imageUrl,
          },
          options: Options(headers: headers),
        );
      }

      if (response.statusCode == 200) {
        return AIResponse.fromJson(response.data);
      } else {
        throw Exception('AI service returned status ${response.statusCode}');
      }
    } on DioException catch (e) {
      // Handle different types of errors
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw Exception(
          'Request timeout. The AI is taking longer than expected. Please try again.',
        );
      } else if (e.type == DioExceptionType.connectionError) {
        throw Exception(
          'Cannot connect to AI service. Please check:\n'
          '1. Backend is running at ${Environment.aiBackendUrl}\n'
          '2. Your device can reach the backend\n'
          '3. Firewall is not blocking connection',
        );
      } else if (e.response != null) {
        // Server returned an error response
        final errorMessage = e.response?.data?['detail'] ?? e.message;
        throw Exception('AI service error: $errorMessage');
      } else {
        throw Exception('Unexpected error: ${e.message}');
      }
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  /// Health check to verify backend connectivity
  Future<bool> healthCheck() async {
    try {
      final response = await _dio.get(
        '/health',
        options: Options(
          receiveTimeout: const Duration(seconds: 5),
        ),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('❌ Health check failed: $e');
      return false;
    }
  }
}
