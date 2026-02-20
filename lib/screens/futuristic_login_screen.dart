import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_auth_provider.dart';
import '../theme/futuristic_theme.dart';

class FuturisticLoginScreen extends StatefulWidget {
  const FuturisticLoginScreen({super.key});

  @override
  State<FuturisticLoginScreen> createState() => _FuturisticLoginScreenState();
}

class _FuturisticLoginScreenState extends State<FuturisticLoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  bool _isSignUp = false;
  bool _isLoading = false;
  bool _obscurePassword = true;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _toggleMode() {
    setState(() {
      _isSignUp = !_isSignUp;
      _animationController.reset();
      _animationController.forward();
    });
  }

  Future<void> _handleEmailAuth() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<AppAuthProvider>();

      if (_isSignUp) {
        await authProvider.registerWithEmailPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          displayName: _nameController.text.trim(),
        );
      } else {
        await authProvider.signInWithEmailPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: FuturisticTheme.accentError,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(FuturisticTheme.radiusMd),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleAuth() async {
    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<AppAuthProvider>();
      await authProvider.signInWithGoogle();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: FuturisticTheme.accentError,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(FuturisticTheme.radiusMd),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              FuturisticTheme.bgPrimary,
              FuturisticTheme.bgSecondary,
              FuturisticTheme.bgPrimary,
            ],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 800;

              return Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: isWide ? 0 : 24,
                    vertical: 32,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isWide ? 480 : double.infinity,
                    ),
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: Container(
                          padding: const EdgeInsets.all(FuturisticTheme.xl),
                          decoration: BoxDecoration(
                            color: FuturisticTheme.glassLight,
                            borderRadius: BorderRadius.circular(
                              FuturisticTheme.radiusXl,
                            ),
                            border: Border.all(
                              color: FuturisticTheme.borderLight.withOpacity(0.3),
                              width: 1,
                            ),
                            boxShadow: FuturisticTheme.cardShadow,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildHeader(),
                              const SizedBox(height: FuturisticTheme.xxl),
                              _buildForm(),
                              const SizedBox(height: FuturisticTheme.lg),
                              _buildDivider(),
                              const SizedBox(height: FuturisticTheme.lg),
                              _buildGoogleButton(),
                              const SizedBox(height: FuturisticTheme.lg),
                              _buildToggleButton(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Logo with glow effect
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: FuturisticTheme.md,
            vertical: FuturisticTheme.sm,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                FuturisticTheme.accentPrimary.withOpacity(0.2),
                FuturisticTheme.accentSecondary.withOpacity(0.2),
              ],
            ),
            borderRadius: BorderRadius.circular(FuturisticTheme.radiusMd),
            border: Border.all(
              color: FuturisticTheme.accentPrimary.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: const Text(
            'BUFF',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: 4,
              color: FuturisticTheme.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: FuturisticTheme.md),
        const Text(
          'AI Beauty Assistant',
          style: TextStyle(
            fontSize: 14,
            color: FuturisticTheme.textMuted,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: FuturisticTheme.xl),
        Text(
          _isSignUp ? 'Create Account' : 'Welcome Back',
          style: Theme.of(context).textTheme.displayMedium,
        ),
        const SizedBox(height: FuturisticTheme.sm),
        Text(
          _isSignUp
              ? 'Sign up to get started'
              : 'Sign in to continue your journey',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          if (_isSignUp) ...[
            _buildTextField(
              controller: _nameController,
              label: 'Full Name',
              hint: 'Enter your name',
              icon: Icons.person_outline,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your name';
                }
                return null;
              },
            ),
            const SizedBox(height: FuturisticTheme.md),
          ],
          _buildTextField(
            controller: _emailController,
            label: 'Email Address',
            hint: 'you@example.com',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your email';
              }
              if (!value.contains('@')) {
                return 'Please enter a valid email';
              }
              return null;
            },
          ),
          const SizedBox(height: FuturisticTheme.md),
          _buildTextField(
            controller: _passwordController,
            label: 'Password',
            hint: '••••••••',
            icon: Icons.lock_outline,
            obscureText: _obscurePassword,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                size: 20,
                color: FuturisticTheme.textMuted,
              ),
              onPressed: () {
                setState(() => _obscurePassword = !_obscurePassword);
              },
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your password';
              }
              if (_isSignUp && value.length < 6) {
                return 'Password must be at least 6 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: FuturisticTheme.xl),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleEmailAuth,
              style: ElevatedButton.styleFrom(
                backgroundColor: FuturisticTheme.accentPrimary,
                disabledBackgroundColor: FuturisticTheme.bgTertiary,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          FuturisticTheme.textPrimary,
                        ),
                      ),
                    )
                  : Text(_isSignUp ? 'Create Account' : 'Sign In'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 20),
        suffixIcon: suffixIcon,
      ),
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      enabled: !_isLoading,
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  FuturisticTheme.border,
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: FuturisticTheme.md),
          child: Text(
            'OR',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  FuturisticTheme.border,
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGoogleButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: _isLoading ? null : _handleGoogleAuth,
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: FuturisticTheme.border,
            width: 1,
          ),
        ),
        icon: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Image.network(
                'https://www.google.com/favicon.ico',
                width: 20,
                height: 20,
                errorBuilder: (_, __, ___) => const Icon(Icons.login, size: 20),
              ),
        label: const Text('Continue with Google'),
      ),
    );
  }

  Widget _buildToggleButton() {
    return Center(
      child: TextButton(
        onPressed: _isLoading ? null : _toggleMode,
        child: RichText(
          text: TextSpan(
            style: Theme.of(context).textTheme.bodyMedium,
            children: [
              TextSpan(
                text: _isSignUp
                    ? 'Already have an account? '
                    : "Don't have an account? ",
              ),
              TextSpan(
                text: _isSignUp ? 'Sign In' : 'Sign Up',
                style: const TextStyle(
                  color: FuturisticTheme.accentPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
