import 'package:flutter/material.dart';
import 'package:ping/core/theme/app_theme.dart';
import 'package:ping/core/widgets/neumorphic_container.dart';

/// Pulse button with ripple animation for ping actions
class PulseButton extends StatefulWidget {
  final VoidCallback onTap;
  final Widget child;
  final double size;
  final Color? color;

  const PulseButton({
    super.key,
    required this.onTap,
    required this.child,
    this.size = 44,
    this.color,
  });

  @override
  State<PulseButton> createState() => _PulseButtonState();
}

class _PulseButtonState extends State<PulseButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    _controller.forward(from: 0).then((_) => _controller.reset());
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final pulseColor = widget.color ?? AppColors.accent;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: _handleTap,
      child: SizedBox(
        width: widget.size + 16,
        height: widget.size + 16,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // Pulse Effect Ring
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Transform.scale(
                  scale: 1.0 + (_controller.value * 0.6),
                  child: Container(
                    width: widget.size,
                    height: widget.size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: pulseColor.withAlpha(
                        ((1.0 - _controller.value) * 80).toInt(),
                      ),
                    ),
                  ),
                );
              },
            ),
            // Button
            AnimatedScale(
              scale: _isPressed ? 0.92 : 1.0,
              duration: const Duration(milliseconds: 100),
              child: NeumorphicContainer(
                width: widget.size,
                height: widget.size,
                isPressed: _isPressed,
                color: widget.color?.withAlpha(40) ?? AppColors.cardColor,
                borderRadius: BorderRadius.circular(widget.size / 2),
                child: Center(child: widget.child),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
