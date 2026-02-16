import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:animate_do/animate_do.dart';
import '../models/chat_message.dart';
import '../theme/app_theme.dart';
import '../screens/full_screen_image.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const MessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isAgent = message.isAgent;

    return FadeInUp(
      duration: const Duration(milliseconds: 400),
      from: 20,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Row(
          mainAxisAlignment: isAgent ? MainAxisAlignment.start : MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (isAgent) _buildAvatar(context, isAgent),
            if (isAgent) const SizedBox(width: 10),
            Flexible(child: _buildBubble(context, isAgent)),
            if (!isAgent) const SizedBox(width: 10),
            if (!isAgent) _buildAvatar(context, isAgent),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(BuildContext context, bool isAgent) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        gradient: isAgent
            ? LinearGradient(
                colors: [AppTheme.gold.withOpacity(0.3), AppTheme.roseGold.withOpacity(0.2)],
              )
            : null,
        color: isAgent ? null : Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isAgent ? AppTheme.gold.withOpacity(0.4) : Colors.transparent,
          width: 1,
        ),
        boxShadow: isAgent
            ? [BoxShadow(color: AppTheme.gold.withOpacity(0.15), blurRadius: 8, offset: const Offset(0, 2))]
            : null,
      ),
      child: Icon(
        isAgent ? Icons.auto_awesome : Icons.person_rounded,
        size: 17,
        color: isAgent ? AppTheme.gold : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
      ),
    );
  }

  Widget _buildBubble(BuildContext context, bool isAgent) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.72,
      ),
      decoration: BoxDecoration(
        // Agent: Glass effect, User: Gold gradient
        gradient: isAgent
            ? null
            : LinearGradient(colors: [AppTheme.gold, AppTheme.goldGlow]),
        color: isAgent
            ? (isDark
                ? AppTheme.charcoalMuted.withOpacity(0.7)
                : AppTheme.pearlSurface.withOpacity(0.9))
            : null,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(20),
          topRight: const Radius.circular(20),
          bottomLeft: Radius.circular(isAgent ? 4 : 20),
          bottomRight: Radius.circular(isAgent ? 20 : 4),
        ),
        border: isAgent
            ? Border.all(
                color: isDark
                    ? AppTheme.gold.withOpacity(0.15)
                    : AppTheme.gold.withOpacity(0.1),
                width: 0.5,
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: isAgent
                ? Colors.black.withOpacity(isDark ? 0.2 : 0.04)
                : AppTheme.gold.withOpacity(0.25),
            blurRadius: isAgent ? 8 : 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(20),
          topRight: const Radius.circular(20),
          bottomLeft: Radius.circular(isAgent ? 4 : 20),
          bottomRight: Radius.circular(isAgent ? 20 : 4),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (message.hasImage) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _buildImage(context),
                ),
                if (message.hasText) const SizedBox(height: 10),
              ],
              if (message.hasText)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message.text!,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontSize: 14.5,
                        height: 1.5,
                        color: isAgent
                            ? theme.colorScheme.onSurface
                            : AppTheme.charcoal,
                        fontWeight: isAgent ? FontWeight.w400 : FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildActionButtons(context, isAgent),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage(BuildContext context) {
    final String tag = DateTime.now().millisecondsSinceEpoch.toString();

    if (message.imageBytes != null) {
      return GestureDetector(
        onTap: () {
          Navigator.push(context, MaterialPageRoute(
            builder: (context) => FullScreenImage(imageBytes: message.imageBytes, tag: tag),
          ));
        },
        child: Hero(
          tag: tag,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 400),
            child: Image.memory(message.imageBytes!, fit: BoxFit.contain, width: double.infinity),
          ),
        ),
      );
    } else if (message.imageUrl != null) {
      return GestureDetector(
        onTap: () {
          Navigator.push(context, MaterialPageRoute(
            builder: (context) => FullScreenImage(imageUrl: message.imageUrl, tag: tag),
          ));
        },
        child: Hero(
          tag: tag,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 400),
            child: Image.network(
              message.imageUrl!,
              fit: BoxFit.contain,
              width: double.infinity,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  height: 150,
                  color: Theme.of(context).colorScheme.surfaceContainer,
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.gold,
                      strokeWidth: 2,
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 100,
                  color: Theme.of(context).colorScheme.surfaceContainer,
                  child: Center(child: Icon(Icons.broken_image, color: AppTheme.gold.withOpacity(0.5))),
                );
              },
            ),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildActionButtons(BuildContext context, bool isAgent) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final buttonColor = isAgent
        ? (isDark ? Colors.white.withOpacity(0.6) : Colors.black54)
        : Colors.black.withOpacity(0.7);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Copy button
        InkWell(
          onTap: () async {
            if (message.text != null) {
              await Clipboard.setData(ClipboardData(text: message.text!));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Copied to clipboard'),
                    duration: const Duration(seconds: 1),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    margin: const EdgeInsets.all(16),
                    backgroundColor: AppTheme.gold.withOpacity(0.9),
                  ),
                );
              }
            }
          },
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Row(
              children: [
                Icon(
                  Icons.copy_rounded,
                  size: 14,
                  color: buttonColor,
                ),
                const SizedBox(width: 4),
                Text(
                  'Copy',
                  style: TextStyle(
                    fontSize: 11,
                    color: buttonColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
