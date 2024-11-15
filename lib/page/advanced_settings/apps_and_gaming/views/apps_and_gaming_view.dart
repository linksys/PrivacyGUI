import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/advanced_settings/_advanced_settings.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/providers/apps_and_gaming_provider.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/page/components/styled/styled_tab_page_view.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ddns/_ddns.dart';

class AppsGamingSettingsView extends ArgumentsConsumerStatefulView {
  const AppsGamingSettingsView({super.key, super.args});

  @override
  ConsumerState<AppsGamingSettingsView> createState() =>
      _AppsGamingSettingsViewState();
}

class _AppsGamingSettingsViewState
    extends ConsumerState<AppsGamingSettingsView> {
  @override
  void initState() {
    super.initState();

    doSomethingWithSpinner(
        context, ref.read(appsAndGamingProvider.notifier).fetch());
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      Tab(
        text: loc(context).ddns,
      ),
      Tab(
        text: loc(context).singlePortForwarding,
      ),
      Tab(
        text: loc(context).portRangeForwarding,
      ),
      Tab(
        text: loc(context).portRangeTriggering,
      ),
    ];
    final tabContents = [
      DDNSSettingsView(),
      SinglePortForwardingListView(),
      PortRangeForwardingListView(),
      PortRangeTriggeringListView(),
    ];
    return StyledAppTabPageView(
      title: loc(context).appsGaming,
      tabs: tabs,
      tabContentViews: tabContents,
      expandedHeight: 120,
    );
  }
}
