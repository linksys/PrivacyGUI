import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacygui_widgets/widgets/gap/const/spacing.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';

import '../model/node_instant_actions.dart';

class NodeActionMenu extends StatelessWidget {
  const NodeActionMenu({
    super.key,
    required this.actions,
    required this.onActionTap,
    required this.itemBuilder,
    this.subMenuBuilder,
  });

  final List<NodeInstantActions> actions;
  final void Function(NodeInstantActions)? onActionTap;
  final Widget Function(BuildContext, NodeInstantActions)? subMenuBuilder;
  final Widget Function(BuildContext, NodeInstantActions) itemBuilder;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(
          vertical: Spacing.large1, horizontal: Spacing.medium),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          AppText.labelLarge(loc(context).instantAction),
          PopupMenuButton<NodeInstantActions>(
            color: Theme.of(context).colorScheme.surface,
            iconSize: 20,
            elevation: 10,
            surfaceTintColor: Theme.of(context).colorScheme.surface,
            itemBuilder: (context) {
              return actions
                  .mapIndexed((index, e) => PopupMenuItem<NodeInstantActions>(
                        padding: EdgeInsets.zero,
                        value: e.isSub ? null : e,
                        enabled: !e.isSub,
                        child: PopupMenuItemView(
                          action: e,
                          onActionTap: onActionTap,
                          itemBuilder: itemBuilder,
                          subMenuBuilder: subMenuBuilder,
                        ),
                      ))
                  .toList();
            },
            onSelected: onActionTap,
          )
        ],
      ),
    );
  }
}

class PopupMenuItemView extends StatelessWidget {
  const PopupMenuItemView({
    super.key,
    required this.action,
    required this.onActionTap,
    required this.itemBuilder,
    this.subMenuBuilder,
  });

  final NodeInstantActions action;
  final void Function(NodeInstantActions)? onActionTap;
  final Widget Function(BuildContext, NodeInstantActions) itemBuilder;
  final Widget Function(BuildContext, NodeInstantActions)? subMenuBuilder;

  @override
  Widget build(BuildContext context) {
    return action.isSub
        ? _subMenuBuilder(context, action)
        : Padding(
            padding: const EdgeInsets.symmetric(horizontal: Spacing.small3),
            child: itemBuilder(context, action),
          );
  }

  Widget _subMenuBuilder(BuildContext context, NodeInstantActions action) {
    return Theme(
      data: Theme.of(context).copyWith(
        disabledColor: Theme.of(context).colorScheme.onSurface,
        iconTheme: IconThemeData(
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      child: PopupMenuButton<NodeInstantActions>(
        key: ValueKey('popup-menu-${action.name}'),
        color: Theme.of(context).colorScheme.surface,
        padding: EdgeInsets.zero,
        elevation: 10,
        surfaceTintColor: Theme.of(context).colorScheme.surface,
        itemBuilder: (context) {
          return action.subActions
              .mapIndexed((index, e) => PopupMenuItem<NodeInstantActions>(
                    key: ValueKey('popup-sub-menu-${e.name}'),
                    padding: EdgeInsets.zero,
                    value: e.isSub ? null : e,
                    enabled: !e.isSub,
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: e.isSub ? 0 : Spacing.small3,
                      ),
                      child: e.isSub
                          ? _subMenuBuilder(context, e)
                          : itemBuilder(context, e),
                    ),
                  ))
              .toList();
        },
        onSelected: onActionTap,
        child: subMenuBuilder?.call(context, action) ??
            Container(
              padding: const EdgeInsets.symmetric(horizontal: Spacing.small3),
              constraints: const BoxConstraints(minHeight: 48),
              child: Row(
                children: [
                  Expanded(
                    child: AppText.labelLarge(
                      action.resolveLabel(context),
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  Icon(
                    Icons.arrow_right,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ],
              ),
            ),
      ),
    );
  }
}
