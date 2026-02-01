import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LiquidContainer extends StatefulWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final bool isActive;
  final Color? activeColor;

  const LiquidContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.isActive = false,
    this.activeColor,
  });

  @override
  State<LiquidContainer> createState() => _LiquidContainerState();
}

class _LiquidContainerState extends State<LiquidContainer> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        duration: const Duration(milliseconds: 100),
        reverseDuration: const Duration(milliseconds: 100),
        vsync: this);
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.onTap != null) {
      _controller.forward();
      HapticFeedback.lightImpact();
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.onTap != null) {
      _controller.reverse();
      widget.onTap!();
    }
  }

  void _onTapCancel() {
    if (widget.onTap != null) {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = Colors.white.withValues(alpha: 0.05);
    final activeGlow = widget.activeColor ?? const Color(0xFFD4AF37);

    // If no onTap, just render without GestureDetector to save overhead
    Widget content = Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: widget.isActive
            ? [
                BoxShadow(
                  color: activeGlow.withValues(alpha: 0.3),
                  blurRadius: 30,
                  spreadRadius: -5,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: activeGlow.withValues(alpha: 0.1),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: CustomPaint(
            painter: _LiquidRimPainter(isActive: widget.isActive, activeColor: activeGlow),
            child: Container(
              padding: widget.padding,
              decoration: BoxDecoration(
                color: baseColor,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.15), // Top Left Highlight
                    Colors.white.withValues(alpha: 0.02), // Center
                    Colors.black.withValues(alpha: 0.1), // Bottom Right Shadow
                  ],
                  stops: const [0.0, 0.4, 1.0],
                ),
              ),
              child: widget.child,
            ),
          ),
        ),
      ),
    );

    if (widget.onTap == null) {
      return content;
    }

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        ),
        child: content,
      ),
    );
  }
}

class _LiquidRimPainter extends CustomPainter {
  final bool isActive;
  final Color activeColor;

  _LiquidRimPainter({required this.isActive, required this.activeColor});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(24));

    // 1. The Border Stroke (Gradient)
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isActive
            ? [
                activeColor.withValues(alpha: 0.8), // Bright active color
                activeColor.withValues(alpha: 0.1),
                activeColor.withValues(alpha: 0.8),
              ]
            : [
                Colors.white.withValues(alpha: 0.4), // Rim Light
                Colors.white.withValues(alpha: 0.05), // Fade
                Colors.black.withValues(alpha: 0.2), // Shadow
              ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(rect);

    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant _LiquidRimPainter oldDelegate) {
    return oldDelegate.isActive != isActive;
  }
}

class LiquidIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Color? color;

  const LiquidIconButton({
    super.key,
    required this.icon,
    this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return LiquidContainer(
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      width: 50,
      height: 50,
      child: Center(
        child: Icon(icon, color: color ?? Colors.white, size: 24),
      ),
    );
  }
}
