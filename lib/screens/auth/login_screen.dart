import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:ns_transport/core/constants/app_colors.dart';
import 'package:ns_transport/routes/app_routes.dart';
import 'package:ns_transport/widgets/custom_button.dart';
import 'package:ns_transport/widgets/custom_text_field.dart';
import 'package:ns_transport/providers/auth_provider.dart';
import 'package:ns_transport/models/user_model.dart';
import 'package:ns_transport/utils/error_handler.dart';
import 'dart:ui';
import 'package:ns_transport/widgets/animated_background.dart';
import 'package:ns_transport/widgets/custom_logo.dart';

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
        SnackBar(content: Text(ErrorHandler.getFriendlyMessage(e))),
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
        SnackBar(content: Text(ErrorHandler.getFriendlyMessage(e))),
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
                  SnackBar(content: Text(ErrorHandler.getFriendlyMessage(e))),
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
                      SnackBar(content: Text(ErrorHandler.getFriendlyMessage(e))),
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

    return Scaffold(
      backgroundColor: const Color(0xFFF0F5FA), // Light blue background
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo Section
                const Center(
                  child: CustomLogo(size: 1.2, isLightOnDark: false),
                ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
                
                const SizedBox(height: 40),
                
                // Welcome Text
                Text(
                  'Welcome Back! 👋',
                  style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ).animate().slideX(begin: -0.1, duration: 400.ms).fadeIn(),
                
                const SizedBox(height: 8),
                
                Text(
                  'Manage trips, drivers, vehicles\nand reports efficiently.',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ).animate().slideX(begin: -0.1, delay: 100.ms, duration: 400.ms).fadeIn(),
                
                const SizedBox(height: 32),
                
                // Form Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        CustomTextField(
                          controller: _emailController,
                          label: 'Email Address',
                          prefixIcon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          isGlassmorphic: false,
                          validator: (val) {
                            if (val == null || val.isEmpty) return 'Enter your email';
                            if (!val.contains('@')) return 'Please enter a valid email';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        CustomTextField(
                          controller: _passwordController,
                          label: 'Password',
                          prefixIcon: Icons.lock_outline,
                          isPassword: true,
                          isGlassmorphic: false,
                          validator: (val) => val == null || val.isEmpty ? 'Enter your password' : null,
                        ),
                        const SizedBox(height: 16),
                        
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Checkbox(
                                  value: false,
                                  onChanged: (val) {},
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                ),
                                Text('Remember Me', style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 14)),
                              ],
                            ),
                            TextButton(
                              onPressed: _showForgotPasswordDialog,
                              child: Text(
                                'Forgot Password?',
                                style: GoogleFonts.inter(
                                  color: AppColors.primary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 24),
                        CustomButton(
                          text: 'LOGIN',
                          onPressed: _login,
                          isLoading: _isLoading,
                          isGradient: false,
                        ),
                        
                        const SizedBox(height: 32),
                        Row(
                          children: [
                            const Expanded(child: Divider()),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                'OR CONTINUE WITH',
                                style: GoogleFonts.inter(color: AppColors.textHint, fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ),
                            const Expanded(child: Divider()),
                          ],
                        ),
                        const SizedBox(height: 24),
                        
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _googleLogin,
                                icon: const Icon(Icons.g_mobiledata, color: Colors.red, size: 28),
                                label: Text('Continue with Google', style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13)),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  side: BorderSide(color: Colors.grey.shade300),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {},
                                icon: const Icon(Icons.phone_iphone, color: Colors.black87, size: 24),
                                label: Text('Continue with Phone', style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13)),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  side: BorderSide(color: Colors.grey.shade300),
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 32),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Don't have an account? ",
                              style: GoogleFonts.inter(color: AppColors.textSecondary),
                            ),
                            GestureDetector(
                              onTap: () => Navigator.pushNamed(context, AppRoutes.register),
                              child: Text(
                                'Create Account',
                                style: GoogleFonts.inter(color: AppColors.primary, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ).animate().slideY(begin: 0.1, delay: 200.ms, duration: 400.ms).fadeIn(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
