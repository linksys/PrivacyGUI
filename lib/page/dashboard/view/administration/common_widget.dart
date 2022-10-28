import 'package:flutter/material.dart';
import 'package:linksys_moab/page/components/base_components/tile/setting_tile.dart';

Widget administrationSection({required String title, required Widget content}) {
  return SectionTile(
    header: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        height: 48,
        child: Text(title.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color.fromRGBO(0, 0, 0, 0.5),
            )),
        alignment: Alignment.bottomLeft,
      ),
    ),
    child: content,
  );
}

Widget administrationTile(
    {required Widget title,
    required Widget value,
    Widget? icon,
    void Function()? onPress}) {
  return SettingTile(
    title: title,
    value: value,
    icon: icon,
    onPress: onPress,
    tileHeight: 64,
    padding: const EdgeInsets.symmetric(horizontal: 24),
  );
}

Widget administrationTwoLineTile(
    {required Widget title,
    required Widget value,
    Widget? icon,
    void Function()? onPress}) {
  return SettingTileTwoLine(
    title: title,
    value: value,
    icon: icon,
    onPress: onPress,
    tileHeight: 64,
    padding: const EdgeInsets.symmetric(horizontal: 24),
  );
}

Widget administrationTileDesc(
    {required Widget title,
    required Widget value,
    Widget? description,
    void Function()? onPress}) {
  return SettingTileWithDescription(
    title: title,
    value: value,
    onPress: onPress,
    tileHeight: 88,
    padding: const EdgeInsets.symmetric(horizontal: 24),
    description: description ?? Center(),
  );
}
