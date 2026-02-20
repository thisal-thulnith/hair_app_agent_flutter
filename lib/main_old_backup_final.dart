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

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    print('❌ Firebase initialization error: $e');
  }

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
        title: 'Salon Buff - Beauty AI',
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark().copyWith(
          primaryColor: const Color(0xFF8B5CF6),
          scaffoldBackgroundColor: const Color(0xFF0F172A),
          cardColor: const Color(0xFF1E293B),
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF8B5CF6),
            secondary: Color(0xFFEC4899),
            surface: Color(0xFF1E293B),
            background: Color(0xFF0F172A),
          ),
          textTheme: const TextTheme(
            displayLarge: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
            displayMedium: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
            displaySmall: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            headlineMedium: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
            bodyLarge: TextStyle(
              fontSize: 16,
              color: Colors.white,
              height: 1.5,
            ),
            bodyMedium: TextStyle(
              fontSize: 14,
              color: Color(0xFFCBD5E1),
              height: 1.5,
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B5CF6),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: const Color(0xFF1E293B),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF334155)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF334155)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF8B5CF6), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
        home: ErrorBoundary(
          child: Consumer<AppAuthProvider>(
            builder: (context, auth, _) {
              print('🔍 Main Consumer rebuilt:');
              print('   isLoading: ${auth.isLoading}');
              print('   isAuthenticated: ${auth.isAuthenticated}');
              print('   user: ${auth.user?.displayName ?? "null"}');

              if (auth.isLoading) {
                print('   → Showing loading spinner');
                return const Scaffold(
                  backgroundColor: Color(0xFF0F172A),
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 48,
                          height: 48,
                          child: CircularProgressIndicator(
                            color: Color(0xFF8B5CF6),
                            strokeWidth: 3,
                          ),
                        ),
                        SizedBox(height: 20),
                        Text(
                          'Loading Salon Buff...',
                          style: TextStyle(
                            color: Color(0xFFCBD5E1),
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (auth.isAuthenticated) {
                print('   → Showing Conversations Screen');
                return const AppConversationsScreen();
              } else {
                print('   → Showing Login Screen');
                return const AppLoginScreen();
              }
            },
          ),
        ),
      ),
    );
  }
}

/// Error boundary widget
class ErrorBoundary extends StatefulWidget {
  final Widget child;

  const ErrorBoundary({super.key, required this.child});

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  Object? _error;

  @override
  void initState() {
    super.initState();
    FlutterError.onError = (FlutterErrorDetails details) {
      if (mounted) {
        setState(() {
          _error = details.exception;
        });
      }
      FlutterError.presentError(details);
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.red.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.error_outline_rounded,
                    size: 56,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 28),
                const Text(
                  'Oops! Something went wrong',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Don\'t worry, just refresh to try again.',
                  style: TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 15,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _error = null;
                    });
                  },
                  icon: const Icon(Icons.refresh_rounded, size: 20),
                  label: const Text('Reload App'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B5CF6),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                    elevation: 0,
                    shadowColor: const Color(0xFF8B5CF6).withOpacity(0.3),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return widget.child;
  }
}
