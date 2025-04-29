import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/theme/_theme.dart';
import 'package:privacygui_widgets/widgets/buttons/button.dart';
import 'package:privacygui_widgets/widgets/table/table_settings_view.dart';
import 'package:privacygui_widgets/widgets/text/app_text.dart';
import 'package:super_tooltip/super_tooltip.dart';

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
  final Widget Function(BuildContext, WidgetRef, int, T, String?)?
      editCellBuilder;
  final int? editRowIndex;
  final int?
      pivotalIndex; // Once the focus value of the pivotal cell changes, all other cells need to be rechecked
  final T Function() createNewItem;
  final String addLabel;
  final IconData? addIcon;
  final bool? isEditingDataValid;
  final void Function(int? index, T cell)? onSaved;
  final void Function(int? index, T cell)? onDeleted;
  final String? emptyMessage;
  final bool addEnabled;
  final String? Function(int index)? onValidate;

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
    this.pivotalIndex,
    required this.createNewItem,
    this.addLabel = '',
    this.addIcon,
    this.isEditingDataValid,
    this.onSaved,
    this.onDeleted,
    this.emptyMessage,
    this.addEnabled = true,
    this.onValidate,
  });

  @override
  ConsumerState<AppEditableTableSettingsView<T>> createState() =>
      _AppEditableTableSettingsViewState<T>();
}

class _AppEditableTableSettingsViewState<T>
    extends ConsumerState<AppEditableTableSettingsView<T>> {
  int? _editRow;
  T? _tempItem;
  Map<int, String?> errorMap = {};
  Map<int, SuperTooltipController> tipControllerMap = {};

  @override
  void initState() {
    tipControllerMap = List.generate(
      widget.headers.length,
      (index) => SuperTooltipController(),
    ).asMap();
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
          ? Wrap(
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
          ? Wrap(
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
          :
          // NOTE: SuperTooltip widget will be shown unexpectedly even if
          // showTooltip is not called. So it will only be installed when the error exists
          errorMap[index] != null
              ? SuperTooltip(
                  controller: tipControllerMap[index],
                  showBarrier: false,
                  shadowOffset: Offset(0, 0),
                  shadowBlurRadius: 5,
                  shadowSpreadRadius: 1,
                  borderColor: Theme.of(context).colorScheme.error,
                  arrowBaseWidth: 10,
                  arrowLength: 8,
                  arrowTipDistance: 35,
                  borderWidth: 1,
                  borderRadius: 5,
                  content: AppText.bodySmall(
                    errorMap[index] ?? '',
                    color: Theme.of(context).colorScheme.error,
                  ),
                  child: Focus(
                    onFocusChange: (focus) =>
                        _focusChangedHandler(focus, index),
                    child: widget.editCellBuilder?.call(
                            context, ref, index, data, errorMap[index]) ??
                        SizedBox.shrink(),
                  ),
                )
              : Focus(
                  onFocusChange: (focus) => _focusChangedHandler(focus, index),
                  child: widget.editCellBuilder
                          ?.call(context, ref, index, data, errorMap[index]) ??
                      SizedBox.shrink(),
                ),
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

  void _focusChangedHandler(bool focus, int index) {
    if (index == widget.pivotalIndex) {
      // Everytime the focus state changes, recheck all other cell items
      setState(() {
        for (int i = 0; i < widget.headers.length; i++) {
          final error = widget.onValidate?.call(i);
          errorMap[i] = error;
        }
      });
      // Immediately show or hide tooltips for each cell item
      for (int i = 0; i < widget.headers.length; i++) {
        Future.delayed(Duration(milliseconds: 100), () {
          final controller = tipControllerMap[i];
          if (errorMap[i] != null) {
            controller?.showTooltip();
          } else {
            controller?.hideTooltip();
          }
        });
      }
    } else {
      // Only when the state is unfocused, the tooltips will be shown or hidden
      if (!focus) {
        // Check the current focused cell item
        setState(() {
          final error = widget.onValidate?.call(index);
          errorMap[index] = error;
        });
        Future.delayed(Duration(milliseconds: 100), () {
          final controller = tipControllerMap[index];
          if (errorMap[index] != null) {
            controller?.showTooltip();
          } else {
            controller?.hideTooltip();
          }
        });
      }
    }
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
