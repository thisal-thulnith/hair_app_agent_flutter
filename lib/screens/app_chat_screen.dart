import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_auth_provider.dart';
import '../providers/app_chat_provider.dart';
import '../models/message.dart';

class AppChatScreen extends StatefulWidget {
  const AppChatScreen({super.key});

  @override
  State<AppChatScreen> createState() => _AppChatScreenState();
}

class _AppChatScreenState extends State<AppChatScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  Uint8List? _selectedImage;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 400), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  Future<void> _pickImage() async {
    final chatProvider = context.read<AppChatProvider>();
    final imageBytes = await chatProvider.pickImageFromGallery();
    if (imageBytes != null) {
      setState(() => _selectedImage = imageBytes);
      _animationController.forward();
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
    setState(() {
      _selectedImage = null;
      _animationController.reverse();
    });

    try {
      await chatProvider.sendMessage(
        userId: authProvider.user!.uid,
        text: text.isNotEmpty ? text : 'Please analyze this image',
        imageBytes: imageToSend,
      );
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar(e.toString().replaceFirst('Exception: ', ''));
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontSize: 14, color: Colors.white),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).size.height * 0.08,
          left: 16,
          right: 16,
        ),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 800; // Tablet/Desktop detection

    return Column(
      children: [
        // Chat area
        Expanded(
          child: Consumer<AppChatProvider>(
            builder: (context, chatProvider, _) {
              if (chatProvider.messages.isEmpty) {
                return _buildEmptyState(isWide);
              }

              return LayoutBuilder(
                builder: (context, constraints) {
                  // Center chat on wide screens
                  final maxWidth = isWide ? 900.0 : constraints.maxWidth;

                  return Center(
                    child: SizedBox(
                      width: maxWidth,
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: EdgeInsets.symmetric(
                          horizontal: isWide ? 32 : 16,
                          vertical: 20,
                        ),
                        itemCount: chatProvider.messages.length,
                        itemBuilder: (ctx, i) {
                          final message = chatProvider.messages[i];
                          final showDateDivider = i == 0 ||
                              !_isSameDay(
                                message.createdAt,
                                chatProvider.messages[i - 1].createdAt,
                              );

                          return Column(
                            children: [
                              if (showDateDivider)
                                _DateDivider(date: message.createdAt),
                              _MessageBubble(
                                message: message,
                                isWide: isWide,
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),

        // Typing indicator
        Consumer<AppChatProvider>(
          builder: (context, chatProvider, _) {
            if (chatProvider.isSending) {
              return _TypingIndicator(isWide: isWide);
            }
            return const SizedBox.shrink();
          },
        ),

        // Input area
        _buildInputArea(isWide),
      ],
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Widget _buildEmptyState(bool isWide) {
    return Center(
      child: Container(
        constraints: BoxConstraints(maxWidth: isWide ? 500 : double.infinity),
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated gradient icon
            TweenAnimationBuilder(
              duration: const Duration(seconds: 2),
              tween: Tween<double>(begin: 0, end: 1),
              builder: (context, double value, child) {
                return Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color.lerp(
                            const Color(0xFF8B5CF6), const Color(0xFFEC4899), value)!,
                        Color.lerp(
                            const Color(0xFFEC4899), const Color(0xFF8B5CF6), value)!,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF8B5CF6).withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    size: 48,
                    color: Colors.white,
                  ),
                );
              },
            ),
            const SizedBox(height: 32),
            const Text(
              'Your Beauty AI Assistant',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Get personalized beauty advice, hairstyle recommendations, and more!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.white.withOpacity(0.6),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 40),
            _SuggestionChips(),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea(bool isWide) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Center(
          child: Container(
            constraints: BoxConstraints(maxWidth: isWide ? 900 : double.infinity),
            padding: EdgeInsets.symmetric(
              horizontal: isWide ? 32 : 16,
              vertical: 12,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Image preview
                if (_selectedImage != null)
                  AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      height: 100,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF8B5CF6),
                          width: 2,
                        ),
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
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    _selectedImage = null;
                                    _animationController.reverse();
                                  });
                                },
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.7),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Input row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Image picker button
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _pickImage,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF334155),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.add_photo_alternate_rounded,
                            color: Color(0xFF8B5CF6),
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Text input
                    Expanded(
                      child: Container(
                        constraints: const BoxConstraints(
                          maxHeight: 120,
                          minHeight: 48,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF334155),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: TextField(
                          controller: _controller,
                          focusNode: _focusNode,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            height: 1.4,
                          ),
                          maxLines: null,
                          textInputAction: TextInputAction.newline,
                          decoration: InputDecoration(
                            hintText: 'Ask me anything about beauty...',
                            hintStyle: TextStyle(
                              color: Colors.white.withOpacity(0.4),
                              fontSize: 15,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Send button
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _sendMessage,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF8B5CF6).withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.send_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Typing indicator widget
class _TypingIndicator extends StatefulWidget {
  final bool isWide;

  const _TypingIndicator({required this.isWide});

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: widget.isWide ? 32 : 16,
        vertical: 16,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.auto_awesome, size: 16, color: Colors.white),
          ),
          const SizedBox(width: 12),
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Row(
                children: List.generate(3, (index) {
                  final delay = index * 0.2;
                  final value = (_controller.value - delay).clamp(0.0, 1.0);
                  final opacity = (Curves.easeInOut.transform(value) * 2 - 1).abs();

                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B5CF6).withOpacity(0.3 + opacity * 0.7),
                      shape: BoxShape.circle,
                    ),
                  );
                }),
              );
            },
          ),
          const SizedBox(width: 12),
          Text(
            'AI is thinking...',
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

// Date divider
class _DateDivider extends StatelessWidget {
  final DateTime date;

  const _DateDivider({required this.date});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isToday = date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;

    final dateStr = isToday
        ? 'Today'
        : date.day == now.day - 1
            ? 'Yesterday'
            : '${date.day}/${date.month}/${date.year}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Expanded(
            child: Divider(
              color: Colors.white.withOpacity(0.1),
              thickness: 1,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              dateStr,
              style: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Divider(
              color: Colors.white.withOpacity(0.1),
              thickness: 1,
            ),
          ),
        ],
      ),
    );
  }
}

// Suggestion chips for empty state
class _SuggestionChips extends StatelessWidget {
  final List<Map<String, dynamic>> suggestions = [
    {
      'icon': Icons.face_rounded,
      'text': 'Analyze my skin',
      'gradient': [Color(0xFFEC4899), Color(0xFFF472B6)],
    },
    {
      'icon': Icons.content_cut,
      'text': 'Suggest hairstyles',
      'gradient': [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
    },
    {
      'icon': Icons.spa_rounded,
      'text': 'Skincare routine',
      'gradient': [Color(0xFF06B6D4), Color(0xFF67E8F9)],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: suggestions.map((s) {
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              // Implement suggestion click
            },
            borderRadius: BorderRadius.circular(24),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: s['gradient']),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: s['gradient'][0].withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(s['icon'], size: 18, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    s['text'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// Message bubble widget
class _MessageBubble extends StatelessWidget {
  final Message message;
  final bool isWide;

  const _MessageBubble({
    required this.message,
    required this.isWide,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            _buildAvatar(false),
            const SizedBox(width: 12),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: isWide ? 600 : MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: isUser
                    ? const LinearGradient(
                        colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isUser ? null : const Color(0xFF334155),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isUser ? 20 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: isUser
                        ? const Color(0xFF8B5CF6).withOpacity(0.2)
                        : Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User uploaded image
                  if (message.hasUploadedImage) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: _buildUploadedImage(message),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Message text
                  Text(
                    message.content,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.white,
                      height: 1.5,
                    ),
                  ),

                  // AI generated image
                  if (message.hasGeneratedImage) ...[
                    const SizedBox(height: 12),
                    const Divider(color: Colors.white24, height: 24),
                    Row(
                      children: [
                        const Icon(
                          Icons.auto_awesome,
                          size: 16,
                          color: Colors.white70,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'AI Generated',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.7),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: _buildGeneratedImage(message, context),
                    ),
                  ],

                  // Timestamp
                  const SizedBox(height: 8),
                  Text(
                    _formatTime(message.createdAt),
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 12),
            _buildAvatar(true),
          ],
        ],
      ),
    );
  }

  Widget _buildAvatar(bool isUser) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        gradient: isUser
            ? const LinearGradient(
                colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
              )
            : const LinearGradient(
                colors: [Color(0xFF06B6D4), Color(0xFF0EA5E9)],
              ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: (isUser ? const Color(0xFF8B5CF6) : const Color(0xFF06B6D4))
                .withOpacity(0.3),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Icon(
        isUser ? Icons.person : Icons.auto_awesome,
        color: Colors.white,
        size: 20,
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

    if (message.generatedImageUrl != null &&
        message.generatedImageUrl!.isNotEmpty) {
      imageWidget = Image.network(
        message.generatedImageUrl!,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const Center(child: CircularProgressIndicator());
        },
        errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
      );
    } else if (message.generatedImageBase64 != null) {
      try {
        final base64String = message.generatedImageBase64!;
        final base64Data =
            base64String.contains(',') ? base64String.split(',').last : base64String;
        final bytes = base64Decode(base64Data);
        imageWidget = Image.memory(bytes, fit: BoxFit.cover);
      } catch (e) {
        print('Error decoding generated image: $e');
        return const Icon(Icons.broken_image);
      }
    } else {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: () {
        // Show full screen image
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => _FullScreenImage(message: message),
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

// Full screen image viewer
class _FullScreenImage extends StatelessWidget {
  final Message message;

  const _FullScreenImage({required this.message});

  @override
  Widget build(BuildContext context) {
    Widget imageWidget;

    if (message.generatedImageUrl != null) {
      imageWidget = Image.network(message.generatedImageUrl!, fit: BoxFit.contain);
    } else if (message.generatedImageBase64 != null) {
      try {
        final base64String = message.generatedImageBase64!;
        final base64Data =
            base64String.contains(',') ? base64String.split(',').last : base64String;
        final bytes = base64Decode(base64Data);
        imageWidget = Image.memory(bytes, fit: BoxFit.contain);
      } catch (e) {
        imageWidget = const Icon(Icons.broken_image, size: 48);
      }
    } else {
      imageWidget = const Icon(Icons.broken_image, size: 48);
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: InteractiveViewer(
          panEnabled: true,
          boundaryMargin: const EdgeInsets.all(80),
          minScale: 0.5,
          maxScale: 4,
          child: imageWidget,
        ),
      ),
    );
  }
}
