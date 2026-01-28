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

class _LoadingTileState extends State<LoadingTile> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Widget _createSkeletonFromWidget(Widget w) {
    // Determine effective colors from widget properties or context if needed,
    // but AppSkeleton handles theme-aware colors by default.
    // If specific overrides are passed to LoadingTile, we can use them.
    final baseColor = widget.baseColor;
    final highlightColor = widget.shimmerColor;

    if (w is Text) {
      return AppSkeleton.text(
        width: w.data?.length != null ? w.data!.length * 8.0 : 100,
        baseColor: baseColor,
        highlightColor: highlightColor,
      );
    } else if (w is AppText) {
      // AppText from ui_kit doesn't expose text property easily without reflection or extending,
      // assume a standard width or try to infer. For now use fixed size.
      return AppSkeleton.text(
        width: 100,
        baseColor: baseColor,
        highlightColor: highlightColor,
      );
    } else if (w is Icon) {
      return AppSkeleton(
        width: 24,
        height: 24,
        baseColor: baseColor,
        highlightColor: highlightColor,
      );
    } else if (w is Image) {
      return AppSkeleton(
        width: w.width,
        height: w.height,
        baseColor: baseColor,
        highlightColor: highlightColor,
      );
    } else if (w is AppSwitch) {
      // Simulate switch shape
      return AppSkeleton.capsule(
        width: 40,
        height: 20, // Approx switch size
        baseColor: baseColor,
        highlightColor: highlightColor,
      );
    }
    return AppSkeleton(
      width: 100,
      height: 24,
      baseColor: baseColor,
      highlightColor: highlightColor,
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
        desktop: (ctx) => _buildSkeletonFromChild(child.desktop(ctx)),
        mobile: (ctx) => _buildSkeletonFromChild(child.mobile(ctx)),
      );
    } else if (child is Expanded) {
      return Expanded(
        child: _buildSkeletonFromChild(child.child),
      );
    } else if (child is Container) {
      // If container has child, recurse. If it's a spacer/block, replace with skeleton (via _createSkeletonFromWidget implicitly if we return it directly, but here we recurse)
      // Actually, if 'child' is null, we should probably render a skeleton for the container's box.
      if (child.child != null) {
        return Container(
          width: child.constraints?.maxWidth,
          height: child.constraints?.maxHeight,
          padding: child.padding,
          margin: child.margin,
          constraints: child.constraints,
          // We don't want the container's background color in skeleton mode, usually
          decoration: const BoxDecoration(color: Colors.transparent),
          child: _buildSkeletonFromChild(child.child!),
        );
      } else {
        // Empty container usually acts as spacer or block
        // Use maxWidth/maxHeight if bounded, else custom default
        double? w = child.constraints?.maxWidth;
        double? h = child.constraints?.maxHeight;

        if (w == double.infinity || w == null) w = 100;
        if (h == double.infinity || h == null) h = 24;

        return AppSkeleton(
          width: w,
          height: h,
          baseColor: widget.baseColor,
          highlightColor: widget.shimmerColor,
        );
      }
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
    return widget.isLoading
        ? (widget.child != null
            ? _buildSkeletonFromChild(widget.child!)
            : _buildDefaultSkeleton())
        : widget.child ?? const SizedBox.shrink();
  }

  Widget _buildDefaultSkeleton() {
    final baseColor = widget.baseColor;
    final highlightColor = widget.shimmerColor;

    // Use LayoutBuilder to adapt content based on available space
    return LayoutBuilder(
      builder: (context, constraints) {
        final content = Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              AppSkeleton(
                width: double.infinity,
                height: 24,
                baseColor: baseColor,
                highlightColor: highlightColor,
              ),
              if (constraints.maxHeight > 80) ...[
                AppGap.lg(),
                AppSkeleton(
                  width: 200,
                  height: 16,
                  baseColor: baseColor,
                  highlightColor: highlightColor,
                ),
              ],
              if (constraints.maxHeight > 120) ...[
                AppGap.sm(),
                AppSkeleton(
                  width: 150,
                  height: 16,
                  baseColor: baseColor,
                  highlightColor: highlightColor,
                ),
              ],
            ],
          ),
        );

        // If height is very small, just show a single centered skeleton bar
        if (constraints.maxHeight < 56) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: AppSkeleton(
                width: double.infinity,
                height: 24, // Consistent height
                baseColor: baseColor,
                highlightColor: highlightColor,
              ),
            ),
          );
        }

        return content;
      },
    );
  }
}
