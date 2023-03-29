import 'package:flutter/material.dart';
import 'package:linksys_moab/constants/build_config.dart';
import 'package:linksys_moab/page/components/customs/debug_overlay_view.dart';
import 'package:linksys_moab/page/components/shortcuts/snack_bar.dart';
import 'package:linksys_moab/page/components/views/arguments_view.dart';
import 'package:linksys_moab/route/model/_model.dart';
import 'package:linksys_moab/route/_route.dart';

import 'package:linksys_moab/util/debug_mixin.dart';
import 'package:linksys_moab/util/logger.dart';
import 'package:linksys_moab/utils.dart';
import 'package:linksys_widgets/hook/icon_hooks.dart';
import 'package:linksys_widgets/theme/theme.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';

enum DashboardBottomItemType { home, security, health, settings }

class DashboardBottomTabContainer extends ArgumentsStatefulView {
  const DashboardBottomTabContainer(
      {Key? key, required this.navigator, required this.cubit})
      : super(key: key);

  final NavigationCubit cubit;
  final Navigator navigator;

  @override
  State<DashboardBottomTabContainer> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardBottomTabContainer>
    with DebugObserver {
  int _selectedIndex = 0;
  final List<DashboardBottomItem> _bottomTabItems = [];

  @override
  void initState() {
    super.initState();
    _prepareBottomTabItems(context);
  }

  @override
  Widget build(BuildContext context) {
    return _contentView();
  }

  Widget _contentView() {
    return Scaffold(
      body: Stack(
        children: [
          GestureDetector(
              onTap: () {
                if (increase()) {
                  logger.d('Triggered!');
                  NavigationCubit.of(context).push(DebugToolsMainPath());
                }
              },
              child: widget.navigator),
          !showDebugPanel
              ? const Center()
              : Positioned(
                  left: Utils.getScreenWidth(context) -
                      Utils.getScreenWidth(context) / 2,
                  child: IgnorePointer(
                    ignoring: true,
                    child: Padding(
                      padding: EdgeInsets.only(
                          top: Utils.getTopSafeAreaPadding(context)),
                      child: OverlayInfoView(),
                    ),
                  ),
                ),
          // : Container(),
        ],
      ),
      bottomNavigationBar: Offstage(
        offstage: widget.cubit.state.last.pageConfig.isHideBottomNavBar,
        child: BottomNavigationBar(
            type: BottomNavigationBarType.shifting,
            iconSize:
                AppTheme.of(context).icons.sizes.resolve(AppIconSize.regular),
            // selectedFontSize:
            //     AppTheme.of(context).icons.sizes.resolve(AppIconSize.small),
            selectedIconTheme: IconThemeData(
              color: AppTheme.of(context).colors.textBoxText,
              size:
                  AppTheme.of(context).icons.sizes.resolve(AppIconSize.regular),
            ),
            selectedItemColor: AppTheme.of(context).colors.textBoxText,
            unselectedIconTheme: IconThemeData(
                color: AppTheme.of(context).colors.textBoxText, opacity: 0.6),
            unselectedItemColor:
                AppTheme.of(context).colors.textBoxText.withOpacity(0.6),
            // unselectedFontSize:
            //     AppTheme.of(context).icons.sizes.resolve(AppIconSize.small),
            showSelectedLabels: true,
            showUnselectedLabels: true,
            currentIndex: _selectedIndex,
            //New
            onTap: _onItemTapped,
            items:
                List.from(_bottomTabItems.map((e) => _bottomSheetIconView(e)))),
      ),
    );
  }

  void _onItemTapped(int index) {
    if (index == 1 || index == 2) {
      showSimpleSnackBar(context, null, "Not Implemented!");
      return;
    }
    widget.cubit.clearAndPush(_bottomTabItems[index].rootPath);
    setState(() {
      _selectedIndex = index;
    });
  }

  BottomNavigationBarItem _bottomSheetIconView(DashboardBottomItem item) {
    return BottomNavigationBarItem(
      icon: Icon(
        getCharactersIcons(context).getByName(item.iconId),
        color: AppTheme.of(context).colors.textBoxText,
      ),
      activeIcon: CircleAvatar(
        backgroundColor: Colors.transparent,
        child: Icon(
          getCharactersIcons(context).getByName(item.iconId),
          color: AppTheme.of(context).colors.textBoxText,
        ),
      ),
      label: item.title,
      backgroundColor: AppTheme.of(context).colors.bottomBackground,
    );
  }

  _prepareBottomTabItems(BuildContext context) {
    //
    if (!mounted) {
      return;
    }
    _bottomTabItems.addAll(navigationBottomItems());
  }
}

navigationBottomItems() => [
      DashboardBottomItem(
        iconId: 'homeDefault',
        title: 'Home',
        type: DashboardBottomItemType.home,
        rootPath: DashboardHomePath(),
      ),
      DashboardBottomItem(
        iconId: 'securityDefault',
        title: 'Security',
        type: DashboardBottomItemType.security,
        rootPath: DashboardSecurityPath(),
      ),
      DashboardBottomItem(
        iconId: 'healthDefault',
        title: 'Health',
        type: DashboardBottomItemType.health,
        rootPath: DashboardHealthPath(),
      ),
      DashboardBottomItem(
        iconId: 'settingsDefault',
        title: 'Settings',
        type: DashboardBottomItemType.settings,
        rootPath: DashboardSettingsPath(),
      ),
    ];

class DashboardBottomItem {
  const DashboardBottomItem({
    required this.iconId,
    required this.title,
    required this.type,
    required this.rootPath,
  });

  final String iconId;
  final String title;
  final DashboardBottomItemType type;
  final BasePath rootPath;
}
