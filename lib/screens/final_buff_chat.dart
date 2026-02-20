import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_auth_provider.dart';
import '../providers/app_chat_provider.dart';
import '../models/message.dart';
import '../models/conversation.dart';
import '../config/environment.dart';

class FinalBuffChat extends StatefulWidget {
  const FinalBuffChat({super.key});

  @override
  State<FinalBuffChat> createState() => _FinalBuffChatState();
}

class _FinalBuffChatState extends State<FinalBuffChat> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Uint8List? _selectedImage;
  bool _showSidebar = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    final authProvider = context.read<AppAuthProvider>();
    final chatProvider = context.read<AppChatProvider>();

    if (authProvider.user != null) {
      chatProvider.loadConversations(authProvider.user!.uid);
      await chatProvider.initialize();
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
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

  Future<void> _sendMessage({String? predefinedText}) async {
    final text = predefinedText ?? _messageController.text.trim();
    if (text.isEmpty && _selectedImage == null) return;

    final authProvider = context.read<AppAuthProvider>();
    final chatProvider = context.read<AppChatProvider>();

    if (authProvider.user == null) return;

    _messageController.clear();
    final imageToSend = _selectedImage;
    setState(() => _selectedImage = null);

    try {
      await chatProvider.sendMessage(
        userId: authProvider.user!.uid,
        text: text.isNotEmpty ? text : 'Analyze this image',
        imageBytes: imageToSend,
      );
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    }
  }

  void _showSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: const Color(0xFF00D9FF).withOpacity(0.3),
            width: 1,
          ),
        ),
        title: const Text(
          'Settings',
          style: TextStyle(color: Color(0xFFE5E5E5)),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.person, color: Color(0xFF00D9FF)),
              title: Text(
                context.read<AppAuthProvider>().user?.email ?? 'User',
                style: const TextStyle(color: Color(0xFFE5E5E5)),
              ),
            ),
            const Divider(color: Color(0xFF2D2D2D)),
            ListTile(
              leading: const Icon(Icons.info_outline, color: Color(0xFF00D9FF)),
              title: const Text(
                'Version 1.0.0',
                style: TextStyle(color: Color(0xFFE5E5E5)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: Color(0xFF00D9FF))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 768;

        return Scaffold(
          backgroundColor: const Color(0xFF0A0A0A),
          body: Stack(
            children: [
              Column(
                children: [
                  _buildHeader(isMobile),
                  Expanded(
                    child: _buildChatArea(),
                  ),
                ],
              ),
              if (_showSidebar) _buildSidebarOverlay(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(bool isMobile) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        color: Color(0xFF0F0F0F),
        border: Border(
          bottom: BorderSide(
            color: Color(0xFF2D2D2D),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            GestureDetector(
              onTap: () => setState(() => _showSidebar = !_showSidebar),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF2D2D2D),
                  ),
                ),
                child: const Icon(
                  Icons.menu_rounded,
                  color: Color(0xFF8B8B8B),
                  size: 18,
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Buff Salon',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFFE5E5E5),
                letterSpacing: 0.3,
              ),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.logout_rounded, size: 18),
              color: const Color(0xFF6B6B6B),
              onPressed: () => context.read<AppAuthProvider>().signOut(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebarOverlay() {
    return GestureDetector(
      onTap: () => setState(() => _showSidebar = false),
      child: Container(
        color: Colors.black.withOpacity(0.5),
        child: SafeArea(
          child: Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              onTap: () {}, // Prevent closing when tapping sidebar
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: -280, end: 0),
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                builder: (context, value, child) {
                  return Transform.translate(
                    offset: Offset(value, 0),
                    child: child,
                  );
                },
                child: Container(
                  width: 280,
                  height: double.infinity,
                  decoration: const BoxDecoration(
                    color: Color(0xFF0F0F0F),
                    border: Border(
                      right: BorderSide(
                        color: Color(0xFF2D2D2D),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            const Text(
                              'Buff Salon',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFE5E5E5),
                              ),
                            ),
                            const Spacer(),
                            GestureDetector(
                              onTap: () => setState(() => _showSidebar = false),
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1A1A1A),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.close_rounded,
                                  color: Color(0xFF8B8B8B),
                                  size: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      _buildNewChatButton(),
                      const SizedBox(height: 8),
                      Expanded(child: _buildConversationsList()),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNewChatButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            context.read<AppChatProvider>().clearCurrentConversation();
            if (_showSidebar) {
              setState(() => _showSidebar = false);
            }
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF2D2D2D), width: 1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.edit_outlined, color: Color(0xFFE5E5E5), size: 16),
                SizedBox(width: 10),
                Text(
                  'New chat',
                  style: TextStyle(
                    color: Color(0xFFE5E5E5),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConversationsList() {
    return Consumer<AppChatProvider>(
      builder: (context, chatProvider, _) {
        if (chatProvider.conversations.isEmpty) {
          return const Center(
            child: Text(
              'No conversations',
              style: TextStyle(fontSize: 13, color: Color(0xFF4A4A4A)),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          itemCount: chatProvider.conversations.length,
          itemBuilder: (context, index) {
            final conversation = chatProvider.conversations[index];
            final isSelected =
                chatProvider.currentConversation?.id == conversation.id;

            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  chatProvider.setCurrentConversation(conversation);
                  if (_showSidebar) {
                    setState(() => _showSidebar = false);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF2D2D2D) : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.chat_bubble_outline,
                        size: 14,
                        color: Color(0xFF8B8B8B),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          conversation.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFFE5E5E5),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildChatArea() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0A0A0A),
      ),
      child: Column(
        children: [
          Expanded(child: _buildMessagesList()),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessagesList() {
    return Consumer<AppChatProvider>(
      builder: (context, chatProvider, _) {
        if (chatProvider.messages.isEmpty) {
          return const Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Welcome to Buff Salon',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFE5E5E5),
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Start a conversation with your AI beauty assistant',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF6B6B6B),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(24),
          itemCount: chatProvider.messages.length + (chatProvider.isSending ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == chatProvider.messages.length && chatProvider.isSending) {
              return const _ThinkingBubble();
            }
            final message = chatProvider.messages[index];
            // Only animate typing for the last AI message (most recent)
            final isLastMessage = index == chatProvider.messages.length - 1;
            final shouldAnimate = isLastMessage && !message.isUser;
            return _MessageBubble(
              message: message,
              animateTyping: shouldAnimate,
            );
          },
        );
      },
    );
  }


  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Color(0xFF0F0F0F),
        border: Border(
          top: BorderSide(
            color: Color(0xFF2D2D2D),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            if (_selectedImage != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                constraints: const BoxConstraints(
                  maxHeight: 200,
                  maxWidth: 300,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF0A0A0A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF2D2D2D), width: 1),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(11),
                        child: Image.memory(
                          _selectedImage!,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            print('❌ Preview image error: $error');
                            return Container(
                              height: 150,
                              width: double.infinity,
                              color: const Color(0xFF1A1A1A),
                              child: const Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.broken_image,
                                      color: Color(0xFF6B6B6B),
                                      size: 32,
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Invalid image',
                                      style: TextStyle(
                                        color: Color(0xFF6B6B6B),
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedImage = null),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1A1A).withOpacity(0.9),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF2D2D2D),
                              width: 1,
                            ),
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Color(0xFFE5E5E5),
                            size: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF2D2D2D),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.image_outlined),
                    color: const Color(0xFF8B8B8B),
                    iconSize: 20,
                    onPressed: _pickImage,
                  ),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      style: const TextStyle(color: Color(0xFFE5E5E5)),
                      decoration: const InputDecoration(
                        hintText: 'Ask me anything...',
                        hintStyle: TextStyle(color: Color(0xFF4A4A4A)),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 12,
                        ),
                      ),
                      maxLines: null,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  Consumer<AppChatProvider>(
                    builder: (context, chatProvider, _) {
                      if (chatProvider.isSending) {
                        return Container(
                          margin: const EdgeInsets.all(4),
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: const Color(0xFF3D3D3D),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                // Stop generation
                                // Note: This requires the provider to support cancellation
                                if (chatProvider.cancelGeneration != null) {
                                  chatProvider.cancelGeneration!();
                                }
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: const Icon(
                                Icons.stop_rounded,
                                color: Color(0xFFE5E5E5),
                                size: 18,
                              ),
                            ),
                          ),
                        );
                      }
                      return Container(
                        margin: const EdgeInsets.all(4),
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE5E5E5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _sendMessage(),
                            borderRadius: BorderRadius.circular(8),
                            child: const Icon(
                              Icons.arrow_upward_rounded,
                              color: Color(0xFF0A0A0A),
                              size: 18,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.day}/${date.month}';
  }
}

class _MessageBubble extends StatelessWidget {
  final Message message;
  final bool animateTyping;

  const _MessageBubble({
    required this.message,
    this.animateTyping = false,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: const Color(0xFF2D2D2D),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Center(
                child: Icon(
                  Icons.auto_awesome_outlined,
                  color: Color(0xFFE5E5E5),
                  size: 16,
                ),
              ),
            ),
            const SizedBox(width: 10),
          ],
          Flexible(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 600),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isUser ? const Color(0xFF2D2D2D) : const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isUser ? const Color(0xFF3D3D3D) : const Color(0xFF2D2D2D),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message.hasUploadedImage) ...[
                    _ChatImage(
                      url: message.imageUrl,
                      base64: message.userImageBase64,
                    ),
                    const SizedBox(height: 10),
                  ],
                  isUser
                    ? Text(
                        message.content,
                        style: const TextStyle(
                          color: Color(0xFFE5E5E5),
                          fontSize: 13,
                          height: 1.5,
                        ),
                      )
                    : _TypingText(
                        text: message.content,
                        animate: animateTyping,
                        style: const TextStyle(
                          color: Color(0xFFE5E5E5),
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                  if (message.hasGeneratedImage) ...[
                    const SizedBox(height: 10),
                    _ChatImage(
                      url: message.generatedImageUrl,
                      base64: message.generatedImageBase64,
                    ),
                  ],
                  const SizedBox(height: 6),
                  Text(
                    _formatTime(message.createdAt),
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF6B6B6B),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 10),
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: const Color(0xFF2D2D2D),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Center(
                child: Icon(
                  Icons.person_outline,
                  color: Color(0xFFE5E5E5),
                  size: 16,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}

// Standalone image display widget
class _ChatImage extends StatelessWidget {
  final String? url;
  final String? base64;

  const _ChatImage({this.url, this.base64});

  @override
  Widget build(BuildContext context) {
    // Get screen width to set max constraints
    final screenWidth = MediaQuery.of(context).size.width;
    final maxWidth = (screenWidth * 0.7).clamp(200.0, 400.0);

    // Priority: base64 first (more reliable), then URL
    if (base64 != null && base64!.isNotEmpty) {
      try {
        // Clean up base64 string - remove data URL prefix if present
        String cleanBase64 = base64!;
        if (base64!.contains(',')) {
          cleanBase64 = base64!.split(',').last;
        }

        // Remove any whitespace
        cleanBase64 = cleanBase64.replaceAll(RegExp(r'\s+'), '');

        final bytes = base64Decode(cleanBase64);
        print('✅ Displaying image from base64 (${bytes.length} bytes)');

        return ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: maxWidth,
            maxHeight: 400,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0A0A0A),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.memory(
                bytes,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  print('❌ Image.memory error: $error');
                  return _buildImageError('Failed to display image');
                },
              ),
            ),
          ),
        );
      } catch (e) {
        print('❌ Base64 decode error: $e');
        // If base64 fails, try URL as fallback
        if (url != null && url!.isNotEmpty) {
          return _buildNetworkImage(url!);
        }
        return _buildImageError('Invalid image data');
      }
    }

    // Try URL if base64 not available
    if (url != null && url!.isNotEmpty) {
      return _buildNetworkImage(url!);
    }

    return const SizedBox();
  }

  Widget _buildNetworkImage(String imageUrl) {
    // Convert relative URLs to absolute URLs
    String fullUrl = imageUrl;
    if (imageUrl.startsWith('/')) {
      fullUrl = '${Environment.aiBackendUrl}$imageUrl';
    }

    print('🖼️ Loading image from URL: $fullUrl');

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;
        final maxWidth = (screenWidth * 0.7).clamp(200.0, 400.0);

        return ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: maxWidth,
            maxHeight: 400,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0A0A0A),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                fullUrl,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    height: 200,
                    color: const Color(0xFF1A1A1A),
                    child: Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                        color: const Color(0xFF8B8B8B),
                        strokeWidth: 2,
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  print('❌ Image.network error for $fullUrl: $error');
                  print('   Original URL: $imageUrl');
                  return _buildImageError('Failed to load image');
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildImageError(String message) {
    return Container(
      height: 200,
      color: const Color(0xFF1A1A1A),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.broken_image,
              color: Color(0xFF6B6B6B),
              size: 40,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(
                color: Color(0xFF6B6B6B),
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ThinkingBubble extends StatefulWidget {
  const _ThinkingBubble();

  @override
  State<_ThinkingBubble> createState() => _ThinkingBubbleState();
}

class _ThinkingBubbleState extends State<_ThinkingBubble> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: const Color(0xFF2D2D2D),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Center(
              child: Icon(
                Icons.auto_awesome_outlined,
                color: Color(0xFFE5E5E5),
                size: 16,
              ),
            ),
          ),
          const SizedBox(width: 10),
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Opacity(
                  opacity: 0.7 + (_pulseAnimation.value - 0.95) * 6,
                  child: child,
                ),
              );
            },
            child: Container(
              constraints: const BoxConstraints(maxWidth: 200),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF2D2D2D),
                  width: 1,
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Agent thinking',
                    style: TextStyle(
                      color: Color(0xFF8B8B8B),
                      fontSize: 13,
                    ),
                  ),
                  SizedBox(width: 8),
                  _BouncingDots(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BouncingDots extends StatefulWidget {
  const _BouncingDots();

  @override
  State<_BouncingDots> createState() => _BouncingDotsState();
}

class _BouncingDotsState extends State<_BouncingDots> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final delay = index * 0.2;
            final adjustedValue = (_controller.value - delay) % 1.0;
            final bounce = (adjustedValue < 0.5
                ? adjustedValue * 2
                : 2 - (adjustedValue * 2)).clamp(0.0, 1.0);

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1),
              child: Transform.translate(
                offset: Offset(0, -4 * bounce),
                child: Container(
                  width: 4,
                  height: 4,
                  decoration: const BoxDecoration(
                    color: Color(0xFF8B8B8B),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

class _TypingText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final bool animate;

  const _TypingText({
    required this.text,
    required this.style,
    this.animate = false, // Only animate for new messages during generation
  });

  @override
  State<_TypingText> createState() => _TypingTextState();
}

class _TypingTextState extends State<_TypingText> with SingleTickerProviderStateMixin {
  String _displayedText = '';
  int _currentIndex = 0;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.text.length * 15),
    );

    // Only animate if this is a new message during generation
    if (widget.animate) {
      _startTyping();
    } else {
      // Show full text immediately for historical messages
      _displayedText = widget.text;
    }
  }

  void _startTyping() {
    if (_currentIndex < widget.text.length) {
      Future.delayed(const Duration(milliseconds: 15), () {
        if (mounted) {
          setState(() {
            _displayedText = widget.text.substring(0, _currentIndex + 1);
            _currentIndex++;
          });
          _startTyping();
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(_displayedText, style: widget.style);
  }
}
