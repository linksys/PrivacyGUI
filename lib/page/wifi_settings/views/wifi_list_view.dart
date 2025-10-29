import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_bundle_provider.dart';
import 'package:privacy_gui/page/wifi_settings/views/wifi_list_advanced_mode_view.dart';
import 'package:privacy_gui/page/wifi_settings/views/wifi_list_simple_mode_view.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';

class WiFiListView extends ArgumentsConsumerStatelessView {
  const WiFiListView({Key? key, super.args}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // The state is now read from the single bundle provider.
    final wifiListState = ref.watch(
        wifiBundleProvider.select((state) => state.settings.current.wifiList));
    final notifier = ref.read(wifiBundleProvider.notifier);

    final wifiBands = wifiListState.mainWiFi
        .map((e) => e.radioID.bandName)
        .toList()
        .join(', ');
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _wifiDescription(context, wifiBands),
          const AppGap.medium(),
          _quickSetupSwitch(context, ref, wifiListState.isSimpleMode),
          const AppGap.medium(),
          wifiListState.isSimpleMode
              ? SimpleModeView(
                  onWifiNameEdited: (value) {
                    notifier.setSimpleModeWifi(
                        wifiListState.simpleModeWifi.copyWith(ssid: value));
                  },
                  onWifiPasswordEdited: (value) {
                    final wifiItem =
                        wifiListState.simpleModeWifi.copyWith(password: value);
                    notifier.setSimpleModeWifi(wifiItem);
                  },
                  onSecurityTypeChanged: (value) {
                    final wifiItem = wifiListState.simpleModeWifi
                        .copyWith(securityType: value);
                    notifier.setSimpleModeWifi(wifiItem);
                  },
                )
              : const AdvancedModeView(),
        ],
      ),
    );
  }

  Widget _wifiDescription(BuildContext context, String wifiBands) {
    return AppCard(
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            semanticLabel: 'info icon',
            color: Theme.of(context).colorScheme.primary,
          ),
          const AppGap.medium(),
          Expanded(
            child: AppText.bodySmall(
              loc(context).wifiListDescription(wifiBands),
              maxLines: 30,
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickSetupSwitch(
      BuildContext context, WidgetRef ref, bool isSimpleMode) {
    final notifier = ref.read(wifiBundleProvider.notifier);
    return AppCard(
      child: Row(
        children: [
          Icon(
            Icons.bolt_outlined,
            color: Theme.of(context).colorScheme.primary,
          ),
          const AppGap.medium(),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                AppText.labelMedium(
                  loc(context).quickSetup,
                ),
                const AppGap.small1(),
                AppText.bodySmall(
                  loc(context).quickSetupDescription,
                ),
              ],
            ),
          ),
          AppSwitch(
            semanticLabel: 'quick setup switch',
            value: isSimpleMode,
            onChanged: (value) {
              notifier.setSimpleMode(value);
              if (value) {
                // Logic to init simple mode settings if needed can be called here
              } else {
                // Logic to revert to advanced settings if needed
              }
            },
          ),
        ],
      ),
    );
  }
}
