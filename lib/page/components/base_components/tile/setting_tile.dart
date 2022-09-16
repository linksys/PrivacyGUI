import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:linksys_moab/page/components/shortcuts/sized_box.dart';


class SettingTile extends StatelessWidget {
  const SettingTile(
      {Key? key,
        required this.title,
        required this.value,
        this.onPress,})
      : super(key: key);

  final Widget title;
  final Widget value;
  final VoidCallback? onPress;

  @override
  Widget build(BuildContext context) {
    return Column(
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
      ],
    );
  }
}

class SettingTileWithDescription extends StatelessWidget {
  const SettingTileWithDescription(
      {Key? key,
        required this.title,
        required this.value,
        required this.description,
        this.onPress,})
      : super(key: key);

  final Widget title;
  final Widget value;
  final VoidCallback? onPress;
  final Widget description;

  @override
  Widget build(BuildContext context) {
    return Column(
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
    );
  }
}

class SettingTileTwoLine extends StatelessWidget {
  const SettingTileTwoLine(
      {Key? key,
        required this.title,
        required this.value,
        this.icon,
        this.onPress})
      : super(key: key);

  final Widget title;
  final Widget value;
  final Widget? icon;
  final VoidCallback? onPress;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPress,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        title,
                        box8(),
                        value,
                      ],
                    )),
                box8(),
                if (onPress != null) icon ?? Icon(Icons.arrow_forward_ios)
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class SectionTile extends StatelessWidget {
  const SectionTile(
      {Key? key, required this.header, required this.child, this.space = 32})
      : super(key: key);

  final Widget header;
  final Widget child;
  final double space;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: space,
        ),
        header,
        box16(),
        child,
      ],
    );
  }
}
