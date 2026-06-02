import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/instant_test/providers/instant_test_provider.dart';
import 'package:privacy_gui/page/instant_test/views/help_me_fix_it_tab.dart';
import 'package:privacy_gui/page/instant_test/views/my_devices_tab.dart';
import 'package:privacy_gui/page/instant_test/views/my_network_tab.dart';
import 'package:privacy_gui/page/instant_test/views/overview_tab.dart';

class InstantTestPage extends ConsumerStatefulWidget {
  const InstantTestPage({super.key});

  @override
  ConsumerState<InstantTestPage> createState() => _InstantTestPageState();
}

class _InstantTestPageState extends ConsumerState<InstantTestPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  // -1 = reset to landing menu; positive int = launch that flow
  final _helpMeFlowNotifier = ValueNotifier<int?>(null);

  static const int _tabCount = 4;
  static const int _helpMeFixItTabIndex = 3;
  static const int _myDevicesTabIndex = 1;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabCount, vsync: this);
    // Re-tap on Tab 3 while already active → reset flow to landing menu
    int _previousTab = 0;
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        if (_tabController.index == _helpMeFixItTabIndex &&
            _previousTab == _helpMeFixItTabIndex) {
          _helpMeFlowNotifier.value = -1;
        }
        _previousTab = _tabController.index;
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(instantTestProvider.notifier).fetch();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _helpMeFlowNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(loc(context).instantTest),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [
            Tab(text: loc(context).instantTestTabOverview),
            Tab(text: loc(context).instantTestTabDevices),
            Tab(text: loc(context).instantTestTabNetwork),
            Tab(text: loc(context).instantTestTabHelpFix),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          const OverviewTab(),
          MyDevicesTab(
            // Launch Help Me Fix It Flow 3 and navigate to that tab
            onGoToFlow3: () {
              _helpMeFlowNotifier.value = 3;
              _tabController.animateTo(_helpMeFixItTabIndex);
            },
          ),
          const MyNetworkTab(),
          HelpMeFixItTab(
            pendingFlowNotifier: _helpMeFlowNotifier,
            onNavigateToMyDevices: () =>
                _tabController.animateTo(_myDevicesTabIndex),
          ),
        ],
      ),
    );
  }
}
