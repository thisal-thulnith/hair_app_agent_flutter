import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/environment.dart';
import '../models/user_model.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  late Dio _dio;
  final _storage = const FlutterSecureStorage();

  static const String _tokenKey = 'jwt_token';

  void initialize() {
    _dio = Dio(BaseOptions(
      baseUrl: Environment.nestBackendUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // Add JWT interceptor (optional - works without authentication)
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await getToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) {
        // Pass through errors without blocking
        return handler.next(error);
      },
    ));
  }

  // =====================
  // Token Management
  // =====================

  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  Future<void> clearToken() async {
    await _storage.delete(key: _tokenKey);
  }

  Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // =====================
  // Authentication APIs
  // =====================

  /// Authenticate with Google ID token
  /// Returns user data and JWT token on success
  /// Throws DioException with NEW_USER message if user needs to register
  Future<Map<String, dynamic>> authenticateWithGoogle({
    required String idToken,
    String? userType,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/google',
        data: {
          'idToken': idToken,
          if (userType != null) 'userType': userType,
        },
      );

      return response.data;
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        final data = e.response?.data;
        if (data is Map && data['message'] == 'NEW_USER') {
          // New user - return google data for registration
          throw NewUserException(
            googleData: data['googleData'],
            idToken: idToken,
          );
        }
      }
      rethrow;
    }
  }

  /// Register with email and password
  Future<Map<String, dynamic>> registerWithEmail({
    required String email,
    required String password,
    required String name,
    required String userType, // 'customer' or 'salon_owner'
  }) async {
    try {
      final response = await _dio.post(
        '/auth/register',
        data: {
          'email': email,
          'password': password,
          'name': name,
          'userType': userType,
        },
      );

      return response.data;
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        throw Exception(e.response?.data['message'] ?? 'Registration failed');
      }
      throw Exception('Registration failed: ${e.message}');
    }
  }

  /// Login with email and password
  Future<Map<String, dynamic>> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: {
          'email': email,
          'password': password,
        },
      );

      return response.data;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Invalid email or password');
      }
      if (e.response?.statusCode == 404) {
        throw Exception('User not found');
      }
      throw Exception('Login failed: ${e.message}');
    }
  }

  /// Get current user profile
  Future<UserModel> getCurrentUser() async {
    try {
      final response = await _dio.get('/auth/profile');
      return UserModel.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Not authenticated');
      }
      throw Exception('Failed to get user profile: ${e.message}');
    }
  }

  // =====================
  // Conversation APIs
  // =====================

  /// Get all conversations for current user
  Future<List<ConversationModel>> getConversations() async {
    try {
      final response = await _dio.get('/conversations');
      final List<dynamic> data = response.data;
      return data.map((json) => ConversationModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to load conversations: $e');
    }
  }

  /// Get a single conversation with its messages
  Future<Map<String, dynamic>> getConversation(int conversationId) async {
    try {
      final response = await _dio.get('/conversations/$conversationId');
      return response.data;
    } catch (e) {
      throw Exception('Failed to load conversation: $e');
    }
  }

  /// Create a new conversation
  Future<ConversationModel> createConversation({required String title}) async {
    try {
      final response = await _dio.post(
        '/conversations',
        data: {'title': title},
      );
      return ConversationModel.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to create conversation: $e');
    }
  }

  /// Delete a conversation
  Future<void> deleteConversation(int conversationId) async {
    try {
      await _dio.delete('/conversations/$conversationId');
    } catch (e) {
      throw Exception('Failed to delete conversation: $e');
    }
  }

  // =====================
  // Message APIs
  // =====================

  /// Get messages for a conversation
  Future<List<MessageModel>> getMessages(int conversationId) async {
    try {
      final response = await _dio.get('/conversations/$conversationId/messages');
      final List<dynamic> data = response.data;
      return data.map((json) => MessageModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to load messages: $e');
    }
  }

  /// Save a message to a conversation
  Future<MessageModel> saveMessage({
    required int conversationId,
    required String role,
    required String content,
    String? imageUrl,
  }) async {
    try {
      final response = await _dio.post(
        '/conversations/$conversationId/messages',
        data: {
          'role': role,
          'content': content,
          if (imageUrl != null) 'imageUrl': imageUrl,
        },
      );
      return MessageModel.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to save message: $e');
    }
  }

  // =====================
  // AI Chat API
  // =====================

  /// Send message to AI backend
  Future<Map<String, dynamic>> sendToAI({
    required String message,
    String? imageBase64,
  }) async {
    try {
      // Create separate Dio instance for AI backend
      final aiDio = Dio(BaseOptions(
        baseUrl: Environment.aiChatEndpoint,
        connectTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 60),
      ));

      final response = await aiDio.post(
        '',
        data: {
          'message': message,
          if (imageBase64 != null) 'image': imageBase64,
        },
      );

      return response.data;
    } catch (e) {
      throw Exception('Failed to get AI response: $e');
    }
  }
}

/// Custom exception for new user registration
class NewUserException implements Exception {
  final Map<String, dynamic> googleData;
  final String idToken;

  NewUserException({
    required this.googleData,
    required this.idToken,
  });

  @override
  String toString() => 'NewUserException: User needs to complete registration';
}
