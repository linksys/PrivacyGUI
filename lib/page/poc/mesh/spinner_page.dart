import 'package:flutter/material.dart';
import 'dart:math';

class SpinnerPage extends StatelessWidget {
  const SpinnerPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: const _RotatingSpinner(),
      color: Colors.white,
      alignment: Alignment.center,
    );
  }
}

class _RotatingSpinner extends StatefulWidget {
  const _RotatingSpinner({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _RotatingSpinnerState();
  }
}

class _RotatingSpinnerState extends State<_RotatingSpinner> with SingleTickerProviderStateMixin {

  late AnimationController _animationController;

  @override
  void initState() {
    _animationController = AnimationController(vsync: this, duration: const Duration(seconds: 1));
    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _animationController.reset();
      } else if (status == AnimationStatus.dismissed) {
        _animationController.forward();
      }
    });

    _animationController.forward();

    super.initState();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _animationController,
      child: CustomPaint(
        painter: Spinner(),
      ),
    );
  }
}

class Spinner extends CustomPainter {
  var linePaint = Paint()
    ..isAntiAlias = true
    ..strokeWidth = 8
    ..invertColors = false
    ..color = const Color.fromRGBO(9, 163, 234, 1.0)
    ..style = PaintingStyle.stroke;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawArc(
        Rect.fromCenter(
            center: Offset(size.width / 2, size.height / 2),
            width: 100,
            height: 100
        ),
        180 * (pi / 180.0),
        270 * (pi / 180.0),
        false,
        linePaint
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
