import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:ui_kit_library/ui_kit.dart';

typedef SpeedGaugeBuilder = Widget Function(
    BuildContext context, double displayValue);

/// Animated speed gauge shared by the speed-test page and the dashboard card.
///
/// When [isAnimating] is true the gauge runs a randomized "demo" animation
/// while the speed test is in progress; otherwise it renders [value].
class SpeedGauge extends StatefulWidget {
  const SpeedGauge({
    super.key,
    required this.value,
    required this.isAnimating,
    required this.size,
    required this.centerBuilder,
    this.bottomBuilder,
  });

  final double value;
  final bool isAnimating;
  final double size;
  final SpeedGaugeBuilder centerBuilder;
  final SpeedGaugeBuilder? bottomBuilder;

  @override
  State<SpeedGauge> createState() => SpeedGaugeState();
}

class SpeedGaugeState extends State<SpeedGauge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final _random = Random();
  double _currentValue = 0;
  double _targetValue = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    )..addListener(_onTick);
    if (widget.isAnimating) _startRandomAnimation();
  }

  void _startRandomAnimation() {
    _generateNewTarget();
    _controller.forward(from: 0);
  }

  void _generateNewTarget() {
    final base = 50 + _random.nextDouble() * 100;
    final noise = (_random.nextDouble() - 0.5) * 60;
    _targetValue = (base + noise).clamp(20, 250);
  }

  void _onTick() {
    if (!mounted) return;
    setState(() {
      _currentValue = _currentValue + (_targetValue - _currentValue) * 0.15;
    });
    if (_controller.isCompleted && widget.isAnimating) {
      _generateNewTarget();
      _controller.forward(from: 0);
    }
  }

  @override
  void didUpdateWidget(SpeedGauge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isAnimating && !oldWidget.isAnimating) {
      _startRandomAnimation();
    } else if (!widget.isAnimating && oldWidget.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onTick);
    _controller.dispose();
    super.dispose();
  }

  double get displayValue => widget.isAnimating ? _currentValue : widget.value;

  @override
  Widget build(BuildContext context) {
    return AppGauge(
      value: displayValue,
      size: widget.size,
      markers: const [0, 50, 100, 200, 300, 500],
      centerBuilder: (context, _) =>
          widget.centerBuilder(context, displayValue),
      bottomBuilder: widget.bottomBuilder == null
          ? null
          : (context, _) => widget.bottomBuilder!(context, displayValue),
    );
  }
}
