import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_auth_provider.dart';
import '../providers/app_chat_provider.dart';
import '../models/message.dart';
import '../theme/modern_theme.dart';

class ModernChatScreen extends StatefulWidget {
  const ModernChatScreen({super.key});

  @override
  State<ModernChatScreen> createState() => _ModernChatScreenState();
}

class _ModernChatScreenState extends State<ModernChatScreen> {
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
            content: Text('Error: ${e.toString()}'),
            backgroundColor: ModernTheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: ModernTheme.md,
            vertical: ModernTheme.md,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).dividerColor,
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, size: 20),
                onPressed: () {
                  context.read<AppChatProvider>().clearCurrentConversation();
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: ModernTheme.md),
              Text(
                'AI Assistant',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.search, size: 20),
                onPressed: () {},
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),

        // Messages
        Expanded(
          child: Consumer<AppChatProvider>(
            builder: (context, chatProvider, _) {
              if (chatProvider.messages.isEmpty) {
                return _buildEmptyState();
              }

              return ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(ModernTheme.md),
                itemCount: chatProvider.messages.length,
                itemBuilder: (ctx, i) {
                  final message = chatProvider.messages[i];
                  return _MessageBubble(message: message);
                },
              );
            },
          ),
        ),

        // Typing indicator
        Consumer<AppChatProvider>(
          builder: (context, chatProvider, _) {
            if (chatProvider.isSending) {
              return Container(
                padding: const EdgeInsets.all(ModernTheme.md),
                child: Row(
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: ModernTheme.md),
                    Text(
                      'AI is thinking...',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),

        // Input area
        Container(
          padding: const EdgeInsets.all(ModernTheme.md),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              top: BorderSide(
                color: Theme.of(context).dividerColor,
                width: 1,
              ),
            ),
          ),
          child: Column(
            children: [
              if (_selectedImage != null)
                Container(
                  margin: const EdgeInsets.only(bottom: ModernTheme.md),
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(ModernTheme.radiusMd),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2,
                    ),
                  ),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(ModernTheme.radiusMd - 2),
                        child: Image.memory(
                          _selectedImage!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: IconButton(
                          icon: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close, color: Colors.white, size: 16),
                          ),
                          onPressed: () => setState(() => _selectedImage = null),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ),
                    ],
                  ),
                ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.attach_file, size: 20),
                    onPressed: _pickImage,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: ModernTheme.md),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        hintText: 'Type a message...',
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                      maxLines: null,
                      textInputAction: TextInputAction.newline,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: ModernTheme.md),
                  IconButton(
                    icon: Icon(
                      Icons.send,
                      size: 20,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    onPressed: _sendMessage,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(ModernTheme.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Start a conversation',
              style: Theme.of(context).textTheme.displayMedium,
            ),
            const SizedBox(height: ModernTheme.md),
            Text(
              'Ask me anything about beauty, skincare, makeup, or hairstyles',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).brightness == Brightness.dark
                  ? ModernTheme.darkTextMuted
                  : ModernTheme.lightTextMuted,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final Message message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: ModernTheme.md),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            _buildAvatar(false),
            const SizedBox(width: ModernTheme.sm),
          ],
          Flexible(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 500),
              padding: const EdgeInsets.all(ModernTheme.md),
              decoration: BoxDecoration(
                color: isUser
                    ? (isDark ? ModernTheme.darkAccent : ModernTheme.lightAccent)
                    : (isDark ? ModernTheme.darkSurface : ModernTheme.lightSurface),
                borderRadius: BorderRadius.circular(ModernTheme.radiusMd),
                border: isUser
                    ? null
                    : Border.all(
                        color: isDark ? ModernTheme.darkBorder : ModernTheme.lightBorder,
                        width: 1,
                      ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message.hasUploadedImage) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(ModernTheme.radiusSm),
                      child: _buildUploadedImage(message),
                    ),
                    const SizedBox(height: ModernTheme.sm),
                  ],
                  Text(
                    message.content,
                    style: TextStyle(
                      fontSize: 14,
                      color: isUser
                          ? (isDark ? ModernTheme.darkBg : Colors.white)
                          : (isDark ? ModernTheme.darkText : ModernTheme.lightText),
                      height: 1.5,
                    ),
                  ),
                  if (message.hasGeneratedImage) ...[
                    const SizedBox(height: ModernTheme.md),
                    const Divider(height: 1),
                    const SizedBox(height: ModernTheme.sm),
                    Text(
                      'AI Generated Image',
                      style: TextStyle(
                        fontSize: 12,
                        color: isUser
                            ? (isDark ? ModernTheme.darkBg : Colors.white).withOpacity(0.7)
                            : (isDark ? ModernTheme.darkTextMuted : ModernTheme.lightTextMuted),
                      ),
                    ),
                    const SizedBox(height: ModernTheme.sm),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(ModernTheme.radiusSm),
                      child: _buildGeneratedImage(message, context),
                    ),
                  ],
                  const SizedBox(height: ModernTheme.xs),
                  Text(
                    _formatTime(message.createdAt),
                    style: TextStyle(
                      fontSize: 11,
                      color: isUser
                          ? (isDark ? ModernTheme.darkBg : Colors.white).withOpacity(0.6)
                          : (isDark ? ModernTheme.darkTextMuted : ModernTheme.lightTextMuted),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: ModernTheme.sm),
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
        color: isUser ? ModernTheme.lightAccent : ModernTheme.lightSurface,
        shape: BoxShape.circle,
        border: Border.all(color: ModernTheme.lightBorder, width: 1),
      ),
      child: Icon(
        isUser ? Icons.person : Icons.auto_awesome,
        color: isUser ? Colors.white : ModernTheme.lightText,
        size: 16,
      ),
    );
  }

  Widget _buildUploadedImage(Message message) {
    if (message.imageUrl != null && message.imageUrl!.isNotEmpty) {
      return Image.network(
        message.imageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
      );
    } else if (message.userImageBase64 != null) {
      try {
        final bytes = base64Decode(message.userImageBase64!);
        return Image.memory(bytes, fit: BoxFit.cover);
      } catch (e) {
        return const Icon(Icons.broken_image);
      }
    }
    return const SizedBox.shrink();
  }

  Widget _buildGeneratedImage(Message message, BuildContext context) {
    Widget imageWidget;

    if (message.generatedImageUrl != null && message.generatedImageUrl!.isNotEmpty) {
      imageWidget = Image.network(
        message.generatedImageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
      );
    } else if (message.generatedImageBase64 != null) {
      try {
        final base64String = message.generatedImageBase64!;
        final base64Data = base64String.contains(',') ? base64String.split(',').last : base64String;
        final bytes = base64Decode(base64Data);
        imageWidget = Image.memory(bytes, fit: BoxFit.cover);
      } catch (e) {
        return const Icon(Icons.broken_image);
      }
    } else {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: () {
        // Full screen viewer
        showDialog(
          context: context,
          builder: (_) => Dialog(
            child: imageWidget,
          ),
        );
      },
      child: imageWidget,
    );
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
