import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_app/localization/localization_hook.dart';
import 'package:linksys_app/page/components/styled/styled_tab_page_view.dart';
import 'package:linksys_app/page/wifi_settings/_wifi_settings.dart';
import 'package:linksys_app/page/wifi_settings/providers/guest_wif_provider.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';

class WiFiShareTabView extends ConsumerStatefulWidget {
  const WiFiShareTabView({Key? key}) : super(key: key);

  @override
  ConsumerState<WiFiShareTabView> createState() => _WiFiShareTabViewState();
}

class _WiFiShareTabViewState extends ConsumerState<WiFiShareTabView> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(wifiListProvider);
    final guest = ref.watch(guestWifiProvider);
    final List<(String, String, int)> items = state.mainWiFi
        .map(
          (e) => (e.ssid, e.password, e.numOfDevices),
        )
        .toList();
    items.add((
      guest.ssid,
      guest.password,
      guest.numOfDevices,
    ));
    return StyledAppTabPageView(
      title: loc(context).wifi,
      // headerContent: const Padding(
      //     padding: EdgeInsets.all(Spacing.regular),
      //     child: AppText.headlineMedium('WiFi')),
      tabs: items.map((e) => AppTab(title: e.$1)).toList(),
      tabContentViews: items.map((e) => _wifiView(e.$1, e.$2, e.$3)).toList(),
      expandedHeight: 120,
    );
  }

  Widget _wifiView(String ssid, String password, int numOfDevices) {
    return WiFiShareDetailView(
      ssid: ssid,
      password: password,
      numOfDevices: numOfDevices,
    );
  }
}
