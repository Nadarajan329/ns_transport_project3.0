import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:ns_transport/widgets/glitter_effect.dart';

class AnimatedBackground extends StatelessWidget {
  final String imagePath;
  
  const AnimatedBackground({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return GlitterEffect(
      child: SizedBox.expand(
        child: Image.asset(
          imagePath,
          fit: BoxFit.cover,
        )
            .animate(
              onPlay: (controller) => controller.repeat(reverse: true),
            )
            .scale(
              begin: const Offset(1.0, 1.0),
              end: const Offset(1.15, 1.15),
              duration: 25.seconds,
              curve: Curves.easeInOutSine,
            ),
      ),
    );
  }
}
