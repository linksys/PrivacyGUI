import 'package:flutter/material.dart';

class StatefulPopupMenuItem<T> extends PopupMenuEntry<T> {
  const StatefulPopupMenuItem({
    Key? key,
    this.enabled = true,
    this.height = kMinInteractiveDimension,
    required this.child,
    this.onTap,
    this.padding,
    this.expandChild = false,
  }) : super(key: key);

  /// Whether the user can interact with this item.
  final bool enabled;

  /// The height of the menu item.
  ///
  /// Defaults to [kMinInteractiveDimension] pixels.
  @override
  final double height;

  final VoidCallback? onTap;
  final EdgeInsets? padding;
  final bool expandChild;

  /// The widget below this widget in the tree.
  final Widget child;

  @override
  State<StatefulPopupMenuItem<T>> createState() =>
      _StatefulPopupMenuItemState<T>();

  @override
  bool represents(T? value) =>
      false; // Crucial: Doesn't represent a value, so it won't trigger onSelected
}

class _StatefulPopupMenuItemState<T> extends State<StatefulPopupMenuItem<T>> {
  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    final EdgeInsetsGeometry padding = widget.padding ??
        (theme.useMaterial3
            ? const EdgeInsets.symmetric(horizontal: 12.0)
            : const EdgeInsets.symmetric(horizontal: 16.0));

    final Widget itemContent = widget.expandChild
        ? widget.child
        : Align(
            alignment: AlignmentDirectional.centerStart, child: widget.child);

    // This is the core layout that mimics PopupMenuItem.
    Widget item = ConstrainedBox(
      constraints: BoxConstraints(minHeight: widget.height),
      child: Padding(
        key: const Key('menu item padding'),
        padding: padding,
        child: itemContent,
      ),
    );

    // If disabled, return the item without the InkWell.
    if (!widget.enabled) {
      return item;
    }

    // Wrap in an InkWell to get the ripple effect without closing the menu.
    return InkWell(
      onTap: widget.onTap,
      canRequestFocus: false, // Prevents the item from being focused.
      child: item,
    );
  }
}