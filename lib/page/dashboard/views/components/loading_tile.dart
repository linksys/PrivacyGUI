import 'package:flutter/material.dart';

import 'package:ui_kit_library/ui_kit.dart';

class LoadingTile extends StatefulWidget {
  final bool isLoading;
  final Widget? child;
  final Color? baseColor;
  final Color? shimmerColor;

  const LoadingTile({
    Key? key,
    this.isLoading = true,
    this.child,
    this.baseColor,
    this.shimmerColor,
  }) : super(key: key);

  @override
  State<LoadingTile> createState() => _LoadingTileState();
}

class _LoadingTileState extends State<LoadingTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _createSkeletonFromWidget(Widget widget) {
    if (widget is Text) {
      return Container(
        width: widget.data?.length != null ? widget.data!.length * 8.0 : 100,
        height: 16,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(4),
        ),
      );
    } else if (widget is AppText) {
      // AppText from ui_kit doesn't expose text property, use fixed size
      return Container(
        width: 100,
        height: 16,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(4),
        ),
      );
    } else if (widget is Icon) {
      return Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(4),
        ),
      );
    } else if (widget is Image) {
      return Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(4),
        ),
      );
    } else if (widget is AppSwitch) {
      return AppSwitch(
        value: widget.value,
        onChanged: null,
      );
    }
    return Container(
      width: 100,
      height: 24,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _buildSkeletonFromChild(Widget child) {
    if (child is SingleChildScrollView) {
      return SingleChildScrollView(
        scrollDirection: child.scrollDirection,
        child: _buildSkeletonFromChild(child.child ?? Container()),
      );
    } else if (child is Padding) {
      return Padding(
        padding: child.padding,
        child: _buildSkeletonFromChild(child.child ?? Container()),
      );
    } else if (child is Column) {
      return Column(
        crossAxisAlignment: child.crossAxisAlignment,
        mainAxisAlignment: child.mainAxisAlignment,
        children:
            child.children.map((w) => _buildSkeletonFromChild(w)).toList(),
      );
    } else if (child is Row) {
      return Row(
        crossAxisAlignment: child.crossAxisAlignment,
        mainAxisAlignment: child.mainAxisAlignment,
        children:
            child.children.map((w) => _buildSkeletonFromChild(w)).toList(),
      );
    } else if (child is AppCard) {
      // AppCard from ui_kit doesn't expose margin property
      return Container(
        padding: child.padding,
        child: _buildSkeletonFromChild(child.child),
      );
    } else if (child is SizedBox) {
      return SizedBox(
        width: child.width,
        height: child.height,
        child: _buildSkeletonFromChild(child.child ?? Container()),
      );
    } else if (child is AppResponsiveLayout) {
      return AppResponsiveLayout(
        desktop: _buildSkeletonFromChild(child.desktop),
        mobile: _buildSkeletonFromChild(child.mobile),
      );
    } else if (child is Expanded) {
      return Expanded(
        child: _buildSkeletonFromChild(child.child),
      );
    } else if (child is Container) {
      return Container(
        width: child.constraints?.maxWidth,
        height: child.constraints?.maxHeight,
        padding: child.padding,
        margin: child.margin,
        constraints: child.constraints,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(4),
        ),
        child: _buildSkeletonFromChild(child.child ?? Container()),
      );
    } else if (child is Table) {
      return Table(
        border: const TableBorder(),
        columnWidths: child.columnWidths,
        children: child.children
            .whereType<TableRow>()
            .map((e) => TableRow(
                  children: e.children
                      .map((w) => _buildSkeletonFromChild(w))
                      .toList(),
                ))
            .toList(),
      );
    }
    return _createSkeletonFromWidget(child);
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = widget.baseColor ??
        Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3);
    final shimmerColor = widget.shimmerColor ??
        Theme.of(context).colorScheme.primary.withOpacity(0.5);

    return widget.isLoading
        ? AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      baseColor,
                      shimmerColor,
                      baseColor,
                    ],
                    stops: [
                      0.0,
                      _animation.value,
                      1.0,
                    ],
                  ),
                ),
                child: widget.child != null
                    ? _buildSkeletonFromChild(widget.child!)
                    : _buildDefaultSkeleton(),
              );
            },
          )
        : widget.child ?? const SizedBox.shrink();
  }

  Widget _buildDefaultSkeleton() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          AppGap.lg(),
          Container(
            width: 200,
            height: 16,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          AppGap.sm(),
          Container(
            width: 150,
            height: 16,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }
}

class FillPainter extends CustomPainter {
  final Color fillColor;
  final double fillAmount;

  FillPainter({
    required this.fillColor,
    required this.fillAmount,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final fillHeight = size.height * fillAmount;
    final rect =
        Rect.fromLTWH(0, size.height - fillHeight, size.width, fillHeight);
    canvas.clipRect(rect);
  }

  @override
  bool shouldRepaint(FillPainter oldDelegate) {
    return oldDelegate.fillAmount != fillAmount ||
        oldDelegate.fillColor != fillColor;
  }
}
