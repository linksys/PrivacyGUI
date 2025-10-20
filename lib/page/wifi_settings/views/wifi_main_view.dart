import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_bundle_provider.dart';
import 'package:privacy_gui/page/wifi_settings/views/mac_filtering_view.dart';
import 'package:privacy_gui/page/wifi_settings/views/wifi_advanced_settings_view.dart';
import 'package:privacy_gui/page/wifi_settings/views/wifi_list_view.dart';
import 'package:privacygui_widgets/widgets/text/app_text.dart';

class WiFiMainView extends ArgumentsConsumerStatefulView {
  const WiFiMainView({Key? key, super.args}) : super(key: key);

  @override
  ConsumerState<WiFiMainView> createState() => _WiFiMainViewState();
}

class _WiFiMainViewState extends ConsumerState<WiFiMainView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late int _previousIndex;
  late WifiBundleNotifier _notifier;
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _previousIndex = _tabController.index;
    _tabController.addListener(_handleTabChange);
    _notifier = ref.read(wifiBundleProvider.notifier);
    doSomethingWithSpinner(context, _notifier.fetch());
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _handleTabChange() async {
    if (!_tabController.indexIsChanging) {
      return;
    }

    final notifier = ref.read(wifiBundleProvider.notifier);
    if (notifier.isDirty()) {
      final shouldDiscard = await showUnsavedAlert(context);
      if (shouldDiscard == true) {
        notifier.revert();
      } else {
        // User cancelled, prevent tab change
        _tabController.index = _previousIndex;
        return;
      }
    }
    _previousIndex = _tabController.index;
  }

  @override
  Widget build(BuildContext context) {
    final bundleState = ref.watch(wifiBundleProvider);

    final tabs = [
      loc(context).wifi,
      loc(context).advanced,
      loc(context).macFiltering
    ];

    final tabContents = [
      WiFiListView(args: widget.args),
      const WifiAdvancedSettingsView(),
      const MacFilteringView(),
    ];

    return StyledAppPageView(
      title: loc(context).incredibleWiFi,
      // onBackTap is no longer needed, LinksysRoute will handle it.
      bottomBar: PageBottomBar(
        isPositiveEnabled: bundleState.isDirty,
        onPositiveTap: () => ref.read(wifiBundleProvider.notifier).save(),
      ),
      tabs: tabs
          .mapIndexed((index, e) => Tab(
                child: AppText.titleSmall(
                  e,
                ),
              ))
          .toList(),
      tabContentViews: tabContents,
      tabController: _tabController,
      useMainPadding: false,
    );
  }
}
