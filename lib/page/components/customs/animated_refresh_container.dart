import 'package:flutter/widgets.dart';
import 'package:ui_kit_library/ui_kit.dart';

class AnimatedRefreshContainer extends StatefulWidget {
  final Widget Function(AnimationController) builder;
  const AnimatedRefreshContainer({
    Key? key,
    required this.builder,
  }) : super(key: key);

  @override
  State<AnimatedRefreshContainer> createState() =>
      _AnimatedRefreshContainerState();
}

class _AnimatedRefreshContainerState extends State<AnimatedRefreshContainer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
  }

  @override
  Widget build(BuildContext context) {
    return _controller.isAnimating
        ? Padding(
            padding: const EdgeInsets.all(8.0),
            child: RotationTransition(
              turns: _controller,
              child: const AppIcon.font(AppFontIcons.refresh),
            ),
          )
        : widget.builder(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
