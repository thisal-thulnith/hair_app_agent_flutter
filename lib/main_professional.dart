import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'providers/app_auth_provider.dart';
import 'providers/app_chat_provider.dart';
import 'screens/professional/splash_screen.dart';
import 'screens/professional/login_screen.dart';
import 'screens/professional/home_screen.dart';
import 'theme/salon_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations (portrait for mobile, all for tablet/desktop)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    print('❌ Firebase initialization error: $e');
  }

  runApp(const BuffSalonApp());
}

class BuffSalonApp extends StatelessWidget {
  const BuffSalonApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppAuthProvider()),
        ChangeNotifierProvider(create: (_) => AppChatProvider()),
      ],
      child: MaterialApp(
        title: 'Buff Salon - AI Beauty Assistant',
        debugShowCheckedModeBanner: false,
        theme: SalonTheme.lightTheme,
        darkTheme: SalonTheme.darkTheme,
        themeMode: ThemeMode.light, // Can be changed to ThemeMode.system
        home: const AppNavigator(),
      ),
    );
  }
}

class AppNavigator extends StatelessWidget {
  const AppNavigator({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppAuthProvider>(
      builder: (context, authProvider, child) {
        // Show splash screen while initializing
        if (authProvider.isLoading) {
          return const ProfessionalSplashScreen();
        }

        // Show login screen if not authenticated
        if (!authProvider.isAuthenticated) {
          return const ProfessionalLoginScreen();
        }

        // Show main app if authenticated
        return const ProfessionalHomeScreen();
      },
    );
  }
}
