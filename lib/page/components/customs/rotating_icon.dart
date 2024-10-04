import 'package:flutter/widgets.dart';

class RotatingIcon extends StatefulWidget {
  final Duration? duration;
  final Icon icon;
  final bool animate;

  const RotatingIcon(
    this.icon, {
    Key? key,
    this.duration,
    this.animate = true,
  }) : super(key: key);

  @override
  State<RotatingIcon> createState() => _RotatingIconState();
}

class _RotatingIconState extends State<RotatingIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration ?? const Duration(milliseconds: 1000),
      vsync: this,
    );
    if (widget.animate) {
      _controller.repeat();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: RotationTransition(
        turns: _controller,
        child: widget.icon,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
