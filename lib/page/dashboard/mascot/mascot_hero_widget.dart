import 'package:flutter/material.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Hero tag for mascot transition to AI Assistant.
const mascotHeroTag = 'mascot-to-ai-assistant';

/// Static mascot widget for Hero animation.
///
/// Unlike the animated [MascotOverlay], this widget renders a static mascot
/// that can be wrapped in a [Hero] for page transitions.
class MascotHeroWidget extends StatelessWidget {
  const MascotHeroWidget({
    super.key,
    this.size = 80,
    this.animation = MascotAnimationKey.idle,
  });

  final double size;
  final MascotAnimationKey animation;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size * 1.375, // aspect ratio from LinksysMascotRenderer (80x110)
      child: CustomPaint(
        painter: _StaticMascotPainter(animation: animation),
      ),
    );
  }
}

/// Static painter for mascot - renders a single frame.
class _StaticMascotPainter extends CustomPainter {
  final MascotAnimationKey animation;

  // Mascot brand colors - intentionally hardcoded for character consistency
  // These represent the physical router device and should not change with theme
  static const _bodyColor = Color(0xFFFAFAFA);
  static const _borderColor = Color(0xFF333333);
  static const _ledBlue = Color(0xFF00A3E0);
  static const _ledGreen = Color(0xFF4CD964);
  static const _ledOrange = Color(0xFFFF9500);
  static const _faceColor = Color(0xFF333333);

  _StaticMascotPainter({required this.animation});

  bool get isCelebrating => animation == MascotAnimationKey.celebrate;
  bool get isSad => animation == MascotAnimationKey.sad;
  bool get isThinking => animation == MascotAnimationKey.think;

  @override
  void paint(Canvas canvas, Size size) {
    // Scale to fit the provided size
    const baseWidth = 80.0;
    final scale = size.width / baseWidth;
    canvas.scale(scale);

    const cx = baseWidth / 2;

    _drawBody(canvas, cx);
    _drawLed(canvas, cx);
    _drawFace(canvas, cx);
    _drawFeet(canvas, cx);
  }

  void _drawBody(Canvas canvas, double cx) {
    final paint = Paint();

    const bodyWidth = 56.0;
    const bodyHeight = 72.0;
    const topY = 10.0;
    const radius = 14.0;

    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(cx - bodyWidth / 2, topY, bodyWidth, bodyHeight),
      const Radius.circular(radius),
    );

    paint.color = _bodyColor;
    paint.style = PaintingStyle.fill;
    canvas.drawRRect(bodyRect, paint);

    paint.color = _borderColor;
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 3;
    canvas.drawRRect(bodyRect, paint);
  }

  void _drawLed(Canvas canvas, double cx) {
    final paint = Paint();

    const ledY = 20.0;
    const ledWidth = 32.0;
    const ledHeight = 6.0;

    Color ledColor;
    double opacity = 1.0;

    if (isSad) {
      ledColor = _ledOrange;
      opacity = 0.6;
    } else if (isCelebrating) {
      ledColor = _ledGreen;
    } else {
      ledColor = _ledBlue;
    }

    // LED glow
    paint.color = ledColor.withValues(alpha: 0.4 * opacity);
    paint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(cx, ledY),
          width: ledWidth + 8,
          height: ledHeight + 8,
        ),
        const Radius.circular(4),
      ),
      paint,
    );
    paint.maskFilter = null;

    // LED bar
    paint.color = ledColor.withValues(alpha: opacity);
    paint.style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(cx, ledY),
          width: ledWidth,
          height: ledHeight,
        ),
        const Radius.circular(3),
      ),
      paint,
    );
  }

  void _drawFace(Canvas canvas, double cx) {
    final paint = Paint()
      ..color = _faceColor
      ..style = PaintingStyle.fill;

    const eyeY = 42.0;
    const eyeSpacing = 12.0;
    const mouthY = 58.0;

    if (isCelebrating) {
      // Happy squint eyes (^_^)
      paint.style = PaintingStyle.stroke;
      paint.strokeWidth = 3;
      paint.strokeCap = StrokeCap.round;

      // Left eye ^
      canvas.drawLine(
        Offset(cx - eyeSpacing - 5, eyeY),
        Offset(cx - eyeSpacing, eyeY - 5),
        paint,
      );
      canvas.drawLine(
        Offset(cx - eyeSpacing, eyeY - 5),
        Offset(cx - eyeSpacing + 5, eyeY),
        paint,
      );

      // Right eye ^
      canvas.drawLine(
        Offset(cx + eyeSpacing - 5, eyeY),
        Offset(cx + eyeSpacing, eyeY - 5),
        paint,
      );
      canvas.drawLine(
        Offset(cx + eyeSpacing, eyeY - 5),
        Offset(cx + eyeSpacing + 5, eyeY),
        paint,
      );

      // Big smile
      paint.style = PaintingStyle.fill;
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromCenter(center: Offset(cx, mouthY), width: 20, height: 8),
          bottomLeft: const Radius.circular(8),
          bottomRight: const Radius.circular(8),
        ),
        paint,
      );
    } else if (isSad) {
      // Sad droopy eyes
      paint.style = PaintingStyle.fill;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(cx - eyeSpacing, eyeY + 3),
            width: 8,
            height: 6,
          ),
          const Radius.circular(2),
        ),
        paint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(cx + eyeSpacing, eyeY + 3),
            width: 8,
            height: 6,
          ),
          const Radius.circular(2),
        ),
        paint,
      );

      // Sad mouth
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromCenter(center: Offset(cx, mouthY + 2), width: 14, height: 5),
          topLeft: const Radius.circular(5),
          topRight: const Radius.circular(5),
        ),
        paint,
      );
    } else {
      // Normal eyes
      paint.style = PaintingStyle.fill;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(cx - eyeSpacing, eyeY),
            width: 8,
            height: 10,
          ),
          const Radius.circular(2),
        ),
        paint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(cx + eyeSpacing, eyeY),
            width: 8,
            height: 10,
          ),
          const Radius.circular(2),
        ),
        paint,
      );

      // Normal smile
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromCenter(center: Offset(cx, mouthY), width: 16, height: 5),
          bottomLeft: const Radius.circular(5),
          bottomRight: const Radius.circular(5),
        ),
        paint,
      );
    }
  }

  void _drawFeet(Canvas canvas, double cx) {
    final paint = Paint()
      ..color = _borderColor
      ..style = PaintingStyle.fill;

    const footWidth = 14.0;
    const footHeight = 10.0;
    const footSpacing = 18.0;
    const footY = 110 - footHeight - 2;

    // Left foot
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(
          cx - footSpacing - footWidth / 2,
          footY,
          footWidth,
          footHeight,
        ),
        bottomLeft: const Radius.circular(4),
        bottomRight: const Radius.circular(4),
      ),
      paint,
    );

    // Right foot
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(
          cx + footSpacing - footWidth / 2,
          footY,
          footWidth,
          footHeight,
        ),
        bottomLeft: const Radius.circular(4),
        bottomRight: const Radius.circular(4),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(_StaticMascotPainter oldDelegate) =>
      animation != oldDelegate.animation;
}
