import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:linksys_core/theme/data/icons.dart';

import '../../theme/_theme.dart';

enum AppIconSize {
  small,
  regular,
  big,
}

extension AppIconSizeExtension on AppIconSizesData {
  double resolve(AppIconSize size) {
    switch (size) {
      case AppIconSize.small:
        return small;
      case AppIconSize.regular:
        return regular;
      case AppIconSize.big:
        return big;
    }
  }
}

class AppIcon extends StatelessWidget {
  const AppIcon(
    this.data, {
    Key? key,
    this.color,
    this.size = AppIconSize.regular,
  }) : super(key: key);

  const AppIcon.small(
    this.data, {
    Key? key,
    this.color,
  })  : size = AppIconSize.small,
        super(key: key);

  const AppIcon.regular(
    this.data, {
    Key? key,
    this.color,
  })  : size = AppIconSize.regular,
        super(key: key);

  const AppIcon.big(
    this.data, {
    Key? key,
    this.color,
  })  : size = AppIconSize.big,
        super(key: key);

  final IconData? data;
  final Color? color;
  final AppIconSize size;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final color = this.color;
    return Icon(
      data,
      color: color,
      size: theme.icons.sizes.resolve(size),
    );
  }
}