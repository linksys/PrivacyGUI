import 'package:flutter/material.dart';
import 'package:linksys_core/theme/_theme.dart';
import 'package:linksys_core/widgets/_widgets.dart';
import 'package:linksys_core/widgets/base/padding.dart';
import 'package:tap_builder/tap_builder.dart';

part 'panel_with_simple_title.dart';
part 'panel_with_info.dart';
part 'panel_with_value_check.dart';
part 'panel_with_switch.dart';
part 'panel_with_timeline.dart';
part 'device_panel.dart';

/*
class AppPanel extends StatelessWidget {
  final Widget head;
  final Widget? tail;
  final Widget? description;
  final AppWidgetStateColorSet? backgroundColorSet;
  final AppWidgetStateColorSet? borderColorSet;
  final Widget? iconOne;
  final Widget? iconTwo;
  final double? panelHeight;
  final AppEdgeInsets? padding;
  final VoidCallback? onTap;
  final bool forcedHidingAccessory;

  const AppPanel({
    Key? key,
    required this.head,
    this.tail,
    this.description,
    this.backgroundColorSet,
    this.borderColorSet,
    this.iconOne,
    this.iconTwo,
    this.panelHeight,
    this.padding,
    this.onTap,
    this.forcedHidingAccessory = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TapBuilder(
      onTap: onTap,
      builder: (context, state, hasFocus) {
        switch (state) {
          case TapState.inactive:
            return Semantics(
              enabled: true,
              selected: true,
              child: AppPanelLayout.inactive(
                head: head,
                tail: tail,
                description: description,
                backgroundColorSet: backgroundColorSet,
                borderColorSet: borderColorSet,
                iconOne: iconOne,
                iconTwo: iconTwo,
                panelHeight: panelHeight,
                padding: padding,
                isHidingAccessory: (forcedHidingAccessory || onTap == null),
              ),
            );
          case TapState.hover:
            return Semantics(
              enabled: true,
              selected: true,
              child: AppPanelLayout.hovered(
                head: head,
                tail: tail,
                description: description,
                backgroundColorSet: backgroundColorSet,
                borderColorSet: borderColorSet,
                iconOne: iconOne,
                iconTwo: iconTwo,
                panelHeight: panelHeight,
                padding: padding,
                isHidingAccessory: (forcedHidingAccessory || onTap == null),
              ),
            );
          case TapState.pressed:
            return Semantics(
              enabled: true,
              selected: true,
              child: AppPanelLayout.pressed(
                head: head,
                tail: tail,
                description: description,
                backgroundColorSet: backgroundColorSet,
                borderColorSet: borderColorSet,
                iconOne: iconOne,
                iconTwo: iconTwo,
                panelHeight: panelHeight,
                padding: padding,
                isHidingAccessory: (forcedHidingAccessory || onTap == null),
              ),
            );
          case TapState.disabled:
            return Semantics(
              enabled: true,
              selected: true,
              child: AppPanelLayout.disabled(
                head: head,
                tail: tail,
                description: description,
                backgroundColorSet: backgroundColorSet,
                borderColorSet: borderColorSet,
                iconOne: iconOne,
                iconTwo: iconTwo,
                panelHeight: panelHeight,
                padding: padding,
                isHidingAccessory: (forcedHidingAccessory || onTap == null),
              ),
            );
        }
      },
    );
  }
}
 */

class AppPanelLayout extends StatelessWidget {
  final AppWidgetState _state;
  final Widget head;
  final Widget? tail;
  final Widget? description;
  final AppWidgetStateColorSet? backgroundColorSet;
  final AppWidgetStateColorSet? borderColorSet;
  final Widget? iconOne;
  final Widget? iconTwo;
  final double? panelHeight;
  final AppEdgeInsets? padding;
  final bool isHidingAccessory;

  const AppPanelLayout.inactive({
    Key? key,
    required this.head,
    this.tail,
    this.description,
    this.backgroundColorSet,
    this.borderColorSet,
    this.iconOne,
    this.iconTwo,
    this.panelHeight,
    this.padding,
    this.isHidingAccessory = false,
  })  : _state = AppWidgetState.inactive,
        super(key: key);

  const AppPanelLayout.hovered({
    Key? key,
    required this.head,
    this.tail,
    this.description,
    this.backgroundColorSet,
    this.borderColorSet,
    this.iconOne,
    this.iconTwo,
    this.panelHeight,
    this.padding,
    this.isHidingAccessory = false,
  })  : _state = AppWidgetState.hovered,
        super(key: key);

  const AppPanelLayout.pressed({
    Key? key,
    required this.head,
    this.tail,
    this.description,
    this.backgroundColorSet,
    this.borderColorSet,
    this.iconOne,
    this.iconTwo,
    this.panelHeight,
    this.padding,
    this.isHidingAccessory = false,
  })  : _state = AppWidgetState.pressed,
        super(key: key);

  const AppPanelLayout.disabled({
    Key? key,
    required this.head,
    this.tail,
    this.description,
    this.backgroundColorSet,
    this.borderColorSet,
    this.iconOne,
    this.iconTwo,
    this.panelHeight,
    this.padding,
    this.isHidingAccessory = false,
  })  : _state = AppWidgetState.disabled,
        super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final iconOne = this.iconOne;
    final iconTwo = this.iconTwo;
    final tail = this.tail;
    final description = this.description;
    final backgroundColor = backgroundColorSet?.resolve(_state);
    final borderColor = borderColorSet?.resolve(_state);

    return AnimatedContainer(
      duration: theme.durations.quick,
      decoration: BoxDecoration(
        color: backgroundColor,
        border: borderColor == null
            ? null
            : Border.all(
                color: borderColor,
              ),
      ),
      height: panelHeight,
      child: AppPadding(
        padding: padding ??
            const AppEdgeInsets.symmetric(
                vertical: AppGapSize.regular, horizontal: AppGapSize.semiBig),
        child: Row(
          children: [
            if (iconOne != null)
              AppPadding(
                padding: const AppEdgeInsets.only(right: AppGapSize.regular),
                child: iconOne,
              ),
            if (iconTwo != null)
              AppPadding(
                padding: const AppEdgeInsets.only(right: AppGapSize.regular),
                child: iconTwo,
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  head,
                  if (description != null) description
                ],
              ),
            ),
            if (tail != null) AppPadding(
              padding: const AppEdgeInsets.only(left: AppGapSize.regular),
              child: tail,
            ),
            if (!isHidingAccessory)
              AppPadding(
                padding: const AppEdgeInsets.only(left: AppGapSize.semiSmall),
                child: AppIcon(
                  icon: theme.icons.characters.chevronRight,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
