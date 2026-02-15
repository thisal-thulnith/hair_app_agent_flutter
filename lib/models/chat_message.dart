import 'dart:typed_data';

class ChatMessage {
  final String? text;
  final String? imageUrl;       // For network images (from agent response)
  final Uint8List? imageBytes;  // For local image uploads (user selected)
  final String? imageName;
  final bool isAgent;
  final DateTime timestamp;

  ChatMessage({
    this.text,
    this.imageUrl,
    this.imageBytes,
    this.imageName,
    required this.isAgent,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  bool get hasImage => imageUrl != null || imageBytes != null;
  bool get hasText => text != null && text!.isNotEmpty;
}
