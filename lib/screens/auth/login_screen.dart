import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ns_transport/core/constants/app_colors.dart';
import 'package:ns_transport/routes/app_routes.dart';
import 'package:ns_transport/widgets/custom_button.dart';
import 'package:ns_transport/widgets/custom_text_field.dart';
import 'package:ns_transport/providers/auth_provider.dart';
import 'package:ns_transport/models/user_model.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await ref.read(authProvider.notifier).signInWithEmail(
        _emailController.text.trim(),
        _passwordController.text,
      );
      // Wait for authProvider listener to navigate
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login failed: ${e.toString()}')),
      );
      setState(() => _isLoading = false);
    }
  }

  Future<void> _googleLogin() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(authProvider.notifier).signInWithGoogle();
      // Wait for authProvider listener to navigate
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Google Login failed: ${e.toString()}')),
      );
      setState(() => _isLoading = false);
    }
  }

  Future<void> _showForgotPasswordDialog() async {
    final emailCtrl = TextEditingController(text: _emailController.text);
    return showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reset Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter your email address to receive a password reset link.'),
            const SizedBox(height: 16),
            TextField(
              controller: emailCtrl,
              decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (emailCtrl.text.isEmpty) return;
              try {
                await ref.read(authProvider.notifier).resetPassword(emailCtrl.text.trim());
                if (!dialogContext.mounted) return;
                Navigator.pop(dialogContext);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Password reset email sent')),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed: $e')),
                );
              }
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  Future<void> _showRoleSelectionDialog(String userId, String email, String? name, String? avatarUrl) async {
    String selectedRole = 'owner';
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setStateBuilder) {
          return AlertDialog(
            title: const Text('Complete Profile'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Please select your role to continue:'),
                const SizedBox(height: 16),
                RadioListTile(
                  title: const Text('Transport Owner'),
                  value: 'owner',
                  groupValue: selectedRole,
                  onChanged: (val) => setStateBuilder(() => selectedRole = val.toString()),
                ),
                RadioListTile(
                  title: const Text('Driver'),
                  value: 'driver',
                  groupValue: selectedRole,
                  onChanged: (val) => setStateBuilder(() => selectedRole = val.toString()),
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () async {
                  try {
                    final userModel = UserModel(
                      id: userId,
                      email: email,
                      name: name ?? 'User',
                      role: selectedRole,
                      avatarUrl: avatarUrl,
                    );

                    // Insert user profile into the users table
                    await ref.read(authServiceProvider).createUserProfile(userModel);

                    // Force a reload of the auth state
                    ref.read(authProvider.notifier).init();

                    if (!dialogContext.mounted) return;
                    Navigator.pop(dialogContext);
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed: $e')),
                    );
                  }
                },
                child: const Text('Save'),
              ),
            ],
          );
        }
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authProvider, (previous, next) {
      if (_isLoading && !next.isLoading && next.value != null) {
        setState(() => _isLoading = false);
        final user = next.value!;
        final homeRoute = user.role == 'owner' ? AppRoutes.ownerDashboard : AppRoutes.driverDashboard;
        Navigator.pushReplacementNamed(context, homeRoute);
      } else if (_isLoading && !next.isLoading && next.value == null) {
        final supaUser = Supabase.instance.client.auth.currentUser;
        if (supaUser != null) {
           // User is authenticated via Google but not yet in our users table
           _showRoleSelectionDialog(
             supaUser.id,
             supaUser.email ?? '',
             supaUser.userMetadata?['full_name'],
             supaUser.userMetadata?['avatar_url'],
           );
        } else {
          setState(() => _isLoading = false);
        }
      } else if (_isLoading && next.hasError) {
        setState(() => _isLoading = false);
      }
    });

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.local_shipping,
                    size: 64,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Welcome Back',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sign in to your account',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: isDark ? Colors.grey.shade400 : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 32),
                  CustomTextField(
                    controller: _emailController,
                    label: 'Email',
                    prefixIcon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: (val) {
                      if (val == null || val.isEmpty) return 'Enter your email';
                      if (!val.contains('@')) return 'Please enter a valid email (e.g. name@gmail.com)';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _passwordController,
                    label: 'Password',
                    prefixIcon: Icons.lock_outline,
                    isPassword: true,
                    validator: (val) => val == null || val.isEmpty ? 'Enter your password' : null,
                  ),
                  const SizedBox(height: 24),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _showForgotPasswordDialog,
                      child: Text(
                        'Forgot Password?',
                        style: GoogleFonts.inter(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  CustomButton(
                    text: 'Login',
                    onPressed: _login,
                    isLoading: _isLoading,
                  ),
                  const SizedBox(height: 16),
                  CustomButton(
                    text: 'Sign in with Google',
                    onPressed: _googleLogin,
                    isOutlined: true,
                    icon: Icons.g_mobiledata,
                    isLoading: _isLoading,
                  ),
                  const SizedBox(height: 24),
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, AppRoutes.register);
                    },
                    child: Text(
                      'Don\'t have an account? Register',
                      style: GoogleFonts.inter(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
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
}
