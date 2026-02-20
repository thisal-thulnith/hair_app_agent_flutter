import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_auth_provider.dart';
import '../providers/app_chat_provider.dart';
import '../models/message.dart';
import '../config/environment.dart';

class AppChatScreen extends StatefulWidget {
  const AppChatScreen({super.key});

  @override
  State<AppChatScreen> createState() => _AppChatScreenState();
}

class _AppChatScreenState extends State<AppChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Uint8List? _selectedImage;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _pickImage() async {
    final chatProvider = context.read<AppChatProvider>();
    final imageBytes = await chatProvider.pickImageFromGallery();
    if (imageBytes != null) {
      setState(() => _selectedImage = imageBytes);
    }
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty && _selectedImage == null) return;

    final authProvider = context.read<AppAuthProvider>();
    final chatProvider = context.read<AppChatProvider>();

    if (authProvider.user == null) return;

    _controller.clear();
    final imageToSend = _selectedImage;
    setState(() => _selectedImage = null);

    try {
      await chatProvider.sendMessage(
        userId: authProvider.user!.uid,
        text: text.isNotEmpty ? text : 'Please analyze this image',
        imageBytes: imageToSend,
      );
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Message Failed',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        e.toString().replaceFirst('Exception: ', ''),
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFFFFCDD2)),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Dismiss',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Consumer<AppChatProvider>(
            builder: (context, chatProvider, _) {
              if (chatProvider.messages.isEmpty) {
                return _buildEmptyState();
              }

              return ListView.builder(
                controller: _scrollController,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                itemCount: chatProvider.messages.length,
                itemBuilder: (ctx, i) {
                  final message = chatProvider.messages[i];
                  return _MessageBubble(message: message);
                },
              );
            },
          ),
        ),
        Consumer<AppChatProvider>(
          builder: (context, chatProvider, _) {
            if (chatProvider.isSending) {
              return Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          const Color(0xFF9333EA),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'AI is thinking...',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
        _buildInputArea(),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF9333EA), Color(0xFFEC4899)],
              ),
              shape: BoxShape.circle,
            ),
            child:
                const Icon(Icons.auto_awesome, size: 40, color: Colors.white),
          ),
          const SizedBox(height: 20),
          const Text(
            'Start Chatting',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Ask about beauty, skincare, hair styling, or upload a photo!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.white12),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_selectedImage != null)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF9333EA), width: 2),
              ),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.memory(
                      _selectedImage!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedImage = null),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close,
                            color: Colors.white, size: 18),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              IconButton(
                icon: const Icon(Icons.add_photo_alternate,
                    color: Color(0xFF9333EA), size: 24),
                onPressed: _pickImage,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 120),
                  decoration: BoxDecoration(
                    color: const Color(0xFF40414F),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: _controller,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    maxLines: null,
                    decoration: InputDecoration(
                      hintText: 'Send a message...',
                      hintStyle: TextStyle(
                          color: Colors.white.withOpacity(0.4), fontSize: 14),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF9333EA), Color(0xFFEC4899)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  icon: const Icon(Icons.send, color: Colors.white, size: 20),
                  onPressed: _sendMessage,
                  padding: const EdgeInsets.all(10),
                  constraints: const BoxConstraints(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final Message message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            _buildAvatar(false),
            const SizedBox(width: 12),
          ],
          if (message.isUser) const Spacer(),
          Flexible(
            flex: 8,
            child: Column(
              crossAxisAlignment: message.isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: message.isUser
                        ? const LinearGradient(
                            colors: [Color(0xFF9333EA), Color(0xFFEC4899)],
                          )
                        : null,
                    color: message.isUser ? null : const Color(0xFF444654),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // User-uploaded image
                      if (message.hasUploadedImage)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _buildUploadedImage(message),
                        ),

                      // Message text
                      Text(
                        message.content,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                          height: 1.5,
                        ),
                      ),

                      // AI-generated image
                      if (message.hasGeneratedImage)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '✨ AI Generated Image:',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: () {
                                  final imageBytes =
                                      _decodeGeneratedImage(message);
                                  if (imageBytes == null) return;
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => _FullScreenImage(
                                        imageBytes: imageBytes,
                                      ),
                                    ),
                                  );
                                },
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: _buildGeneratedImage(message),
                                ),
                              ),
                            ],
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
                      fontSize: 11,
                      color: Colors.white.withOpacity(0.4),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 12),
            _buildAvatar(true),
          ],
        ],
      ),
    );
  }

  Widget _buildAvatar(bool isUser) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isUser
              ? [const Color(0xFF9333EA), const Color(0xFFEC4899)]
              : [const Color(0xFF10A37F), const Color(0xFF19C37D)],
        ),
        shape: BoxShape.circle,
      ),
      child: Icon(
        isUser ? Icons.person : Icons.auto_awesome,
        color: Colors.white,
        size: 18,
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  Uint8List _decodeBase64(String base64String) {
    final base64Data =
        base64String.replaceFirst(RegExp(r'data:image/[^;]+;base64,'), '');
    return base64Decode(base64Data);
  }

  Widget _buildUploadedImage(Message message) {
    if (message.userImageBase64 != null &&
        message.userImageBase64!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.memory(
          _decodeBase64(message.userImageBase64!),
          width: 200,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _brokenImage(),
        ),
      );
    }

    final imageUrl = message.imageUrl;
    if (imageUrl == null || imageUrl.isEmpty) {
      return _brokenImage();
    }

    final resolvedUrl = _resolveBackendImageUrl(imageUrl);
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.network(
        resolvedUrl,
        width: 200,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _brokenImage(),
      ),
    );
  }

  String _resolveBackendImageUrl(String imageRef) {
    if (imageRef.startsWith('/uploads/')) {
      return '${Environment.aiBackendUrl}$imageRef';
    }
    if (imageRef.startsWith('uploads/')) {
      return '${Environment.aiBackendUrl}/$imageRef';
    }

    final uri = Uri.tryParse(imageRef);
    if (uri != null && uri.hasScheme && uri.path.startsWith('/uploads/')) {
      return '${Environment.aiBackendUrl}${uri.path}';
    }
    return imageRef;
  }

  Widget _brokenImage() {
    return Container(
      width: 200,
      height: 150,
      color: Colors.grey.shade800,
      child: const Icon(Icons.broken_image, color: Colors.white54),
    );
  }

  Widget _buildGeneratedImage(Message message) {
    if (message.generatedImageUrl != null &&
        message.generatedImageUrl!.isNotEmpty) {
      return Image.network(
        _resolveBackendImageUrl(message.generatedImageUrl!),
        width: 220,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _generatedBrokenImage(),
      );
    }

    final decoded = _decodeGeneratedImage(message);
    if (decoded == null) return _generatedBrokenImage();

    return Image.memory(
      decoded,
      width: 220,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => _generatedBrokenImage(),
    );
  }

  Uint8List? _decodeGeneratedImage(Message message) {
    final base64Value = message.generatedImageBase64;
    if (base64Value == null || base64Value.isEmpty) return null;
    try {
      return _decodeBase64(base64Value);
    } catch (_) {
      return null;
    }
  }

  Widget _generatedBrokenImage() {
    return Container(
      width: 220,
      height: 180,
      color: Colors.grey.shade800,
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.broken_image, color: Colors.white54, size: 28),
          SizedBox(height: 6),
          Text(
            'Failed to load image',
            style: TextStyle(color: Colors.white54, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _FullScreenImage extends StatelessWidget {
  final Uint8List imageBytes;

  const _FullScreenImage({required this.imageBytes});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download, color: Colors.white),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Download feature coming soon!'),
                  backgroundColor: Color(0xFF9333EA),
                ),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: Image.memory(imageBytes),
        ),
      ),
    );
  }
}
