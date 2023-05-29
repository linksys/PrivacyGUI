import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum SettingTileAxis {
  vertical,
  horizontal,
}

class SettingTile extends ConsumerWidget {
  const SettingTile({
    Key? key,
    required this.title,
    this.value,
    this.description,
    this.background,
    this.tileHeight,
    this.padding,
    this.icon,
    this.axis = SettingTileAxis.horizontal,
    this.onPress,
  }) : super(key: key);

  final Widget title;
  final Widget? value;
  final String? description;
  final Color? background;
  final double? tileHeight;
  final EdgeInsets? padding;
  final Widget? icon;
  final SettingTileAxis? axis;
  final VoidCallback? onPress;

  Widget _arrangeInHorizontal() {
    return Row(
      children: [
        Expanded(
          child: title,
        ),
        if (value != null)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: value,
          ),
        if (onPress != null) icon ?? const Icon(Icons.arrow_forward_ios),
      ],
    );
  }

  Widget _arrangeInVertical() {
    return Row(
      children: [
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              title,
              if (value != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: value,
                )
            ],
          ),
        ),
        if (onPress != null)
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: icon ?? const Icon(Icons.arrow_forward_ios),
          )
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: onPress,
      child: Container(
        height: tileHeight,
        decoration:
            const BoxDecoration(color: Colors.lightBlueAccent ?? Colors.transparent),
        padding: padding ?? EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            (axis == SettingTileAxis.horizontal)
                ? _arrangeInHorizontal()
                : _arrangeInVertical(),
            if (description != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  description!,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: const Color.fromRGBO(102, 102, 102, 1.0),
                      ),
                ),
              )
          ],
        ),
      ),
    );
  }
}

class SectionTile extends ConsumerWidget {
  const SectionTile({
    Key? key,
    this.enabled = true,
    required this.header,
    required this.child,
  }) : super(key: key);

  final bool enabled;
  final Widget header;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        header,
        Opacity(
          opacity: enabled ? 1 : 0.4,
          child: AbsorbPointer(
            absorbing: !enabled,
            child: child,
          ),
        ),
      ],
    );
  }
}
