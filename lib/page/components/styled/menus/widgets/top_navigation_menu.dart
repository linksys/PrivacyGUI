import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:privacy_gui/page/components/styled/menus/menu_consts.dart';
import 'package:privacygui_widgets/theme/custom_theme.dart';
import 'package:privacygui_widgets/theme/material/color_tonal_palettes.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/gap/const/spacing.dart';

class NavigationMenu extends StatefulWidget {
  final List<NaviType> items;
  final void Function(int)? onItemClick;
  final NaviType? selected;
  const NavigationMenu({
    super.key,
    required this.items,
    this.onItemClick,
    this.selected,
  });

  @override
  State<NavigationMenu> createState() => _NavigationMenuState();
}

class _NavigationMenuState extends State<NavigationMenu> {
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
    // return Container(
    //   decoration: BoxDecoration(
    //       color: widget.selected == type
    //           ? Color(primaryTonal.get(40))
    //           : Color(neutralTonal.get(6)),
    //       borderRadius: CustomTheme.of(context).radius.asBorderRadius().large),
    //   child: InkWell(
    //     hoverColor: Colors.amber,
    //     onTap: () {
    //       if (widget.selected == type) {
    //         return;
    //       }

    //       widget.onItemClick?.call(widget.items.indexOf(type));
    //     },
    //     child: Row(
    //       children: [
    //         Padding(
    //           padding: const EdgeInsets.all(Spacing.small1),
    //           child:
    //               Icon(type.resolveIcon(), color: Color(neutralTonal.get(100))),
    //         ),
    //         const AppGap.small2(),
    //         AppText.labelMedium(
    //           type.resloveLabel(context),
    //           color: Color(
    //             neutralTonal.get(100),
    //           ),
    //         ),
    //         const AppGap.small2(),
    //       ],
    //     ),
    //   ),
    // );
    return ChoiceChip(
      avatar: Icon(type.resolveIcon(), color: Color(neutralTonal.get(100))),
      label: AppText.labelMedium(
        type.resloveLabel(context),
        color: Color(neutralTonal.get(100)),
      ),
      selected: widget.selected == type,
      showCheckmark: false,
      onSelected: (value) {
        if (widget.selected == type) {
          return;
        }

        widget.onItemClick?.call(widget.items.indexOf(type));
      },
      selectedColor: Color(primaryTonal.get(40)),
      backgroundColor: Color(neutralTonal.get(6)),
      side: BorderSide(color: Color(neutralTonal.get(6)), width: 0),
      shape: RoundedRectangleBorder(
          borderRadius: CustomTheme.of(context).radius.asBorderRadius().large),
      elevation: 0,
    );
  }
}
