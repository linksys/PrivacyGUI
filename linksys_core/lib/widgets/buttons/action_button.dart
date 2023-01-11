import 'package:flutter/material.dart';
import 'package:linksys_core/theme/_theme.dart';
import 'package:linksys_core/widgets/buttons/button_bases.dart';
import 'package:linksys_core/widgets/state.dart';
import 'package:tap_builder/tap_builder.dart';

class AppActionButton extends StatelessWidget {
  final String title;
  final VoidCallback? actions;

  const AppActionButton(
    this.title, {
    super.key,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return TapBuilder(
      onTap: actions,
      builder: (context, state, hasFocus) {
        final theme = AppTheme.of(context);
        final foregroundColorSet = AppWidgetStateColorSet(
          inactive: theme.colors.ctaPrimary,
          pressed: theme.colors.ctaSecondary,
          hovered: theme.colors.ctaSecondary.withOpacity(0.6),
          disabled: theme.colors.ctaPrimary,
        );

        switch (state) {
          case TapState.hover:
            return Semantics(
              enabled: true,
              selected: true,
              child: AppActionButtonLayout.hovered(
                title: title,
                hasActions: actions != null,
                foregroundColorSet: foregroundColorSet,
              ),
            );
          case TapState.pressed:
            return Semantics(
              enabled: true,
              selected: true,
              child: AppActionButtonLayout.pressed(
                title: title,
                hasActions: actions != null,
                foregroundColorSet: foregroundColorSet,
              ),
            );
          case TapState.inactive:
            return Semantics(
              enabled: true,
              selected: true,
              child: AppActionButtonLayout.inactive(
                title: title,
                hasActions: actions != null,
                foregroundColorSet: foregroundColorSet,
              ),
            );
          case TapState.disabled:
            return Semantics(
              enabled: true,
              selected: true,
              child: AppActionButtonLayout.disabled(
                title: title,
                hasActions: actions != null,
                foregroundColorSet: foregroundColorSet,
              ),
            );
        }
      },
    );
  }
}
