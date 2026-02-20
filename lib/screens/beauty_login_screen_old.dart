import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import '../providers/beauty_auth_provider.dart';
import '../services/api_service.dart';
import '../widgets/beauty_registration_modal.dart';

class BeautyLoginScreen extends StatefulWidget {
  const BeautyLoginScreen({super.key});

  @override
  State<BeautyLoginScreen> createState() => _BeautyLoginScreenState();
}

class _BeautyLoginScreenState extends State<BeautyLoginScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleGoogleSignIn() async {
    final authProvider = Provider.of<BeautyAuthProvider>(context, listen: false);

    try {
      final success = await authProvider.signInWithGoogle();
      if (success && mounted) {
        // Navigate to conversations screen
        Navigator.of(context).pushReplacementNamed('/conversations');
      }
    } on NewUserException catch (e) {
      // Show registration modal for new users
      if (mounted) {
        final userType = await showModalBottomSheet<String>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => const BeautyRegistrationModal(),
        );

        if (userType != null && mounted) {
          // Complete registration with selected user type
          final success = await authProvider.completeRegistration(
            idToken: e.idToken,
            userType: userType,
          );

          if (success && mounted) {
            Navigator.of(context).pushReplacementNamed('/conversations');
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sign in failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<BeautyAuthProvider>(context);

    return Scaffold(
      body: Stack(
        children: [
          // Animated gradient background
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color.lerp(
                        const Color(0xFF9333EA), // Purple
                        const Color(0xFF3B82F6), // Blue
                        _controller.value,
                      )!,
                      Color.lerp(
                        const Color(0xFF3B82F6), // Blue
                        const Color(0xFF6366F1), // Indigo
                        _controller.value,
                      )!,
                    ],
                  ),
                ),
              );
            },
          ),

          // Decorative blobs
          Positioned(
            top: -100,
            right: -100,
            child: FadeIn(
              duration: const Duration(seconds: 2),
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withOpacity(0.1),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          Positioned(
            bottom: -150,
            left: -150,
            child: FadeIn(
              duration: const Duration(seconds: 2),
              delay: const Duration(milliseconds: 500),
              child: Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withOpacity(0.1),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // App logo/icon
                    FadeInDown(
                      duration: const Duration(milliseconds: 800),
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.auto_awesome,
                          size: 64,
                          color: Colors.white,
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // App title
                    FadeInDown(
                      duration: const Duration(milliseconds: 800),
                      delay: const Duration(milliseconds: 200),
                      child: ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [Colors.white, Color(0xFFEC4899)],
                        ).createShader(bounds),
                        child: const Text(
                          'Buff Salon',
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Subtitle
                    FadeInDown(
                      duration: const Duration(milliseconds: 800),
                      delay: const Duration(milliseconds: 400),
                      child: const Text(
                        'AI Beauty Consultant',
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.white70,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ),

                    const SizedBox(height: 64),

                    // Google Sign-In Button
                    FadeInUp(
                      duration: const Duration(milliseconds: 800),
                      delay: const Duration(milliseconds: 600),
                      child: authProvider.isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : ElevatedButton.icon(
                              onPressed: _handleGoogleSignIn,
                              icon: Image.asset(
                                'assets/google_logo.png',
                                height: 24,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.login, color: Colors.black87),
                              ),
                              label: const Text(
                                'Sign in with Google',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32,
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                elevation: 8,
                              ),
                            ),
                    ),

                    const SizedBox(height: 64),

                    // Features list
                    FadeInUp(
                      duration: const Duration(milliseconds: 800),
                      delay: const Duration(milliseconds: 800),
                      child: Column(
                        children: [
                          _buildFeature('💄', 'Personalized beauty advice'),
                          const SizedBox(height: 16),
                          _buildFeature('✂️', 'Virtual hairstyle try-on'),
                          const SizedBox(height: 16),
                          _buildFeature('🛍️', 'Product recommendations'),
                          const SizedBox(height: 16),
                          _buildFeature('📅', 'Salon booking'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeature(String emoji, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            emoji,
            style: const TextStyle(fontSize: 24),
          ),
          const SizedBox(width: 12),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
