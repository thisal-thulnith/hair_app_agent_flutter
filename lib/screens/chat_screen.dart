import 'dart:typed_data';
import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/chat_message.dart';
import '../services/chat_service.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/message_bubble.dart';
import '../widgets/chat_input.dart';
import '../widgets/typing_indicator.dart';

class ChatScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final bool isDark;

  const ChatScreen({
    super.key,
    required this.onToggleTheme,
    required this.isDark,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final List<ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();
  final ChatService _chatService = ChatService();
  bool _isTyping = false;
  bool _shouldCancelGeneration = false; // Flag to cancel generation
  late String _currentSessionId; // Session ID for conversation tracking

  late AnimationController _bgAnimController;
  late AnimationController _headerAnimController;
  late Animation<double> _headerFade;

  @override
  void initState() {
    super.initState();
    _currentSessionId = const Uuid().v4(); // Generate new session ID

    _bgAnimController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat(reverse: true);

    _headerAnimController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _headerFade = CurvedAnimation(
      parent: _headerAnimController,
      curve: Curves.easeOut,
    );
    _headerAnimController.forward();

    _messages.add(
      ChatMessage(
        text: "Welcome to Salon Buff! ✨ I'm your premium beauty assistant. Ask me about hairstyles, skincare, makeup tips, or upload a photo for personalized advice!",
        isAgent: true,
      ),
    );
  }

  void _startNewConversation() {
    setState(() {
      _currentSessionId = const Uuid().v4();
      _messages.clear();
      _messages.add(ChatMessage(
        text: "Welcome to Salon Buff! ✨ I'm your premium beauty assistant. Ask me about hairstyles, skincare, makeup tips, or upload a photo for personalized advice!",
        isAgent: true,
      ));
    });
    _scrollToBottom();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _bgAnimController.dispose();
    _headerAnimController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _stopGenerating() {
    setState(() {
      _shouldCancelGeneration = true;
      _isTyping = false;
    });
  }

  Future<void> _handleSend(String text, Uint8List? imageBytes, String? imageName) async {
    setState(() {
      _messages.add(ChatMessage(
        text: text.isNotEmpty ? text : null,
        imageBytes: imageBytes,
        imageName: imageName,
        isAgent: false,
      ));
      _isTyping = true;
      _shouldCancelGeneration = false; // Reset cancel flag
    });
    _scrollToBottom();

    try {
      final response = await _chatService.sendMessage(
        message: text,
        sessionId: _currentSessionId,
        imageBytes: imageBytes,
        imageName: imageName,
      );

      // Check if generation was cancelled
      if (_shouldCancelGeneration) {
        setState(() {
          _messages.add(ChatMessage(
            text: "(Generation stopped)",
            isAgent: true,
          ));
          _isTyping = false;
          _shouldCancelGeneration = false;
        });
        return;
      }

      setState(() {
        _messages.add(ChatMessage(
          text: response['response'] as String?,
          imageUrl: response['image'] as String?,
          isAgent: true,
        ));
        _isTyping = false;
      });
    } catch (e) {
      // Check if it was cancelled
      if (_shouldCancelGeneration) {
        setState(() {
          _messages.add(ChatMessage(
            text: "(Generation stopped)",
            isAgent: true,
          ));
          _isTyping = false;
          _shouldCancelGeneration = false;
        });
        return;
      }

      setState(() {
        _messages.add(ChatMessage(
          text: "I'm having trouble connecting right now. Please try again later.",
          isAgent: true,
        ));
        _isTyping = false;
      });
    }
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    // Authentication check disabled for now
    // Can be re-enabled later when auth is needed

    final theme = Theme.of(context);
    final isDark = widget.isDark;

    return Scaffold(
      body: Stack(
        children: [
          // ─── Animated Gradient Background ───
          _buildAnimatedBackground(isDark),

          // ─── Decorative Orbs ───
          _buildDecorativeOrbs(isDark),

          // ─── Main Content ───
          Column(
            children: [
              _buildGlassHeader(context, isDark),
              Expanded(
                child: _messages.isEmpty
                    ? _buildEmptyState(context, isDark)
                    : Column(
                        children: [
                          Expanded(
                            child: ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              itemCount: _messages.length + (_isTyping ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index == _messages.length && _isTyping) {
                                  return const TypingIndicator();
                                }
                                return MessageBubble(message: _messages[index]);
                              },
                            ),
                          ),
                          // Stop generating button
                          if (_isTyping)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _buildStopButton(isDark),
                            ),
                        ],
                      ),
              ),
              ChatInput(onSend: _handleSend, isLoading: _isTyping),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Animated gradient that shifts slowly ───
  Widget _buildAnimatedBackground(bool isDark) {
    return AnimatedBuilder(
      animation: _bgAnimController,
      builder: (context, child) {
        final t = _bgAnimController.value;
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(-1.0 + t * 0.5, -1.0),
              end: Alignment(1.0, 1.0 - t * 0.5),
              colors: isDark
                  ? [
                      AppTheme.charcoal,
                      AppTheme.charcoalSurface,
                      const Color(0xFF15101F), // Hint of deep purple
                      AppTheme.charcoal,
                    ]
                  : [
                      AppTheme.pearl,
                      const Color(0xFFFFF5EE), // Warm seashell
                      const Color(0xFFFCF0F5), // Soft rose mist
                      AppTheme.pearl,
                    ],
              stops: [0.0, 0.3 + t * 0.1, 0.7 - t * 0.1, 1.0],
            ),
          ),
        );
      },
    );
  }

  // ─── Floating decorative blur orbs ───
  Widget _buildDecorativeOrbs(bool isDark) {
    return AnimatedBuilder(
      animation: _bgAnimController,
      builder: (context, child) {
        final t = _bgAnimController.value;
        return Stack(
          children: [
            Positioned(
              top: -60 + 20 * math.sin(t * math.pi),
              right: -40 + 15 * math.cos(t * math.pi),
              child: _blurOrb(
                180,
                isDark ? AppTheme.gold.withOpacity(0.06) : AppTheme.roseGold.withOpacity(0.12),
              ),
            ),
            Positioned(
              bottom: 100 + 30 * math.cos(t * math.pi * 0.7),
              left: -60 + 20 * math.sin(t * math.pi * 0.7),
              child: _blurOrb(
                220,
                isDark ? AppTheme.lavender.withOpacity(0.04) : AppTheme.lavender.withOpacity(0.1),
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).size.height * 0.4,
              right: -80 + 25 * math.sin(t * math.pi * 1.3),
              child: _blurOrb(
                150,
                isDark ? AppTheme.roseGold.withOpacity(0.04) : AppTheme.gold.withOpacity(0.08),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _blurOrb(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: color, blurRadius: size * 0.6, spreadRadius: size * 0.2)],
      ),
    );
  }

  Widget _buildStopButton(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ElevatedButton.icon(
        onPressed: _stopGenerating,
        icon: Icon(Icons.stop_circle_outlined, size: 18),
        label: Text('Stop Generating'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: AppTheme.gold,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: AppTheme.gold.withOpacity(0.5), width: 1.5),
          ),
        ),
      ),
    );
  }

  // ─── Frosted glass header with theme toggle ───
  Widget _buildGlassHeader(BuildContext context, bool isDark) {
    final theme = Theme.of(context);

    return FadeTransition(
      opacity: _headerFade,
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 12,
              bottom: 14,
              left: 20,
              right: 20,
            ),
            decoration: BoxDecoration(
              color: isDark
                  ? AppTheme.charcoalSurface.withOpacity(0.6)
                  : AppTheme.pearlSurface.withOpacity(0.7),
              border: Border(
                bottom: BorderSide(
                  color: AppTheme.gold.withOpacity(isDark ? 0.2 : 0.15),
                  width: 0.5,
                ),
              ),
            ),
            child: Row(
              children: [
                // ─── Profile Button (disabled for now - no auth) ───
                // IconButton(
                //   icon: Icon(Icons.person_rounded, color: AppTheme.gold),
                //   onPressed: () {
                //     Navigator.of(context).pushNamed('/profile');
                //   },
                //   tooltip: 'Profile',
                // ),
                // ─── Title & Subtitle ───
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Salon Buff',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        'AI Beauty Assistant',
                        style: theme.textTheme.bodySmall?.copyWith(
                          letterSpacing: 0.5,
                          color: isDark
                              ? AppTheme.roseGold.withOpacity(0.7)
                              : AppTheme.goldDim.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                // ─── New Conversation Button ───
                IconButton(
                  icon: Icon(Icons.add_circle_outline, color: AppTheme.gold),
                  onPressed: _startNewConversation,
                  tooltip: 'New Conversation',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Empty state with Beauty-themed suggestions ───
  Widget _buildEmptyState(BuildContext context, bool isDark) {
    final theme = Theme.of(context);
    final suggestions = [
      '💇‍♀️  Recommend a hairstyle',
      '💄  Makeup tips for a party',
      '🧴  Best skincare routine',
      '📸  Analyze my photo',
    ];

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Glowing icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.gold.withOpacity(0.2), AppTheme.roseGold.withOpacity(0.2)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: AppTheme.gold.withOpacity(0.15), blurRadius: 30, spreadRadius: 5),
                ],
              ),
              child: Icon(Icons.spa_rounded, size: 36, color: AppTheme.gold),
            ),
            const SizedBox(height: 24),
            Text(
              'Your Beauty Journey Starts Here',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Ask me anything about beauty, hair, skin, or upload a photo!',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            // Suggestion chips
            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: suggestions.map((s) => _buildSuggestionChip(s, isDark)).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionChip(String label, bool isDark) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          // Remove emoji prefix for sending
          final text = label.replaceFirst(RegExp(r'^[^\w]+\s*'), '');
          _handleSend(text, null, null);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: isDark
                ? AppTheme.charcoalMuted.withOpacity(0.6)
                : AppTheme.pearlMuted.withOpacity(0.7),
            border: Border.all(
              color: AppTheme.gold.withOpacity(isDark ? 0.2 : 0.15),
              width: 0.5,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppTheme.textLight : AppTheme.textDark,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
