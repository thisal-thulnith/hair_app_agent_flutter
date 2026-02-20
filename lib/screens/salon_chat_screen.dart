import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_auth_provider.dart';
import '../providers/app_chat_provider.dart';
import '../models/message.dart';
import '../models/conversation.dart';

class SalonChatScreen extends StatefulWidget {
  const SalonChatScreen({super.key});

  @override
  State<SalonChatScreen> createState() => _SalonChatScreenState();
}

class _SalonChatScreenState extends State<SalonChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Uint8List? _selectedImage;

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
            backgroundColor: const Color(0xFFE11D48),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;

        return Scaffold(
          backgroundColor: const Color(0xFFFFFBF5),
          body: Column(
            children: [
              // Header
              _buildHeader(),

              // Mobile: History on top, Desktop: Side by side
              if (isMobile) ...[
                _buildMobileHistoryBar(),
                Expanded(child: _buildChatArea()),
              ] else ...[
                Expanded(
                  child: Row(
                    children: [
                      _buildDesktopSidebar(),
                      Expanded(child: _buildChatArea()),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            const Text(
              'Buff Salon',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Color(0xFFDB2777),
                letterSpacing: -0.5,
              ),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.settings_outlined, size: 22),
              color: const Color(0xFF6B7280),
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(Icons.logout, size: 22),
              color: const Color(0xFF6B7280),
              onPressed: () => context.read<AppAuthProvider>().signOut(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileHistoryBar() {
    return Container(
      height: 120,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFF3F4F6), width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                const Text(
                  'Conversations',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF374151),
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () {
                    context.read<AppChatProvider>().clearCurrentConversation();
                  },
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('New'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFDB2777),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: _buildConversationsList(horizontal: true)),
        ],
      ),
    );
  }

  Widget _buildDesktopSidebar() {
    return Container(
      width: 280,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          right: BorderSide(color: Color(0xFFF3F4F6), width: 1),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  context.read<AppChatProvider>().clearCurrentConversation();
                },
                icon: const Icon(Icons.add, size: 18),
                label: const Text('New Chat'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDB2777),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
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
                'Recent Chats',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6B7280),
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(child: _buildConversationsList(horizontal: false)),
        ],
      ),
    );
  }

  Widget _buildConversationsList({required bool horizontal}) {
    return Consumer<AppChatProvider>(
      builder: (context, chatProvider, _) {
        if (chatProvider.conversations.isEmpty) {
          return Center(
            child: Text(
              'No chats yet',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade400,
              ),
            ),
          );
        }

        if (horizontal) {
          return ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: chatProvider.conversations.length,
            itemBuilder: (context, index) {
              final conversation = chatProvider.conversations[index];
              final isSelected =
                  chatProvider.currentConversation?.id == conversation.id;

              return Container(
                margin: const EdgeInsets.only(right: 8),
                child: ActionChip(
                  label: Text(
                    conversation.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  backgroundColor:
                      isSelected ? const Color(0xFFFCE7F3) : const Color(0xFFF9FAFB),
                  side: BorderSide(
                    color: isSelected
                        ? const Color(0xFFDB2777)
                        : const Color(0xFFE5E7EB),
                    width: 1,
                  ),
                  onPressed: () =>
                      chatProvider.setCurrentConversation(conversation),
                ),
              );
            },
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          itemCount: chatProvider.conversations.length,
          itemBuilder: (context, index) {
            final conversation = chatProvider.conversations[index];
            final isSelected =
                chatProvider.currentConversation?.id == conversation.id;

            return Container(
              margin: const EdgeInsets.symmetric(vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFFCE7F3) : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListTile(
                title: Text(
                  conversation.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: const Color(0xFF1F2937),
                  ),
                ),
                subtitle: Text(
                  _formatDate(conversation.updatedAt),
                  style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                ),
                onTap: () => chatProvider.setCurrentConversation(conversation),
                dense: true,
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildChatArea() {
    return Container(
      color: const Color(0xFFFFFBF5),
      child: Column(
        children: [
          // Chat header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Color(0xFFF3F4F6), width: 1),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFDB2777), Color(0xFFF472B6)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.spa, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Salon Buff',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111827),
                      ),
                    ),
                    Text(
                      'Your beauty AI assistant',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Messages
          Expanded(child: _buildMessagesList()),

          // Typing indicator
          Consumer<AppChatProvider>(
            builder: (context, chatProvider, _) {
              if (chatProvider.isSending) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Color(0xFFDB2777)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Salon Buff is typing...',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),

          // Input area
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
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFCE7F3), Color(0xFFFDF2F8)],
                    ),
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: const Icon(
                    Icons.chat_bubble_outline,
                    size: 36,
                    color: Color(0xFFDB2777),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Start a conversation',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF374151),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Ask about beauty, skincare, or hairstyles',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            if (_selectedImage != null)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                height: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFDB2777), width: 2),
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
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedImage = null),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.image_outlined),
                  color: const Color(0xFF6B7280),
                  onPressed: _pickImage,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        hintText: 'Type your message...',
                        hintStyle: TextStyle(color: Color(0xFF9CA3AF)),
                        border: InputBorder.none,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      maxLines: null,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFDB2777), Color(0xFFF472B6)],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
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
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFDB2777), Color(0xFFF472B6)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.spa, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 12),
          ],
          Flexible(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 500),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser ? const Color(0xFFDB2777) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message.hasUploadedImage) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: _buildImage(message.imageUrl, message.userImageBase64),
                    ),
                    const SizedBox(height: 8),
                  ],
                  Text(
                    message.content,
                    style: TextStyle(
                      color: isUser ? Colors.white : const Color(0xFF1F2937),
                      fontSize: 15,
                      height: 1.5,
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
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(message.createdAt),
                    style: TextStyle(
                      fontSize: 11,
                      color: isUser
                          ? Colors.white.withOpacity(0.7)
                          : const Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 12),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.person, color: Color(0xFF6B7280), size: 16),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildImage(String? url, String? base64) {
    if (url != null && url.isNotEmpty) {
      return Image.network(url, fit: BoxFit.cover);
    } else if (base64 != null) {
      try {
        final data = base64.contains(',') ? base64.split(',').last : base64;
        return Image.memory(base64Decode(data), fit: BoxFit.cover);
      } catch (e) {
        return const Icon(Icons.broken_image);
      }
    }
    return const SizedBox();
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
