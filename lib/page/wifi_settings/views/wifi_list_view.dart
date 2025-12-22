import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_bundle_provider.dart';
import 'package:privacy_gui/page/wifi_settings/views/wifi_list_advanced_mode_view.dart';
import 'package:privacy_gui/page/wifi_settings/views/wifi_list_simple_mode_view.dart';
import 'package:ui_kit_library/ui_kit.dart';

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
          AppGap.lg(),
          _quickSetupSwitch(context, ref, wifiListState.isSimpleMode),
          AppGap.lg(),
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
          AppIcon.font(
            Icons.info_outline_rounded,
            color: Theme.of(context).colorScheme.primary,
          ),
          AppGap.md(),
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
          AppIcon.font(
            Icons.bolt_outlined,
            color: Theme.of(context).colorScheme.primary,
          ),
          AppGap.md(),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                AppText.labelLarge(
                  loc(context).quickSetup,
                ),
                AppGap.xs(),
                AppText.bodySmall(
                  loc(context).quickSetupDescription,
                ),
              ],
            ),
          ),
          AppSwitch(
            key: const Key('quickSetupSwitch'),
            value: isSimpleMode,
            onChanged: (value) {
              notifier.setSimpleMode(value);
            },
          ),
        ],
      ),
    );
  }
}
