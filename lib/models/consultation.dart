class Consultation {
  final String id;
  final String message;
  final String? imageUrl;
  final String response;
  final DateTime timestamp;

  Consultation({
    required this.id,
    required this.message,
    this.imageUrl,
    required this.response,
    required this.timestamp,
  });

  factory Consultation.fromJson(Map<String, dynamic> json) {
    return Consultation(
      id: json['id']?.toString() ?? json['session_id']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      imageUrl: json['image_url']?.toString(),
      response: json['response']?.toString() ?? '',
      timestamp: json['timestamp'] != null || json['created_at'] != null
          ? DateTime.parse(json['timestamp'] ?? json['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'message': message,
      'image_url': imageUrl,
      'response': response,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
