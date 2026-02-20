import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_auth_provider.dart';
import '../providers/app_chat_provider.dart';
import '../models/message.dart';
import '../models/conversation.dart';

class CompleteChatApp extends StatefulWidget {
  const CompleteChatApp({super.key});

  @override
  State<CompleteChatApp> createState() => _CompleteChatAppState();
}

class _CompleteChatAppState extends State<CompleteChatApp> {
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
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar with conversations
          Container(
            width: 280,
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              border: Border(right: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Column(
              children: [
                _buildSidebarHeader(),
                _buildConversationsList(),
              ],
            ),
          ),

          // Main chat area
          Expanded(
            child: Consumer<AppChatProvider>(
              builder: (context, chatProvider, _) {
                return Column(
                  children: [
                    _buildChatHeader(chatProvider),
                    Expanded(child: _buildMessagesList(chatProvider)),
                    if (chatProvider.isSending) _buildTypingIndicator(),
                    _buildMessageInput(),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Buff',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const Spacer(),
              Consumer<AppAuthProvider>(
                builder: (context, auth, _) {
                  if (auth.user != null) {
                    return IconButton(
                      icon: const Icon(Icons.logout, size: 20),
                      onPressed: () => auth.signOut(),
                    );
                  }
                  return const SizedBox();
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                context.read<AppChatProvider>().clearCurrentConversation();
              },
              icon: const Icon(Icons.add, size: 18),
              label: const Text('New Chat'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationsList() {
    return Expanded(
      child: Consumer<AppChatProvider>(
        builder: (context, chatProvider, _) {
          if (chatProvider.conversations.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'No conversations yet.\nStart chatting!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: chatProvider.conversations.length,
            itemBuilder: (context, index) {
              final conversation = chatProvider.conversations[index];
              final isSelected = chatProvider.currentConversation?.id == conversation.id;

              return Container(
                margin: const EdgeInsets.only(bottom: 4),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.blue.shade50 : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListTile(
                  title: Text(
                    conversation.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14),
                  ),
                  subtitle: Text(
                    _formatDate(conversation.updatedAt),
                    style: const TextStyle(fontSize: 12),
                  ),
                  onTap: () => chatProvider.setCurrentConversation(conversation),
                  dense: true,
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildChatHeader(AppChatProvider chatProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: Color(0xFF3B82F6),
            child: Icon(Icons.auto_awesome, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'AI Assistant',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              Text(
                chatProvider.messages.isEmpty
                    ? 'Start a conversation'
                    : '${chatProvider.messages.length} messages',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList(AppChatProvider chatProvider) {
    if (chatProvider.messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.chat_bubble_outline, size: 48, color: Color(0xFF3B82F6)),
            ),
            const SizedBox(height: 24),
            const Text(
              'Start a conversation',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Ask me anything about beauty, skincare, or hairstyles',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: chatProvider.messages.length,
      itemBuilder: (context, index) {
        final message = chatProvider.messages[index];
        return _MessageBubble(message: message);
      },
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 12),
          Text('AI is thinking...', style: TextStyle(color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        children: [
          if (_selectedImage != null)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              height: 100,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF3B82F6)),
              ),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(_selectedImage!, fit: BoxFit.cover, width: double.infinity),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => setState(() => _selectedImage = null),
                    ),
                  ),
                ],
              ),
            ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.image_outlined),
                onPressed: _pickImage,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    hintText: 'Type your message...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  maxLines: null,
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF3B82F6),
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
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            const CircleAvatar(
              radius: 16,
              backgroundColor: Color(0xFF3B82F6),
              child: Icon(Icons.auto_awesome, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 600),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isUser ? const Color(0xFF3B82F6) : const Color(0xFFF1F3F5),
                borderRadius: BorderRadius.circular(12),
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
                      color: isUser ? Colors.white : Colors.black87,
                      fontSize: 15,
                    ),
                  ),
                  if (message.hasGeneratedImage) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isUser ? Colors.white.withOpacity(0.2) : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AI Generated Image',
                            style: TextStyle(
                              fontSize: 12,
                              color: isUser ? Colors.white70 : Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: _buildImage(
                              message.generatedImageUrl,
                              message.generatedImageBase64,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(message.createdAt),
                    style: TextStyle(
                      fontSize: 11,
                      color: isUser ? Colors.white70 : Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            const CircleAvatar(
              radius: 16,
              backgroundColor: Color(0xFF6B7280),
              child: Icon(Icons.person, color: Colors.white, size: 16),
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
