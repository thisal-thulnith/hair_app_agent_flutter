import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_theme.dart';

class ChatInput extends StatefulWidget {
  final Function(String text, Uint8List? imageBytes, String? imageName) onSend;
  final bool isLoading;

  const ChatInput({
    super.key,
    required this.onSend,
    this.isLoading = false,
  });

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  Uint8List? _selectedImage;
  String? _selectedImageName;

  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _selectedImage = bytes;
          _selectedImageName = image.name;
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  void _clearImage() {
    setState(() {
      _selectedImage = null;
      _selectedImageName = null;
    });
  }

  void _handleSend() {
    final text = _controller.text.trim();
    if (text.isEmpty && _selectedImage == null) return;
    if (widget.isLoading) return;
    widget.onSend(text, _selectedImage, _selectedImageName);
    _controller.clear();
    _clearImage();
  }

  bool get _canSend =>
      !widget.isLoading && (_controller.text.trim().isNotEmpty || _selectedImage != null);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? AppTheme.charcoalSurface.withOpacity(0.7)
                : AppTheme.pearlSurface.withOpacity(0.85),
            border: Border(
              top: BorderSide(
                color: AppTheme.gold.withOpacity(isDark ? 0.15 : 0.1),
                width: 0.5,
              ),
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Image Preview
                if (_selectedImage != null)
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Row(
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.memory(
                                _selectedImage!,
                                width: 64,
                                height: 64,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: -6,
                              right: -6,
                              child: GestureDetector(
                                onTap: _clearImage,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: AppTheme.error,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(color: AppTheme.error.withOpacity(0.3), blurRadius: 6),
                                    ],
                                  ),
                                  child: const Icon(Icons.close, size: 12, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 12),
                        Text('Image attached', style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),

                // Input Row
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      // Image Picker Button
                      _buildIconButton(
                        icon: Icons.add_photo_alternate_rounded,
                        onTap: widget.isLoading ? null : _pickImage,
                        isDark: isDark,
                      ),
                      const SizedBox(width: 10),

                      // Text Field
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppTheme.charcoalMuted.withOpacity(0.6)
                                : AppTheme.pearlMuted.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: AppTheme.gold.withOpacity(isDark ? 0.12 : 0.08),
                              width: 0.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _controller,
                                  enabled: !widget.isLoading,
                                  onChanged: (_) => setState(() {}),
                                  onSubmitted: (_) => _handleSend(),
                                  textInputAction: TextInputAction.send,
                                  style: theme.textTheme.bodyLarge?.copyWith(fontSize: 15),
                                  decoration: InputDecoration(
                                    hintText: 'Ask about beauty, hair, skin...',
                                    hintStyle: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.hintColor.withOpacity(0.4),
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 18, vertical: 14,
                                    ),
                                  ),
                                ),
                              ),
                              // Send Button
                              Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: AnimatedBuilder(
                                  animation: _pulseController,
                                  builder: (context, child) {
                                    final scale = _canSend
                                        ? 1.0 + 0.05 * _pulseController.value
                                        : 1.0;
                                    return Transform.scale(
                                      scale: scale,
                                      child: child,
                                    );
                                  },
                                  child: GestureDetector(
                                    onTap: _canSend ? _handleSend : null,
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 300),
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        gradient: _canSend
                                            ? LinearGradient(
                                                colors: [AppTheme.gold, AppTheme.goldGlow],
                                              )
                                            : null,
                                        color: _canSend ? null : AppTheme.gold.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: _canSend
                                            ? [
                                                BoxShadow(
                                                  color: AppTheme.gold.withOpacity(0.3),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ]
                                            : null,
                                      ),
                                      child: Icon(
                                        Icons.send_rounded,
                                        size: 20,
                                        color: _canSend
                                            ? AppTheme.charcoal
                                            : (isDark ? AppTheme.textLight.withOpacity(0.2) : AppTheme.textDark.withOpacity(0.2)),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback? onTap,
    required bool isDark,
  }) {
    return Material(
      color: isDark
          ? AppTheme.charcoalMuted.withOpacity(0.6)
          : AppTheme.pearlMuted.withOpacity(0.7),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          child: Icon(
            icon,
            size: 22,
            color: onTap == null
                ? Theme.of(context).disabledColor
                : AppTheme.gold.withOpacity(0.8),
          ),
        ),
      ),
    );
  }
}
