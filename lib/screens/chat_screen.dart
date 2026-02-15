import 'dart:typed_data';
import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/chat_message.dart';
import '../services/chat_service.dart';
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

  late AnimationController _bgAnimController;
  late AnimationController _headerAnimController;
  late Animation<double> _headerFade;

  @override
  void initState() {
    super.initState();
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

  Future<void> _handleSend(String text, Uint8List? imageBytes, String? imageName) async {
    setState(() {
      _messages.add(ChatMessage(
        text: text.isNotEmpty ? text : null,
        imageBytes: imageBytes,
        imageName: imageName,
        isAgent: false,
      ));
      _isTyping = true;
    });
    _scrollToBottom();

    try {
      final response = await _chatService.sendMessage(
        message: text,
        imageBytes: imageBytes,
        imageName: imageName,
      );
      setState(() {
        _messages.add(ChatMessage(
          text: response['response'] as String?,
          imageUrl: response['image'] as String?,
          isAgent: true,
        ));
        _isTyping = false;
      });
    } catch (e) {
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
                    : ListView.builder(
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
                // ─── Theme Toggle Button (Spacing Fix) ───
                const SizedBox(width: 44), // To balance the toggle button on the right
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
