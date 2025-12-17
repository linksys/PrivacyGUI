import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Item for AppRadioList
class AppRadioListItem<T> {
  final String? title;
  final T value;
  final Widget? titleWidget;
  final Widget? expandedWidget;
  final Widget? subTitleWidget;
  final bool enabled;

  AppRadioListItem({
    this.title,
    required this.value,
    this.titleWidget,
    this.expandedWidget,
    this.subTitleWidget,
    this.enabled = true,
  });
}

/// A list of radio buttons that can be selected.
///
/// This is a composed component that uses UI Kit components internally.
/// Migrated from privacygui_widgets for decoupling.
class AppRadioList<T> extends StatefulWidget {
  final List<AppRadioListItem<T>> items;
  final T? initial;
  final T? selected;
  final void Function(int index, T? value)? onChanged;
  final MainAxisSize mainAxisSize;
  final bool withDivider;
  final double? itemHeight;

  const AppRadioList({
    super.key,
    required this.items,
    this.initial,
    this.selected,
    this.onChanged,
    this.withDivider = false,
    this.mainAxisSize = MainAxisSize.max,
    this.itemHeight,
  });

  @override
  State<AppRadioList> createState() => _AppRadioListState<T>();
}

class _AppRadioListState<T> extends State<AppRadioList<T>> {
  T? _selected;

  @override
  void initState() {
    super.initState();
    setState(() {
      _selected = widget.selected ?? widget.initial;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.selected != null) {
      setState(() {
        _selected = widget.selected;
      });
    }
    return Column(
      mainAxisSize: widget.mainAxisSize,
      children: widget.items
          .mapIndexed((index, e) => _itemTile(item: e))
          .expandIndexed<Widget>((index, element) sync* {
        if (index != widget.items.length - 1) {
          yield element;
          if (widget.withDivider) yield const Divider();
        } else {
          yield element;
        }
      }).toList(),
    );
  }

  Widget _itemTile({required AppRadioListItem item}) {
    return Opacity(
      opacity: item.enabled ? 1 : 0.5,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            constraints: const BoxConstraints(minHeight: 56),
            height: widget.itemHeight,
            child: InkWell(
              onTap: item.enabled
                  ? () {
                      setState(() {
                        _selected = item.value;
                        widget.onChanged?.call(
                            widget.items.indexWhere(
                                (element) => element.value == _selected),
                            _selected);
                      });
                    }
                  : null,
              child: Row(
                children: [
                  AbsorbPointer(
                    child: Radio<T>(
                      value: item.value,
                      groupValue: _selected,
                      onChanged: (T? value) {
                        widget.onChanged?.call(
                            widget.items.indexWhere(
                                (element) => element.value == _selected),
                            _selected);
                      },
                    ),
                  ),
                  AppGap.xs(),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        item.titleWidget ??
                            AppText.labelLarge(item.title ?? ''),
                        if (item.subTitleWidget != null) ...[
                          item.subTitleWidget!,
                        ]
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
          if (item.expandedWidget != null) ...[
            AppGap.sm(),
            item.expandedWidget!,
            AppGap.xxl()
          ],
        ],
      ),
    );
  }
}
