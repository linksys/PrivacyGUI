import 'package:flutter/material.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';
import 'package:privacy_gui/page/dashboard/views/components/loading_tile.dart';

class DashboardTile extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final EdgeInsets? padding;
  final double? height;
  final double? width;

  const DashboardTile({
    super.key,
    required this.isLoading,
    required this.child,
    this.padding,
    this.height,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? AppCard(
            padding: padding ?? EdgeInsets.zero,
            child: SizedBox(
              width: width ?? double.infinity,
              height: height ?? 150,
              child: const LoadingTile(),
            ),
          )
        : AppCard(
            padding: padding,
            child: child,
          );
  }
}
