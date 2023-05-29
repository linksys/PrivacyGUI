import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_widgets/theme/_theme.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';

import 'dart:math' as math;

class CircleProgressBar extends ConsumerStatefulWidget {
  final double progress;
  final double strokeWidth;
  final Color backgroundColor;
  final Color foregroundColor;

  const CircleProgressBar({
    Key? key,
    required this.progress,
    this.strokeWidth = 4.0,
    this.backgroundColor = Colors.grey,
    this.foregroundColor = Colors.blue,
  }) : super(key: key);

  @override
  ConsumerState<CircleProgressBar> createState() => _CircleProgressBarState();
}

class _CircleProgressBarState extends ConsumerState<CircleProgressBar> {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      foregroundPainter: CircleProgressBarPainter(
        progress: widget.progress,
        strokeWidth: widget.strokeWidth,
        backgroundColor: widget.backgroundColor,
        foregroundColor: widget.foregroundColor,
      ),
      child: const SizedBox(
        width: double.infinity,
        height: double.infinity,
      ),
    );
  }
}

class CircleProgressBarPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final Color backgroundColor;
  final Color foregroundColor;

  CircleProgressBarPainter({
    required this.progress,
    required this.strokeWidth,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    const radius = 100.0;

    // Draw background circle
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(Offset(centerX, centerY), radius, backgroundPaint);

    // Draw progress arc
    final progressPaint = Paint()
      ..color = foregroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    const startAngle = -math.pi / 2;
    final sweepAngle = math.pi * 2 * progress;
    canvas.drawArc(
        Rect.fromCircle(center: Offset(centerX, centerY), radius: radius),
        startAngle,
        sweepAngle,
        false,
        progressPaint);
  }

  @override
  bool shouldRepaint(CircleProgressBarPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.foregroundColor != foregroundColor;
  }
}

class TriLayerButton extends ConsumerStatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;

  const TriLayerButton({
    super.key,
    required this.child,
    this.onPressed,
  });

  @override
  ConsumerState<TriLayerButton> createState() => _TriLayerButtonState();
}

class _TriLayerButtonState extends ConsumerState<TriLayerButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
      lowerBound: 0.75,
      upperBound: 1.0,
    )..addListener(() {
        setState(() {});
      });
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.bounceOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: (() {
        _controller.forward(from: 0);
        widget.onPressed!();
      }),
      child: Transform.scale(
        scale: _animation.value,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: ConstantColors.primaryLinksysBlue.withOpacity(0.3)),
              width: 200,
              height: 200,
            ),
            Container(
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: ConstantColors.primaryLinksysBlue.withOpacity(0.5)),
              width: 180,
              height: 180,
            ),
            Container(
              decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: ConstantColors.primaryLinksysBlue),
              width: 150,
              height: 150,
            ),
            const AppText.subhead(
              'START',
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}
