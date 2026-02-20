import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';
import '../services/api_service.dart';
import '../services/image_service.dart';

class BeautyChatProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  final ImageService _imageService = ImageService();

  List<ConversationModel> _conversations = [];
  List<MessageModel> _messages = [];
  ConversationModel? _currentConversation;
  bool _isLoading = false;
  bool _isSending = false;
  String? _error;

  // Getters
  List<ConversationModel> get conversations => _conversations;
  List<MessageModel> get messages => _messages;
  ConversationModel? get currentConversation => _currentConversation;
  bool get isLoading => _isLoading;
  bool get isSending => _isSending;
  String? get error => _error;

  /// Load all conversations
  Future<void> loadConversations() async {
    _setLoading(true);
    _error = null;

    try {
      _conversations = await _apiService.getConversations();
    } catch (e) {
      _error = 'Failed to load conversations: $e';
    } finally {
      _setLoading(false);
    }
  }

  /// Load messages for a conversation
  Future<void> loadMessages(int conversationId) async {
    _setLoading(true);
    _error = null;

    try {
      _messages = await _apiService.getMessages(conversationId);

      // Find and set current conversation
      _currentConversation = _conversations.firstWhere(
        (conv) => conv.id == conversationId,
        orElse: () => throw Exception('Conversation not found'),
      );
    } catch (e) {
      _error = 'Failed to load messages: $e';
    } finally {
      _setLoading(false);
    }
  }

  /// Create a new conversation
  Future<ConversationModel?> createConversation({required String title}) async {
    _setLoading(true);
    _error = null;

    try {
      final conversation = await _apiService.createConversation(title: title);
      _conversations.insert(0, conversation);
      _currentConversation = conversation;
      _messages = [];
      _setLoading(false);
      return conversation;
    } catch (e) {
      _error = 'Failed to create conversation: $e';
      _setLoading(false);
      return null;
    }
  }

  /// Delete a conversation
  Future<bool> deleteConversation(int conversationId) async {
    try {
      await _apiService.deleteConversation(conversationId);
      _conversations.removeWhere((conv) => conv.id == conversationId);

      if (_currentConversation?.id == conversationId) {
        _currentConversation = null;
        _messages = [];
      }

      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to delete conversation: $e';
      return false;
    }
  }

  /// Send a message
  Future<bool> sendMessage({
    required String text,
    Uint8List? imageBytes,
  }) async {
    if (_currentConversation == null) {
      // Create new conversation if none exists
      final firstWords = text.split(' ').take(5).join(' ');
      final conversation = await createConversation(
        title: firstWords.length > 40 ? '${firstWords.substring(0, 37)}...' : firstWords,
      );

      if (conversation == null) return false;
    }

    _isSending = true;
    _error = null;
    notifyListeners();

    try {
      // 1. Add user message to UI immediately (optimistic update)
      final userMessage = MessageModel(
        id: DateTime.now().millisecondsSinceEpoch, // Temporary ID
        role: 'user',
        content: text,
        imageUrl: imageBytes != null ? 'local' : null,
        createdAt: DateTime.now(),
      );
      _messages.add(userMessage);
      notifyListeners();

      // 2. Save user message to backend
      final savedUserMessage = await _apiService.saveMessage(
        conversationId: _currentConversation!.id,
        role: 'user',
        content: text,
        imageUrl: imageBytes != null ? 'uploaded' : null, // TODO: Upload image to storage
      );

      // Replace temporary message with saved one
      final index = _messages.indexWhere((m) => m.id == userMessage.id);
      if (index != -1) {
        _messages[index] = savedUserMessage;
      }

      // 3. Get AI response
      String? imageBase64;
      if (imageBytes != null) {
        imageBase64 = _imageService.toBase64(imageBytes);
      }

      final aiResponse = await _apiService.sendToAI(
        message: text,
        imageBase64: imageBase64,
      );

      // 4. Add AI message to UI
      final aiMessage = MessageModel(
        id: DateTime.now().millisecondsSinceEpoch + 1,
        role: 'assistant',
        content: aiResponse['response'] ?? 'No response from AI',
        createdAt: DateTime.now(),
      );
      _messages.add(aiMessage);
      notifyListeners();

      // 5. Save AI message to backend
      final savedAiMessage = await _apiService.saveMessage(
        conversationId: _currentConversation!.id,
        role: 'assistant',
        content: aiMessage.content,
      );

      // Replace temporary AI message
      final aiIndex = _messages.indexWhere((m) => m.id == aiMessage.id);
      if (aiIndex != -1) {
        _messages[aiIndex] = savedAiMessage;
      }

      _isSending = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to send message: $e';
      _isSending = false;
      notifyListeners();
      return false;
    }
  }

  /// Clear current conversation
  void clearCurrentConversation() {
    _currentConversation = null;
    _messages = [];
    notifyListeners();
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Set loading state
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
