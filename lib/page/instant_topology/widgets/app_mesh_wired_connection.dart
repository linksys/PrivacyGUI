import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui_kit_library/ui_kit.dart';

class AppMeshWiredConnection extends ConsumerStatefulWidget {
  final bool animate;
  final Duration duration;

  const AppMeshWiredConnection({
    super.key,
    this.animate = true,
    this.duration = const Duration(seconds: 2),
  });

  @override
  ConsumerState<AppMeshWiredConnection> createState() =>
      _AppMeshWiredConnectionState();
}

class _AppMeshWiredConnectionState extends ConsumerState<AppMeshWiredConnection>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    if (widget.animate) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(AppMeshWiredConnection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate != oldWidget.animate) {
      if (widget.animate) {
        _controller.repeat();
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
    final theme = Theme.of(context).extension<AppDesignTheme>();
    final colors = theme?.colorScheme;

    // Default icon color if theme is missing (fallback)
    final iconColor = colors?.onSurface ?? Colors.black;
    // Connection line color
    final lineColor = colors?.outline ?? Colors.grey;
    // Animated dot color
    final highlightColor = colors?.primary ?? Colors.blue;

    return SizedBox(
      height: 64, // Sufficient height for icons
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Parent Node
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppIcon.font(
                AppFontIcons.router,
                size: 40,
                color: iconColor,
              ),
            ],
          ),

          // Connection Line with Animation
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return CustomPaint(
                    painter: _ConnectionPainter(
                      progress: _controller.value,
                      lineColor: lineColor,
                      dotColor: highlightColor,
                      enabled: widget.animate,
                    ),
                    size: Size.infinite,
                  );
                },
              ),
            ),
          ),

          // Child Node
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppIcon.font(
                AppFontIcons.router,
                size: 40,
                color: iconColor,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ConnectionPainter extends CustomPainter {
  final double progress;
  final Color lineColor;
  final Color dotColor;
  final bool enabled;

  _ConnectionPainter({
    required this.progress,
    required this.lineColor,
    required this.dotColor,
    required this.enabled,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerY = size.height / 2;

    // Draw the static connecting line
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final p1 = Offset(0, centerY);
    final p2 = Offset(size.width, centerY);

    canvas.drawLine(p1, p2, linePaint);

    if (enabled) {
      // Draw the moving dot
      final dotPaint = Paint()
        ..color = dotColor
        ..style = PaintingStyle.fill;

      final dotX = size.width * progress;
      final dotCenter = Offset(dotX, centerY);

      canvas.drawCircle(dotCenter, 4.0, dotPaint);

      // Optional: Add a subtle trail or glow if desired, but simple circle is clear
    }
  }

  @override
  bool shouldRepaint(_ConnectionPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.dotColor != dotColor ||
        oldDelegate.enabled != enabled;
  }
}
