import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/page/components/styled/styled_tab_page_view.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:privacy_gui/page/wifi_settings/_wifi_settings.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_view_provider.dart';
import 'package:privacy_gui/page/wifi_settings/views/wifi_list_view.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';

enum _WiFiSubMenus {
  wifi,
  guest,
  advanced,
  ;
}

class WiFiMainView extends ArgumentsConsumerStatefulView {
  const WiFiMainView({Key? key, super.args}) : super(key: key);

  @override
  ConsumerState<WiFiMainView> createState() => _WiFiMainViewState();
}

class _WiFiMainViewState extends ConsumerState<WiFiMainView> {
  int _selectMenuIndex = 0;

  @override
  void initState() {
    super.initState();
    final goToGuest = widget.args['guest'] as bool? ?? false;
    if (goToGuest) {
      _selectMenuIndex = 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [loc(context).wifi, loc(context).advanced];
    final tabContents = [
      WiFiListView(args: widget.args),
      const WifiAdvancedSettingsView()
    ];
    return StyledAppTabPageView(
      title: loc(context).incredibleWiFi,
      onBackTap: () async {
        final isCurrentChanged =
            ref.read(wifiViewProvider).isCurrentViewStateChanged;
        if (isCurrentChanged && (await showUnsavedAlert(context) != true)) {
          return;
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
      tabs: tabs
          .map((e) => AppTab(
                title: e,
              ))
          .toList(),
      tabContentViews: tabContents,
      expandedHeight: 120,

      // child: _content(_WiFiSubMenus.values[_selectMenuIndex]),
    );
  }
}
