import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// A premium animated button with press feedback, loading state, and gold styling.
class GoldButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final bool outlined;

  const GoldButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.outlined = false,
  });

  @override
  State<GoldButton> createState() => _GoldButtonState();
}

class _GoldButtonState extends State<GoldButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onPressed != null && !widget.isLoading) {
      setState(() => _isPressed = true);
      _controller.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (_isPressed) {
      _controller.reverse();
      setState(() => _isPressed = false);
    }
  }

  void _handleTapCancel() {
    if (_isPressed) {
      _controller.reverse();
      setState(() => _isPressed = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDisabled = widget.onPressed == null || widget.isLoading;
    
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: isDisabled ? null : widget.onPressed,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            gradient: widget.outlined ? null : LinearGradient(
              colors: isDisabled 
                ? [Colors.grey.shade700, Colors.grey.shade800]
                : [const Color(0xFFD4AF37), const Color(0xFFB8962E)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: widget.outlined ? Border.all(
              color: isDisabled ? Colors.grey.shade600 : const Color(0xFFD4AF37),
              width: 1.5,
            ) : null,
            borderRadius: BorderRadius.circular(12),
            boxShadow: (widget.outlined || isDisabled) ? null : [
              BoxShadow(
                color: const Color(0xFFD4AF37).withOpacity(_isPressed ? 0.2 : 0.4),
                blurRadius: _isPressed ? 8 : 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.isLoading)
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: widget.outlined ? const Color(0xFFD4AF37) : Colors.black,
                  ),
                )
              else if (widget.icon != null)
                Icon(
                  widget.icon,
                  size: 18,
                  color: widget.outlined 
                    ? (isDisabled ? Colors.grey : const Color(0xFFD4AF37))
                    : Colors.black,
                ),
              if ((widget.icon != null || widget.isLoading) && widget.label.isNotEmpty)
                const SizedBox(width: 8),
              Text(
                widget.label,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                  color: widget.outlined 
                    ? (isDisabled ? Colors.grey : const Color(0xFFD4AF37))
                    : Colors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Full-width version
class GoldButtonFull extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;

  const GoldButtonFull({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: GoldButton(
        label: label,
        onPressed: onPressed,
        isLoading: isLoading,
        icon: icon,
      ),
    );
  }
}
