import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/table/card_list_settings_view.dart';

class AppEditableCardListSettingsView<T> extends StatefulWidget {
  final String? title;
  final String? addLabel;
  final IconData? addIcon;
  final List<T> dataList;
  final EditableListItem Function(BuildContext, T) itemCardBuilder;
  final String editRoute;
  final String? emptyMessage;
  final bool addEnabled;

  final void Function(int, T)? onSave;
  final void Function(int, T)? onDelete;

  /// The prefix of the list's identifiers (constitution 11.3): the add button
  /// is `{identifier}-add`, and a card's actions are `{identifier}-edit-{key}`
  /// and `-delete-`.
  final String? identifier;

  /// A card's key, from its data: never its position or translated text. It
  /// is required with [identifier].
  final String Function(T item)? rowKey;

  const AppEditableCardListSettingsView({
    super.key,
    this.title,
    this.addIcon,
    this.addLabel,
    required this.dataList,
    required this.itemCardBuilder,
    required this.editRoute,
    this.emptyMessage,
    this.onSave,
    this.onDelete,
    this.addEnabled = true,
    this.identifier,
    this.rowKey,
  }) : assert(identifier == null || rowKey != null,
            'A list with an identifier needs a rowKey.');

  @override
  State<AppEditableCardListSettingsView<T>> createState() =>
      _AppEditableCardListSettingsViewState<T>();
}

class _AppEditableCardListSettingsViewState<T>
    extends State<AppEditableCardListSettingsView<T>> {
  @override
  Widget build(BuildContext context) {
    return AppCardListSettingsView<T>(
      title: widget.title,
      actions: [
        if (widget.addLabel != null)
          AppTextButton(
            widget.addLabel!,
            icon: widget.addIcon ?? LinksysIcons.add,
            identifier:
                widget.identifier == null ? null : '${widget.identifier}-add',
            onTap: widget.addEnabled
                ? () {
                    onEdit(null);
                  }
                : null,
          ),
      ],
      dataList: widget.dataList,
      emptyView: SizedBox(
          height: 120,
          child: Center(child: AppText.bodyLarge(widget.emptyMessage ?? ''))),
      itemCardBuilder: (context, data) => EditableListItemWidget(
        title: widget.itemCardBuilder(context, data).title,
        actions: [
          AppIconButton(
              icon: LinksysIcons.edit,
              identifier: _rowIdentifier('edit', data),
              onTap: () {
                onEdit(data);
              }),
          AppIconButton(
            icon: LinksysIcons.delete,
            color: Theme.of(context).colorScheme.error,
            identifier: _rowIdentifier('delete', data),
            onTap: () {
              widget.onDelete?.call(widget.dataList.indexOf(data), data);
            },
          ),
        ],
        content: widget.itemCardBuilder(context, data).content,
      ),
    );
  }

  /// The identifier of [item]'s [action], `{identifier}-{action}-{key}`.
  String? _rowIdentifier(String action, T item) {
    final identifier = widget.identifier;
    final rowKey = widget.rowKey;
    if (identifier == null || rowKey == null) return null;
    return '$identifier-$action-${rowKey(item)}';
  }

  void onEdit(T? data) {
    context.pushNamed<T>(widget.editRoute, extra: {
      'items': widget.dataList,
      if (data != null) 'edit': data,
    }).then((value) {
      if (value != null) {
        widget.onSave
            ?.call(data == null ? -1 : widget.dataList.indexOf(data), value);
      }
    });
  }
}

class EditableListItem {
  final String title;
  final Widget content;

  EditableListItem({required this.title, required this.content});
}

class EditableListItemWidget extends StatelessWidget {
  final String title;
  final List<Widget> actions;
  final Widget content;
  const EditableListItemWidget({
    super.key,
    required this.title,
    required this.actions,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [AppText.titleSmall(title), Wrap(children: actions)],
        ),
        const AppGap.medium(),
        content,
      ],
    );
  }
}
