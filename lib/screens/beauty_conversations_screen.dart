import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import '../providers/beauty_chat_provider.dart';
import '../widgets/beauty_conversation_item.dart';
import 'beauty_chat_screen.dart';

class BeautyConversationsScreen extends StatefulWidget {
  const BeautyConversationsScreen({super.key});

  @override
  State<BeautyConversationsScreen> createState() =>
      _BeautyConversationsScreenState();
}

class _BeautyConversationsScreenState extends State<BeautyConversationsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isDark = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    // Load conversations on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<BeautyChatProvider>(context, listen: false)
          .loadConversations();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _startNewConversation() async {
    final chatProvider = Provider.of<BeautyChatProvider>(context, listen: false);
    chatProvider.clearCurrentConversation();

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const BeautyChatScreen(),
        ),
      );
    }
  }

  Future<void> _openConversation(int conversationId) async {
    final chatProvider = Provider.of<BeautyChatProvider>(context, listen: false);
    await chatProvider.loadMessages(conversationId);

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const BeautyChatScreen(),
        ),
      );
    }
  }

  Future<void> _deleteConversation(int conversationId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _isDark ? const Color(0xFF374151) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'Delete Conversation',
          style: TextStyle(
            color: _isDark ? Colors.white : Colors.black87,
          ),
        ),
        content: Text(
          'Are you sure you want to delete this conversation?',
          style: TextStyle(
            color: _isDark ? Colors.white70 : Colors.black54,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: _isDark ? Colors.white70 : Colors.black54,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final chatProvider =
          Provider.of<BeautyChatProvider>(context, listen: false);
      await chatProvider.deleteConversation(conversationId);
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Animated gradient background
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: _isDark
                        ? [
                            Color.lerp(
                              const Color(0xFF9333EA),
                              const Color(0xFF3B82F6),
                              _controller.value,
                            )!,
                            Color.lerp(
                              const Color(0xFF3B82F6),
                              const Color(0xFF6366F1),
                              _controller.value,
                            )!,
                          ]
                        : [
                            Color.lerp(
                              const Color(0xFFFCF5F3),
                              const Color(0xFFFFF5F7),
                              _controller.value,
                            )!,
                            Color.lerp(
                              const Color(0xFFFFF5F7),
                              const Color(0xFFF5F3FF),
                              _controller.value,
                            )!,
                          ],
                  ),
                ),
              );
            },
          ),

          // Decorative blobs
          Positioned(
            top: -100,
            right: -100,
            child: FadeIn(
              duration: const Duration(seconds: 2),
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withOpacity(0.1),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          Positioned(
            bottom: -150,
            left: -150,
            child: FadeIn(
              duration: const Duration(seconds: 2),
              delay: const Duration(milliseconds: 500),
              child: Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withOpacity(0.1),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: Consumer<BeautyChatProvider>(
                    builder: (context, chatProvider, _) {
                      if (chatProvider.isLoading) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: Colors.white,
                          ),
                        );
                      }

                      if (chatProvider.conversations.isEmpty) {
                        return _buildEmptyState();
                      }

                      return RefreshIndicator(
                        color: Colors.white,
                        backgroundColor: const Color(0xFF9333EA),
                        onRefresh: () async {
                          await chatProvider.loadConversations();
                        },
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: chatProvider.conversations.length,
                          itemBuilder: (context, index) {
                            final conversation =
                                chatProvider.conversations[index];
                            return FadeInUp(
                              duration: Duration(
                                milliseconds: 300 + (index * 100),
                              ),
                              child: BeautyConversationItem(
                                conversation: conversation,
                                isDark: _isDark,
                                onTap: () =>
                                    _openConversation(conversation.id),
                                onDelete: () =>
                                    _deleteConversation(conversation.id),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Floating Action Button
          Positioned(
            right: 20,
            bottom: 20,
            child: FadeInUp(
              duration: const Duration(milliseconds: 800),
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF9333EA), Color(0xFFEC4899)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF9333EA).withOpacity(0.5),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _startNewConversation,
                    borderRadius: BorderRadius.circular(30),
                    child: const Padding(
                      padding: EdgeInsets.all(18),
                      child: Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Colors.white, Color(0xFFEC4899)],
                    ).createShader(bounds),
                    child: const Text(
                      'Buff Salon',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Your Beauty Conversations',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: Icon(
                  _isDark ? Icons.light_mode : Icons.dark_mode,
                  color: Colors.white,
                ),
                onPressed: () {
                  setState(() {
                    _isDark = !_isDark;
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: FadeInUp(
        duration: const Duration(milliseconds: 800),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chat_bubble_outline,
                size: 64,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Conversations Yet',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Start a new conversation to get personalized beauty advice from our AI consultant!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _startNewConversation,
              icon: const Icon(Icons.add, color: Color(0xFF9333EA)),
              label: const Text(
                'Start New Conversation',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF9333EA),
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
