import 'dart:ffi';

import 'package:flutter/material.dart';

import '../../space/sized_box.dart';

class SettingTile extends StatelessWidget {
  const SettingTile(
      {Key? key,
        required this.title,
        required this.value,
        this.onPress,
        this.space = 16})
      : super(key: key);

  final Widget title;
  final Widget value;
  final VoidCallback? onPress;
  final double space;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: space,
        ),
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

class SettingTileTwoLine extends StatelessWidget {
  const SettingTileTwoLine(
      {Key? key,
        required this.title,
        required this.value,
        this.onPress,
        this.space = 16})
      : super(key: key);

  final Widget title;
  final Widget value;
  final VoidCallback? onPress;
  final double space;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: space,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
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
            if (onPress != null) Icon(Icons.arrow_forward_ios)
          ],
        ),
      ],
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