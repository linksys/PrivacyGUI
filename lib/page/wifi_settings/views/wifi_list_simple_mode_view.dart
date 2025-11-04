import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_bundle_provider.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_item.dart';
import 'package:privacy_gui/page/wifi_settings/views/widgets/wifi_setting_modal_mixin.dart';
import 'package:privacy_gui/page/wifi_settings/views/wifi_term_titles.dart';
import 'package:privacy_gui/page/wifi_settings/views/widgets/guest_wifi_card.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';
import 'package:privacygui_widgets/widgets/card/list_card.dart';
import 'package:privacygui_widgets/widgets/container/responsive_layout.dart';
import 'package:privacygui_widgets/widgets/gap/const/spacing.dart';

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

    final isMobile = ResponsiveLayout.isMobileLayout(context);

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
            const AppGap.medium(),
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
          vertical: Spacing.small2, horizontal: Spacing.large2),
      child: Column(
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

  Widget _simpleWiFiNameCard(String ssid) => AppListCard(
        showBorder: false,
        title: AppText.bodyMedium(loc(context).wifiName),
        description: AppText.labelLarge(ssid),
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        trailing: const Icon(
          LinksysIcons.edit,
          semanticLabel: 'edit',
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
      child: IgnorePointer(
        ignoring: securityType.isOpenVariant ? true : false,
        child: AppListCard(
          showBorder: false,
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          title: AppText.bodyMedium(
            loc(context).wifiPassword,
            color: !securityType.isOpenVariant && password.isEmpty
                ? Theme.of(context).colorScheme.error
                : Theme.of(context).colorScheme.onSurface,
          ),
          description: IntrinsicWidth(
            child: Theme(
              data: Theme.of(context).copyWith(
                  inputDecorationTheme: const InputDecorationTheme(
                      isDense: true, contentPadding: EdgeInsets.zero)),
              child: securityType.isOpenVariant
                  ? Semantics(
                      textField: false,
                      explicitChildNodes: true,
                      child: AppTextField(
                        readOnly: true,
                        border: InputBorder.none,
                        controller: _passwordController,
                      ),
                    )
                  : Semantics(
                      textField: false,
                      explicitChildNodes: true,
                      child: AppPasswordField(
                        readOnly: true,
                        border: InputBorder.none,
                        controller: _passwordController,
                        suffixIconConstraints: const BoxConstraints(),
                      ),
                    ),
            ),
          ),
          trailing: const Icon(LinksysIcons.edit),
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
    );
  }

  Widget _simpleWiFiSecurityTypeCard(WiFiItem simpleWifi) {
    final securityTypeTitle =
        getWifiSecurityTypeTitle(context, simpleWifi.securityType);
    return AppListCard(
      showBorder: false,
      title: AppText.bodyMedium(loc(context).securityMode),
      description: AppText.labelLarge(securityTypeTitle),
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      trailing: const Icon(
        LinksysIcons.edit,
        semanticLabel: 'edit',
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
