import 'package:flutter/material.dart';
import 'package:linksys_moab/design/colors.dart';
import 'package:linksys_moab/page/components/layouts/layout.dart';
import 'package:linksys_moab/page/components/views/arguments_view.dart';
import 'package:linksys_moab/route/model/model.dart';
import 'package:linksys_moab/route/route.dart';
import 'package:linksys_moab/util/debug_mixin.dart';
import 'package:linksys_moab/util/logger.dart';

enum DashboardBottomItemType { home, security, health, settings }

class DashboardBottomTabContainer extends ArgumentsStatefulView {
  const DashboardBottomTabContainer({Key? key, required this.navigator, required this.cubit})
      : super(key: key);

  final NavigationCubit cubit;
  final Navigator navigator;

  @override
  _DashboardViewState createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardBottomTabContainer> with DebugObserver {
  int _selectedIndex = 0;
  final List<DashboardBottomItem> _bottomTabItems = [];

  @override
  void initState() {
    super.initState();
    _prepareBottomTabItems();
  }

  @override
  Widget build(BuildContext context) {
    return _contentView();
  }

  Widget _contentView() {
    return Scaffold(
      body: GestureDetector(
        onTap: () {
          if (increase()) {
            logger.d('Triggered!');
            NavigationCubit.of(context).push(DebugToolsMainPath());
          }
        },
        child: BasicLayout(
          alignment: CrossAxisAlignment.start,
          content: widget.navigator,
        ),
      ),
      bottomNavigationBar: Offstage(
        offstage: widget.cubit.state.last.pageConfig.isHideBottomNavBar,
        child: BottomNavigationBar(
            type: BottomNavigationBarType.shifting,
            iconSize: 16,
            selectedFontSize: 18,
            selectedIconTheme: IconThemeData(color: Colors.white, size: 24),
            selectedItemColor: Colors.white,
            selectedLabelStyle: TextStyle(fontWeight: FontWeight.bold),
            unselectedIconTheme: IconThemeData(
              color: Colors.grey,
            ),
            unselectedItemColor: Colors.grey,
            showSelectedLabels: true,
            showUnselectedLabels: true,
            currentIndex: _selectedIndex,
            //New
            onTap: _onItemTapped,
            items: List.from(
                _bottomTabItems.map((e) => _bottomSheetIconView(e)))),
      ),
    );
  }

  void _onItemTapped(int index) {
    widget.cubit.clearAndPush(_bottomTabItems[index].rootPath);
    setState(() {
      _selectedIndex = index;
    });
  }

  BottomNavigationBarItem _bottomSheetIconView(DashboardBottomItem item) {
    return BottomNavigationBarItem(
        icon: Image.asset(
          item.icon,
          width: 24,
          height: 24,
        ),
        label: item.title,
        backgroundColor: MoabColor.dashboardBottomBackground);
  }

  _prepareBottomTabItems() {
    //
    _bottomTabItems.addAll(_dashboardBottomItems);
  }
}

final List<DashboardBottomItem> _dashboardBottomItems = [
  DashboardBottomItem(
    icon: 'assets/images/icon_home.png',
    title: 'Home',
    type: DashboardBottomItemType.home,
    rootPath: DashboardHomePath(),
  ),
  DashboardBottomItem(
    icon: 'assets/images/icon_home.png',
    title: 'Security',
    type: DashboardBottomItemType.security,
    rootPath: DashboardSecurityPath(),
  ),
  DashboardBottomItem(
    icon: 'assets/images/icon_home.png',
    title: 'Health',
    type: DashboardBottomItemType.health,
    rootPath: DashboardHealthPath(),
  ),
  DashboardBottomItem(
    icon: 'assets/images/icon_settings.png',
    title: 'Settings',
    type: DashboardBottomItemType.settings,
    rootPath: DashboardSettingsPath(),
  ),
];

class DashboardBottomItem {
  const DashboardBottomItem({
    required this.icon,
    required this.title,
    required this.type,
    required this.rootPath,
  });

  final String icon;
  final String title;
  final DashboardBottomItemType type;
  final BasePath rootPath;
}
