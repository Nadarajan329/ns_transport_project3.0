import 'dart:math';
import 'package:flutter/material.dart';

class GlitterEffect extends StatefulWidget {
  final Widget child;
  const GlitterEffect({super.key, required this.child});

  @override
  State<GlitterEffect> createState() => _GlitterEffectState();
}

class _GlitterEffectState extends State<GlitterEffect> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<GlitterParticle> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 10))
      ..addListener(() {
        setState(() {
          _updateParticles();
        });
      })
      ..repeat();

    for (int i = 0; i < 60; i++) {
      _particles.add(_generateParticle());
    }
  }

  GlitterParticle _generateParticle() {
    return GlitterParticle(
      x: _random.nextDouble(),
      y: _random.nextDouble(),
      size: _random.nextDouble() * 2 + 0.5,
      opacity: _random.nextDouble(),
      speed: _random.nextDouble() * 0.05 + 0.02,
      phase: _random.nextDouble() * pi * 2,
    );
  }

  void _updateParticles() {
    for (var particle in _particles) {
      particle.phase += particle.speed;
      // Opacity goes from 0 to 1
      particle.opacity = (sin(particle.phase) + 1) / 2;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: GlitterPainter(_particles),
            ),
          ),
        ),
      ],
    );
  }
}

class GlitterParticle {
  double x;
  double y;
  double size;
  double opacity;
  double speed;
  double phase;

  GlitterParticle({
    required this.x,
    required this.y,
    required this.size,
    required this.opacity,
    required this.speed,
    required this.phase,
  });
}

class GlitterPainter extends CustomPainter {
  final List<GlitterParticle> particles;

  GlitterPainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      final paint = Paint()
        ..color = Colors.white.withOpacity(particle.opacity * 0.7)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.0);
      
      canvas.drawCircle(
        Offset(particle.x * size.width, particle.y * size.height),
        particle.size,
        paint,
      );
      
      // Draw cross-star for premium glitter when opacity is high
      if (particle.opacity > 0.6) {
        final centerX = particle.x * size.width;
        final centerY = particle.y * size.height;
        final s = particle.size * 2.5; // Star size
        
        final path = Path()
          ..moveTo(centerX, centerY - s)
          ..lineTo(centerX + s * 0.2, centerY - s * 0.2)
          ..lineTo(centerX + s, centerY)
          ..lineTo(centerX + s * 0.2, centerY + s * 0.2)
          ..lineTo(centerX, centerY + s)
          ..lineTo(centerX - s * 0.2, centerY + s * 0.2)
          ..lineTo(centerX - s, centerY)
          ..lineTo(centerX - s * 0.2, centerY - s * 0.2)
          ..close();
          
        canvas.drawPath(path, paint..color = Colors.white.withOpacity(particle.opacity * 0.9));
      }
    }
  }

  @override
  bool shouldRepaint(covariant GlitterPainter oldDelegate) => true;
}
