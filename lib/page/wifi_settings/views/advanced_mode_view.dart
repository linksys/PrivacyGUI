import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_list_provider.dart';
import 'package:privacy_gui/page/wifi_settings/views/wifi_list_view.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_state.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_item.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';
import 'package:privacygui_widgets/widgets/container/responsive_layout.dart';
import 'package:privacygui_widgets/widgets/page/layout/basic_layout.dart';
import 'package:collection/collection.dart';
import 'package:privacy_gui/page/wifi_settings/providers/guest_wifi_item.dart';


class AdvancedModeView extends ConsumerWidget {
  const AdvancedModeView({
    super.key,
    required this.wifiDescription,
    required this.quickSetup,
    required this.mainWiFiCard,
    required this.guestWiFiCard,
  });

  final Widget Function(String) wifiDescription;
  final Widget Function(List<WiFiItem>) quickSetup;
  final Widget Function(WiFiItem, bool, {bool lastInRow}) mainWiFiCard;
  final Widget Function(GuestWiFiItem, {bool lastInRow}) guestWiFiCard;


  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(wifiListProvider);
    final wifiBands =
        state.mainWiFi.map((e) => e.radioID.bandName).toList().join(', ');

    final columnCount = ResponsiveLayout.isOverExtraLargeLayout(context)
        ? 4
        : ResponsiveLayout.isOverLargeLayout(context)
            ? 3
            : ResponsiveLayout.isOverMedimumLayout(context)
                ? 3
                : 2;
    final fixedWidth = ResponsiveLayout.isOverExtraLargeLayout(context)
        ? 3.col
        : ResponsiveLayout.isOverLargeLayout(context)
            ? 4.col
            : ResponsiveLayout.isOverMedimumLayout(context)
                ? 4.col
                : ResponsiveLayout.isOverSmallLayout(context)
                    ? 4.col
                    : 2.col;
    final columnWidths = Map.fromEntries(
        List.generate(columnCount, (index) => index).map((e) => e ==
                columnCount - 1
            ? MapEntry(e, FixedColumnWidth(fixedWidth))
            : MapEntry(
                e,
                FixedColumnWidth(
                    fixedWidth + ResponsiveLayout.columnPadding(context)))));

    final enabledWiFiCount = state.mainWiFi.where((e) => e.isEnabled).length;
    final canDisableAllMainWiFi = state.canDisableMainWiFi;
    final canBeDisabled = enabledWiFiCount > 1 || canDisableAllMainWiFi;
    final children = [
      columnCount > state.mainWiFi.length
          ? TableRow(children: [
              ...state.mainWiFi
                  .mapIndexed((index, e) =>
                      mainWiFiCard(e, canBeDisabled, lastInRow: index == columnCount - 1))
                  .toList(),
              guestWiFiCard(state.guestWiFi, lastInRow: true),
            ])
          : columnCount == state.mainWiFi.length
              ? TableRow(children: [
                  ...state.mainWiFi
                      .mapIndexed((index, e) => mainWiFiCard(
                          e, canBeDisabled, lastInRow: index == columnCount - 1))
                      .toList(),
                ])
              : TableRow(children: [
                  ...state.mainWiFi
                      .take(columnCount)
                      .mapIndexed((index, e) => mainWiFiCard(
                          e, canBeDisabled, lastInRow: index == columnCount - 1))
                      .toList(),
                ]),
      if (columnCount <= state.mainWiFi.length)
        columnCount == state.mainWiFi.length
            ? TableRow(children: [
                guestWiFiCard(state.guestWiFi, lastInRow: false),
                ...List.filled(columnCount - 1, 0).map(
                  (_) => const SizedBox.shrink(),
                ),
              ])
            : TableRow(children: [
                ...state.mainWiFi
                    .getRange(columnCount, state.mainWiFi.length)
                    .mapIndexed((index, e) => mainWiFiCard(
                        e, canBeDisabled, lastInRow: index == columnCount - 1))
                    .toList(),
                guestWiFiCard(state.guestWiFi, lastInRow: true),
              ])
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        wifiDescription(wifiBands),
        const AppGap.medium(),
        quickSetup(state.mainWiFi),
        const AppGap.medium(),
        AppBasicLayout(
        crossAxisAlignment: CrossAxisAlignment.start,
        content: Table(
          border: const TableBorder(),
          columnWidths: columnWidths,
          defaultVerticalAlignment: TableCellVerticalAlignment.top,
          children: children,
        ))
      ],
    );
  }
}