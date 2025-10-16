import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_item.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_list_provider.dart';
import 'package:privacy_gui/page/wifi_settings/views/widgets/wifi_setting_modal_mixin.dart';
import 'package:privacy_gui/page/wifi_settings/views/wifi_term_titles.dart';
import 'package:privacy_gui/page/wifi_settings/views/widgets/guest_wifi_card.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';
import 'package:privacygui_widgets/widgets/card/list_card.dart';
import 'package:privacygui_widgets/widgets/card/setting_card.dart';
import 'package:privacygui_widgets/widgets/container/responsive_layout.dart';
import 'package:privacygui_widgets/widgets/gap/const/spacing.dart';
import 'package:privacygui_widgets/widgets/page/layout/basic_layout.dart';

class SimpleModeView extends ConsumerStatefulWidget {
  const SimpleModeView({
    super.key,
    required this.simpleWifiNameController,
    required this.simpleWifiPasswordController,
    required this.simpleSecurityType,
    required this.onWifiNameEdited,
    required this.onWifiPasswordEdited,
    required this.onSecurityTypeChanged,
  });

  final TextEditingController simpleWifiNameController;
  final TextEditingController simpleWifiPasswordController;
  final WifiSecurityType simpleSecurityType;
  final Function(String) onWifiNameEdited;
  final Function(String) onWifiPasswordEdited;
  final Function(WifiSecurityType) onSecurityTypeChanged;

  @override
  ConsumerState<SimpleModeView> createState() => _SimpleModeViewState();
}

class _SimpleModeViewState extends ConsumerState<SimpleModeView>
    with WifiSettingModalMixin {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(wifiListProvider);
    Set<WifiSecurityType> securityTypeSet =
        state.mainWiFi.first.availableSecurityTypes.toSet();
    for (var e in state.mainWiFi) {
      final availableSecurityTypesSet = e.availableSecurityTypes.toSet();
      securityTypeSet = securityTypeSet.intersection(availableSecurityTypesSet);
    }
    final securityTypeList = securityTypeSet.toList();

    final isMobile = ResponsiveLayout.isMobileLayout(context);

    final Map<int, TableColumnWidth> columnWidths;
    final List<TableRow> children;

    if (isMobile) {
      columnWidths = const {0: FlexColumnWidth()};
      children = [
        TableRow(
          children: [
            _settingsView(securityTypeList),
          ],
        ),
        TableRow(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: GuestWiFiCard(state: state.guestWiFi, lastInRow: true),
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
            _settingsView(securityTypeList),
            const AppGap.medium(),
            GuestWiFiCard(state: state.guestWiFi, lastInRow: true),
          ],
        ),
      ];
    }

    return AppBasicLayout(
      crossAxisAlignment: CrossAxisAlignment.start,
      content: Table(
        border: const TableBorder(),
        columnWidths: columnWidths,
        defaultVerticalAlignment: TableCellVerticalAlignment.top,
        children: children,
      ),
    );
  }

  Widget _settingsView(List<WifiSecurityType> securityTypeList) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.medium),
      child: Column(
        children: [
          _advancedWiFiNameCard(widget.simpleWifiNameController.text),
          const Divider(),
          _advancedWiFiPasswordCard(widget.simpleWifiPasswordController.text,
              widget.simpleSecurityType),
          const Divider(),
          _advancedWiFiSecurityTypeCard(
              widget.simpleSecurityType, securityTypeList),
        ],
      ),
    );
  }

  Widget _advancedWiFiNameCard(String ssid) => AppSettingCard.noBorder(
        title: loc(context).wifiName,
        description: widget.simpleWifiNameController.text,
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        trailing: const Icon(
          Icons.edit,
          semanticLabel: 'edit',
        ),
        onTap: () {
          showWiFiNameModal(ssid, (value) {
            widget.onWifiNameEdited(value);
          });
        },
      );

  Widget _advancedWiFiPasswordCard(
          String password, WifiSecurityType securityType) =>
      Opacity(
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
                          controller: widget.simpleWifiPasswordController,
                        ),
                      )
                    : Semantics(
                        textField: false,
                        explicitChildNodes: true,
                        child: AppPasswordField(
                          readOnly: true,
                          border: InputBorder.none,
                          controller: widget.simpleWifiPasswordController,
                          suffixIconConstraints: const BoxConstraints(),
                        ),
                      ),
              ),
            ),
            trailing: const Icon(Icons.edit),
            onTap: () {
              showWifiPasswordModal(password, (value) {
                widget.onWifiPasswordEdited(value);
              });
            },
          ),
        ),
      );

  Widget _advancedWiFiSecurityTypeCard(
      WifiSecurityType securityType, List<WifiSecurityType> securityTypeList) {
    final securityTypeTitle = getWifiSecurityTypeTitle(context, securityType);
    return AppListCard(
      showBorder: false,
      title: AppText.bodyMedium(loc(context).securityMode),
      description: SizedBox(
        height: 36,
        child: AppText.labelLarge(securityTypeTitle),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      trailing: const Icon(
        Icons.edit,
        semanticLabel: 'edit',
      ),
      onTap: () {
        showSecurityModeModal(securityType, securityTypeList, (value) {
          widget.onSecurityTypeChanged(value);
        });
      },
    );
  }
}
