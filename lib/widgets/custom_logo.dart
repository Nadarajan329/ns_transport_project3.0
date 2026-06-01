import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:ns_transport/core/constants/app_colors.dart';

class CustomLogo extends StatelessWidget {
  final double size;
  final bool isLightOnDark;

  const CustomLogo({
    super.key,
    this.size = 1.0,
    this.isLightOnDark = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              'N',
              style: GoogleFonts.montserrat(
                fontSize: 80 * size,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                color: isLightOnDark ? Colors.white : AppColors.primaryDark,
                height: 1.0,
              ),
            ),
            Text(
              'S',
              style: GoogleFonts.montserrat(
                fontSize: 80 * size,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                color: isLightOnDark ? AppColors.primaryLight : AppColors.primary,
                height: 1.0,
              ),
            ),
          ],
        )
        .animate(onPlay: (controller) => controller.repeat(reverse: true))
        .shimmer(duration: 2500.ms, color: Colors.white54),
        
        // Curved road line approximation
        Container(
          height: 6 * size,
          width: 120 * size,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                isLightOnDark ? Colors.white : AppColors.primaryDark,
                isLightOnDark ? AppColors.primaryLight : AppColors.primary,
              ],
            ),
            borderRadius: BorderRadius.circular(10),
          ),
        ).animate().scaleX(duration: 800.ms, curve: Curves.easeOutQuart),
        
        SizedBox(height: 8 * size),
        
        Text(
          'NS TRANSPORT',
          style: GoogleFonts.inter(
            fontSize: 16 * size,
            fontWeight: FontWeight.bold,
            letterSpacing: 2.0,
            color: isLightOnDark ? Colors.white : AppColors.primaryDark,
          ),
        ).animate().fadeIn(delay: 400.ms),
        
        SizedBox(height: 4 * size),
        
        Icon(
          Icons.location_on,
          size: 24 * size,
          color: isLightOnDark ? AppColors.primaryLight : AppColors.primary,
        ).animate(onPlay: (controller) => controller.repeat(reverse: true)).slideY(begin: 0, end: -0.2, duration: 800.ms, curve: Curves.easeInOut).fadeIn(),
      ],
    );
  }
}
