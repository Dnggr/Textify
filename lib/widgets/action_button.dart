import 'package:flutter/material.dart';

/// A reusable, glowing action button used throughout the app.
/// Supports an icon, label, color, and an optional subtitle.
class ActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final Color color;
  final VoidCallback onTap;
  final bool isLarge; // Large = home screen, Small = result screen

  const ActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.subtitle,
    this.isLarge = false,
  });

  @override
  State<ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<ActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 120),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    setState(() => _isPressed = true);
    _controller.forward();
  }

  void _onTapUp(TapUpDetails _) {
    setState(() => _isPressed = false);
    _controller.reverse();
    widget.onTap();
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) =>
            Transform.scale(scale: _scaleAnimation.value, child: child),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(
            horizontal: widget.isLarge ? 24 : 16,
            vertical: widget.isLarge ? 20 : 12,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.isLarge ? 20 : 12),
            border: Border.all(
              color: widget.color.withOpacity(_isPressed ? 1.0 : 0.5),
              width: 1.5,
            ),
            color: widget.color.withOpacity(_isPressed ? 0.2 : 0.08),
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(_isPressed ? 0.4 : 0.15),
                blurRadius: _isPressed ? 24 : 12,
                spreadRadius: _isPressed ? 2 : 0,
              ),
            ],
          ),
          child: widget.isLarge ? _buildLargeContent() : _buildSmallContent(),
        ),
      ),
    );
  }

  // Layout for home screen large buttons
  Widget _buildLargeContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(widget.icon, color: widget.color, size: 36),
        const SizedBox(height: 12),
        Text(
          widget.label,
          style: TextStyle(
            color: widget.color,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        if (widget.subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            widget.subtitle!,
            style: TextStyle(
              color: widget.color.withOpacity(0.6),
              fontSize: 11,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  // Layout for result screen small buttons
  Widget _buildSmallContent() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(widget.icon, color: widget.color, size: 18),
        const SizedBox(width: 8),
        Text(
          widget.label,
          style: TextStyle(
            color: widget.color,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }
}
