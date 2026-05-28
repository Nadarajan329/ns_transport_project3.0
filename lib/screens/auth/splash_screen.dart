import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ns_transport/core/constants/app_colors.dart';
import 'package:ns_transport/routes/app_routes.dart';
import 'package:ns_transport/providers/auth_provider.dart';


class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _minTimeElapsed = false;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _minTimeElapsed = true;
        });
        _tryNavigate();
      }
    });
  }

  void _tryNavigate() {
    if (!_minTimeElapsed || _navigated) return;
    
    final authState = ref.read(authProvider);
    if (authState.isLoading) return; // Wait for it to finish loading
    
    _navigated = true;
    final user = authState.value;
    
    if (user != null) {
      final homeRoute = user.role == 'owner' ? AppRoutes.ownerDashboard : AppRoutes.driverDashboard;
      Navigator.pushReplacementNamed(context, homeRoute);
    } else {
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authProvider, (previous, next) {
      if (!next.isLoading) {
        _tryNavigate();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.local_shipping,
              size: 80,
              color: AppColors.primary,
            )
            .animate()
            .scale(duration: 600.ms, curve: Curves.easeOutBack)
            .fadeIn(duration: 600.ms),
            const SizedBox(height: 16),
            Text(
              'NS Transport',
              style: GoogleFonts.inter(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            )
            .animate()
            .slideY(begin: 0.5, end: 0, duration: 600.ms, curve: Curves.easeOut)
            .fadeIn(duration: 600.ms),
          ],
        ),
      ),
    );
  }
}
