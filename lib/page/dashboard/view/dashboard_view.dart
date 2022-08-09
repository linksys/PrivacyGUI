import 'package:flutter/material.dart';
import 'package:linksys_moab/page/components/base_components/base_components.dart';
import 'package:linksys_moab/page/components/layouts/layout.dart';
import 'package:linksys_moab/page/components/views/arguments_view.dart';
import 'package:linksys_moab/page/dashboard/view/dashboard_home_view.dart';
import 'package:linksys_moab/page/dashboard/view/dashboard_settings_view.dart';

import '../../../design/themes.dart';

enum DashboardBottomItemType { home, second, third, settings }

class DashboardView extends ArgumentsStatefulView {
  const DashboardView({Key? key}) : super(key: key);

  @override
  _DashboardViewState createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  int _selectedIndex = 0;

  @override
  void initState() {}

  @override
  Widget build(BuildContext context) {
    return Theme(data: MoabTheme.dashboardLightModeData, child: Builder(
      builder: (context) {
        return _contentView();
      }
    ));
  }

  Widget _contentView() {
    return BasePageView.noNavigationBar(
      child: BasicLayout(
        alignment: CrossAxisAlignment.start,
        content: _pages.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.shifting,
          backgroundColor: Theme.of(context).primaryColor,
          iconSize: 48,
          selectedFontSize: 18,
          selectedIconTheme: IconThemeData(color: Colors.black, size: 40),
          selectedItemColor: Colors.black,
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
              dashboardBottomItems.map((e) => _bottomSheetIconView(e)))),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  BottomNavigationBarItem _bottomSheetIconView(DashboardBottomItem item) {
    return BottomNavigationBarItem(
        icon: Image.asset(
          item.icon,
          width: 48,
          height: 48,
        ),
        label: item.title);
  }
}

const List<Widget> _pages = <Widget>[
  DashboardHomeView(),
  Icon(
    Icons.camera,
    size: 150,
  ),
  Icon(
    Icons.chat,
    size: 150,
  ),
  DashboardSettingsView(),
];

const dashboardBottomItems = [
  DashboardBottomItem(
      'assets/images/dashboard_home.png', 'Home', DashboardBottomItemType.home),
  DashboardBottomItem(
      'assets/icons/ic_foreground.png', 'TBD', DashboardBottomItemType.second),
  DashboardBottomItem(
      'assets/icons/ic_foreground.png', 'TBD', DashboardBottomItemType.third),
  DashboardBottomItem('assets/icons/ic_foreground.png', 'Settings',
      DashboardBottomItemType.settings),
];

class DashboardBottomItem {
  const DashboardBottomItem(this.icon, this.title, this.type);

  final String icon;
  final String title;
  final DashboardBottomItemType type;
}
