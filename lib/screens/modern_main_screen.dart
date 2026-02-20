import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_auth_provider.dart';
import '../providers/app_chat_provider.dart';
import '../theme/modern_theme.dart';
import 'modern_chat_screen.dart';
import '../models/conversation.dart';

class ModernMainScreen extends StatefulWidget {
  const ModernMainScreen({super.key});

  @override
  State<ModernMainScreen> createState() => _ModernMainScreenState();
}

class _ModernMainScreenState extends State<ModernMainScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _darkMode = false;

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

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await context.read<AppAuthProvider>().signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 800;

        return Scaffold(
          key: _scaffoldKey,
          drawer: isWide ? null : _buildDrawer(),
          body: Row(
            children: [
              if (isWide) _buildSidebar(),
              Expanded(
                child: Consumer<AppChatProvider>(
                  builder: (context, chatProvider, _) {
                    if (chatProvider.currentConversation != null) {
                      return const ModernChatScreen();
                    }
                    return _buildWelcomeScreen(isWide);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 240,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          right: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: _buildSidebarContent(),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: _buildSidebarContent(),
    );
  }

  Widget _buildSidebarContent() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(ModernTheme.lg),
          child: Row(
            children: [
              Text(
                'Buff',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),

        // Search
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: ModernTheme.md,
            vertical: ModernTheme.sm,
          ),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search...',
              prefixIcon: const Icon(Icons.search, size: 20),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(ModernTheme.radiusMd),
              ),
            ),
            style: const TextStyle(fontSize: 14),
          ),
        ),

        const SizedBox(height: ModernTheme.sm),

        // New Chat Button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: ModernTheme.md),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                context.read<AppChatProvider>().clearCurrentConversation();
              },
              icon: const Icon(Icons.add, size: 18),
              label: const Text('New Chat'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: ModernTheme.md),

        // Conversations List
        Expanded(
          child: Consumer<AppChatProvider>(
            builder: (context, chatProvider, _) {
              if (chatProvider.conversations.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(ModernTheme.lg),
                    child: Text(
                      'No conversations yet',
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: ModernTheme.sm),
                itemCount: chatProvider.conversations.length,
                itemBuilder: (context, index) {
                  final conversation = chatProvider.conversations[index];
                  final isSelected = chatProvider.currentConversation?.id == conversation.id;

                  return _ConversationTile(
                    conversation: conversation,
                    isSelected: isSelected,
                    onTap: () {
                      chatProvider.setCurrentConversation(conversation);
                    },
                    onDelete: () async {
                      await chatProvider.deleteConversation(conversation.id);
                    },
                  );
                },
              );
            },
          ),
        ),

        // Bottom section
        const Divider(height: 1),

        Padding(
          padding: const EdgeInsets.all(ModernTheme.sm),
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.settings, size: 20),
                title: const Text('Settings', style: TextStyle(fontSize: 14)),
                onTap: () {},
                dense: true,
              ),
              ListTile(
                leading: Icon(
                  _darkMode ? Icons.light_mode : Icons.dark_mode,
                  size: 20,
                ),
                title: const Text('Toggle theme', style: TextStyle(fontSize: 14)),
                onTap: () {
                  setState(() => _darkMode = !_darkMode);
                  // Implement theme toggle
                },
                dense: true,
              ),
              Consumer<AppAuthProvider>(
                builder: (context, auth, _) {
                  return ListTile(
                    leading: const Icon(Icons.logout, size: 20),
                    title: const Text('Sign out', style: TextStyle(fontSize: 14)),
                    onTap: _signOut,
                    dense: true,
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWelcomeScreen(bool isWide) {
    return Center(
      child: Container(
        constraints: BoxConstraints(maxWidth: isWide ? 600 : double.infinity),
        padding: const EdgeInsets.all(ModernTheme.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome to Buff',
              style: Theme.of(context).textTheme.displayLarge,
            ),
            const SizedBox(height: ModernTheme.md),
            Text(
              'Your AI-powered beauty assistant. Start a conversation to get personalized recommendations for skincare, makeup, hairstyles, and more.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).brightness == Brightness.dark
                  ? ModernTheme.darkTextMuted
                  : ModernTheme.lightTextMuted,
              ),
            ),
            const SizedBox(height: ModernTheme.xl),
            ElevatedButton.icon(
              onPressed: () {
                context.read<AppChatProvider>().clearCurrentConversation();
              },
              icon: const Icon(Icons.add),
              label: const Text('Start New Chat'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final Conversation conversation;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ConversationTile({
    required this.conversation,
    required this.isSelected,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: isSelected
            ? (isDark ? ModernTheme.darkBorder : ModernTheme.lightBorder)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(ModernTheme.radiusMd),
      ),
      child: ListTile(
        title: Text(
          conversation.title,
          style: const TextStyle(fontSize: 14),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          _formatDate(conversation.updatedAt),
          style: const TextStyle(fontSize: 12),
        ),
        onTap: onTap,
        dense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: ModernTheme.md,
          vertical: ModernTheme.xs,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
