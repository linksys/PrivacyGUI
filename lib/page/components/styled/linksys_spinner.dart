import 'package:flutter/material.dart';
import 'dart:math' as math;

/// A widget that displays an animated filling icon with a wave effect.
///
/// The fill animates from 0 to 1 in a continuous loop.
/// [size] sets the width/height of the widget.
class LinksysSpinner extends StatefulWidget {
  final double size;

  const LinksysSpinner({
    Key? key,
    this.size = 120.0,
  }) : super(key: key);

  @override
  State<LinksysSpinner> createState() => _LinksysSpinnerState();
}

class _LinksysSpinnerState extends State<LinksysSpinner>
    with TickerProviderStateMixin {
  late AnimationController _fillController;
  late AnimationController _waveController;
  late Animation<double> _waveAmplitudeAnimation;

  @override
  void initState() {
    super.initState();
    _fillController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat();
    _waveAmplitudeAnimation =
        Tween<double>(begin: 4.0, end: 6.0).animate(_waveController);
  }

  @override
  void dispose() {
    _fillController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _fillController,
          _waveController,
          _waveAmplitudeAnimation,
        ]),
        builder: (context, child) {
          return CustomPaint(
            painter: _WaveFillPainter(
              fillPercentage: _fillController.value,
              waveController: _waveController,
              waveAmplitudeAnimation: _waveAmplitudeAnimation,
            ),
            size: Size(widget.size, widget.size),
          );
        },
      ),
    );
  }
}

class _WaveFillPainter extends CustomPainter {
  final double fillPercentage;
  final AnimationController waveController;
  final Animation<double> waveAmplitudeAnimation;

  _WaveFillPainter({
    required this.fillPercentage,
    required this.waveController,
    required this.waveAmplitudeAnimation,
  }) : super(repaint: waveController);

  @override
  void paint(Canvas canvas, Size size) {
    final iconData = Icons.favorite;
    const iconSize = 96.0;
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    textPainter.text = TextSpan(
      text: String.fromCharCode(iconData.codePoint),
      style: TextStyle(
        fontSize: iconSize,
        fontFamily: iconData.fontFamily,
        color: Colors.grey[300]!,
      ),
    );

    textPainter.layout();
    final iconOffset = Offset(
      (size.width - textPainter.width) / 2,
      (size.height - textPainter.height) / 2,
    );

    textPainter.paint(canvas, iconOffset);

    // Calculate the fill height based on the percentage.
    final fillHeight = size.height * fillPercentage;

    // Wave effect
    final waveAmplitude = waveAmplitudeAnimation.value;
    const waveFrequency = .1;
    final wavePhase = waveController.value * 6 * math.pi;

    Path wavePath = Path();
    wavePath.moveTo(0, size.height);

    for (double i = 0; i <= size.width; i += 1) {
      double y = size.height -
          fillHeight +
          waveAmplitude * math.sin(i * waveFrequency + wavePhase);
      wavePath.lineTo(i, y);
    }

    wavePath.lineTo(size.width, size.height);
    wavePath.close();

    canvas.save();
    canvas.clipPath(wavePath);

    final fillTextPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    fillTextPainter.text = TextSpan(
      text: String.fromCharCode(iconData.codePoint),
      style: TextStyle(
        fontSize: iconSize,
        fontFamily: iconData.fontFamily,
        foreground: Paint()
          ..shader = RadialGradient(
            colors: [
              Colors.red.shade400.withAlpha(255),
              Colors.red.shade400.withAlpha((0.4 * 255).toInt()),
            ],
            stops: const [
              0.0,
              1.0,
            ],
            center: Alignment.center,
            radius: 0.5,
          ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
      ),
    );

    fillTextPainter.layout();
    fillTextPainter.paint(canvas, iconOffset);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _WaveFillPainter oldDelegate) {
    return oldDelegate.fillPercentage != fillPercentage ||
        oldDelegate.waveController.value != waveController.value ||
        oldDelegate.waveAmplitudeAnimation.value !=
            waveAmplitudeAnimation.value;
  }
}
