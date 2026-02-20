import 'package:flutter/material.dart';
import '../../theme/salon_theme.dart';

class ProfessionalSplashScreen extends StatefulWidget {
  const ProfessionalSplashScreen({super.key});

  @override
  State<ProfessionalSplashScreen> createState() => _ProfessionalSplashScreenState();
}

class _ProfessionalSplashScreenState extends State<ProfessionalSplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              SalonTheme.softCream,
              Colors.white,
              SalonTheme.softCream,
            ],
          ),
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value,
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo with golden glow
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: SalonTheme.primaryGradient,
                          boxShadow: SalonTheme.goldGlow,
                        ),
                        child: const Icon(
                          Icons.auto_awesome,
                          size: 64,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Brand Name
                      ShaderMask(
                        shaderCallback: (bounds) => SalonTheme.primaryGradient
                            .createShader(bounds),
                        child: Text(
                          'Buff Salon',
                          style: Theme.of(context).textTheme.displayLarge?.copyWith(
                                color: Colors.white,
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -1.5,
                              ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Tagline
                      Text(
                        'Your AI Beauty Expert',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: SalonTheme.deepPurple,
                              letterSpacing: 2,
                              fontWeight: FontWeight.w300,
                            ),
                      ),
                      const SizedBox(height: 48),

                      // Loading indicator
                      SizedBox(
                        width: 40,
                        height: 40,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            SalonTheme.primaryGold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
