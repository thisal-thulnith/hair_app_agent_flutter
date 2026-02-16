import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
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

  Future<void> _handleLogout() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.logout();

    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    return Scaffold(
      body: Stack(
        children: [
          _buildAnimatedBackground(isDark),
          _buildDecorativeOrbs(isDark),
          CustomScrollView(
            slivers: [
              _buildGlassAppBar(context, isDark),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      _buildAvatar(isDark),
                      const SizedBox(height: 24),
                      _buildUserInfo(user?.fullName ?? 'User', isDark),
                      const SizedBox(height: 8),
                      _buildUserEmail(user?.email ?? '', isDark),
                      const SizedBox(height: 32),
                      _buildHistoryButton(context, isDark),
                      const SizedBox(height: 16),
                      _buildLogoutButton(isDark),
                    ],
                  ),
                ),
              ),
            ],
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

  Widget _buildGlassAppBar(BuildContext context, bool isDark) {
    return SliverAppBar(
      expandedHeight: 0,
      floating: true,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: isDark
                  ? AppTheme.charcoalSurface.withOpacity(0.6)
                  : AppTheme.pearlSurface.withOpacity(0.7),
              border: Border(
                bottom: BorderSide(
                  color: AppTheme.gold.withOpacity(isDark ? 0.2 : 0.15),
                  width: 0.5,
                ),
              ),
            ),
          ),
        ),
      ),
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_rounded,
          color: isDark ? Colors.white : Colors.black87,
        ),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Text(
        'Profile',
        style: GoogleFonts.playfairDisplay(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: isDark ? AppTheme.gold : AppTheme.charcoal,
        ),
      ),
    );
  }

  Widget _buildAvatar(bool isDark) {
    return Container(
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
        border: Border.all(
          color: AppTheme.gold,
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.gold.withOpacity(0.3),
            blurRadius: 30,
          ),
        ],
      ),
      child: Icon(
        Icons.person_rounded,
        size: 50,
        color: AppTheme.gold,
      ),
    );
  }

  Widget _buildUserInfo(String name, bool isDark) {
    return Text(
      name,
      style: GoogleFonts.playfairDisplay(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: isDark ? Colors.white : Colors.black87,
      ),
    );
  }

  Widget _buildUserEmail(String email, bool isDark) {
    return Text(
      email,
      style: GoogleFonts.poppins(
        fontSize: 14,
        color: (isDark ? Colors.white : Colors.black87).withOpacity(0.6),
      ),
    );
  }

  Widget _buildHistoryButton(BuildContext context, bool isDark) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: isDark
                ? AppTheme.charcoalMuted.withOpacity(0.7)
                : AppTheme.pearlSurface.withOpacity(0.9),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppTheme.gold.withOpacity(isDark ? 0.15 : 0.1),
              width: 0.5,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                Navigator.of(context).pushNamed('/history');
              },
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Icon(
                      Icons.history_rounded,
                      color: AppTheme.gold,
                      size: 28,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Consultation History',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'View your past beauty consultations',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: (isDark ? Colors.white : Colors.black87)
                                  .withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: AppTheme.gold.withOpacity(0.5),
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton(bool isDark) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _handleLogout,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.red.shade400, Colors.red.shade600],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.logout_rounded, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  'Logout',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
