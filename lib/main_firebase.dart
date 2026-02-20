import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'providers/app_auth_provider.dart';
import 'providers/app_chat_provider.dart';
import 'screens/app_login_screen.dart';
import 'screens/app_conversations_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const BeautyAIApp());
}

class BeautyAIApp extends StatelessWidget {
  const BeautyAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppAuthProvider()),
        ChangeNotifierProvider(create: (_) => AppChatProvider()),
      ],
      child: MaterialApp(
        title: 'Buff Salon - Beauty AI',
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark().copyWith(
          primaryColor: const Color(0xFF9333EA),
          scaffoldBackgroundColor: const Color(0xFF1F2937),
          cardColor: const Color(0xFF374151),
          colorScheme: ColorScheme.dark(
            primary: const Color(0xFF9333EA),
            secondary: const Color(0xFFEC4899),
            surface: const Color(0xFF374151),
          ),
        ),
        home: Consumer<AppAuthProvider>(
          builder: (context, auth, _) {
            if (auth.isLoading) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF9333EA),
                  ),
                ),
              );
            }

            return auth.isAuthenticated
                ? const AppConversationsScreen()
                : const AppLoginScreen();
          },
        ),
      ),
    );
  }
}
