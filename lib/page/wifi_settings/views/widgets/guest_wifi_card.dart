import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_service_supported.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/wifi_settings/providers/guest_wifi_item.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_list_provider.dart';
import 'package:privacy_gui/page/wifi_settings/views/widgets/wifi_setting_modal_mixin.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';
import 'package:privacygui_widgets/widgets/card/list_card.dart';
import 'package:privacygui_widgets/widgets/container/responsive_layout.dart';
import 'package:privacygui_widgets/widgets/gap/const/spacing.dart';

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

class _GuestWiFiCardState extends ConsumerState<GuestWiFiCard> with WifiSettingModalMixin {
  final _guestPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _guestPasswordController.text = widget.state.password;
  }

  @override
  void didUpdateWidget(covariant GuestWiFiCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state.password != oldWidget.state.password) {
      _guestPasswordController.text = widget.state.password;
    }
  }

  @override
  void dispose() {
    _guestPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSupportGuestWiFi = serviceHelper.isSupportGuestNetwork();
    return isSupportGuestWiFi
        ? Padding(
            padding: EdgeInsets.only(
              right: widget.lastInRow
                  ? 0
                  : ResponsiveLayout.columnPadding(context),
              bottom: Spacing.medium,
            ),
            child: AppCard(
              key: const ValueKey('WiFiGuestCard'),
              padding: const EdgeInsets.symmetric(
                  vertical: Spacing.small2, horizontal: Spacing.large2),
              child: Column(
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
        : const SizedBox.shrink();
  }

  Widget _guestWiFiBandCard(GuestWiFiItem state) => AppListCard(
        showBorder: false,
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        title: AppText.labelLarge(loc(context).guest),
        trailing: AppSwitch(
          semanticLabel: 'guest',
          value: state.isEnabled,
          onChanged: (value) {
            ref.read(wifiListProvider.notifier).setWiFiEnabled(value);
          },
        ),
      );

  Widget _guestWiFiNameCard(GuestWiFiItem state) => AppListCard(
        showBorder: false,
        title: AppText.bodyMedium(loc(context).guestWiFiName),
        description: AppText.labelLarge(state.ssid),
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        trailing: const Icon(
          LinksysIcons.edit,
          semanticLabel: 'edit',
        ),
        onTap: () {
          showWiFiNameModal(state.ssid, (value) {
            ref.read(wifiListProvider.notifier).setWiFiSSID(value);
          });
        },
      );

  Widget _guestWiFiPasswordCard(GuestWiFiItem state) => AppListCard(
        showBorder: false,
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        title: AppText.bodyMedium(loc(context).guestWiFiPassword),
        description: IntrinsicWidth(
            child: Theme(
                data: Theme.of(context).copyWith(
                    inputDecorationTheme: const InputDecorationTheme(
                        isDense: true, contentPadding: EdgeInsets.zero)),
                child: Semantics(
                  textField: false,
                  explicitChildNodes: true,
                  child: AppPasswordField(
                    semanticLabel: 'guest wifi password',
                    readOnly: true,
                    border: InputBorder.none,
                    controller: _guestPasswordController,
                    suffixIconConstraints: const BoxConstraints(),
                  ),
                ))),
        trailing: const Icon(LinksysIcons.edit),
        onTap: () {
          showWifiPasswordModal(state.password, (value) {
            ref.read(wifiListProvider.notifier).setWiFiPassword(value);
          });
        },
      );
  
}
