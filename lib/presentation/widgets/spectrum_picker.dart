import 'dart:math';
import 'package:flutter/material.dart';

class SpectrumPicker extends StatefulWidget {
  final Color currentColor;
  final ValueChanged<Color> onChanged;
  final double size;

  const SpectrumPicker({
    super.key,
    required this.currentColor,
    required this.onChanged,
    this.size = 280,
  });

  @override
  State<SpectrumPicker> createState() => _SpectrumPickerState();
}

class _SpectrumPickerState extends State<SpectrumPicker> {
  late HSVColor _hsvColor;

  @override
  void initState() {
    super.initState();
    _hsvColor = HSVColor.fromColor(widget.currentColor);
  }

  @override
  void didUpdateWidget(covariant SpectrumPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentColor != oldWidget.currentColor) {
      _hsvColor = HSVColor.fromColor(widget.currentColor);
    }
  }

  void _handleGesture(Offset localPosition, double radius) {
    final center = Offset(radius, radius);
    final dx = localPosition.dx - center.dx;
    final dy = localPosition.dy - center.dy;

    // Angle in radians (0 to 2*pi)
    double angle = atan2(dy, dx);
    if (angle < 0) angle += 2 * pi;

    // Map angle to Hue (0-360)
    final hue = (angle * 180 / pi) % 360;

    // Distance from center (0 to 1)
    final distance = sqrt(dx * dx + dy * dy);
    final saturation = (distance / radius).clamp(0.0, 1.0);

    final newHsv = HSVColor.fromAHSV(1.0, hue, saturation, 1.0); // Full Value
    
    // Smooth update
    setState(() {
      _hsvColor = newHsv;
    });
    
    // Debounced output could be added here if needed, but for now instant
    widget.onChanged(newHsv.toColor());
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: GestureDetector(
        onPanUpdate: (details) => _handleGesture(details.localPosition, widget.size / 2),
        onTapDown: (details) => _handleGesture(details.localPosition, widget.size / 2),
        child: CustomPaint(
          painter: _SpectrumPainter(_hsvColor),
          size: Size(widget.size, widget.size),
        ),
      ),
    );
  }
}

class _SpectrumPainter extends CustomPainter {
  final HSVColor selectedColor;

  _SpectrumPainter(this.selectedColor);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // 1. Draw Spectrum Gradient (Conical)
    final rect = Rect.fromCircle(center: center, radius: radius);
    final gradient = SweepGradient(
      colors: const [
        Color(0xFFFF0000),
        Color(0xFFFF00FF),
        Color(0xFF0000FF),
        Color(0xFF00FFFF),
        Color(0xFF00FF00),
        Color(0xFFFFFF00),
        Color(0xFFFF0000),
      ],
      stops: const [0.0, 0.16, 0.33, 0.5, 0.66, 0.83, 1.0],
    );

    final paint = Paint()..shader = gradient.createShader(rect);
    canvas.drawCircle(center, radius, paint);

    // 2. Draw Saturation Overlay (Radial White -> Transparent)
    final saturationGradient = RadialGradient(
      colors: [Colors.white, Colors.white.withValues(alpha: 0.0)],
      stops: const [0.0, 1.0],
    );
    final satPaint = Paint()..shader = saturationGradient.createShader(rect);
    canvas.drawCircle(center, radius, satPaint);

    // 3. Draw Thumb (Selection Indicator)
    final hueRad = selectedColor.hue * pi / 180;
    final saturationDist = selectedColor.saturation * radius;
    
    final thumbX = center.dx + cos(hueRad) * saturationDist;
    final thumbY = center.dy + sin(hueRad) * saturationDist;
    final thumbPos = Offset(thumbX, thumbY);

    // Glow
    canvas.drawCircle(
      thumbPos, 
      12, 
      Paint()..color = Colors.black.withValues(alpha: 0.3)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4)
    );

    // Border
    canvas.drawCircle(
      thumbPos, 
      10, 
      Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 3
    );
    
    // Fill
    canvas.drawCircle(
      thumbPos, 
      10, 
      Paint()..color = selectedColor.toColor()
    );
  }

  @override
  bool shouldRepaint(covariant _SpectrumPainter oldDelegate) {
    return oldDelegate.selectedColor != selectedColor;
  }
}
