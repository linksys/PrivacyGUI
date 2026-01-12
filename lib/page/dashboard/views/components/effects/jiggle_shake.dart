import 'dart:math';
import 'package:flutter/material.dart';

/// Applies a random jiggle (shake) animation to its child when [active].
///
/// Used in dashboard edit mode to indicate editable items.
class JiggleShake extends StatefulWidget {
  final bool active;
  final Widget child;
  final double degrees;

  const JiggleShake({
    super.key,
    required this.active,
    required this.child,
    this.degrees = 1.0,
  });

  @override
  State<JiggleShake> createState() => _JiggleShakeState();
}

class _JiggleShakeState extends State<JiggleShake>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;
  final _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 140),
      vsync: this,
    );

    // Randomize the shake direction/offset slightly so items don't shake in perfect sync
    final bool startPositive = _random.nextBool();
    final double maxRad = widget.degrees * (pi / 180);

    _animation = Tween<double>(
      begin: startPositive ? -maxRad : maxRad,
      end: startPositive ? maxRad : -maxRad,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    if (widget.active) {
      _startShaking();
    }
  }

  @override
  void didUpdateWidget(covariant JiggleShake oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active != oldWidget.active) {
      if (widget.active) {
        _startShaking();
      } else {
        _stopShaking();
      }
    }
  }

  void _startShaking() {
    // Add a tiny random delay before starting to enhance the organic feel
    Future.delayed(Duration(milliseconds: _random.nextInt(50)), () {
      if (mounted && widget.active) {
        _controller.repeat(reverse: true);
      }
    });
  }

  void _stopShaking() {
    _controller.stop();
    _controller.animateTo(0.5); // Reset to center (approx) or just reset
    _controller.reset();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Optimization: If not active and not animating, return child directly (or Rotation with 0)
    // But RotationTransition with 0 turns is cheap.
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        // If inactive, force 0 rotation
        final turns = widget.active ? _animation.value : 0.0;
        return Transform.rotate(
          angle: turns,
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
