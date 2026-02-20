import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/beauty_chat_provider.dart';
import 'services/api_service.dart';
import 'screens/beauty_chat_screen.dart';
import 'screens/beauty_conversations_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize API service
  ApiService().initialize();

  runApp(
    ChangeNotifierProvider(
      create: (_) => BeautyChatProvider(),
      child: const BeautyAIApp(),
    ),
  );
}

class BeautyAIApp extends StatelessWidget {
  const BeautyAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Buff Salon - Beauty AI',
      debugShowCheckedModeBanner: false,
      theme: _buildLightTheme(),
      darkTheme: _buildDarkTheme(),
      themeMode: ThemeMode.dark,
      home: const BeautyConversationsScreen(),
      routes: {
        '/conversations': (context) => const BeautyConversationsScreen(),
        '/chat': (context) => const BeautyChatScreen(),
      },
    );
  }

  ThemeData _buildLightTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF9333EA), // Purple
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: Colors.grey[50],
    );
  }

  ThemeData _buildDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF9333EA), // Purple
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: const Color(0xFF1F2937), // Dark background
      cardColor: const Color(0xFF374151), // Card background
    );
  }
}

