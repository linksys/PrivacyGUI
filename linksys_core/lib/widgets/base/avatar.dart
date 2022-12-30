import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:linksys_core/theme/data/avatars.dart';
import 'package:linksys_core/theme/data/icons.dart';

import '../../theme/_theme.dart';

enum AppAvatarSize {
  extraSmall,
  small,
  normal,
  large,
}

extension AppAvatarSizeExtension on AppAvatarSizesData {
  double resolve(AppAvatarSize size) {
    switch (size) {
      case AppAvatarSize.extraSmall:
        return extraSmall;
      case AppAvatarSize.small:
        return small;
      case AppAvatarSize.normal:
        return normal;
      case AppAvatarSize.large:
        return large;
    }
  }
}

class AppAvatar extends StatelessWidget {
  const AppAvatar(
    this.data, {
    Key? key,
    this.color,
    this.size = AppAvatarSize.normal,
  }) : super(key: key);

  const AppAvatar.extraSmall(
    this.data, {
    Key? key,
    this.color,
  })  : size = AppAvatarSize.extraSmall,
        super(key: key);

  const AppAvatar.small(
    this.data, {
    Key? key,
    this.color,
  })  : size = AppAvatarSize.small,
        super(key: key);

  const AppAvatar.normal(
    this.data, {
    Key? key,
    this.color,
  })  : size = AppAvatarSize.normal,
        super(key: key);

  const AppAvatar.large(
    this.data, {
    Key? key,
    this.color,
  })  : size = AppAvatarSize.large,
        super(key: key);

  final PictureProvider data;
  final Color? color;
  final AppAvatarSize size;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final size = theme.avatar.resolve(this.size);
    return ClipRRect(
      borderRadius: BorderRadius.circular(100.0),
      child: SvgPicture(
        data,
        width: size,
        height: size,
      ),
    );
  }
}
