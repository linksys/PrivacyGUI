import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_bundle_provider.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_item.dart';
import 'package:privacy_gui/page/wifi_settings/providers/guest_wifi_item.dart';
import 'package:privacy_gui/page/wifi_settings/views/widgets/guest_wifi_card.dart';
import 'package:privacy_gui/page/wifi_settings/views/widgets/main_wifi_card.dart';
import 'package:ui_kit_library/ui_kit.dart';

class AdvancedModeView extends ConsumerWidget {
  const AdvancedModeView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(wifiBundleProvider);

    // Calculate column count based on breakpoints
    // > 1440: 4 columns
    // > 905: 3 columns
    // <= 905: 2 columns
    final columnCount = context.isDesktopLargeLayout
        ? 4
        : context.isDesktopLayout
            ? 3
            : 2;

    // Calculate span for each item in the underlying grid
    // Desktop (12 cols) / 4 = 3 span
    // Desktop (12 cols) / 3 = 4 span
    // Tablet (8 cols) / 2 = 4 span
    // Mobile (4 cols) / 2 = 2 span
    final span = context.currentMaxColumns ~/ columnCount;

    // Calculate fixed width using colWidth from ui_kit
    final fixedWidth = context.colWidth(span);
    // Use layout gutter from ui_kit
    final padding = context.layoutGutter;

    final enabledWiFiCount = state.settings.current.wifiList.mainWiFi
        .where((e) => e.isEnabled)
        .length;
    final canDisableAllMainWiFi = state.status.wifiList.canDisableMainWiFi;
    // Condition to allow disabling an enabled wifi
    final canDisableMore = enabledWiFiCount > 1 || canDisableAllMainWiFi;

    // Better Approach: Flatten list and chunk it
    final allItems = [
      ...state.settings.current.wifiList.mainWiFi
          .map((e) => _AppWiFiItem.main(e)),
      _AppWiFiItem.guest(state.settings.current.wifiList.guestWiFi),
    ];

    final rows = <TableRow>[];
    for (var i = 0; i < allItems.length; i += columnCount) {
      final chunk = allItems.skip(i).take(columnCount).toList();
      final rowChildren = <Widget>[];
      for (var j = 0; j < columnCount; j++) {
        if (j < chunk.length) {
          final item = chunk[j];
          final isLast = j == columnCount - 1;
          if (item.isMain) {
            // Fix: Can toggle if it's currently disabled (to turn ON)
            // OR if it's enabled and we are allowed to disable more.
            final canToggle = !item.main!.isEnabled || canDisableMore;
            rowChildren.add(MainWiFiCard(
                radio: item.main!, canBeDisable: canToggle, lastInRow: isLast));
          } else {
            rowChildren
                .add(GuestWiFiCard(state: item.guest!, lastInRow: isLast));
          }
        } else {
          rowChildren.add(const SizedBox.shrink());
        }
      }
      rows.add(TableRow(children: rowChildren));
    }

    return Table(
      columnWidths: Map.fromEntries(
        List.generate(columnCount, (index) => index).map((e) =>
            e == columnCount - 1
                ? MapEntry(e, FixedColumnWidth(fixedWidth))
                : MapEntry(e, FixedColumnWidth(fixedWidth + padding))),
      ),
      children: rows,
    );
  }
}

class _AppWiFiItem {
  final WiFiItem? main;
  final GuestWiFiItem? guest;
  final bool isMain;
  _AppWiFiItem.main(this.main)
      : guest = null,
        isMain = true;
  _AppWiFiItem.guest(this.guest)
      : main = null,
        isMain = false;
}
