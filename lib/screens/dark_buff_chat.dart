import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_auth_provider.dart';
import '../providers/app_chat_provider.dart';
import '../models/message.dart';
import '../models/conversation.dart';

class DarkBuffChat extends StatefulWidget {
  const DarkBuffChat({super.key});

  @override
  State<DarkBuffChat> createState() => _DarkBuffChatState();
}

class _DarkBuffChatState extends State<DarkBuffChat> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Uint8List? _selectedImage;
  bool _showSidebar = true;

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

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
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
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 768;

        return Scaffold(
          backgroundColor: const Color(0xFF0F0F0F),
          body: Row(
            children: [
              if (isDesktop && _showSidebar) _buildSidebar(),
              Expanded(
                child: Column(
                  children: [
                    _buildHeader(isDesktop),
                    Expanded(child: _buildChatArea()),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(bool isDesktop) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1A1A), Color(0xFF0F0F0F)],
        ),
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFFFFD700).withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            if (isDesktop)
              IconButton(
                icon: Icon(
                  _showSidebar ? Icons.menu_open : Icons.menu,
                  color: const Color(0xFFFFD700),
                ),
                onPressed: () {
                  setState(() => _showSidebar = !_showSidebar);
                },
              ),
            const SizedBox(width: 12),
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
              ).createShader(bounds),
              child: const Text(
                'Buff Salon',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              color: const Color(0xFF8B8B8B),
              onPressed: () {},
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.logout),
              color: const Color(0xFF8B8B8B),
              onPressed: () => context.read<AppAuthProvider>().signOut(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1A1A1A), Color(0xFF0F0F0F)],
        ),
        border: Border(
          right: BorderSide(
            color: const Color(0xFFFFD700).withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              width: double.infinity,
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFD700).withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    context.read<AppChatProvider>().clearCurrentConversation();
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: const Center(
                    child: Text(
                      '+ New Chat',
                      style: TextStyle(
                        color: Color(0xFF0F0F0F),
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'CONVERSATIONS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF6B6B6B),
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(child: _buildConversationsList()),
        ],
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
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF4A4A4A),
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemCount: chatProvider.conversations.length,
          itemBuilder: (context, index) {
            final conversation = chatProvider.conversations[index];
            final isSelected =
                chatProvider.currentConversation?.id == conversation.id;

            return Container(
              margin: const EdgeInsets.only(bottom: 4),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? const LinearGradient(
                        colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                      )
                    : null,
                color: isSelected ? null : const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () =>
                      chatProvider.setCurrentConversation(conversation),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          conversation.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? const Color(0xFF0F0F0F)
                                : const Color(0xFFE5E5E5),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDate(conversation.updatedAt),
                          style: TextStyle(
                            fontSize: 11,
                            color: isSelected
                                ? const Color(0xFF0F0F0F).withOpacity(0.7)
                                : const Color(0xFF6B6B6B),
                          ),
                        ),
                      ],
                    ),
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
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0F0F0F), Color(0xFF1A1A1A)],
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            child: ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
              ).createShader(bounds),
              child: const Text(
                'Salon Buff',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          Expanded(child: _buildMessagesList()),
          Consumer<AppChatProvider>(
            builder: (context, chatProvider, _) {
              if (chatProvider.isSending) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFFFFD700),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Typing...',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B6B6B),
                        ),
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessagesList() {
    return Consumer<AppChatProvider>(
      builder: (context, chatProvider, _) {
        if (chatProvider.messages.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFD700).withOpacity(0.3),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.chat_bubble_outline,
                      size: 40,
                      color: Color(0xFF0F0F0F),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                  ).createShader(bounds),
                  child: const Text(
                    'Welcome to Buff Salon',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Start your beauty journey',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF6B6B6B),
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(24),
          itemCount: chatProvider.messages.length,
          itemBuilder: (context, index) {
            final message = chatProvider.messages[index];
            return _MessageBubble(message: message);
          },
        );
      },
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        border: Border(
          top: BorderSide(
            color: const Color(0xFFFFD700).withOpacity(0.1),
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
                height: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFFFD700),
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
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: const Color(0xFF2D2D2D),
                            child: const Center(
                              child: Icon(
                                Icons.broken_image,
                                color: Color(0xFF6B6B6B),
                                size: 32,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedImage = null),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Color(0xFF0F0F0F),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Color(0xFFFFD700),
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF2D2D2D),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFFFD700).withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.image_outlined),
                    color: const Color(0xFFFFD700),
                    onPressed: _pickImage,
                  ),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      style: const TextStyle(color: Color(0xFFE5E5E5)),
                      decoration: const InputDecoration(
                        hintText: 'Ask me anything...',
                        hintStyle: TextStyle(color: Color(0xFF6B6B6B)),
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
                  Container(
                    margin: const EdgeInsets.all(4),
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                      ),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFFD700).withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _sendMessage,
                        borderRadius: BorderRadius.circular(8),
                        child: const Icon(
                          Icons.send,
                          color: Color(0xFF0F0F0F),
                          size: 20,
                        ),
                      ),
                    ),
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

  const _MessageBubble({required this.message});

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
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text(
                  'AI',
                  style: TextStyle(
                    color: Color(0xFF0F0F0F),
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Flexible(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 600),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: isUser
                    ? const LinearGradient(
                        colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                      )
                    : const LinearGradient(
                        colors: [Color(0xFF2D2D2D), Color(0xFF1A1A1A)],
                      ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isUser
                      ? Colors.transparent
                      : const Color(0xFFFFD700).withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message.hasUploadedImage) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: _buildImage(
                          message.imageUrl, message.userImageBase64),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Text(
                    message.content,
                    style: TextStyle(
                      color: isUser
                          ? const Color(0xFF0F0F0F)
                          : const Color(0xFFE5E5E5),
                      fontSize: 15,
                      height: 1.6,
                    ),
                  ),
                  if (message.hasGeneratedImage) ...[
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: _buildImage(
                        message.generatedImageUrl,
                        message.generatedImageBase64,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    _formatTime(message.createdAt),
                    style: TextStyle(
                      fontSize: 11,
                      color: isUser
                          ? const Color(0xFF0F0F0F).withOpacity(0.6)
                          : const Color(0xFF6B6B6B),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 12),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF2D2D2D),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF4A4A4A),
                  width: 1,
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.person,
                  color: Color(0xFF8B8B8B),
                  size: 20,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildImage(String? url, String? base64) {
    if (url != null && url.isNotEmpty) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            height: 200,
            color: const Color(0xFF2D2D2D),
            child: const Center(
              child: Icon(
                Icons.broken_image,
                color: Color(0xFF6B6B6B),
                size: 40,
              ),
            ),
          );
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            height: 200,
            color: const Color(0xFF2D2D2D),
            child: const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFD700)),
              ),
            ),
          );
        },
      );
    } else if (base64 != null) {
      try {
        final data = base64.contains(',') ? base64.split(',').last : base64;
        return Image.memory(
          base64Decode(data),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              height: 200,
              color: const Color(0xFF2D2D2D),
              child: const Center(
                child: Icon(
                  Icons.broken_image,
                  color: Color(0xFF6B6B6B),
                  size: 40,
                ),
              ),
            );
          },
        );
      } catch (e) {
        return Container(
          height: 200,
          color: const Color(0xFF2D2D2D),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.broken_image, color: Color(0xFF6B6B6B), size: 40),
                SizedBox(height: 8),
                Text(
                  'Failed to load image',
                  style: TextStyle(color: Color(0xFF6B6B6B)),
                ),
              ],
            ),
          ),
        );
      }
    }
    return const SizedBox();
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
