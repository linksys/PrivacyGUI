import 'package:flutter/material.dart';

class BreathDot extends StatefulWidget {
  final Duration breathSpeed;
  final Color lightColor;
  final Color borderColor;
  final double size;
  final double dotSize;
  final bool animated;

  const BreathDot({
    super.key,
    this.breathSpeed = const Duration(seconds: 1),
    required this.lightColor,
    required this.borderColor,
    this.size = 12,
    this.dotSize = 6,
    this.animated = true,
  });

  @override
  State<BreathDot> createState() => _BreathDotState();
}

class _BreathDotState extends State<BreathDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.breathSpeed,
    );

    _animation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    if (widget.animated) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant BreathDot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animated != oldWidget.animated) {
      if (widget.animated) {
        _controller.repeat(reverse: true);
      } else {
        _controller.stop();
        _controller.reset();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: widget.borderColor,
          width:
              1, // Keep the border width consistent with the original inner dot's border
        ),
      ),
      child: Center(
        child: AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return Container(
              width: widget.dotSize,
              height: widget.dotSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.lightColor.withValues(
                    alpha: widget.animated ? _animation.value : 1.0),
              ),
            );
          },
        ),
      ),
    );
  }
}
