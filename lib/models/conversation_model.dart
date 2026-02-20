class ConversationModel {
  final int id;
  final String title;
  final DateTime updatedAt;
  final DateTime createdAt;
  final String? lastMessage;

  ConversationModel({
    required this.id,
    required this.title,
    required this.updatedAt,
    required this.createdAt,
    this.lastMessage,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      id: json['id'] as int,
      title: json['title'] as String,
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastMessage: json['lastMessage'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'updatedAt': updatedAt.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      if (lastMessage != null) 'lastMessage': lastMessage,
    };
  }

  ConversationModel copyWith({
    int? id,
    String? title,
    DateTime? updatedAt,
    DateTime? createdAt,
    String? lastMessage,
  }) {
    return ConversationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      updatedAt: updatedAt ?? this.updatedAt,
      createdAt: createdAt ?? this.createdAt,
      lastMessage: lastMessage ?? this.lastMessage,
    );
  }
}
