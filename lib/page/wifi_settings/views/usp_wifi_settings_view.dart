import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/components/ui_kit_page_view.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/page/shell/usp_top_bar.dart';
import 'package:privacy_gui/page/wifi_settings/providers/usp_wifi_settings_provider.dart';
import 'package:privacy_gui/page/wifi_settings/views/tabs/wifi_advanced_tab.dart';
import 'package:privacy_gui/page/wifi_settings/views/tabs/wifi_list_tab.dart';

class UspWifiSettingsView extends ConsumerStatefulWidget {
  const UspWifiSettingsView({super.key});

  @override
  ConsumerState<UspWifiSettingsView> createState() =>
      _UspWifiSettingsViewState();
}

class _UspWifiSettingsViewState extends ConsumerState<UspWifiSettingsView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late int _previousTabIndex;

  static const _tabLabels = ['WiFi', 'Advanced'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabLabels.length, vsync: this);
    _previousTabIndex = _tabController.index;
    _tabController.addListener(_handleTabChange);
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  /// Guards against switching tabs with unsaved changes.
  Future<void> _handleTabChange() async {
    if (!_tabController.indexIsChanging) return;

    final notifier = ref.read(uspWifiSettingsProvider.notifier);
    if (!notifier.isDirty()) {
      _previousTabIndex = _tabController.index;
      return;
    }

    final confirmed = await showUnsavedAlert(context);
    if (!mounted) return;

    if (confirmed == true) {
      // Discard changes and allow tab switch.
      notifier.revert();
    } else {
      // Cancel — snap back to previous tab.
      _tabController.index = _previousTabIndex;
      return;
    }
    _previousTabIndex = _tabController.index;
  }

  @override
  Widget build(BuildContext context) {
    return UiKitPageView.withSliver(
      title: 'WiFi Settings',
      topbar: const PreferredSize(
        preferredSize: Size.fromHeight(64),
        child: UspTopBar(),
      ),
      showAppBarBorder: false,
      showTabBorder: false,
      backFallback: RouteNamed.uspMenu,
      tabController: _tabController,
      tabs: const [
        Tab(text: 'WiFi'),
        Tab(text: 'Advanced'),
      ],
      tabContentViews: const [
        UspWifiListTab(),
        UspWifiAdvancedTab(),
      ],
    );
  }
}
