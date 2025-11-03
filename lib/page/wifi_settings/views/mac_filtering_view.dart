import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/core/utils/extension.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/instant_device/providers/device_list_state.dart';
import 'package:privacy_gui/page/instant_privacy/providers/instant_privacy_state.dart';
import 'package:privacy_gui/page/wifi_settings/providers/displayed_mac_filtering_devices_provider.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_bundle_provider.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/theme/_theme.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';
import 'package:privacygui_widgets/widgets/card/info_card.dart';
import 'package:privacygui_widgets/widgets/card/setting_card.dart';
import 'package:privacygui_widgets/widgets/container/responsive_layout.dart';
import 'package:privacygui_widgets/widgets/gap/const/spacing.dart';

class MacFilteringView extends ConsumerWidget {
  const MacFilteringView({
    super.key,
    this.args,
  });

  final Map<String, dynamic>? args;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final privacyState = ref.watch(
        wifiBundleProvider.select((state) => state.settings.current.privacy));
    final originalPrivacyState = ref.watch(
        wifiBundleProvider.select((state) => state.settings.original.privacy));

    final displayDevices = ref.watch(macFilteringDeviceListProvider);
    return SingleChildScrollView(
      child: ResponsiveLayout(
        desktop: _desktopLayout(
            context, ref, privacyState, originalPrivacyState, displayDevices),
        mobile: _mobileLayout(
            context, ref, privacyState, originalPrivacyState, displayDevices),
      ),
    );
  }

  Widget _desktopLayout(
      BuildContext context,
      WidgetRef ref,
      InstantPrivacySettings state,
      InstantPrivacySettings originalState,
      List<DeviceListItem> deviceList) {
    return SizedBox(
      width: 9.col,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (originalState.mode == MacFilterMode.allow) ...[
            _warningCard(context),
            const AppGap.small2(),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _enableTile(context, ref, state),
                    const AppGap.small2(),
                    _infoCard(context, state.mode == MacFilterMode.deny,
                        deviceList.length),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _mobileLayout(
      BuildContext context,
      WidgetRef ref,
      InstantPrivacySettings state,
      InstantPrivacySettings originalState,
      List<DeviceListItem> deviceList) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (originalState.mode == MacFilterMode.allow) ...[
          _warningCard(context),
          const AppGap.small2(),
        ],
        _enableTile(context, ref, state),
        const AppGap.small2(),
        _infoCard(context, state.mode == MacFilterMode.deny, deviceList.length),
        const AppGap.large2(),
      ],
    );
  }

  Widget _warningCard(BuildContext context) {
    return AppSettingCard(
      title: loc(context).instantPrivacyDisableWarning,
      leading: Icon(
        LinksysIcons.infoCircle,
        color: Theme.of(context).colorScheme.error,
      ),
      borderColor: Theme.of(context).colorScheme.error,
    );
  }

  Widget _infoCard(BuildContext context, bool enabled, int length) {
    return Opacity(
      opacity: enabled ? 1 : .5,
      child: AppInfoCard(
        padding: const EdgeInsets.all(Spacing.medium),
        onTap: enabled
            ? () {
                context.pushNamed(RouteNamed.macFilteringInput);
              }
            : null,
        title: loc(context).nDevices(length).capitalizeWords(),
        description: loc(context).denyAccessDesc,
        trailing: Icon(LinksysIcons.chevronRight),
      ),
    );
  }

  Widget _enableTile(
      BuildContext context, WidgetRef ref, InstantPrivacySettings state) {
    final notifier = ref.read(wifiBundleProvider.notifier);
    return AppCard(
        child: Row(
      children: [
        Expanded(child: AppText.labelLarge(loc(context).wifiMacFiltering)),
        AppSwitch(
          semanticLabel: 'wifi mac filtering',
          value: state.mode == MacFilterMode.deny,
          onChanged: (value) {
            notifier.setMacFilterMode(
                value ? MacFilterMode.deny : MacFilterMode.disabled);
          },
        )
      ],
    ));
  }
}
