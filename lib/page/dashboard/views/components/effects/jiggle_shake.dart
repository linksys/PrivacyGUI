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
    this.degrees = 0.5,
  });

  @override
  State<JiggleShake> createState() => _JiggleShakeState();
}

class _JiggleShakeState extends State<JiggleShake>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;
  final _random = Random();

  /// Platform "reduce motion" accessibility flag. Read from MediaQuery in
  /// didChangeDependencies (not initState, where inherited widgets are unsafe).
  /// Null until the first didChangeDependencies so the initial sync always runs.
  bool? _reduceMotion;

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
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // MediaQuery is only safe to read here — not in initState.
    // didChangeDependencies fires on ANY ancestor InheritedWidget change
    // (Theme, Directionality, Localizations…), so short-circuit when the
    // reduce-motion value is unchanged to avoid re-triggering the animation.
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduceMotion == _reduceMotion) return;
    _reduceMotion = reduceMotion;
    _syncAnimation();
  }

  @override
  void didUpdateWidget(covariant JiggleShake oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active != oldWidget.active) {
      _syncAnimation();
    }
  }

  /// Whether motion is allowed: reduce-motion is off (or not yet resolved).
  bool get _motionAllowed => _reduceMotion != true;

  /// Starts or stops the shake based on [active] and the reduce-motion flag.
  void _syncAnimation() {
    if (widget.active && _motionAllowed) {
      _startShaking();
    } else {
      _stopShaking();
    }
  }

  void _startShaking() {
    if (_controller.isAnimating) return;
    // Add a tiny random delay before starting to enhance the organic feel
    Future.delayed(Duration(milliseconds: _random.nextInt(50)), () {
      if (mounted && widget.active && _motionAllowed) {
        _controller.repeat(reverse: true);
      }
    });
  }

  void _stopShaking() {
    _controller.stop();
    _controller.reset();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        // build() is the single source of truth for the rendered angle:
        // force 0 when inactive or when reduce-motion is on (deterministic,
        // static rendering — also what golden tests rely on).
        final turns =
            (widget.active && _motionAllowed) ? _animation.value : 0.0;
        return Transform.rotate(
          angle: turns,
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
