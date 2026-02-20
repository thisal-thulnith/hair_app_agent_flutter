import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../models/message_model.dart';

class BeautyMessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isDark;

  const BeautyMessageBubble({
    super.key,
    required this.message,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return FadeInUp(
      duration: const Duration(milliseconds: 300),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          mainAxisAlignment:
              message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!message.isUser) ...[
              _buildAvatar(),
              const SizedBox(width: 12),
            ],
            Flexible(
              child: Column(
                crossAxisAlignment: message.isUser
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: message.isUser
                          ? const LinearGradient(
                              colors: [Color(0xFF9333EA), Color(0xFFEC4899)],
                            )
                          : null,
                      color: message.isUser
                          ? null
                          : (isDark
                              ? Colors.white.withOpacity(0.1)
                              : Colors.black.withOpacity(0.05)),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(20),
                        topRight: const Radius.circular(20),
                        bottomLeft: Radius.circular(message.isUser ? 20 : 4),
                        bottomRight: Radius.circular(message.isUser ? 4 : 20),
                      ),
                      border: !message.isUser
                          ? Border.all(
                              color: (isDark ? Colors.white : Colors.black)
                                  .withOpacity(0.1),
                              width: 1,
                            )
                          : null,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (message.imageUrl != null &&
                            message.imageUrl!.isNotEmpty &&
                            message.imageUrl != 'local' &&
                            message.imageUrl != 'uploaded')
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                message.imageUrl!,
                                width: 200,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                  width: 200,
                                  height: 150,
                                  color: Colors.grey.withOpacity(0.3),
                                  child: const Icon(
                                    Icons.broken_image,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        Text(
                          message.content,
                          style: TextStyle(
                            fontSize: 15,
                            color: message.isUser
                                ? Colors.white
                                : (isDark ? Colors.white : Colors.black87),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      _formatTime(message.createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: (isDark ? Colors.white : Colors.black87)
                            .withOpacity(0.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (message.isUser) ...[
              const SizedBox(width: 12),
              _buildAvatar(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        gradient: message.isUser
            ? const LinearGradient(
                colors: [Color(0xFF9333EA), Color(0xFFEC4899)],
              )
            : const LinearGradient(
                colors: [Color(0xFF3B82F6), Color(0xFF6366F1)],
              ),
        shape: BoxShape.circle,
      ),
      child: Icon(
        message.isUser ? Icons.person : Icons.auto_awesome,
        color: Colors.white,
        size: 20,
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}
