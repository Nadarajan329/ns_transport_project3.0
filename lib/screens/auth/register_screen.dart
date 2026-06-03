import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ns_transport/core/constants/app_colors.dart';
import 'package:ns_transport/models/user_model.dart';
import 'package:ns_transport/routes/app_routes.dart';
import 'package:ns_transport/widgets/custom_button.dart';
import 'package:ns_transport/widgets/custom_text_field.dart';
import 'package:ns_transport/providers/auth_provider.dart';
import 'package:ns_transport/utils/error_handler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:ui';
import 'package:ns_transport/widgets/animated_background.dart';
import 'package:ns_transport/widgets/custom_logo.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String _selectedRole = 'driver'; // 'owner' or 'driver'

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final userModel = UserModel(
      id: '', // Will be set by backend after creation
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      role: _selectedRole,
    );

    try {
      await ref.read(authProvider.notifier).signUp(
        _emailController.text.trim(),
        _passwordController.text,
        userModel,
      );
      // Wait for authProvider listener to navigate
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ErrorHandler.getFriendlyMessage(e))),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authProvider, (previous, next) {
      if (_isLoading && !next.isLoading && next.value != null) {
        setState(() => _isLoading = false);
        final user = next.value!;
        final homeRoute = user.role == 'owner' ? AppRoutes.ownerDashboard : AppRoutes.driverDashboard;
        Navigator.pushNamedAndRemoveUntil(context, homeRoute, (route) => false);
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
                  child: CustomLogo(size: 1.0, isLightOnDark: false),
                ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
                
                const SizedBox(height: 32),
                
                Text(
                  'Create Your Account',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ).animate().slideY(begin: -0.1, duration: 400.ms).fadeIn(),
                
                const SizedBox(height: 8),
                
                Text(
                  'Join NS Transport and manage your business smartly.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ).animate().slideY(begin: -0.1, delay: 100.ms, duration: 400.ms).fadeIn(),
                
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
                        Text(
                          'Select User Type',
                          style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 16),
                        ),
                        const SizedBox(height: 16),
                        
                        Row(
                          children: [
                            Expanded(
                              child: _RoleCard(
                                title: 'Driver',
                                icon: Icons.local_shipping,
                                subtitle: 'I drive vehicles\nand manage trips',
                                isSelected: _selectedRole == 'driver',
                                onTap: () => setState(() => _selectedRole = 'driver'),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _RoleCard(
                                title: 'Owner',
                                icon: Icons.business,
                                subtitle: 'I own a fleet\nand manage drivers',
                                isSelected: _selectedRole == 'owner',
                                onTap: () => setState(() => _selectedRole = 'owner'),
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 32),
                        Text(
                          'Basic Information',
                          style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 16),
                        ),
                        const SizedBox(height: 16),
                        
                        Row(
                          children: [
                            Expanded(
                              child: CustomTextField(
                                controller: _nameController,
                                label: 'Full Name',
                                prefixIcon: Icons.person_outline,
                                isGlassmorphic: false,
                                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: CustomTextField(
                                label: 'Mobile Number',
                                prefixIcon: Icons.phone_outlined,
                                keyboardType: TextInputType.phone,
                                isGlassmorphic: false,
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: CustomTextField(
                                controller: _emailController,
                                label: 'Email Address',
                                prefixIcon: Icons.email_outlined,
                                keyboardType: TextInputType.emailAddress,
                                isGlassmorphic: false,
                                validator: (val) {
                                  if (val == null || val.isEmpty) return 'Required';
                                  if (!val.contains('@')) return 'Invalid email';
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: CustomTextField(
                                label: 'Confirm Password',
                                prefixIcon: Icons.lock_outline,
                                isPassword: true,
                                isGlassmorphic: false,
                                validator: (val) => val == null || val.length < 6 ? 'Too short' : null,
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: CustomTextField(
                                controller: _passwordController,
                                label: 'Password',
                                prefixIcon: Icons.lock_outline,
                                isPassword: true,
                                isGlassmorphic: false,
                                validator: (val) => val == null || val.length < 6 ? 'Too short' : null,
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Spacer(), // Empty space for half width
                          ],
                        ),
                        
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Checkbox(
                              value: false,
                              onChanged: (val) {},
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                            ),
                            RichText(
                              text: TextSpan(
                                text: 'I agree to ',
                                style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 14),
                                children: [
                                  TextSpan(
                                    text: 'Terms & Conditions',
                                    style: GoogleFonts.inter(color: AppColors.primary, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 24),
                        CustomButton(
                          text: 'CREATE ACCOUNT',
                          onPressed: _register,
                          isLoading: _isLoading,
                          isGradient: false,
                        ),
                        
                        const SizedBox(height: 32),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Already have an account? ",
                              style: GoogleFonts.inter(color: AppColors.textSecondary),
                            ),
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Text(
                                'Login Here',
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

class _RoleCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.title,
    required this.icon,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 40,
              color: isSelected ? AppColors.primary : Colors.grey.shade800,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.textSecondary,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
