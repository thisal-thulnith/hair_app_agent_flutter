import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/chat_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/history_screen.dart';
import 'providers/auth_provider.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: const SalonBuffApp(),
    ),
  );
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

  @override
  void initState() {
    super.initState();
    // Initialize auth provider to check for saved token
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AuthProvider>(context, listen: false).initialize();
    });
  }

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
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/chat': (context) => ChatScreen(
              onToggleTheme: toggleTheme,
              isDark: isDark,
            ),
        '/profile': (context) => const ProfileScreen(),
        '/history': (context) => const HistoryScreen(),
      },
      // Skip authentication for now - go directly to chat
      home: ChatScreen(
        onToggleTheme: toggleTheme,
        isDark: isDark,
      ),
    );
  }
}
