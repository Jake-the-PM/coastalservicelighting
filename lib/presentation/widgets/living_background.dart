import 'dart:math';
import 'package:flutter/material.dart';

class LivingBackground extends StatefulWidget {
  final Widget? child;
  const LivingBackground({super.key, this.child});

  @override
  State<LivingBackground> createState() => _LivingBackgroundState();
}

class _LivingBackgroundState extends State<LivingBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // Orbiting Blobs
  final List<_LightBlob> _blobs = [
    _LightBlob(color: const Color(0xFFD4AF37), offset: Offset.zero, radius: 1.0), // Gold
    _LightBlob(color: const Color(0xFF1C3A63), offset: const Offset(1, 1), radius: 0.8), // Blue
    _LightBlob(color: const Color(0xFFCF6679), offset: const Offset(0, 1), radius: 0.5), // Red Hint
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 20), // Slow "Breathing"
      vsync: this,
    )..repeat();
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
        // Deep Background
        Container(color: const Color(0xFF050E1C)), // Navy Base

        // Animated Painter
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomPaint(
              painter: _MeshPainter(
                progress: _controller.value,
                blobs: _blobs,
              ),
              size: Size.infinite,
            );
          },
        ),

        // Content
        if (widget.child != null) widget.child!,
      ],
    );
  }
}

class _LightBlob {
  final Color color;
  final Offset offset; // Normalized 0..1 starting pos
  final double radius; // Relative size

  _LightBlob({required this.color, required this.offset, required this.radius});
}

class _MeshPainter extends CustomPainter {
  final double progress;
  final List<_LightBlob> blobs;

  _MeshPainter({required this.progress, required this.blobs});

  @override
  void paint(Canvas canvas, Size size) {
    
    // Animate Blobs in elliptical paths
    for (int i = 0; i < blobs.length; i++) {
        final blob = blobs[i];
        final t = (progress + (i * 0.33)) * 2 * pi; // Offset phases
        
        // Complex Orbit
        final x = (size.width * blob.offset.dx) + (cos(t) * size.width * 0.3);
        final y = (size.height * blob.offset.dy) + (sin(t) * size.height * 0.2);

        final paint = Paint()
          ..color = blob.color.withValues(alpha: 0.15 * blob.radius) // Very subtle
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 80 * blob.radius); // Massive Blur

        canvas.drawCircle(Offset(x, y), size.width * 0.6 * blob.radius, paint);
    }
    
    // Add "Noise" overlay if needed (skipped for performance, can add later)
  }

  @override
  bool shouldRepaint(covariant _MeshPainter oldDelegate) {
     return oldDelegate.progress != progress;
  }
}
