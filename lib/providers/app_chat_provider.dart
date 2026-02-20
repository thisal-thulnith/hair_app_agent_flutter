import 'dart:typed_data';
import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import '../models/conversation.dart';
import '../models/message.dart';
import '../services/firestore_service.dart';
import '../services/ai_service.dart';
import '../services/storage_service.dart';

class AppChatProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final AIService _aiService = AIService();
  final StorageService _storageService = StorageService();

  List<Conversation> _conversations = [];
  List<Message> _messages = [];
  Conversation? _currentConversation;
  bool _isLoading = false;
  bool _isSending = false;
  String? _error;
  bool _backendHealthy = true;
  bool _cancelRequested = false;
  StreamSubscription<List<Conversation>>? _conversationsSubscription;
  StreamSubscription<List<Message>>? _messagesSubscription;

  List<Conversation> get conversations => _conversations;
  List<Message> get messages => _messages;
  Conversation? get currentConversation => _currentConversation;
  bool get isLoading => _isLoading;
  bool get isSending => _isSending;
  String? get error => _error;
  bool get backendHealthy => _backendHealthy;

  /// Cancel current generation
  void Function()? get cancelGeneration => _isSending ? _cancelCurrentGeneration : null;

  void _cancelCurrentGeneration() {
    _cancelRequested = true;
    _isSending = false;
    notifyListeners();
  }

  /// Initialize provider and check backend health
  Future<void> initialize() async {
    _backendHealthy = await _aiService.healthCheck();
    if (!_backendHealthy) {
      _error =
          'Warning: AI backend is not reachable. Please start the backend server.';
    }
    notifyListeners();
  }

  void loadConversations(String userId) {
    _conversationsSubscription?.cancel();
    _conversationsSubscription =
        _firestoreService.getConversationsStream(userId).listen(
      (conversations) {
        _conversations = conversations;
        notifyListeners();
      },
      onError: (error) {
        _error = 'Failed to load conversations: $error';
        notifyListeners();
      },
    );
  }

  void loadMessages(String conversationId) {
    _messagesSubscription?.cancel();
    _messagesSubscription =
        _firestoreService.getMessagesStream(conversationId).listen(
      (messages) {
        _messages = messages;
        notifyListeners();
      },
      onError: (error) {
        _error = 'Failed to load messages: $error';
        notifyListeners();
      },
    );
  }

  Future<void> setCurrentConversation(Conversation conversation) async {
    _currentConversation = conversation;
    loadMessages(conversation.id);
    notifyListeners();
  }

  void clearCurrentConversation() {
    _currentConversation = null;
    _messages = [];
    notifyListeners();
  }

  Future<void> sendMessage({
    required String userId,
    required String text,
    Uint8List? imageBytes,
  }) async {
    _isSending = true;
    _error = null;
    _cancelRequested = false;
    notifyListeners();

    try {
      String? imageUrl;
      String? userImageBase64;
      if (imageBytes != null) {
        // ALWAYS store base64 as primary fallback (more reliable than URLs)
        if (imageBytes.length <= 800 * 1024) {
          userImageBase64 = base64Encode(imageBytes);
          print('✅ Encoded user image to base64 (${userImageBase64!.length ~/ 1024} KB)');
        }

        // Also try to upload to Firebase Storage for URL access
        try {
          imageUrl = await _storageService.uploadChatImage(imageBytes);
          print('✅ Uploaded user image to Firebase Storage: $imageUrl');
        } catch (e) {
          print('⚠️  Firebase Storage upload failed: $e');
          // Continue without URL - base64 will be used
          imageUrl = null;
        }
      }

      String conversationId;
      if (_currentConversation == null) {
        final title = text.length > 40 ? '${text.substring(0, 37)}...' : text;
        conversationId = await _firestoreService.createConversation(
          userId: userId,
          title: title,
        );

        final conversations =
            await _firestoreService.getConversationsStream(userId).first;
        _currentConversation =
            conversations.firstWhere((c) => c.id == conversationId);
        loadMessages(conversationId);
      } else {
        conversationId = _currentConversation!.id;
      }

      // Step 3: Store user message in Firestore
      final userMessage = Message.user(
        content: text,
        imageUrl: imageUrl,
        userImageBase64: userImageBase64,
      );
      await _firestoreService.addMessage(
        conversationId: conversationId,
        message: userMessage,
      );

      // Step 4: Call Beauty AI backend for response
      final aiResponse = await _aiService.sendMessage(
        message: text,
        sessionId:
            conversationId, // Use Firestore conversation ID as session ID
        userId: userId,
        imageUrl: imageUrl,
        imageBytes: imageBytes,
      );

      // Check if generation was cancelled
      if (_cancelRequested) {
        _isSending = false;
        _cancelRequested = false;
        notifyListeners();
        return;
      }

      // DEBUG: Log what we received from backend
      print('📥 Backend Response Received:');
      print('  - Response text: ${aiResponse.response.substring(0, aiResponse.response.length > 50 ? 50 : aiResponse.response.length)}...');
      print('  - Has generated image: ${aiResponse.generatedImage != null}');
      if (aiResponse.generatedImage != null) {
        final sizeKB = aiResponse.generatedImage!.length / 1024;
        print('  - Generated image size: ${sizeKB.toStringAsFixed(2)} KB');
      }

      String? generatedImageUrl;
      String? generatedImageBase64;
      if (aiResponse.generatedImage != null &&
          aiResponse.generatedImage!.isNotEmpty) {
        final generatedBytes = _decodeBase64Safely(aiResponse.generatedImage!);
        if (generatedBytes != null) {
          print('  - Decoded image bytes: ${generatedBytes.length}');
          try {
            generatedImageUrl =
                await _storageService.uploadChatImage(generatedBytes);
            print('✅ Generated image uploaded to Firebase Storage: $generatedImageUrl');
          } catch (uploadError) {
            print('⚠️  Firebase Storage upload failed: $uploadError');
            // Fallback below if upload unavailable.
          }
        }

        // Avoid Firestore oversized documents from very large base64 payloads.
        final sizeKB = aiResponse.generatedImage!.length / 1024;
        if (generatedImageUrl == null) {
          if (sizeKB <= 350) {
            generatedImageBase64 = aiResponse.generatedImage;
            print('✅ Storing base64 in Firestore (${sizeKB.toStringAsFixed(2)} KB)');
          } else {
            print('❌ Image too large for Firestore (${sizeKB.toStringAsFixed(2)} KB > 350 KB)');
            print('   AND Firebase Storage upload failed!');
            print('   Generated image will NOT be saved to history.');
          }
        }
      }

      // Step 5: Create assistant message with AI response
      final assistantMessage = Message.assistant(
        content: aiResponse.response,
        generatedImageUrl: generatedImageUrl,
        generatedImageBase64: generatedImageBase64,
        metadata: {
          if (aiResponse.orchestratorReasoning != null)
            'orchestrator_reasoning': aiResponse.orchestratorReasoning,
          if (aiResponse.agentsUsed != null)
            'agents_used': aiResponse.agentsUsed,
        },
      );

      // DEBUG: Log what we're saving to Firestore
      print('💾 Saving assistant message to Firestore:');
      print('  - Content: ${assistantMessage.content.substring(0, assistantMessage.content.length > 50 ? 50 : assistantMessage.content.length)}...');
      print('  - Has generatedImageUrl: ${assistantMessage.generatedImageUrl != null}');
      print('  - Has generatedImageBase64: ${assistantMessage.generatedImageBase64 != null}');

      // Step 6: Store assistant message in Firestore
      await _firestoreService.addMessage(
        conversationId: conversationId,
        message: assistantMessage,
      );
      print('✅ Message saved to Firestore successfully');

      _isSending = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to send message: $e';
      _isSending = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteConversation(String conversationId) async {
    try {
      await _firestoreService.deleteConversation(conversationId);
      if (_currentConversation?.id == conversationId) {
        clearCurrentConversation();
      }
    } catch (e) {
      _error = 'Failed to delete conversation: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<Uint8List?> pickImageFromGallery() async {
    try {
      return await _storageService.pickImageFromGallery();
    } catch (e) {
      _error = 'Failed to pick image: $e';
      notifyListeners();
      return null;
    }
  }

  Future<Uint8List?> pickImageFromCamera() async {
    try {
      return await _storageService.pickImageFromCamera();
    } catch (e) {
      _error = 'Failed to take picture: $e';
      notifyListeners();
      return null;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Uint8List? _decodeBase64Safely(String base64String) {
    try {
      final normalized =
          base64String.replaceFirst(RegExp(r'data:image/[^;]+;base64,'), '');
      return base64Decode(normalized);
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _conversationsSubscription?.cancel();
    _messagesSubscription?.cancel();
    super.dispose();
  }
}
