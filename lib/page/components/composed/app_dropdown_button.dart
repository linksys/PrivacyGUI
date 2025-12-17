import 'package:flutter/material.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// A dropdown button adapted from privacygui_widgets for UI Kit decoupling.
/// Uses UI Kit's AppText and AppFontIcons internally.
class AppDropdownButton<T> extends StatefulWidget {
  final String? title;
  final List<T> items;
  final T? initial;
  final T? selected;
  final String Function(T item) label;
  final void Function(T value)? onChanged;

  const AppDropdownButton({
    super.key,
    this.title,
    required this.items,
    this.initial,
    this.selected,
    required this.label,
    this.onChanged,
  });

  @override
  State<AppDropdownButton<T>> createState() => _AppDropdownButtonState();
}

class _AppDropdownButtonState<T> extends State<AppDropdownButton<T>> {
  late T _selected;

  @override
  void initState() {
    super.initState();
    setState(() {
      _selected = widget.selected ?? widget.initial ?? widget.items.first;
    });
  }

  @override
  Widget build(BuildContext context) {
    final widgetSelected = widget.selected;
    if (widgetSelected != null) {
      setState(() {
        _selected = widgetSelected;
      });
    }
    final enable = widget.onChanged != null;
    return InputDecorator(
      decoration: InputDecoration(
        labelText: widget.title,
        border: OutlineInputBorder(),
        filled: true,
        enabled: enable,
      ),
      child: DropdownButtonHideUnderline(
        child: ButtonTheme(
          child: Theme(
            data: Theme.of(context).copyWith(
                focusColor: Theme.of(context).colorScheme.primaryContainer),
            child: DropdownButton<T>(
              elevation: 0,
              padding: EdgeInsets.zero,
              value: _selected,
              isDense: true,
              isExpanded: true,
              items: widget.items
                  .map((e) => DropdownMenuItem<T>(
                        value: e,
                        child: Container(
                          width: double.infinity,
                          constraints: BoxConstraints(minHeight: 48.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  widget.label(e),
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelMedium
                                      ?.copyWith(
                                        color: e == _selected
                                            ? Theme.of(context)
                                                .colorScheme
                                                .primary
                                            : Theme.of(context)
                                                .colorScheme
                                                .onSurface,
                                      ),
                                ),
                              ),
                              if (e == _selected)
                                Icon(
                                  AppFontIcons.check,
                                  color: Theme.of(context).colorScheme.primary,
                                )
                            ],
                          ),
                        ),
                      ))
                  .toList(),
              selectedItemBuilder: (context) => widget.items
                  .map((e) => Text(
                        widget.label(e),
                        overflow: TextOverflow.ellipsis,
                        style:
                            Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: enable
                                      ? null
                                      : Theme.of(context).colorScheme.outline,
                                ),
                      ))
                  .toList(),
              focusColor: Colors.transparent,
              onChanged: widget.onChanged == null
                  ? null
                  : (value) {
                      if (value == null) {
                        return;
                      }
                      setState(() {
                        _selected = value;
                      });
                      widget.onChanged?.call(value);
                    },
            ),
          ),
        ),
      ),
    );
  }
}
