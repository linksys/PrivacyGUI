import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_bundle_provider.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_item.dart';
import 'package:privacy_gui/page/wifi_settings/views/widgets/wifi_setting_modal_mixin.dart';
import 'package:privacy_gui/page/wifi_settings/views/wifi_term_titles.dart';
import 'package:privacy_gui/page/wifi_settings/views/widgets/guest_wifi_card.dart';
import 'package:privacy_gui/page/wifi_settings/views/widgets/wifi_list_tile.dart';
import 'package:ui_kit_library/ui_kit.dart';

class SimpleModeView extends ConsumerStatefulWidget {
  const SimpleModeView({
    super.key,
    this.onWifiNameEdited,
    this.onWifiPasswordEdited,
    this.onSecurityTypeChanged,
  });

  final Function(String)? onWifiNameEdited;
  final Function(String)? onWifiPasswordEdited;
  final Function(WifiSecurityType)? onSecurityTypeChanged;

  @override
  ConsumerState<SimpleModeView> createState() => _SimpleModeViewState();
}

class _SimpleModeViewState extends ConsumerState<SimpleModeView>
    with WifiSettingModalMixin {
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();

    final simpleWifi =
        ref.read(wifiBundleProvider).current.wifiList.simpleModeWifi;
    _passwordController.text =
        simpleWifi.securityType.isOpenVariant ? '' : simpleWifi.password;
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(wifiBundleProvider);
    final simpleWifi = state.current.wifiList.simpleModeWifi;

    final isMobile = context.isMobileLayout;

    final Map<int, TableColumnWidth> columnWidths;
    final List<TableRow> children;

    if (isMobile) {
      columnWidths = const {0: FlexColumnWidth()};
      children = [
        TableRow(
          children: [
            _settingsView(simpleWifi),
          ],
        ),
        TableRow(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: GuestWiFiCard(
                  state: state.settings.current.wifiList.guestWiFi,
                  lastInRow: true),
            ),
          ],
        ),
      ];
    } else {
      columnWidths = const {
        0: FlexColumnWidth(2),
        1: FixedColumnWidth(16),
        2: FlexColumnWidth(1),
      };
      children = [
        TableRow(
          children: [
            _settingsView(simpleWifi),
            AppGap.lg(),
            GuestWiFiCard(
                state: state.settings.current.wifiList.guestWiFi,
                lastInRow: true),
          ],
        ),
      ];
    }

    return Table(
      border: const TableBorder(),
      columnWidths: columnWidths,
      defaultVerticalAlignment: TableCellVerticalAlignment.top,
      children: children,
    );
  }

  Widget _settingsView(WiFiItem simpleWifi) {
    return AppCard(
      padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.sm, horizontal: AppSpacing.xxl),
      child: Column(
        mainAxisSize: MainAxisSize.min, // 關鍵：讓 Column 使用最小高度
        children: [
          _simpleWiFiNameCard(simpleWifi.ssid),
          const Divider(),
          _simpleWiFiPasswordCard(simpleWifi.password, simpleWifi.securityType),
          const Divider(),
          _simpleWiFiSecurityTypeCard(simpleWifi),
        ],
      ),
    );
  }

  Widget _simpleWiFiNameCard(String ssid) => WifiListTile(
        title: AppText.bodyMedium(loc(context).wifiName),
        description: AppText.labelLarge(ssid),
        trailing: const AppIcon.font(
          AppFontIcons.edit,
        ),
        onTap: () {
          showWiFiNameModal(ssid, (value) {
            widget.onWifiNameEdited?.call(value);
          });
        },
      );

  Widget _simpleWiFiPasswordCard(
      String password, WifiSecurityType securityType) {
    return Opacity(
      opacity: securityType.isOpenVariant ? .5 : 1,
      child: IntrinsicWidth(
        child: IgnorePointer(
          ignoring: securityType.isOpenVariant ? true : false,
          child: WifiListTile(
            title: AppText.bodyMedium(
              loc(context).wifiPassword,
              color: !securityType.isOpenVariant && password.isEmpty
                  ? Theme.of(context).colorScheme.error
                  : Theme.of(context).colorScheme.onSurface,
            ),
            description: IntrinsicWidth(
                child: IgnorePointer(
              child: AppTextFormField(
                controller: _passwordController,
                obscureText: true,
              ),
            )),
            trailing: const AppIcon.font(AppFontIcons.edit),
            onTap: () {
              showWifiPasswordModal(password, (value) {
                widget.onWifiPasswordEdited?.call(value);
                setState(() {
                  _passwordController.text = value;
                });
              });
            },
          ),
        ),
      ),
    );
  }

  Widget _simpleWiFiSecurityTypeCard(WiFiItem simpleWifi) {
    final securityTypeTitle =
        getWifiSecurityTypeTitle(context, simpleWifi.securityType);
    return WifiListTile(
      title: AppText.bodyMedium(loc(context).securityMode),
      description: AppText.labelLarge(securityTypeTitle),
      trailing: const AppIcon.font(
        AppFontIcons.edit,
      ),
      onTap: () {
        showSecurityModeModal(
            simpleWifi.securityType, simpleWifi.availableSecurityTypes,
            (value) {
          widget.onSecurityTypeChanged?.call(value);
          setState(() {
            _passwordController.text =
                value.isOpenVariant ? '' : simpleWifi.password;
          });
        });
      },
    );
  }
}
