import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/theme/_theme.dart';
import 'package:privacygui_widgets/widgets/buttons/button.dart';
import 'package:privacygui_widgets/widgets/table/table_settings_view.dart';
import 'package:privacygui_widgets/widgets/text/app_text.dart';

class AppEditableTableSettingsView<T> extends ConsumerStatefulWidget {
  final String? title;
  final List<String> headers;
  final TextStyle? headerStyle;
  final String? actionHeader;
  final Map<int, TableColumnWidth>? columnWidths;
  final List<T> dataList;
  final void Function(int? index, T? data)? onStartEdit;
  final T Function()? getEditItem;
  final Widget Function(BuildContext, WidgetRef, int, T) cellBuilder;
  final Widget Function(BuildContext, WidgetRef, int, T)? editCellBuilder;
  final int? editRowIndex;
  final T Function() createNewItem;
  final String addLabel;
  final IconData? addIcon;
  final bool? isEditingDataValid;
  final void Function(int? index, T cell)? onSaved;
  final void Function(int? index, T cell)? onDeleted;
  final String? emptyMessage;
  final bool addEnabled;

  const AppEditableTableSettingsView({
    super.key,
    this.title,
    required this.headers,
    this.headerStyle,
    this.actionHeader,
    this.columnWidths,
    this.onStartEdit,
    this.getEditItem,
    required this.dataList,
    required this.cellBuilder,
    this.editCellBuilder,
    this.editRowIndex,
    required this.createNewItem,
    this.addLabel = '',
    this.addIcon,
    this.isEditingDataValid,
    this.onSaved,
    this.onDeleted,
    this.emptyMessage,
    this.addEnabled = true,
  });

  @override
  ConsumerState<AppEditableTableSettingsView<T>> createState() =>
      _AppEditableTableSettingsViewState<T>();
}

class _AppEditableTableSettingsViewState<T>
    extends ConsumerState<AppEditableTableSettingsView<T>> {
  int? _editRow;
  T? _tempItem;
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final lastIndex = widget.headers.length;
    return AppTableSettingsView<T>(
      title: widget.title,
      headers: [
        ...widget.headers,
        (widget.actionHeader ?? loc(context).action)
      ],
      dataList: [
        ...widget.dataList,
        if (isNew()) _tempItem!,
      ],
      columnWidths: widget.columnWidths,
      editRowIndex: _editRow,
      emptyView: SizedBox(
          height: 120,
          child: Center(child: AppText.bodyLarge(widget.emptyMessage ?? ''))),
      cellBuilder: (context, index, data) => index == lastIndex
          ? Row(
              children: [
                AppIconButton(
                    icon: LinksysIcons.edit,
                    onTap: () {
                      _editItem(widget.dataList.indexOf(data), data);
                    }),
                AppIconButton(
                  icon: LinksysIcons.delete,
                  color: Theme.of(context).colorScheme.error,
                  onTap: () {
                    widget.onDeleted?.call(index, data);
                  },
                ),
              ],
            )
          : widget.cellBuilder(context, ref, index, data),
      editCellBuilder: (context, index, data) => index == lastIndex
          ? Row(
              children: [
                AppIconButton(
                  icon: LinksysIcons.check,
                  color: (widget.isEditingDataValid ?? true)
                      ? Theme.of(context).colorSchemeExt.green
                      : Theme.of(context).colorScheme.outline,
                  onTap: (widget.isEditingDataValid ?? true)
                      ? () {
                          widget.onSaved?.call(isNew() ? null : _editRow, data);
                          _editItem(null, null);
                        }
                      : null,
                ),
                AppIconButton(
                  icon: LinksysIcons.close,
                  onTap: () {
                    _editItem(null, null);
                  },
                ),
              ],
            )
          : widget.editCellBuilder?.call(context, ref, index, data) ??
              SizedBox.shrink(),
      bottomWidget: AppTextButton(
        widget.addLabel,
        icon: widget.addIcon ?? LinksysIcons.add,
        onTap: widget.addEnabled
            ? () {
                final newItem = widget.createNewItem.call();
                setState(() {
                  _tempItem = newItem;
                  _editRow = widget.dataList.length;
                });
                _editItem(widget.dataList.length, newItem);
              }
            : null,
      ),
    );
  }

  void _editItem(int? index, T? item) {
    setState(() {
      _tempItem = item;
      _editRow = index;
    });
    widget.onStartEdit?.call(_editRow, _tempItem);
  }

  bool isNew() => widget.dataList.length == _editRow;
}
