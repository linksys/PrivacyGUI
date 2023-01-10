import 'package:flutter/material.dart';

class SlideActionContainer extends StatefulWidget {
  final Widget child;
  final List<Widget> menuItems;

  const SlideActionContainer(
      {super.key, required this.child, required this.menuItems,});

  @override
  SlideActionContainerState createState() => SlideActionContainerState();
}

class SlideActionContainerState extends State<SlideActionContainer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 200));
  }

  @override
  dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final animation = Tween(
            begin: const Offset(0.0, 0.0),
            end: Offset(-0.1 * widget.menuItems.length, 0.0))
        .animate(CurveTween(curve: Curves.decelerate).animate(_controller));

    return GestureDetector(
      onHorizontalDragUpdate: (data) {
        final primaryDelta = data.primaryDelta;
        final contextWidth = context.size?.width;
        if (primaryDelta == null || contextWidth == null) return;
        // we can access context.size here
        setState(() {
          _controller.value -= primaryDelta / contextWidth;
        });
      },
      onHorizontalDragEnd: (data) {
        final primaryVelocity = data.primaryVelocity;
        if (primaryVelocity == null) return;
        if (primaryVelocity > 2500) {
          _controller.animateTo(.0);
        } else if (_controller.value >= .5 || primaryVelocity < -2500) {
          _controller.animateTo(1.0);
        } else {
          _controller.animateTo(.0);
        }
      },
      child: Stack(
        children: <Widget>[
          SlideTransition(position: animation, child: widget.child),
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraint) {
                return AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Stack(
                      children: <Widget>[
                        Positioned(
                          right: .0,
                          top: .0,
                          bottom: .0,
                          width: constraint.maxWidth * animation.value.dx * -1,
                          child: Container(
                            color: Colors.black26,
                            child: Row(
                              children: widget.menuItems.map((child) {
                                return Expanded(
                                  child: child,
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          )
        ],
      ),
    );
  }
}
