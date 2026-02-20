import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

/// Environment configuration for Beauty AI App
/// Handles platform-specific backend URLs and configuration
class Environment {
  // ============================================
  // Backend URL Configuration
  // ============================================

  /// REMOTE BACKEND URL (ngrok, production server, etc.)
  /// Set this if your backend is hosted remotely (ngrok, cloud server, etc.)
  /// Example: 'https://your-app.ngrok.io' or 'https://api.yourapp.com'
  /// Leave as null to use local development backend
  static const String? remoteBackendUrl = 'https://f46e-123-231-99-27.ngrok-free.app';

  /// Override for physical devices on local network (if not using remote backend)
  /// Find your IP:
  /// - macOS/Linux: Open Terminal → run `ifconfig` → look for inet under en0
  /// - Windows: Open Command Prompt → run `ipconfig` → look for IPv4 Address
  /// Example: static const String? localNetworkIP = '192.168.1.100';
  static const String? localNetworkIP = null;

  /// Get the appropriate backend URL based on platform
  static String get aiBackendUrl {
    // Priority 1: Remote backend URL (ngrok, production, etc.)
    if (remoteBackendUrl != null && remoteBackendUrl!.isNotEmpty) {
      return remoteBackendUrl!;
    }

    // Priority 2: Local network IP (for physical devices on same network)
    if (localNetworkIP != null) {
      return 'http://$localNetworkIP:8000';
    }

    // Priority 3: Platform-specific localhost
    if (kIsWeb) {
      // Web: Use localhost
      return 'http://localhost:8000';
    } else if (Platform.isAndroid) {
      // Android Emulator: 10.0.2.2 maps to host machine's localhost
      // For physical Android device, set localNetworkIP or remoteBackendUrl above
      return 'http://10.0.2.2:8000';
    } else if (Platform.isIOS) {
      // iOS Simulator: localhost works directly
      // For physical iOS device, set localNetworkIP or remoteBackendUrl above
      return 'http://localhost:8000';
    } else {
      // Desktop platforms (macOS, Windows, Linux)
      return 'http://localhost:8000';
    }
  }

  // ============================================
  // API Endpoints
  // ============================================

  static String get aiChatEndpoint => '$aiBackendUrl/chat';
  static String get hairStyleOptionsEndpoint => '$aiBackendUrl/hair-style/options';
  static String get hairStyleSuggestionsEndpoint => '$aiBackendUrl/hair-style/suggestions';
  static String get hairStyleGenerateEndpoint => '$aiBackendUrl/hair-style/generate';
  static String get healthEndpoint => '$aiBackendUrl/health';

  // ============================================
  // App Configuration
  // ============================================

  static const String appName = 'Buff Salon';
  static const String appVersion = '1.0.0';

  // ============================================
  // Image Configuration
  // ============================================

  static const int maxImageWidth = 1024;
  static const int maxImageHeight = 1024;
  static const int imageQuality = 80;

  // ============================================
  // Network Configuration
  // ============================================

  static const Duration connectionTimeout = Duration(seconds: 60);
  static const Duration receiveTimeout = Duration(seconds: 60);

  // ============================================
  // Debug Helpers
  // ============================================

  /// Print current configuration (for debugging)
  static void printConfig() {
    print('🔧 Beauty AI Configuration:');
    print('   Platform: ${_getPlatformName()}');
    print('   Backend URL: $aiBackendUrl');
    print('   Chat Endpoint: $aiChatEndpoint');
  }

  static String _getPlatformName() {
    if (kIsWeb) return 'Web';
    if (Platform.isAndroid) return 'Android';
    if (Platform.isIOS) return 'iOS';
    if (Platform.isMacOS) return 'macOS';
    if (Platform.isWindows) return 'Windows';
    if (Platform.isLinux) return 'Linux';
    return 'Unknown';
  }
}
