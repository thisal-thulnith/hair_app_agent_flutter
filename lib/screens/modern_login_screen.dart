import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_auth_provider.dart';
import '../theme/modern_theme.dart';

class ModernLoginScreen extends StatefulWidget {
  const ModernLoginScreen({super.key});

  @override
  State<ModernLoginScreen> createState() => _ModernLoginScreenState();
}

class _ModernLoginScreenState extends State<ModernLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final authProvider = context.read<AppAuthProvider>();
      await authProvider.signInWithGoogle();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: ModernTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
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
                  constraints: BoxConstraints(maxWidth: isWide ? 400 : double.infinity),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Logo - Simple Text, No Icon
                      Text(
                        'Buff',
                        style: Theme.of(context).textTheme.displayLarge?.copyWith(
                          fontSize: 48,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -2,
                        ),
                      ),
                      const SizedBox(height: 8),

                      Text(
                        'AI Beauty Assistant',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isDark
                            ? ModernTheme.darkTextMuted
                            : ModernTheme.lightTextMuted,
                        ),
                      ),

                      const SizedBox(height: 64),

                      // Welcome text
                      Text(
                        'Welcome back',
                        style: Theme.of(context).textTheme.displaySmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Sign in to continue',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isDark
                            ? ModernTheme.darkTextMuted
                            : ModernTheme.lightTextMuted,
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Email field
                      TextField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email address',
                          hintText: 'you@example.com',
                        ),
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                      ),

                      const SizedBox(height: 16),

                      // Password field
                      TextField(
                        controller: _passwordController,
                        decoration: const InputDecoration(
                          labelText: 'Password',
                          hintText: '••••••••',
                        ),
                        obscureText: true,
                        textInputAction: TextInputAction.done,
                      ),

                      const SizedBox(height: 24),

                      // Sign in button
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : () {},
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Text('Sign in'),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Divider
                      Row(
                        children: [
                          Expanded(child: Divider(color: isDark ? ModernTheme.darkBorder : ModernTheme.lightBorder)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'or',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                          Expanded(child: Divider(color: isDark ? ModernTheme.darkBorder : ModernTheme.lightBorder)),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Google sign in
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton.icon(
                          onPressed: _isLoading ? null : _signInWithGoogle,
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Image.network(
                                  'https://www.google.com/favicon.ico',
                                  width: 20,
                                  height: 20,
                                  errorBuilder: (_, __, ___) => const Icon(Icons.login, size: 20),
                                ),
                          label: const Text('Continue with Google'),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Sign up link
                      Center(
                        child: TextButton(
                          onPressed: () {},
                          child: Text(
                            'Don\'t have an account? Sign up',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
