import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/beauty_chat_provider.dart';
import '../services/image_service.dart';
import '../widgets/beauty_message_bubble.dart';
import '../widgets/beauty_image_preview.dart';

class BeautyChatScreen extends StatefulWidget {
  const BeautyChatScreen({super.key});

  @override
  State<BeautyChatScreen> createState() => _BeautyChatScreenState();
}

class _BeautyChatScreenState extends State<BeautyChatScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImageService _imageService = ImageService();
  late AnimationController _gradientController;

  Uint8List? _selectedImageBytes;
  bool _isDark = true;

  @override
  void initState() {
    super.initState();
    _gradientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();

    // Load messages if conversation is already set
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chatProvider =
          Provider.of<BeautyChatProvider>(context, listen: false);
      if (chatProvider.currentConversation != null) {
        chatProvider.loadMessages(chatProvider.currentConversation!.id);
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _gradientController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
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
  }

  Future<void> _pickImage(ImageSource source) async {
    final bytes = source == ImageSource.gallery
        ? await _imageService.pickFromGallery()
        : await _imageService.pickFromCamera();

    if (bytes != null) {
      setState(() {
        _selectedImageBytes = bytes;
      });
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty && _selectedImageBytes == null) return;

    final chatProvider = Provider.of<BeautyChatProvider>(context, listen: false);

    _messageController.clear();
    final imageToSend = _selectedImageBytes;
    setState(() {
      _selectedImageBytes = null;
    });

    final success = await chatProvider.sendMessage(
      text: text.isNotEmpty ? text : 'Please analyze this image',
      imageBytes: imageToSend,
    );

    if (success) {
      _scrollToBottom();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(chatProvider.error ?? 'Failed to send message'),
          backgroundColor: Colors.red.shade400,
        ),
      );
    }
  }

  void _showImageSourcePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _isDark ? const Color(0xFF374151) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library, color: Color(0xFF9333EA)),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xFF9333EA)),
              title: const Text('Take a Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Animated gradient background
          AnimatedBuilder(
            animation: _gradientController,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: _isDark
                        ? [
                            Color.lerp(
                              const Color(0xFF1F2937),
                              const Color(0xFF374151),
                              _gradientController.value,
                            )!,
                            Color.lerp(
                              const Color(0xFF374151),
                              const Color(0xFF4B5563),
                              _gradientController.value,
                            )!,
                          ]
                        : [
                            Color.lerp(
                              const Color(0xFFFCF5F3),
                              const Color(0xFFFFF5F7),
                              _gradientController.value,
                            )!,
                            Color.lerp(
                              const Color(0xFFFFF5F7),
                              const Color(0xFFF5F3FF),
                              _gradientController.value,
                            )!,
                          ],
                  ),
                ),
              );
            },
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
                            color: Color(0xFF9333EA),
                          ),
                        );
                      }

                      if (chatProvider.messages.isEmpty) {
                        return _buildEmptyState();
                      }

                      return ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 20,
                        ),
                        itemCount: chatProvider.messages.length,
                        itemBuilder: (context, index) {
                          final message = chatProvider.messages[index];
                          return BeautyMessageBubble(
                            message: message,
                            isDark: _isDark,
                          );
                        },
                      );
                    },
                  ),
                ),
                _buildInputArea(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: (_isDark ? Colors.black : Colors.white).withOpacity(0.3),
        border: Border(
          bottom: BorderSide(
            color: (_isDark ? Colors.white : Colors.black).withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF9333EA), Color(0xFFEC4899)],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Consumer<BeautyChatProvider>(
                  builder: (context, chatProvider, _) {
                    return Text(
                      chatProvider.currentConversation?.title ??
                          'Beauty Consultant',
                      style: TextStyle(
                        color: _isDark ? Colors.white : Colors.black87,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    );
                  },
                ),
                Text(
                  'AI Assistant',
                  style: TextStyle(
                    color: (_isDark ? Colors.white : Colors.black87)
                        .withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              _isDark ? Icons.light_mode : Icons.dark_mode,
              color: _isDark ? Colors.white : Colors.black87,
            ),
            onPressed: () {
              setState(() {
                _isDark = !_isDark;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF9333EA), Color(0xFFEC4899)],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.auto_awesome,
              size: 48,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Start a Conversation',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: _isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Ask me anything about beauty, hair styling, or upload a photo for personalized advice!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: (_isDark ? Colors.white : Colors.black87).withOpacity(0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Consumer<BeautyChatProvider>(
      builder: (context, chatProvider, _) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: (_isDark ? Colors.black : Colors.white).withOpacity(0.3),
            border: Border(
              top: BorderSide(
                color: (_isDark ? Colors.white : Colors.black).withOpacity(0.1),
                width: 1,
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_selectedImageBytes != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: BeautyImagePreview(
                    imageBytes: _selectedImageBytes!,
                    onRemove: () {
                      setState(() {
                        _selectedImageBytes = null;
                      });
                    },
                  ),
                ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.add_photo_alternate),
                    color: const Color(0xFF9333EA),
                    onPressed: chatProvider.isSending
                        ? null
                        : _showImageSourcePicker,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      enabled: !chatProvider.isSending,
                      maxLines: null,
                      textInputAction: TextInputAction.newline,
                      style: TextStyle(
                        color: _isDark ? Colors.white : Colors.black87,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Ask me anything...',
                        hintStyle: TextStyle(
                          color: (_isDark ? Colors.white : Colors.black87)
                              .withOpacity(0.5),
                        ),
                        filled: true,
                        fillColor:
                            (_isDark ? Colors.white : Colors.black).withOpacity(0.1),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  chatProvider.isSending
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF9333EA),
                            ),
                          ),
                        )
                      : Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF9333EA), Color(0xFFEC4899)],
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
        );
      },
    );
  }
}
