import 'package:flutter/material.dart';
import 'screens/chat_screen.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SalonBuffApp());
}

class SalonBuffApp extends StatefulWidget {
  const SalonBuffApp({super.key});

  // Global key to access theme toggle from anywhere
  static final GlobalKey<_SalonBuffAppState> appKey = GlobalKey<_SalonBuffAppState>();

  @override
  State<SalonBuffApp> createState() => _SalonBuffAppState();
}

class _SalonBuffAppState extends State<SalonBuffApp> {
  ThemeMode _themeMode = ThemeMode.dark; // Start in dark mode

  void toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    });
  }

  bool get isDark => _themeMode == ThemeMode.dark;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      key: SalonBuffApp.appKey,
      title: 'Salon Buff',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _themeMode,
      home: ChatScreen(
        onToggleTheme: toggleTheme,
        isDark: isDark,
      ),
    );
  }
}
