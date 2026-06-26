import 'dart:math';

import 'package:flutter/material.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Pixel Buddy mascot - a simple, cute pixel-style robot.
///
/// Features:
/// - White rectangular body with rounded corners
/// - LED strip at top that changes color with mood
/// - Simple pixel-style face (eyes + mouth)
/// - Small feet
///
/// Animations:
/// - idle: gentle bobbing
/// - walk: bouncing
/// - greet: happy wave
/// - think: eyes look around + LED blinks
/// - celebrate: jumping with happy face
/// - sad: drooping with dim LED
class LinksysMascotRenderer extends MascotCharacterRenderer {
  const LinksysMascotRenderer();

  @override
  Size get size => const Size(80, 110);

  @override
  Set<MascotAnimationKey> get supportedAnimations => {
        MascotAnimationKey.idle,
        MascotAnimationKey.walk,
        MascotAnimationKey.greet,
        MascotAnimationKey.think,
        MascotAnimationKey.celebrate,
        MascotAnimationKey.sad,
      };

  @override
  Widget build({
    required MascotAnimationKey animationKey,
    required Animation<double> controller,
    required bool facingRight,
  }) {
    return _PixelBuddyWidget(
      animationKey: animationKey,
      controller: controller,
      facingRight: facingRight,
    );
  }
}

class _PixelBuddyWidget extends StatelessWidget {
  final MascotAnimationKey animationKey;
  final Animation<double> controller;
  final bool facingRight;

