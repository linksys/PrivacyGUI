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

  static const int _tabCount = 4;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabCount, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(instantTestProvider.notifier).fetch();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
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
        children: const [
          OverviewTab(),
          MyDevicesTab(),
          MyNetworkTab(),
          HelpMeFixItTab(),
        ],
      ),
    );
  }
}
