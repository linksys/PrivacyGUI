import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/usp_page/wifi_settings/providers/usp_wifi_settings_provider.dart';
import 'package:privacy_gui/usp_page/wifi_settings/views/components/wifi_network_card.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Tab 1 — WiFi networks in a responsive grid.
///
/// Column counts (matching the main wifi_settings page):
///   Desktop large (>1440 px) → 4 columns
///   Desktop        (>905 px) → 3 columns
///   Tablet / Mobile          → 2 columns
///
/// Main networks are sorted 2.4 GHz → 5 GHz → 6 GHz; guest networks follow.
class UspWifiListTab extends ConsumerStatefulWidget {
  const UspWifiListTab({super.key});

  @override
  ConsumerState<UspWifiListTab> createState() => _UspWifiListTabState();
}

class _UspWifiListTabState extends ConsumerState<UspWifiListTab> {
  bool _quickSetupEnabled = false;

  @override
  Widget build(BuildContext context) {
    final networks = ref.watch(
      uspWifiSettingsProvider.select((s) => s.value?.networks ?? []),
    );

    if (networks.isEmpty) {
      return Center(
        child: AppText.bodyMedium(
          'No WiFi networks found',
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      );
    }

    // Sort: main networks by band (2.4 → 5 → 6), then guest networks
    const bandOrder = ['2.4GHz', '5GHz', '6GHz'];
    int bandRank(String band) {
      final idx = bandOrder.indexOf(band);
      return idx < 0 ? 99 : idx;
    }

    final sorted = [...networks]..sort((a, b) {
        if (a.isGuest != b.isGuest) return a.isGuest ? 1 : -1;
        return bandRank(a.band).compareTo(bandRank(b.band));
      });

    // Responsive column count
    final columnCount = context.isDesktopLargeLayout
        ? 4
        : context.isDesktopLayout
            ? 3
            : 2;

    // Fixed column width (same formula as AdvancedModeView)
    final span = context.currentMaxColumns ~/ columnCount;
    final fixedWidth = context.colWidth(span);
    final gutter = context.layoutGutter;

    // Build table rows (chunk sorted list by columnCount)
    final rows = <TableRow>[];
    for (var i = 0; i < sorted.length; i += columnCount) {
      final chunk = sorted.skip(i).take(columnCount).toList();
      final cells = <Widget>[];
      for (var j = 0; j < columnCount; j++) {
        if (j < chunk.length) {
          cells.add(WifiNetworkCard(
            network: chunk[j],
            lastInRow: j == columnCount - 1,
          ));
        } else {
          cells.add(const SizedBox.shrink());
        }
      }
      rows.add(TableRow(children: cells));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Quick Setup card (full width) ─────────────────────────────
          AppCard(
            child: Row(
              children: [
                AppIcon.font(
                  Icons.bolt_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                AppGap.md(),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppText.labelLarge('Quick Setup'),
                      AppGap.xs(),
                      AppText.bodySmall(
                        'Apply the same WiFi settings to all bands at once',
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
                AppSwitch(
                  value: _quickSetupEnabled,
                  onChanged: (v) => setState(() => _quickSetupEnabled = v),
                ),
              ],
            ),
          ),
          AppGap.lg(),
          // ── Per-band network grid ─────────────────────────────────────
          Table(
            defaultVerticalAlignment: TableCellVerticalAlignment.intrinsicHeight,
            columnWidths: Map.fromEntries(
              List.generate(columnCount, (i) => i).map(
                (e) => e == columnCount - 1
                    ? MapEntry(e, FixedColumnWidth(fixedWidth))
                    : MapEntry(e, FixedColumnWidth(fixedWidth + gutter)),
              ),
            ),
            children: rows,
          ),
        ],
      ),
    );
  }
}
