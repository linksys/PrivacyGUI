import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:linksys_moab/design/colors.dart';
import 'package:linksys_moab/page/components/shortcuts/sized_box.dart';

class SettingTile extends StatelessWidget {
  const SettingTile({
    Key? key,
    required this.title,
    this.value,
    this.icon,
    this.onPress,
    this.background,
    this.tileHeight,
    this.padding,
  }) : super(key: key);

  final Widget title;
  final Widget? value;
  final Widget? icon;
  final VoidCallback? onPress;
  final Color? background;
  final double? tileHeight;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPress,
      child: Container(
        decoration: BoxDecoration(color: background ?? Colors.transparent),
        height: tileHeight,
        child: Padding(
          padding: padding ?? EdgeInsets.zero,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: title),
              value ?? const Center(),
              if (onPress != null) box8(),
              if (onPress != null) icon ?? const Icon(Icons.arrow_forward_ios)
            ],
          ),
        ),
      ),
    );
  }
}

class SettingTileWithDescription extends StatelessWidget {
  const SettingTileWithDescription({
    Key? key,
    required this.title,
    required this.value,
    required this.description,
    this.onPress,
    this.background,
    this.tileHeight,
    this.padding,
  }) : super(key: key);

  final Widget title;
  final Widget value;
  final VoidCallback? onPress;
  final Widget description;
  final Color? background;
  final double? tileHeight;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: background ?? Colors.transparent),
      height: tileHeight ?? 100,
      padding: padding ?? EdgeInsets.zero,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onPress,
            child: Row(
              children: [
                Expanded(child: title),
                value,
                box8(),
                if (onPress != null) const Icon(Icons.arrow_forward_ios)
              ],
            ),
          ),
          description,
        ],
      ),
    );
  }
}

class SettingTileTwoLine extends StatelessWidget {
  const SettingTileTwoLine({
    Key? key,
    required this.title,
    required this.value,
    this.description,
    this.icon,
    this.onPress,
    this.background,
    this.tileHeight,
    this.padding,
  }) : super(key: key);

  final Widget title;
  final Widget value;
  final Widget? icon;
  final Widget? description;
  final VoidCallback? onPress;
  final Color? background;
  final double? tileHeight;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPress,
      child: Container(
        height: tileHeight,
        padding: padding ?? const EdgeInsets.symmetric(vertical: 8.0),
        decoration: BoxDecoration(color: background ?? Colors.transparent),
        alignment: Alignment.centerLeft,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      title,
                      box8(),
                      value,
                    ],
                  ),
                ),
                box8(),
                if (onPress != null) icon ?? const Icon(Icons.arrow_forward_ios)
              ],
            ),
            description ?? const Center(),
          ],
        ),
      ),
    );
  }
}

class SectionTile extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        header,
        box8(),
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
