import 'package:flutter/widgets.dart';
import 'package:linksys_core/theme/_theme.dart';
import 'package:linksys_core/widgets/base/padding.dart';
import 'package:linksys_core/widgets/buttons/button_bases.dart';
import 'package:tap_builder/tap_builder.dart';
import 'package:linksys_core/widgets/state.dart';

part 'icon_button.dart';
part 'primary_button.dart';
part 'secondary_button.dart';
part 'tertiary_button.dart';

class AppButton extends StatelessWidget {
  const AppButton({
    Key? key,
    this.icon,
    this.title,
    this.onTap,
    this.mainAxisSize = MainAxisSize.min,
  })
      : assert(
  icon != null || title != null,
  ),
        super(key: key);

  final IconData? icon;
  final String? title;
  final MainAxisSize mainAxisSize;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return TapBuilder(
      onTap: onTap,
      builder: (context, state, hasFocus) {
        switch (state) {
          case TapState.hover:
            return Semantics(
              enabled: true,
              selected: true,
              child: AppButtonLayout.hovered(
                icon: icon,
                title: title,
                mainAxisSize: mainAxisSize,
              ),
            );
          case TapState.pressed:
            return Semantics(
              enabled: true,
              selected: true,
              child: AppButtonLayout.pressed(
                icon: icon,
                title: title,
                mainAxisSize: mainAxisSize,
              ),
            );
          case TapState.inactive:
            return Semantics(
              enabled: true,
              selected: true,
              child: AppButtonLayout.inactive(
                icon: icon,
                title: title,
                mainAxisSize: mainAxisSize,
              ),
            );
          case TapState.disabled:
            return Semantics(
              enabled: false,
              selected: false,
              child: AppButtonLayout.disabled(
                icon: icon,
                title: title,
                mainAxisSize: mainAxisSize,
              ),
            );
        }
      },
    );
  }
}
