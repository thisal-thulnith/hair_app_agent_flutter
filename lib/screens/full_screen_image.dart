import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class FullScreenImage extends StatelessWidget {
  final String? imageUrl;
  final Uint8List? imageBytes;
  final String tag;

  const FullScreenImage({
    super.key,
    this.imageUrl,
    this.imageBytes,
    required this.tag,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: Hero(
          tag: tag,
          child: InteractiveViewer(
            panEnabled: true,
            boundaryMargin: const EdgeInsets.all(20),
            minScale: 0.5,
            maxScale: 4,
            child: imageBytes != null
                ? Image.memory(
                    imageBytes!,
                    fit: BoxFit.contain,
                  )
                : Image.network(
                    imageUrl!,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.broken_image,
                              color: Colors.white54, size: 48),
                          SizedBox(height: 16),
                          Text(
                            'Could not load image',
                            style: TextStyle(color: Colors.white54),
                          ),
                        ],
                      );
                    },
                  ),
          ),
        ),
      ),
    );
  }
}
