import 'package:flutter/material.dart';
import 'package:linksys_core/theme/_theme.dart';

enum AppBoxSize {
  custom,
  small,
  semiSmall,
  regular,
  semiBig,
  big,
}

class AppBox extends StatelessWidget {
  const AppBox(this.size, {
    Key? key,
    this.spacingSize = AppBoxSize.custom,
  }) : super(key: key);

  const AppBox.small({
    Key? key, this.size,
  })
      : spacingSize = AppBoxSize.small,
        super(key: key);

  final AppBoxSize spacingSize;
  final double? size;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    double size = this.size ?? 0;
    switch (spacingSize) {
      case AppBoxSize.custom:
        break;
      case AppBoxSize.small:
        size = theme.spacing.small;
        break;
      case AppBoxSize.semiSmall:
        size = theme.spacing.semiSmall;
        break;
      case AppBoxSize.regular:
        size = theme.spacing.regular;
        break;
      case AppBoxSize.semiBig:
        size = theme.spacing.semiBig;
        break;
      case AppBoxSize.big:
        size = theme.spacing.big;
        break;
    }

    return SizedBox(
      width: size,
      height: size,
    );
  }
}
