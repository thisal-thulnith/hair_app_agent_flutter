import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'providers/app_auth_provider.dart';
import 'providers/app_chat_provider.dart';
import 'screens/final_buff_login.dart';
import 'screens/final_buff_chat.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set system UI to transparent
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
    ),
  );

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    print('❌ Firebase initialization error: $e');
  }

  runApp(const BuffApp());
}

class BuffApp extends StatelessWidget {
  const BuffApp({super.key});

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
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFFFFD700),
            secondary: Color(0xFFFFA500),
            surface: Color(0xFF1A1A1A),
            background: Color(0xFF0F0F0F),
          ),
          scaffoldBackgroundColor: const Color(0xFF0F0F0F),
        ),
        home: const AppRoot(),
      ),
    );
  }
}

class AppRoot extends StatelessWidget {
  const AppRoot({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppAuthProvider>(
      builder: (context, authProvider, child) {
        if (authProvider.isLoading) {
          return const LoadingScreen();
        }

        if (!authProvider.isAuthenticated) {
          return const FinalBuffLogin();
        }

        return const FinalBuffChat();
      },
    );
  }
}

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Loading Buff...',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
