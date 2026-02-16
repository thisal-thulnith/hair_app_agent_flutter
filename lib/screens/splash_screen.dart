import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _bgAnimController;

  @override
  void initState() {
    super.initState();
    _bgAnimController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _bgAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          _buildAnimatedBackground(isDark),
          _buildDecorativeOrbs(isDark),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Glowing logo
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.gold.withOpacity(0.3),
                        AppTheme.roseGold.withOpacity(0.3)
                      ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.gold.withOpacity(0.3),
                        blurRadius: 50,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.spa_rounded,
                    size: 50,
                    color: AppTheme.gold,
                  ),
                ),
                const SizedBox(height: 30),
                CircularProgressIndicator(
                  color: AppTheme.gold,
                  strokeWidth: 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedBackground(bool isDark) {
    return AnimatedBuilder(
      animation: _bgAnimController,
      builder: (context, child) {
        final t = _bgAnimController.value;
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(-1.0 + t * 0.5, -1.0),
              end: Alignment(1.0, 1.0 - t * 0.5),
              colors: isDark
                  ? [
                      AppTheme.charcoal,
                      AppTheme.charcoalSurface,
                      const Color(0xFF15101F),
                      AppTheme.charcoal,
                    ]
                  : [
                      AppTheme.pearl,
                      const Color(0xFFFFF5EE),
                      const Color(0xFFFCF0F5),
                      AppTheme.pearl,
                    ],
              stops: [0.0, 0.3 + t * 0.1, 0.7 - t * 0.1, 1.0],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDecorativeOrbs(bool isDark) {
    return AnimatedBuilder(
      animation: _bgAnimController,
      builder: (context, child) {
        final t = _bgAnimController.value;
        return Stack(
          children: [
            Positioned(
              top: -60 + 20 * math.sin(t * math.pi),
              right: -40 + 15 * math.cos(t * math.pi),
              child: _blurOrb(
                180,
                isDark
                    ? AppTheme.gold.withOpacity(0.06)
                    : AppTheme.roseGold.withOpacity(0.12),
              ),
            ),
            Positioned(
              bottom: 100 + 30 * math.cos(t * math.pi * 0.7),
              left: -60 + 20 * math.sin(t * math.pi * 0.7),
              child: _blurOrb(
                220,
                isDark
                    ? AppTheme.lavender.withOpacity(0.04)
                    : AppTheme.lavender.withOpacity(0.1),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _blurOrb(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
              color: color, blurRadius: size * 0.6, spreadRadius: size * 0.2)
        ],
      ),
    );
  }
}
