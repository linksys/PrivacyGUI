import 'package:flutter/material.dart';
import 'package:privacygui_widgets/widgets/container/responsive_layout.dart';

class DesktopLayout extends StatefulWidget {
  final Widget child;
  final Widget? sub;
  final double subWidth;

  const DesktopLayout({
    super.key,
    required this.child,
    this.sub,
    this.subWidth = 320,
  });

  @override
  State<DesktopLayout> createState() => _DesktopLayoutState();
}

class _DesktopLayoutState extends State<DesktopLayout> {
  double _subSize = 320;
  late double _minWidth;
  late double _maxWidth;

  @override
  void initState() {
    super.initState();
    _subSize = widget.subWidth;
  }

  @override
  Widget build(BuildContext context) {
    setState(() {
      _maxWidth = MediaQuery.of(context).size.width / 2;
      _minWidth = MediaQuery.of(context).size.width / 4;
    });
    return Row(
      children: [
        if (widget.sub != null) ...[
          SizedBox(
            width: _subSize,
            child: widget.sub,
          ),
          MouseRegion(
            cursor: SystemMouseCursors.resizeColumn,
            child: GestureDetector(
              onVerticalDragUpdate: (details) {
                double xDelta = details.delta.dx;
                if (xDelta < 0 && _subSize + xDelta < _minWidth) {
                  xDelta = 0;
                } else if (xDelta > 0 && _subSize + xDelta > _maxWidth) {
                  xDelta = 0;
                }
                setState(() {
                  _subSize += xDelta;
                });
              },
              onHorizontalDragUpdate: (details) {
                double xDelta = details.delta.dx;
                if (xDelta < 0 && _subSize + xDelta < _minWidth) {
                  xDelta = 0;
                } else if (xDelta > 0 && _subSize + xDelta > _maxWidth) {
                  xDelta = 0;
                }
                setState(() {
                  _subSize += xDelta;
                });
              },
              child: const VerticalDivider(
                width: 4,
              ),
            ),
          )
        ],
        Flexible(
          child: Center(
            child: Container(
              constraints:
                  BoxConstraints(maxWidth: ResponsiveLayout.tabletBreakpoint),
              child: widget.child,
            ),
          ),
        ),
      ],
    );
  }
}
