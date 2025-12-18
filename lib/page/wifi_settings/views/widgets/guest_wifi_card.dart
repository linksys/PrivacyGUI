import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_service_supported.dart';
import 'package:privacy_gui/di.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/wifi_settings/providers/guest_wifi_item.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_bundle_provider.dart';
import 'package:privacy_gui/page/wifi_settings/views/widgets/wifi_setting_modal_mixin.dart';
import 'package:privacy_gui/page/wifi_settings/views/widgets/wifi_list_tile.dart';
import 'package:privacy_gui/page/wifi_settings/views/widgets/wifi_password_field.dart';
import 'package:ui_kit_library/ui_kit.dart';

class GuestWiFiCard extends ConsumerStatefulWidget {
  const GuestWiFiCard({
    super.key,
    required this.state,
    this.lastInRow = false,
  });

  final GuestWiFiItem state;
  final bool lastInRow;

  @override
  ConsumerState<GuestWiFiCard> createState() => _GuestWiFiCardState();
}

class _GuestWiFiCardState extends ConsumerState<GuestWiFiCard>
    with WifiSettingModalMixin {
  // Get serviceHelper from dependency injection
  final serviceHelper = getIt<ServiceHelper>();

  @override
  Widget build(BuildContext context) {
    final isSupportGuestWiFi = serviceHelper.isSupportGuestNetwork();
    return isSupportGuestWiFi
        ? Padding(
            padding: EdgeInsets.only(
              // Note: horizontal spacing is handled by Wrap's spacing property
              // Only add bottom padding for vertical separation between rows
              bottom: AppSpacing.lg,
            ),
            child: AppCard(
              key: const Key('WiFiGuestCard'),
              padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.sm, horizontal: AppSpacing.xxl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _guestWiFiBandCard(widget.state),
                  if (widget.state.isEnabled) ...[
                    const Divider(),
                    _guestWiFiNameCard(widget.state),
                    const Divider(),
                    _guestWiFiPasswordCard(widget.state),
                  ],
                ],
              ),
            ),
          )
        : const SizedBox.shrink(key: Key('guest-wifi-disabled'));
  }

  Widget _guestWiFiBandCard(GuestWiFiItem state) => WifiListTile(
        title: AppText.labelLarge(loc(context).guest),
        trailing: AppSwitch(
          key: const Key('WiFiGuestSwitch'),
          value: state.isEnabled,
          onChanged: (value) {
            ref.read(wifiBundleProvider.notifier).setWiFiEnabled(value);
          },
        ),
      );

  Widget _guestWiFiNameCard(GuestWiFiItem state) => WifiListTile(
        title: AppText.bodyMedium(loc(context).guestWiFiName),
        description: AppText.labelLarge(state.ssid),
        trailing: const AppIcon.font(
          AppFontIcons.edit,
        ),
        onTap: () {
          showWiFiNameModal(state.ssid, (value) {
            ref.read(wifiBundleProvider.notifier).setWiFiSSID(value);
          });
        },
      );

  Widget _guestWiFiPasswordCard(GuestWiFiItem state) => WifiListTile(
        title: AppText.bodyMedium(loc(context).guestWiFiPassword),
        description: WifiPasswordField(
          controller: TextEditingController(text: state.password),
          readOnly: true,
          showLabel: false,
          isLength64: true,
        ),
        trailing: const AppIcon.font(AppFontIcons.edit),
        onTap: () {
          showWifiPasswordModal(state.password, (value) {
            ref.read(wifiBundleProvider.notifier).setWiFiPassword(value);
          });
        },
      );
}
