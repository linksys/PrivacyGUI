import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_item.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_list_provider.dart';
import 'package:privacy_gui/page/wifi_settings/views/wifi_term_titles.dart';
import 'package:privacy_gui/page/wifi_settings/views/widgets/guest_wifi_card.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';
import 'package:privacygui_widgets/widgets/container/responsive_layout.dart';
import 'package:privacygui_widgets/widgets/dropdown/dropdown_button.dart';
import 'package:privacygui_widgets/widgets/page/layout/basic_layout.dart';

class SimpleModeView extends ConsumerStatefulWidget {
  const SimpleModeView({
    super.key,
    required this.simpleWifiNameController,
    required this.simpleWifiPasswordController,
    required this.simpleSecurityType,
    required this.onSecurityTypeChanged,
  });

  final TextEditingController simpleWifiNameController;
  final TextEditingController simpleWifiPasswordController;
  final WifiSecurityType? simpleSecurityType;
  final Function(WifiSecurityType) onSecurityTypeChanged;

  @override
  ConsumerState<SimpleModeView> createState() => _SimpleModeViewState();
}

class _SimpleModeViewState extends ConsumerState<SimpleModeView> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(wifiListProvider);
    // final firstActiveWifi = state.mainWiFi.firstWhereOrNull((e) => e.isEnabled);

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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.titleLarge(loc(context).quickSetup),
          const AppGap.medium(),
          AppText.labelMedium(loc(context).wifiName),
          const AppGap.small1(),
          AppTextField(
            controller: widget.simpleWifiNameController,
            border: const OutlineInputBorder(),
          ),
          const AppGap.medium(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText.labelMedium(loc(context).wifiPassword),
                    const AppGap.small1(),
                    AppPasswordField(
                      controller: widget.simpleWifiPasswordController,
                      border: const OutlineInputBorder(),
                    ),
                  ],
                ),
              ),
              const AppGap.medium(),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText.labelMedium(loc(context).securityMode),
                    const AppGap.small1(),
                    AppDropdownButton<WifiSecurityType>(
                      initial: widget.simpleSecurityType,
                      items: securityTypeList,
                      label: (e) => getWifiSecurityTypeTitle(context, e),
                      onChanged: (value) {
                        widget.onSecurityTypeChanged(value);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const AppGap.medium(),
          AppText.bodySmall(loc(context).quickSetupDesc),
        ],
      ),
    );
  }
}
