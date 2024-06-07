import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:privacygui_widgets/theme/custom_theme.dart';
import 'package:privacygui_widgets/widgets/container/responsive_layout.dart';

class DashboardNavigationRail extends ConsumerStatefulWidget {
  final List<NavigationRailDestination> items;
  final void Function(int)? onItemTapped;
  final int selected;

  const DashboardNavigationRail({
    super.key,
    required this.items,
    this.onItemTapped,
    this.selected = 0,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _DashboardNavigationRailState();
}

class _DashboardNavigationRailState
    extends ConsumerState<DashboardNavigationRail> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    bool isMobile = ResponsiveLayout.isMobileLayout(context);
    return NavigationRail(
      leading: isMobile
          ? null
          : Padding(
              padding: const EdgeInsets.only(
                  top: 8, left: 24, bottom: 60, right: 24),
              child: SvgPicture(
                CustomTheme.of(context).images.linksysLogoBlack,
                width: 20,
                height: 20,
              ),
            ),
      labelType: NavigationRailLabelType.all,
      destinations: widget.items,
      selectedIndex: widget.selected,
      indicatorColor: Theme.of(context).colorScheme.primary,
      // selectedIconTheme:
      //     IconThemeData(color: Theme.of(context).colorScheme.onPrimary),
      onDestinationSelected: widget.onItemTapped,
    );
  }
}
