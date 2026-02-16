import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/consultation.dart';
import '../services/history_service.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _bgAnimController;
  final HistoryService _historyService = HistoryService();

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
          Column(
            children: [
              _buildGlassAppBar(context, isDark),
              Expanded(
                child: FutureBuilder<List<Consultation>>(
                  future: _historyService.getConsultationHistory(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return _buildLoading(isDark);
                    }

                    if (snapshot.hasError) {
                      return _buildError(snapshot.error.toString(), isDark);
                    }

                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return _buildEmptyState(isDark);
                    }

                    return _buildHistoryList(snapshot.data!, isDark);
                  },
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
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 12,
            bottom: 14,
            left: 20,
            right: 20,
          ),
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
          child: Row(
            children: [
              IconButton(
                icon: Icon(
                  Icons.arrow_back_rounded,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
              Expanded(
                child: Text(
                  'Consultation History',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppTheme.gold : AppTheme.charcoal,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 48), // Balance the back button
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoading(bool isDark) {
    return Center(
      child: CircularProgressIndicator(
        color: AppTheme.gold,
        strokeWidth: 2,
      ),
    );
  }

  Widget _buildError(String error, bool isDark) {
    // Handle authentication errors
    if (error.contains('Authentication expired')) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        await authProvider.logout();
        Navigator.of(context).pushReplacementNamed('/login');
      });
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.all(32),
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    size: 64,
                    color: Colors.red.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error Loading History',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    error.replaceAll('Exception: ', ''),
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color:
                          (isDark ? Colors.white : Colors.black87).withOpacity(0.6),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {}); // Trigger rebuild to retry
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.gold,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Try Again',
                      style: GoogleFonts.poppins(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.all(32),
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.history_rounded,
                    size: 64,
                    color: AppTheme.gold.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Consultations Yet',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start a conversation with your AI beauty assistant to see your consultation history here.',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color:
                          (isDark ? Colors.white : Colors.black87).withOpacity(0.6),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryList(List<Consultation> consultations, bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: consultations.length,
      itemBuilder: (context, index) {
        final consultation = consultations[index];
        return _buildConsultationCard(consultation, isDark);
      },
    );
  }

  Widget _buildConsultationCard(Consultation consultation, bool isDark) {
    final dateFormat = DateFormat('MMM d, yyyy • h:mm a');

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.all(20),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Timestamp
                Row(
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: 14,
                      color: AppTheme.gold.withOpacity(0.7),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      dateFormat.format(consultation.timestamp),
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: (isDark ? Colors.white : Colors.black87)
                            .withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Message
                Text(
                  'Your Question:',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.gold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  consultation.message,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),

                // Response
                Text(
                  'AI Response:',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.roseGold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  consultation.response,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color:
                        (isDark ? Colors.white : Colors.black87).withOpacity(0.8),
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
