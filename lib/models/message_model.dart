class MessageModel {
  final int id;
  final String role; // 'user' or 'assistant'
  final String content;
  final String? imageUrl;
  final DateTime createdAt;

  MessageModel({
    required this.id,
    required this.role,
    required this.content,
    this.imageUrl,
    required this.createdAt,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] as int,
      role: json['role'] as String,
      content: json['content'] as String,
      imageUrl: json['imageUrl'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role': role,
      'content': content,
      if (imageUrl != null) 'imageUrl': imageUrl,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  bool get isUser => role == 'user';
  bool get isAssistant => role == 'assistant';
  bool get hasImage => imageUrl != null && imageUrl!.isNotEmpty;

  MessageModel copyWith({
    int? id,
    String? role,
    String? content,
    String? imageUrl,
    DateTime? createdAt,
  }) {
    return MessageModel(
      id: id ?? this.id,
      role: role ?? this.role,
      content: content ?? this.content,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
