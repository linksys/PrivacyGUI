import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/page/wifi_settings/_wifi_settings.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_view_provider.dart';
import 'package:privacy_gui/page/wifi_settings/views/wifi_list_view.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';

enum _WiFiSubMenus {
  wifi,
  guest,
  advanced,
  filtering,
  ;
}

class WiFiMainView extends ConsumerStatefulWidget {
  const WiFiMainView({Key? key}) : super(key: key);

  @override
  ConsumerState<WiFiMainView> createState() => _WiFiMainViewState();
}

class _WiFiMainViewState extends ConsumerState<WiFiMainView> {
  int _selectMenuIndex = 0;

  @override
  Widget build(BuildContext context) {
    return StyledAppPageView(
        title: _subMenuLabel(_WiFiSubMenus.values[_selectMenuIndex]),
        onBackTap: () async {
          final isCurrentChanged =
              ref.read(wifiViewProvider).isCurrentViewStateChanged;
          if (isCurrentChanged && (await showUnsavedAlert(context) != true)) {
            return;
          }
          context.pop();
        },
        menuWidget: ListView.builder(
            shrinkWrap: true,
            itemCount: _WiFiSubMenus.values.length,
            itemBuilder: (context, index) {
              return AppCard(
                showBorder: false,
                onTap: () async {
                  final isCurrentChanged =
                      ref.read(wifiViewProvider).isCurrentViewStateChanged;
                  if (isCurrentChanged &&
                      (await showUnsavedAlert(context) != true)) {
                    return;
                  }
                  setState(() {
                    _selectMenuIndex = index;
                  });
                },
                child: AppText.labelLarge(
                  _subMenuLabel(_WiFiSubMenus.values[index]),
                  color: index == _selectMenuIndex
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
              );
            }),
        child: _content(_WiFiSubMenus.values[_selectMenuIndex]));
  }

  String _subMenuLabel(_WiFiSubMenus sub) => switch (sub) {
        _WiFiSubMenus.wifi => loc(context).wifi,
        _WiFiSubMenus.guest => loc(context).guestWifi,
        _WiFiSubMenus.advanced => loc(context).advanced,
        _WiFiSubMenus.filtering => loc(context).macFiltering,
      };

  Widget _content(_WiFiSubMenus sub) => switch (sub) {
        _WiFiSubMenus.wifi => const WiFiListView(),
        _WiFiSubMenus.guest => const GuestWiFiSettingsView(),
        _WiFiSubMenus.advanced => const WifiAdvancedSettingsView(),
        _WiFiSubMenus.filtering => const MacFilteringView(),
      };
}
