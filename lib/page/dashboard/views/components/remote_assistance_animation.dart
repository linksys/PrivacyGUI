import 'package:flutter/material.dart';

/// RemoteAssistanceAnimation
/// A reusable widget that displays an animated dotted line between a person and a router icon.
/// The animation always runs automatically.
class RemoteAssistanceAnimation extends StatefulWidget {
  const RemoteAssistanceAnimation({Key? key}) : super(key: key);

  @override
  State<RemoteAssistanceAnimation> createState() =>
      _RemoteAssistanceAnimationState();
}

class _RemoteAssistanceAnimationState extends State<RemoteAssistanceAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const personSize = 80.0;
        const routerSize = 80.0;

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Person Icon
            const Icon(Icons.person, size: personSize),
            const SizedBox(width: 20),
            // Animated Dotted Line
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return SizedBox(
                  width: constraints.maxWidth / 3,
                  height: 100,
                  child: CustomPaint(
                    painter: FancyDottedLinePainter(
                      animationValue: _animationController.value,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(width: 20),
            // Router Icon
            const Icon(Icons.router, size: routerSize),
          ],
        );
      },
    );
  }
}

class FancyDottedLinePainter extends CustomPainter {
  final double animationValue;

  FancyDottedLinePainter({
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color.fromARGB(255, 0, 255, 255),
          Color.fromARGB(255, 255, 0, 255)
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    const dashWidth = 10.0;
    const dashSpace = 7.0;

    final start = Offset(0, size.height / 2);
    final end = Offset(size.width, size.height / 2);
    final distance = (end - start).distance;

    // Draw the dotted line
    double currentDistance = animationValue * (dashWidth + dashSpace) * 1;
    while (currentDistance < distance) {
      canvas.drawLine(
        start + (end - start) * (currentDistance / distance),
        start + (end - start) * ((currentDistance + dashWidth) / distance),
        paint,
      );
      currentDistance += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant FancyDottedLinePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
