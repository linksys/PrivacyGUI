import 'package:flutter/material.dart';
import 'package:linksys_moab/design/colors.dart';
import 'package:linksys_moab/page/components/base_components/tile/setting_tile.dart';

Widget administrationSection({
  required String title,
  required Widget content,
  Widget? headerAction,
  bool enabled = false,
  EdgeInsets? contentPadding,
  Color? contentBackground,
}) {
  return SectionTile(
    header: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        height: 48,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(child: sectionTitle(title)),
            headerAction ?? const Center(),
          ],
        ),
        alignment: Alignment.bottomLeft,
      ),
    ),
    child: Container(
        padding: contentPadding ?? EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
            color: contentBackground ?? MoabColor.dashboardTileBackground),
        child: content),
  );
}

Widget administrationTile({
  required Widget title,
  Widget? value,
  Widget? icon,
  Color? background,
  EdgeInsets? padding,
  void Function()? onPress,
}) {
  return SettingTile(
    title: title,
    value: value,
    icon: icon,
    onPress: onPress,
    tileHeight: 64,
    background: background ?? Colors.transparent,
    padding: padding ?? EdgeInsets.zero,
  );
}

Widget administrationTwoLineTile({
  required Widget title,
  required Widget value,
  String? description,
  Widget? icon,
  Color? background,
  double? tileHeight = 64,
  EdgeInsets? padding,
  void Function()? onPress,
}) {
  return SettingTile(
    axis: SettingTileAxis.vertical,
    title: title,
    value: value,
    description: description,
    icon: icon,
    onPress: onPress,
    tileHeight: tileHeight,
    background: background ?? Colors.transparent,
    padding: padding ?? EdgeInsets.zero,
  );
}

Widget administrationTileDesc(
    {required Widget title,
    required Widget value,
    String? description,
    Color? background,
    double? tileHeight = 88,
    EdgeInsets? padding,
    void Function()? onPress}) {
  return SettingTile(
    title: title,
    value: value,
    onPress: onPress,
    tileHeight: tileHeight,
    background: background ?? Colors.transparent,
    padding: padding ?? EdgeInsets.zero,
    description: description,
  );
}

Widget sectionTitle(String text) {
  return Text(
    text.toUpperCase(),
    style: const TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      color: Color.fromRGBO(0, 0, 0, 0.5),
    ),
  );
}

Widget title(String text, {double fontSize = 15}) {
  return Text(
    text,
    style: TextStyle(fontSize: fontSize),
  );
}

Widget subTitle(String text, {double fontSize = 13}) {
  return Text(
    text,
    style: TextStyle(
      fontSize: fontSize,
      color: const Color.fromRGBO(102, 102, 102, 1.0),
    ),
  );
}

Widget divider() {
  return const Divider(
    height: 1,
    color: Color.fromRGBO(0, 0, 0, 0.3),
  );
}
