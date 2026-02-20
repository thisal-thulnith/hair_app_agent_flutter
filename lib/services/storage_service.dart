import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http_parser/http_parser.dart';
import '../config/environment.dart';

class StorageService {
  final ImagePicker _picker = ImagePicker();
  final Dio _dio = Dio();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Upload image to backend local storage (replaces Firebase Storage)
  Future<String?> uploadChatImage(Uint8List imageBytes) async {
    try {
      // Compress image
      final compressed = await FlutterImageCompress.compressWithList(
        imageBytes,
        minWidth: 1024,
        minHeight: 1024,
        quality: 80,
      );

      // Get current user ID
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Create multipart form data
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          compressed,
          filename: 'chat_${DateTime.now().millisecondsSinceEpoch}.jpg',
          contentType: MediaType('image', 'jpeg'),
        ),
        'user_id': user.uid,
      });

      // Upload to backend
      final response = await _dio.post(
        '${Environment.aiBackendUrl}/upload-image',
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      if (response.statusCode == 200) {
        final imageUrl = response.data['image_url'] as String;
        // Store backend path (e.g., /uploads/...) so history remains portable
        // across web/emulator/device environments.
        return imageUrl;
      } else {
        throw Exception('Upload failed with status ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  Future<Uint8List?> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image == null) return null;
      return await image.readAsBytes();
    } catch (e) {
      throw Exception('Failed to pick image: $e');
    }
  }

  Future<Uint8List?> pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image == null) return null;
      return await image.readAsBytes();
    } catch (e) {
      throw Exception('Failed to take picture: $e');
    }
  }
}
