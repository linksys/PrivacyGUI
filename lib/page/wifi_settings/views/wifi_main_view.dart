import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/page/components/styled/styled_tab_page_view.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:privacy_gui/page/dashboard/_dashboard.dart';
import 'package:privacy_gui/page/dashboard/providers/dashboard_home_provider.dart';
import 'package:privacy_gui/page/instant_privacy/providers/instant_privacy_provider.dart';
import 'package:privacy_gui/page/wifi_settings/_wifi_settings.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_view_provider.dart';
import 'package:privacy_gui/page/wifi_settings/views/mac_filtering_view.dart';
import 'package:privacy_gui/page/wifi_settings/views/wifi_list_view.dart';
import 'package:privacygui_widgets/widgets/text/app_text.dart';

class WiFiMainView extends ArgumentsConsumerStatefulView {
  const WiFiMainView({Key? key, super.args}) : super(key: key);

  @override
  ConsumerState<WiFiMainView> createState() => _WiFiMainViewState();
}

class _WiFiMainViewState extends ConsumerState<WiFiMainView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  bool _tabIsChanging = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() async {
      final isBridge = ref.read(dashboardHomeProvider).isBridgeMode;
      if (_tabController.indexIsChanging &&
          _tabController.previousIndex != _tabController.index &&
          _tabIsChanging == false) {
        final nextIndex = _tabController.index;
        if (isBridge && (nextIndex == _tabController.length - 1)) {
          _tabIsChanging = false;
          _tabController.animateTo(_tabController.previousIndex);
        } else {
          final isStateChange =
              hasChangedWithTabIndex(_tabController.previousIndex);
          if (isStateChange) {
            _tabIsChanging = true;
            _tabController.animateTo(_tabController.previousIndex);
            if (await showUnsavedAlert(context) != true) {
              _tabIsChanging = false;
            } else {
              _tabController.animateTo(nextIndex);
              _tabIsChanging = false;
            }
          }
        }
      }
    });
  }

  @override
  void dispose() {
    super.dispose();

    _tabController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isBridge = ref.watch(dashboardHomeProvider).isBridgeMode;

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
      onBackTap: () async {
        final isCurrentChanged = hasChangedWithTabIndex(_tabController.index);
        if (isCurrentChanged && (await showUnsavedAlert(context) != true)) {
          return;
        }
        if (_tabController.index == 2) {
          // Handle MAC filter, restore state if discard change
          ref.read(instantPrivacyProvider.notifier).fetch();
        }
        context.pop();
      },
      // menuWidget: ListView.builder(
      //     shrinkWrap: true,
      //     itemCount: _WiFiSubMenus.values.length,
      //     itemBuilder: (context, index) {
      //       return ListTile(
      //         shape: const RoundedRectangleBorder(
      //             borderRadius: BorderRadius.all(Radius.circular(100))),
      //         onTap: () async {
      //           final isCurrentChanged =
      //               ref.read(wifiViewProvider).isCurrentViewStateChanged;
      //           if (isCurrentChanged &&
      //               (await showUnsavedAlert(context) != true)) {
      //             return;
      //           }
      //           setState(() {
      //             _selectMenuIndex = index;
      //           });
      //         },
      //         title: AppText.labelLarge(
      //           _subMenuLabel(_WiFiSubMenus.values[index]),
      //           color: index == _selectMenuIndex
      //               ? Theme.of(context).colorScheme.primary
      //               : null,
      //         ),
      //       );
      //     }),
      tabController: _tabController,
      tabs: tabs
          .mapIndexed((index, e) => Tab(
                child: AppText.titleSmall(
                  e,
                  color: index == _tabController.length - 1 && isBridge
                      ? Theme.of(context).colorScheme.outline
                      : null,
                ),
              ))
          .toList(),
      tabContentViews: tabContents,
      useMainPadding: false,
      // expandedHeight: 120,

      // child: _content(_WiFiSubMenus.values[_selectMenuIndex]),
    );
  }

  bool hasChangedWithTabIndex(int index) {
    return switch (index) {
      0 => ref.read(wifiViewProvider).isWifiListViewStateChanged,
      1 => ref.read(wifiViewProvider).isWifiAdvancedSettingsViewStateChanged,
      2 => ref.read(wifiViewProvider).isMacFilteringViewStateChanged,
      _ => false,
    };
  }
}
