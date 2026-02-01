import 'dart:math' as math;
import 'package:flutter/material.dart';

class EffectPreview extends StatefulWidget {
  final String effectName;
  final bool isSelected;

  const EffectPreview({
    super.key,
    required this.effectName,
    this.isSelected = false,
  });

  @override
  State<EffectPreview> createState() => _EffectPreviewState();
}

class _EffectPreviewState extends State<EffectPreview> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // Continuous animation for the "Live" feel
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: widget.isSelected 
            ? Border.all(color: const Color(0xFFD4AF37), width: 1.5) 
            : Border.all(color: Colors.white10),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CustomPaint(
          painter: _EffectPainter(
            effectName: widget.effectName,
            animationValue: _controller,
            isSelected: widget.isSelected,
          ),
        ),
      ),
    );
  }
}

class _EffectPainter extends CustomPainter {
  final String effectName;
  final Animation<double> animationValue;
  final bool isSelected;

  _EffectPainter({
    required this.effectName,
    required this.animationValue,
    required this.isSelected,
  }) : super(repaint: animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final width = size.width;
    final height = size.height;
    final t = animationValue.value;
    
    // Normalize name for matching
    final name = effectName.toLowerCase();

    if (name.contains('solid')) {
      paint.color = const Color(0xFFD4AF37); // Gold
      canvas.drawRect(Rect.fromLTWH(0, 0, width, height), paint);
    } 
    else if (name.contains('breathe') || name.contains('fade')) {
      // Pulse Opacity
      final opacity = 0.3 + 0.7 * (0.5 * (1 + math.sin(t * 2 * math.pi)));
      paint.color = const Color(0xFF0077BE).withOpacity(opacity);
      canvas.drawRect(Rect.fromLTWH(0, 0, width, height), paint);
    } 
    else if (name.contains('rainbow')) {
      // Rotating Gradient
      final shader = LinearGradient(
        colors: const [Colors.red, Colors.orange, Colors.yellow, Colors.green, Colors.blue, Colors.purple, Colors.red],
        stops: const [0.0, 0.16, 0.33, 0.5, 0.66, 0.83, 1.0],
        transform: GradientRotation(t * 2 * math.pi),
      ).createShader(Rect.fromLTWH(0, 0, width, height));
      
      paint.shader = shader;
      canvas.drawRect(Rect.fromLTWH(0, 0, width, height), paint);
    } 
    else if (name.contains('chase') || name.contains('running')) {
      // Moving Dot
      paint.color = Colors.black;
      canvas.drawRect(Rect.fromLTWH(0, 0, width, height), paint); // BG

      paint.color = const Color(0xFF00FF00); // Green dot
      final dotX = (t * width) % width;
      canvas.drawCircle(Offset(dotX, height / 2), height * 0.4, paint);
      
      // Trail
      paint.color = const Color(0xFF00FF00).withOpacity(0.5);
      canvas.drawCircle(Offset(dotX - 10, height / 2), height * 0.3, paint);
    }
    else if (name.contains('scan') || name.contains('larson')) {
      // Knight Rider style (Ping Pong)
      paint.color = Colors.black;
      canvas.drawRect(Rect.fromLTWH(0, 0, width, height), paint); // BG

      paint.color = Colors.red;
      final x = width * (0.5 + 0.5 * math.sin(t * 2 * math.pi));
      canvas.drawRect(Rect.fromCenter(center: Offset(x, height/2), width: 30, height: height * 0.8), paint);
    }
    else if (name.contains('sparkle') || name.contains('dissolve')) {
      // Random dots
      paint.color = Colors.white;
      final random = math.Random(t.floor()); // Stable seed per frame-ish
      for(int i=0; i<10; i++) {
         if (random.nextDouble() > 0.5) continue;
         final cx = random.nextDouble() * width;
         final cy = random.nextDouble() * height;
         canvas.drawCircle(Offset(cx, cy), 2, paint);
      }
    }
    else {
      // Default: Elegant Shift
      final shader = LinearGradient(
        colors: [const Color(0xFF0F172A), const Color(0xFF1E293B), const Color(0xFF0F172A)],
        stops: [t - 0.2, t, t + 0.2],
        tileMode: TileMode.repeated
      ).createShader(Rect.fromLTWH(0, 0, width, height));
      
      paint.shader = shader;
      canvas.drawRect(Rect.fromLTWH(0, 0, width, height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _EffectPainter oldDelegate) => true;
}
