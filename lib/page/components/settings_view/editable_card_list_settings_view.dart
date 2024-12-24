import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/table/card_list_settings_view.dart';

class EditableCardListsettingsView<T> extends StatefulWidget {
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

  const EditableCardListsettingsView({
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
  });

  @override
  State<EditableCardListsettingsView<T>> createState() =>
      _EditableCardListsettingsViewState<T>();
}

class _EditableCardListsettingsViewState<T>
    extends State<EditableCardListsettingsView<T>> {
  @override
  Widget build(BuildContext context) {
    return AppCardListSettingsView<T>(
      title: widget.title,
      actions: [
        if (widget.addLabel != null)
          AppTextButton(
            widget.addLabel!,
            icon: widget.addIcon ?? LinksysIcons.add,
            onTap: widget.addEnabled ? () {
              onEdit(null);
            } : null,
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
              onTap: () {
                onEdit(data);
              }),
          AppIconButton(
            icon: LinksysIcons.delete,
            color: Theme.of(context).colorScheme.error,
            onTap: () {
              widget.onDelete?.call(widget.dataList.indexOf(data), data);
            },
          ),
        ],
        content: widget.itemCardBuilder(context, data).content,
      ),
    );
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
