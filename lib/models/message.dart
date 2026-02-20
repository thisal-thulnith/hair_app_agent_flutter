import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String id;
  final String role; // 'user' or 'assistant'
  final String content;
  final String?
      imageUrl; // User-uploaded image URL/path (backend local uploads)
  final String? userImageBase64; // Fallback user image if URL upload fails
  final String? generatedImageUrl; // AI-generated image URL/path
  final String? generatedImageBase64; // AI-generated image (base64)
  final DateTime createdAt;
  final Map<String, dynamic>?
      metadata; // For orchestrator reasoning, agents used, etc.

  Message({
    required this.id,
    required this.role,
    required this.content,
    this.imageUrl,
    this.userImageBase64,
    this.generatedImageUrl,
    this.generatedImageBase64,
    required this.createdAt,
    this.metadata,
  });

  // Create from Firestore document
  factory Message.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Message(
      id: doc.id,
      role: data['role'] ?? 'user',
      content: data['content'] ?? '',
      imageUrl: data['imageUrl'],
      userImageBase64: data['userImageBase64'],
      generatedImageUrl: data['generatedImageUrl'],
      generatedImageBase64: data['generatedImageBase64'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      metadata: data['metadata'] as Map<String, dynamic>?,
    );
  }

  // Convert to map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'role': role,
      'content': content,
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (userImageBase64 != null) 'userImageBase64': userImageBase64,
      if (generatedImageUrl != null) 'generatedImageUrl': generatedImageUrl,
      if (generatedImageBase64 != null)
        'generatedImageBase64': generatedImageBase64,
      'createdAt': Timestamp.fromDate(createdAt),
      if (metadata != null) 'metadata': metadata,
    };
  }

  // Create user message
  factory Message.user({
    required String content,
    String? imageUrl,
    String? userImageBase64,
  }) {
    return Message(
      id: '', // Will be set by Firestore
      role: 'user',
      content: content,
      imageUrl: imageUrl,
      userImageBase64: userImageBase64,
      createdAt: DateTime.now(),
    );
  }

  // Create assistant message with optional generated image
  factory Message.assistant({
    required String content,
    String? generatedImageUrl,
    String? generatedImageBase64,
    Map<String, dynamic>? metadata,
  }) {
    return Message(
      id: '', // Will be set by Firestore
      role: 'assistant',
      content: content,
      generatedImageUrl: generatedImageUrl,
      generatedImageBase64: generatedImageBase64,
      createdAt: DateTime.now(),
      metadata: metadata,
    );
  }

  bool get isUser => role == 'user';
  bool get isAssistant => role == 'assistant';
  bool get hasGeneratedImage =>
      (generatedImageUrl != null && generatedImageUrl!.isNotEmpty) ||
      generatedImageBase64 != null && generatedImageBase64!.isNotEmpty;
  bool get hasUploadedImage =>
      (imageUrl != null && imageUrl!.isNotEmpty) ||
      (userImageBase64 != null && userImageBase64!.isNotEmpty);
}
