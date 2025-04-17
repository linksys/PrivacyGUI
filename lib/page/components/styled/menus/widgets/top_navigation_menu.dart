import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:privacy_gui/di.dart';
import 'package:privacy_gui/page/components/styled/menus/menu_consts.dart';
import 'package:privacygui_widgets/theme/_theme.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';

class TopNavigationMenu extends StatefulWidget {
  final List<NaviType> items;
  final void Function(int)? onItemClick;
  final NaviType? selected;
  const TopNavigationMenu({
    super.key,
    required this.items,
    this.onItemClick,
    this.selected,
  });

  @override
  State<TopNavigationMenu> createState() => _TopNavigationMenuState();
}

class _TopNavigationMenuState extends State<TopNavigationMenu> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: widget.items
          .map((e) => _createChip(e))
          .expandIndexed<Widget>((index, element) sync* {
        if (index != widget.items.length - 1) {
          yield element;
          yield const AppGap.medium();
        } else {
          yield element;
        }
      }).toList(),
    );
  }

  Widget _createChip(NaviType type) {
    final theme = getIt.get<ThemeData>(instanceName: 'darkThemeData');
    return Theme(
      data: theme.copyWith(),
      child: ChoiceChip(
        avatar: Icon(type.resolveIcon(), color: Color(neutralTonal.get(100))),
        label: AppText.labelMedium(
          type.resloveLabel(context),
          color: Color(neutralTonal.get(100)),
        ),
        selected: widget.selected == type,
        showCheckmark: false,
        onSelected: (value) {
          widget.onItemClick?.call(widget.items.indexOf(type));
        },
        backgroundColor: Color(neutralTonal.get(6)),
        selectedColor: Color(primaryTonal.get(40)),
        side: BorderSide(color: Color(neutralTonal.get(6)), width: 0),
        clipBehavior: Clip.hardEdge,
        shape: RoundedRectangleBorder(
            borderRadius:
                CustomTheme.of(context).radius.asBorderRadius().large),
        elevation: 0,
      ),
    );
  }
}
