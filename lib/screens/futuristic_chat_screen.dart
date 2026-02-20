import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_auth_provider.dart';
import '../providers/app_chat_provider.dart';
import '../models/message.dart';
import '../models/conversation.dart';
import '../theme/futuristic_theme.dart';

class FuturisticChatScreen extends StatefulWidget {
  const FuturisticChatScreen({super.key});

  @override
  State<FuturisticChatScreen> createState() => _FuturisticChatScreenState();
}

class _FuturisticChatScreenState extends State<FuturisticChatScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Uint8List? _selectedImage;
  bool _showSidebar = true;

  late AnimationController _sidebarController;
  late Animation<double> _sidebarAnimation;

  @override
  void initState() {
    super.initState();
    _initializeApp();

    _sidebarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _sidebarAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _sidebarController, curve: Curves.easeOut),
    );

    _sidebarController.forward();
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
    _sidebarController.dispose();
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

  void _toggleSidebar() {
    setState(() => _showSidebar = !_showSidebar);
    if (_showSidebar) {
      _sidebarController.forward();
    } else {
      _sidebarController.reverse();
    }
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
            backgroundColor: FuturisticTheme.accentError,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              FuturisticTheme.bgPrimary,
              FuturisticTheme.bgSecondary,
              FuturisticTheme.bgPrimary,
            ],
          ),
        ),
        child: Row(
          children: [
            // Sidebar
            if (_showSidebar)
              SizeTransition(
                sizeFactor: _sidebarAnimation,
                axis: Axis.horizontal,
                child: _buildSidebar(),
              ),

            // Main Chat Area
            Expanded(
              child: Column(
                children: [
                  _buildHeader(),
                  Expanded(child: _buildMessagesList()),
                  Consumer<AppChatProvider>(
                    builder: (context, chatProvider, _) {
                      if (chatProvider.isSending) {
                        return _buildTypingIndicator();
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                  _buildMessageInput(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 300,
      decoration: BoxDecoration(
        color: FuturisticTheme.glassLight,
        border: Border(
          right: BorderSide(
            color: FuturisticTheme.border.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          _buildSidebarHeader(),
          const SizedBox(height: FuturisticTheme.md),
          _buildNewChatButton(),
          const SizedBox(height: FuturisticTheme.md),
          Expanded(child: _buildConversationsList()),
          _buildSidebarFooter(),
        ],
      ),
    );
  }

  Widget _buildSidebarHeader() {
    return Container(
      padding: const EdgeInsets.all(FuturisticTheme.lg),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: FuturisticTheme.border.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: FuturisticTheme.md,
              vertical: FuturisticTheme.sm,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  FuturisticTheme.accentPrimary.withOpacity(0.2),
                  FuturisticTheme.accentSecondary.withOpacity(0.2),
                ],
              ),
              borderRadius: BorderRadius.circular(FuturisticTheme.radiusSm),
              border: Border.all(
                color: FuturisticTheme.accentPrimary.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: const Text(
              'BUFF',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: 3,
                color: FuturisticTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewChatButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: FuturisticTheme.md),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () {
            context.read<AppChatProvider>().clearCurrentConversation();
          },
          icon: const Icon(Icons.add, size: 18),
          label: const Text('New Chat'),
          style: ElevatedButton.styleFrom(
            backgroundColor: FuturisticTheme.accentPrimary,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildConversationsList() {
    return Consumer<AppChatProvider>(
      builder: (context, chatProvider, _) {
        if (chatProvider.conversations.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(FuturisticTheme.lg),
              child: Text(
                'No conversations yet.\nStart chatting!',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: FuturisticTheme.sm),
          itemCount: chatProvider.conversations.length,
          itemBuilder: (context, index) {
            final conversation = chatProvider.conversations[index];
            final isSelected =
                chatProvider.currentConversation?.id == conversation.id;

            return _ConversationTile(
              conversation: conversation,
              isSelected: isSelected,
              onTap: () => chatProvider.setCurrentConversation(conversation),
            );
          },
        );
      },
    );
  }

  Widget _buildSidebarFooter() {
    return Container(
      padding: const EdgeInsets.all(FuturisticTheme.md),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: FuturisticTheme.border.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: Consumer<AppAuthProvider>(
        builder: (context, auth, _) {
          return Column(
            children: [
              ListTile(
                leading: const Icon(Icons.settings_outlined, size: 20),
                title: const Text('Settings', style: TextStyle(fontSize: 14)),
                onTap: () {},
                dense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: FuturisticTheme.md,
                ),
              ),
              ListTile(
                leading: const Icon(Icons.logout, size: 20),
                title: const Text('Sign Out', style: TextStyle(fontSize: 14)),
                onTap: () => auth.signOut(),
                dense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: FuturisticTheme.md,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(FuturisticTheme.md),
      decoration: BoxDecoration(
        color: FuturisticTheme.glassLight,
        border: Border(
          bottom: BorderSide(
            color: FuturisticTheme.border.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              _showSidebar ? Icons.menu_open : Icons.menu,
              color: FuturisticTheme.textSecondary,
            ),
            onPressed: _toggleSidebar,
          ),
          const SizedBox(width: FuturisticTheme.sm),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  FuturisticTheme.accentPrimary,
                  FuturisticTheme.accentSecondary,
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: FuturisticTheme.glowShadow(
                FuturisticTheme.accentPrimary,
              ),
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: FuturisticTheme.textPrimary,
              size: 18,
            ),
          ),
          const SizedBox(width: FuturisticTheme.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'AI Assistant',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: FuturisticTheme.textPrimary,
                ),
              ),
              Consumer<AppChatProvider>(
                builder: (context, chatProvider, _) {
                  return Text(
                    chatProvider.messages.isEmpty
                        ? 'Online'
                        : '${chatProvider.messages.length} messages',
                    style: const TextStyle(
                      fontSize: 12,
                      color: FuturisticTheme.textMuted,
                    ),
                  );
                },
              ),
            ],
          ),
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
                    gradient: LinearGradient(
                      colors: [
                        FuturisticTheme.accentPrimary.withOpacity(0.2),
                        FuturisticTheme.accentSecondary.withOpacity(0.2),
                      ],
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: FuturisticTheme.accentPrimary.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.chat_bubble_outline,
                    size: 36,
                    color: FuturisticTheme.accentPrimary,
                  ),
                ),
                const SizedBox(height: FuturisticTheme.lg),
                const Text(
                  'Start a conversation',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: FuturisticTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: FuturisticTheme.sm),
                const Text(
                  'Ask me anything about beauty, skincare, or hairstyles',
                  style: TextStyle(
                    color: FuturisticTheme.textMuted,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(FuturisticTheme.lg),
          itemCount: chatProvider.messages.length,
          itemBuilder: (context, index) {
            final message = chatProvider.messages[index];
            return _MessageBubble(message: message);
          },
        );
      },
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.all(FuturisticTheme.md),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  FuturisticTheme.accentPrimary,
                  FuturisticTheme.accentSecondary,
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: FuturisticTheme.textPrimary,
              size: 16,
            ),
          ),
          const SizedBox(width: FuturisticTheme.md),
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                FuturisticTheme.accentPrimary,
              ),
            ),
          ),
          const SizedBox(width: FuturisticTheme.md),
          const Text(
            'AI is thinking...',
            style: TextStyle(
              color: FuturisticTheme.textMuted,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(FuturisticTheme.md),
      decoration: BoxDecoration(
        color: FuturisticTheme.glassLight,
        border: Border(
          top: BorderSide(
            color: FuturisticTheme.border.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          if (_selectedImage != null)
            Container(
              margin: const EdgeInsets.only(bottom: FuturisticTheme.md),
              height: 100,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(FuturisticTheme.radiusMd),
                border: Border.all(
                  color: FuturisticTheme.accentPrimary,
                  width: 2,
                ),
              ),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(FuturisticTheme.radiusMd - 2),
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
                          color: Colors.black.withOpacity(0.7),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: FuturisticTheme.textPrimary,
                          size: 16,
                        ),
                      ),
                      onPressed: () => setState(() => _selectedImage = null),
                    ),
                  ),
                ],
              ),
            ),
          Row(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.image_outlined,
                  color: FuturisticTheme.textSecondary,
                ),
                onPressed: _pickImage,
              ),
              const SizedBox(width: FuturisticTheme.sm),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: FuturisticTheme.bgTertiary,
                    borderRadius: BorderRadius.circular(FuturisticTheme.radiusLg),
                    border: Border.all(
                      color: FuturisticTheme.border,
                      width: 1,
                    ),
                  ),
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Type your message...',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    maxLines: null,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
              ),
              const SizedBox(width: FuturisticTheme.sm),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      FuturisticTheme.accentPrimary,
                      FuturisticTheme.accentSecondary,
                    ],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: FuturisticTheme.glowShadow(
                    FuturisticTheme.accentPrimary,
                  ),
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.send,
                    color: FuturisticTheme.textPrimary,
                    size: 20,
                  ),
                  onPressed: _sendMessage,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final Conversation conversation;
  final bool isSelected;
  final VoidCallback onTap;

  const _ConversationTile({
    required this.conversation,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: isSelected
            ? FuturisticTheme.accentPrimary.withOpacity(0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(FuturisticTheme.radiusMd),
        border: Border.all(
          color: isSelected
              ? FuturisticTheme.accentPrimary.withOpacity(0.3)
              : Colors.transparent,
          width: 1,
        ),
      ),
      child: ListTile(
        title: Text(
          conversation.title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: FuturisticTheme.textPrimary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          _formatDate(conversation.updatedAt),
          style: const TextStyle(
            fontSize: 12,
            color: FuturisticTheme.textMuted,
          ),
        ),
        onTap: onTap,
        dense: true,
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
      padding: const EdgeInsets.only(bottom: FuturisticTheme.md),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    FuturisticTheme.accentPrimary,
                    FuturisticTheme.accentSecondary,
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: FuturisticTheme.glowShadow(
                  FuturisticTheme.accentPrimary,
                ),
              ),
              child: const Icon(
                Icons.auto_awesome,
                color: FuturisticTheme.textPrimary,
                size: 16,
              ),
            ),
            const SizedBox(width: FuturisticTheme.sm),
          ],
          Flexible(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 600),
              padding: const EdgeInsets.all(FuturisticTheme.md),
              decoration: BoxDecoration(
                gradient: isUser
                    ? LinearGradient(
                        colors: [
                          FuturisticTheme.accentPrimary,
                          FuturisticTheme.accentSecondary,
                        ],
                      )
                    : null,
                color: isUser ? null : FuturisticTheme.bgTertiary,
                borderRadius: BorderRadius.circular(FuturisticTheme.radiusMd),
                border: Border.all(
                  color: isUser
                      ? Colors.transparent
                      : FuturisticTheme.border,
                  width: 1,
                ),
                boxShadow: isUser
                    ? FuturisticTheme.glowShadow(FuturisticTheme.accentPrimary)
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message.hasUploadedImage) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(FuturisticTheme.radiusSm),
                      child: _buildImage(message.imageUrl, message.userImageBase64),
                    ),
                    const SizedBox(height: FuturisticTheme.sm),
                  ],
                  Text(
                    message.content,
                    style: TextStyle(
                      color: FuturisticTheme.textPrimary,
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),
                  if (message.hasGeneratedImage) ...[
                    const SizedBox(height: FuturisticTheme.md),
                    Container(
                      padding: const EdgeInsets.all(FuturisticTheme.sm),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(FuturisticTheme.radiusSm),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'AI Generated Image',
                            style: TextStyle(
                              fontSize: 11,
                              color: FuturisticTheme.textMuted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: FuturisticTheme.sm),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(FuturisticTheme.radiusSm),
                            child: _buildImage(
                              message.generatedImageUrl,
                              message.generatedImageBase64,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: FuturisticTheme.xs),
                  Text(
                    _formatTime(message.createdAt),
                    style: TextStyle(
                      fontSize: 11,
                      color: isUser
                          ? FuturisticTheme.textPrimary.withOpacity(0.7)
                          : FuturisticTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: FuturisticTheme.sm),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: FuturisticTheme.bgTertiary,
                shape: BoxShape.circle,
                border: Border.all(
                  color: FuturisticTheme.border,
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.person,
                color: FuturisticTheme.textSecondary,
                size: 16,
              ),
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
