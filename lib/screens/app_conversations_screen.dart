import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_auth_provider.dart';
import '../providers/app_chat_provider.dart';
import '../models/conversation.dart';
import 'app_chat_screen.dart';

class AppConversationsScreen extends StatefulWidget {
  const AppConversationsScreen({super.key});

  @override
  State<AppConversationsScreen> createState() => _AppConversationsScreenState();
}

class _AppConversationsScreenState extends State<AppConversationsScreen> {
  bool _sidebarExpanded = true;
  bool _hasError = false;
  String? _initializedUserId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeApp();
    });
  }

  Future<void> _initializeApp() async {
    try {
      final authProvider = context.read<AppAuthProvider>();
      final chatProvider = context.read<AppChatProvider>();

      if (authProvider.user != null) {
        _initializedUserId = authProvider.user!.uid;
        chatProvider.loadConversations(_initializedUserId!);
        await chatProvider.initialize();
        setState(() => _hasError = false);
      }
    } catch (e) {
      print('❌ Error initializing app: $e');
      setState(() => _hasError = true);
    }
  }

  Future<void> _startNewConversation() async {
    try {
      final chatProvider = context.read<AppChatProvider>();
      chatProvider.clearCurrentConversation();
    } catch (e) {
      _showError('Failed to start new chat: ${e.toString()}');
    }
  }

  Future<void> _openConversation(Conversation conversation) async {
    try {
      final chatProvider = context.read<AppChatProvider>();
      await chatProvider.setCurrentConversation(conversation);
    } catch (e) {
      _showError('Failed to load conversation: ${e.toString()}');
    }
  }

  Future<void> _deleteConversation(Conversation conversation) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D2D),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title:
            const Text('Delete chat?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'This will delete this chat permanently.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final chatProvider = context.read<AppChatProvider>();
        await chatProvider.deleteConversation(conversation.id);
        if (chatProvider.currentConversation?.id == conversation.id) {
          chatProvider.clearCurrentConversation();
        }
      } catch (e) {
        _showError('Failed to delete chat: ${e.toString()}');
      }
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D2D),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Log out?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to log out?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Log out'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final authProvider = context.read<AppAuthProvider>();
        await authProvider.signOut();
      } catch (e) {
        _showError('Failed to log out: ${e.toString()}');
      }
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red.shade700,
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

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AppAuthProvider>();
    final currentUserId = authProvider.user?.uid;
    if (currentUserId != null && currentUserId != _initializedUserId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _initializeApp();
        }
      });
    }

    return Scaffold(
      backgroundColor: const Color(0xFF343541),
      body: _hasError ? _buildErrorState() : _buildMainContent(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline,
                size: 48,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Oops! Something went wrong',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'We couldn\'t load the app properly.',
              style: TextStyle(color: Colors.white70, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _initializeApp,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF9333EA),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    final authProvider = context.watch<AppAuthProvider>();
    final chatProvider = context.watch<AppChatProvider>();

    return Row(
      children: [
        // Sidebar
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: _sidebarExpanded ? 260 : 0,
          child: _sidebarExpanded
              ? _buildSidebar(authProvider, chatProvider)
              : null,
        ),

        // Main Content
        Expanded(
          child: Column(
            children: [
              _buildTopBar(),
              if (!chatProvider.backendHealthy)
                _buildBackendWarning(chatProvider),
              const Expanded(
                child: AppChatScreen(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSidebar(
      AppAuthProvider authProvider, AppChatProvider chatProvider) {
    return Container(
      color: const Color(0xFF202123),
      child: Column(
        children: [
          // New Chat Button
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: InkWell(
              onTap: _startNewConversation,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white24),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.add, color: Colors.white, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'New chat',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Chat History
          Expanded(
            child: chatProvider.conversations.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'No chats yet\nStart a new conversation!',
                        style: TextStyle(color: Colors.white38, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemCount: chatProvider.conversations.length,
                    itemBuilder: (context, index) {
                      final conversation = chatProvider.conversations[index];
                      final isSelected = chatProvider.currentConversation?.id ==
                          conversation.id;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: InkWell(
                          onTap: () => _openConversation(conversation),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color:
                                  isSelected ? const Color(0xFF343541) : null,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.chat_bubble_outline,
                                    color: Colors.white70, size: 16),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    conversation.title,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (isSelected)
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline,
                                        size: 16),
                                    color: Colors.white38,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: () =>
                                        _deleteConversation(conversation),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // User Info & Logout
          Container(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Colors.white12)),
            ),
            child: InkWell(
              onTap: _logout,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: const Color(0xFF9333EA),
                      child: Text(
                        authProvider.user?.displayName
                                .substring(0, 1)
                                .toUpperCase() ??
                            'U',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        authProvider.user?.displayName ?? 'User',
                        style:
                            const TextStyle(color: Colors.white, fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(Icons.logout, color: Colors.white38, size: 16),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: 60,
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white12)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(_sidebarExpanded ? Icons.menu_open : Icons.menu),
            color: Colors.white,
            onPressed: () {
              setState(() {
                _sidebarExpanded = !_sidebarExpanded;
              });
            },
          ),
          const Expanded(
            child: Center(
              child: Text(
                'Salon Buff',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildBackendWarning(AppChatProvider chatProvider) {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.orange.withOpacity(0.2),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: Colors.orange, size: 20),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'AI backend is not reachable. Please start the backend server.',
              style: TextStyle(color: Colors.orange, fontSize: 13),
            ),
          ),
          TextButton(
            onPressed: () => chatProvider.initialize(),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