  const _PixelBuddyWidget({
    required this.animationKey,
    required this.controller,
    required this.facingRight,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final isIdle = animationKey == MascotAnimationKey.idle;
        final isWalking = animationKey == MascotAnimationKey.walk;
        final isGreeting = animationKey == MascotAnimationKey.greet;
        final isThinking = animationKey == MascotAnimationKey.think;
        final isCelebrating = animationKey == MascotAnimationKey.celebrate;
        final isSad = animationKey == MascotAnimationKey.sad;

        // Idle: very gentle bob (slow and subtle)
        final bob = isIdle ? sin(controller.value * pi) * 1.5 : 0.0;

        // Walk: stepping motion with slight bounce
        final bounce =
            isWalking ? sin(controller.value * pi * 2).abs() * 2 : 0.0;
        final walkSway =
            isWalking ? sin(controller.value * pi * 2) * 0.03 : 0.0;

        // Greet: gentle friendly bob (slower and smaller)
        final greetBob = isGreeting ? sin(controller.value * pi) * 2 : 0.0;

        // Think: slight tilt / Walk: sway
        final tilt =
            isThinking ? sin(controller.value * pi * 2) * 0.03 : walkSway;

        // Celebrate: big jump
        final jump = isCelebrating ? sin(controller.value * pi) * 15 : 0.0;

        // Sad: droop
        final droop = isSad ? 4.0 : 0.0;

        final flipX = facingRight ? 1.0 : -1.0;

        return Transform.translate(
          offset: Offset(0, -bob - bounce - greetBob - jump + droop),
          child: Transform.scale(
            scaleX: flipX,
            child: Transform.rotate(
              angle: tilt,
              child: SizedBox(
                width: 80,
                height: 110,
                child: CustomPaint(
                  painter: _PixelBuddyPainter(
                    animationKey: animationKey,
                    animationValue: controller.value,
                    isWalking: isWalking,
                    isGreeting: isGreeting,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PixelBuddyPainter extends CustomPainter {
  final MascotAnimationKey animationKey;
  final double animationValue;
  final bool isWalking;
  final bool isGreeting;

  // Mascot brand colors - intentionally hardcoded for character consistency
  // These represent the physical router device and should not change with theme
  static const _bodyColor = Color(0xFFFAFAFA);
  static const _borderColor = Color(0xFF333333);
  static const _ledBlue = Color(0xFF00A3E0);
  static const _ledGreen = Color(0xFF4CD964);
  static const _ledOrange = Color(0xFFFF9500);
  static const _faceColor = Color(0xFF333333);

  _PixelBuddyPainter({
    required this.animationKey,
    required this.animationValue,
    required this.isWalking,
    required this.isGreeting,
  });

  bool get isThinking => animationKey == MascotAnimationKey.think;
  bool get isCelebrating => animationKey == MascotAnimationKey.celebrate;
  bool get isSad => animationKey == MascotAnimationKey.sad;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;

    _drawBody(canvas, cx);
    _drawLed(canvas, cx);
    _drawFace(canvas, cx);
    _drawFeet(canvas, cx, size);
  }

  void _drawBody(Canvas canvas, double cx) {
    final paint = Paint();

    // Body dimensions
    const bodyWidth = 56.0;
    const bodyHeight = 72.0;
    const topY = 10.0;
    const radius = 14.0;

    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(cx - bodyWidth / 2, topY, bodyWidth, bodyHeight),
      const Radius.circular(radius),
    );

    // Body fill
    paint.color = _bodyColor;
    paint.style = PaintingStyle.fill;
    canvas.drawRRect(bodyRect, paint);

    // Body border
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

    // LED color based on state
    Color ledColor;
    double opacity = 1.0;

    if (isSad) {
      ledColor = _ledOrange;
      opacity = 0.6;
    } else if (isCelebrating) {
      ledColor = _ledGreen;
    } else if (isThinking) {
      // Blinking effect for thinking
      opacity = 0.4 + (sin(animationValue * pi * 6) + 1) * 0.3;
      ledColor = _ledBlue;
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

      // Eyes looking down
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

      // Sad mouth (upside down smile)
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromCenter(center: Offset(cx, mouthY + 2), width: 14, height: 5),
          topLeft: const Radius.circular(5),
          topRight: const Radius.circular(5),
        ),
        paint,
      );
    } else if (isThinking) {
      // Thinking: eyes look side to side
      final eyeOffset = sin(animationValue * pi * 2) * 3;

      // Left eye
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(cx - eyeSpacing + eyeOffset, eyeY),
            width: 8,
            height: 10,
          ),
          const Radius.circular(2),
        ),
        paint,
      );

      // Right eye
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(cx + eyeSpacing + eyeOffset, eyeY),
            width: 8,
            height: 10,
          ),
          const Radius.circular(2),
        ),
        paint,
      );

      // Small "o" mouth
      canvas.drawOval(
        Rect.fromCenter(center: Offset(cx, mouthY), width: 8, height: 8),
        paint,
      );
      paint.color = _bodyColor;
      canvas.drawOval(
        Rect.fromCenter(center: Offset(cx, mouthY), width: 4, height: 4),
        paint,
      );
    } else if (isGreeting) {
      // Greeting: friendly wink + smile
      paint.style = PaintingStyle.fill;

      // Left eye - winking (closed)
      final winkPhase = sin(animationValue * pi * 2);
      final leftEyeHeight = winkPhase > 0.7 ? 3.0 : 10.0; // Wink occasionally

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(cx - eyeSpacing, eyeY),
            width: 8,
            height: leftEyeHeight,
          ),
          const Radius.circular(2),
        ),
        paint,
      );

      // Right eye - normal
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

      // Friendly smile (slightly bigger)
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromCenter(center: Offset(cx, mouthY), width: 18, height: 6),
          bottomLeft: const Radius.circular(6),
          bottomRight: const Radius.circular(6),
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

  void _drawFeet(Canvas canvas, double cx, Size size) {
    final paint = Paint()
      ..color = _borderColor
      ..style = PaintingStyle.fill;

    const footWidth = 14.0;
    const footHeight = 10.0;
    const footSpacing = 18.0;
    final footY = size.height - footHeight - 2;

    // Walking animation: alternate feet up/down
    final leftFootOffset = isWalking ? sin(animationValue * pi * 2) * 4 : 0.0;
    final rightFootOffset =
        isWalking ? sin(animationValue * pi * 2 + pi) * 4 : 0.0;

    // Left foot
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(
          cx - footSpacing - footWidth / 2,
          footY - leftFootOffset.clamp(0, 4),
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
          footY - rightFootOffset.clamp(0, 4),
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
  bool shouldRepaint(_PixelBuddyPainter oldDelegate) =>
      animationKey != oldDelegate.animationKey ||
      animationValue != oldDelegate.animationValue ||
      isWalking != oldDelegate.isWalking ||
      isGreeting != oldDelegate.isGreeting;
}
