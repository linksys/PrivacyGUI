import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_app/localization/localization_hook.dart';
import 'package:linksys_app/page/components/styled/styled_tab_page_view.dart';
import 'package:linksys_app/page/wifi_settings/_wifi_settings.dart';
import 'package:linksys_widgets/theme/const/spacing.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';

class WifiListView extends ConsumerStatefulWidget {
  const WifiListView({Key? key}) : super(key: key);

  @override
  ConsumerState<WifiListView> createState() => _WifiListViewState();
}

class _WifiListViewState extends ConsumerState<WifiListView> {
  @override
  Widget build(BuildContext context) {
    final items = ref.watch(wifiListProvider);
    return StyledAppTabPageView(
      title: loc(context).wifi,
      // headerContent: const Padding(
      //     padding: EdgeInsets.all(Spacing.regular),
      //     child: AppText.headlineMedium('WiFi')),
      tabs: items.map((e) => AppTab(title: e.ssid)).toList(),
      tabContentViews: items.map((e) => _wifiView(e)).toList(),
      expandedHeight: 120,
    );
  }

  Widget _wifiView(WifiItem item) {
    return WifiDetailView(item: item);
  }
}
