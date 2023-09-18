import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_app/page/components/styled/styled_tab_page_view.dart';
import 'package:linksys_app/page/wifi_settings/view/wifi_detail_view.dart';
import 'package:linksys_app/provider/wifi_setting/_wifi_setting.dart';
import 'package:linksys_app/provider/wifi_setting/wifi_list_provider.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/base/padding.dart';


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
      headerContent: AppPadding.regular(child: AppText.headlineMedium('WiFi')),
      tabs: items.map((e) => AppTab(title: e.ssid)).toList(),
      tabContentViews: items.map((e) => _wifiView(e)).toList(),
      expandedHeight: 200,
    );
  }

  Widget _wifiView(WifiListItem item) {
    return WifiDetailView(item: item);
  }
}
