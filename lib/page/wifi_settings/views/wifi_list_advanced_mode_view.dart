import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/wifi_settings/_wifi_settings.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_state.dart';
import 'package:privacy_gui/page/wifi_settings/views/widgets/guest_wifi_card.dart';
import 'package:privacy_gui/page/wifi_settings/views/widgets/main_wifi_card.dart';
import 'package:privacygui_widgets/theme/_theme.dart';
import 'package:privacygui_widgets/widgets/container/responsive_layout.dart';
import 'package:privacygui_widgets/widgets/page/layout/basic_layout.dart';

class AdvancedModeView extends ConsumerStatefulWidget {
  const AdvancedModeView({
    super.key,
  });

  @override
  ConsumerState<AdvancedModeView> createState() => _AdvancedModeViewState();
}

class _AdvancedModeViewState extends ConsumerState<AdvancedModeView> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(wifiListProvider);

    return _wifiContentView(state);
  }

  Widget _wifiContentView(WiFiState state) {
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
                  .mapIndexed((index, e) => MainWiFiCard(
                      radio: e, canBeDisable: canBeDisabled, lastInRow: false))
                  .toList(),
              GuestWiFiCard(state: state.guestWiFi, lastInRow: true),
            ])
          : columnCount == state.mainWiFi.length
              ? TableRow(children: [
                  ...state.mainWiFi
                      .mapIndexed((index, e) => MainWiFiCard(
                          radio: e,
                          canBeDisable: canBeDisabled,
                          lastInRow: index == columnCount - 1))
                      .toList(),
                ])
              : TableRow(children: [
                  ...state.mainWiFi
                      .take(columnCount)
                      .mapIndexed((index, e) => MainWiFiCard(
                          radio: e,
                          canBeDisable: canBeDisabled,
                          lastInRow: index == columnCount - 1))
                      .toList(),
                ]),
      if (columnCount <= state.mainWiFi.length)
        columnCount == state.mainWiFi.length
            ? TableRow(children: [
                GuestWiFiCard(state: state.guestWiFi, lastInRow: false),
                ...List.filled(columnCount - 1, 0).map(
                  (_) => const SizedBox.shrink(),
                ),
              ])
            : TableRow(children: [
                ...state.mainWiFi
                    .getRange(columnCount, state.mainWiFi.length)
                    .mapIndexed((index, e) => MainWiFiCard(
                        radio: e,
                        canBeDisable: canBeDisabled,
                        lastInRow: false))
                    .toList(),
                GuestWiFiCard(state: state.guestWiFi, lastInRow: true),
              ])
    ];

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
}
