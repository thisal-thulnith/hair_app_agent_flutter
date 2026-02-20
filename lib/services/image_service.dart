import 'dart:convert';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import '../config/environment.dart';

class ImageService {
  static final ImageService _instance = ImageService._internal();
  factory ImageService() => _instance;
  ImageService._internal();

  final ImagePicker _picker = ImagePicker();

  /// Pick image from gallery
  Future<Uint8List?> pickFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: Environment.maxImageWidth.toDouble(),
        maxHeight: Environment.maxImageHeight.toDouble(),
        imageQuality: Environment.imageQuality,
      );

      if (image == null) return null;

      return await _compressImage(await image.readAsBytes());
    } catch (e) {
      throw Exception('Failed to pick image from gallery: $e');
    }
  }

  /// Pick image from camera
  Future<Uint8List?> pickFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: Environment.maxImageWidth.toDouble(),
        maxHeight: Environment.maxImageHeight.toDouble(),
        imageQuality: Environment.imageQuality,
      );

      if (image == null) return null;

      return await _compressImage(await image.readAsBytes());
    } catch (e) {
      throw Exception('Failed to take photo: $e');
    }
  }

  /// Compress image bytes
  Future<Uint8List> _compressImage(Uint8List imageBytes) async {
    try {
      final compressed = await FlutterImageCompress.compressWithList(
        imageBytes,
        minWidth: Environment.maxImageWidth,
        minHeight: Environment.maxImageHeight,
        quality: Environment.imageQuality,
      );

      return Uint8List.fromList(compressed);
    } catch (e) {
      // If compression fails, return original
      return imageBytes;
    }
  }

  /// Convert image bytes to base64 string
  String toBase64(Uint8List imageBytes) {
    return base64Encode(imageBytes);
  }

  /// Convert base64 string to image bytes
  Uint8List fromBase64(String base64String) {
    return base64Decode(base64String);
  }

  /// Get image size in MB
  double getSizeMB(Uint8List imageBytes) {
    return imageBytes.length / (1024 * 1024);
  }

  /// Check if image size is within limits (max 5MB)
  bool isWithinSizeLimit(Uint8List imageBytes, {double maxMB = 5.0}) {
    return getSizeMB(imageBytes) <= maxMB;
  }
}
