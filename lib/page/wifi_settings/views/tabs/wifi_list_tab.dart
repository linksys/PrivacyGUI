import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/components/localizations/service_error_localizations.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/_shared/components/layout_blocks.dart';
import 'package:privacy_gui/page/wifi_settings/providers/usp_wifi_settings_provider.dart';
import 'package:privacy_gui/page/wifi_settings/providers/usp_wifi_settings_state.dart';
import 'package:privacy_gui/page/wifi_settings/views/components/wifi_network_card.dart';
import 'package:privacy_gui/page/wifi_settings/views/components/wifi_quick_setup_card.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Tab 1 — WiFi networks in a responsive grid.
///
/// - **Quick Setup OFF** (default): one card per SSID, sorted by band.
/// - **Quick Setup ON**: two aggregate cards (Main / Guest), Name + Password
///   + Security mode only — changes fan out to all bands on Save.
///
/// A page-level **Save** button appears at the bottom whenever there are
/// pending (dirty) changes. In Quick Setup mode it is also disabled until the
/// user enters a valid password.
class UspWifiListTab extends ConsumerWidget {
  const UspWifiListTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(uspWifiSettingsProvider);

    // Loading state
    if (state.status.isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.xxxl),
          child: AppLoader(),
        ),
      );
    }

    // Error or empty state
    if (state.status.error != null || state.settings.current.networks.isEmpty) {
      final error = state.status.error;
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppIcon.font(Icons.error_outline,
                  color: Theme.of(context).colorScheme.error),
              AppGap.md(),
              AppText.bodyMedium(
                error != null
                    ? localizeServiceError(context, error)
                    : loc(context).noWifiNetworksFound,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      );
    }

    final quickSetupEnabled = state.settings.current.quickSetupEnabled;

    // Responsive column count
    final columnCount = context.isDesktopLargeLayout
        ? 4
        : context.isDesktopLayout
            ? 3
            : 2;

    final span = context.currentMaxColumns ~/ columnCount;
    final fixedWidth = context.colWidth(span);
    final gutter = context.layoutGutter;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Quick Setup toggle card ──────────────────────────────
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: LayoutBlock(
              padding: const EdgeInsets.symmetric(
                vertical: AppSpacing.sm,
                horizontal: AppSpacing.md,
              ),
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
                        AppText.labelLarge(loc(context).quickSetup),
                        AppGap.xs(),
                        AppText.bodySmall(
                          loc(context).quickSetupApplyDesc,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ),
                  AppSwitch(
                    value: quickSetupEnabled,
                    onChanged: (v) => ref
                        .read(uspWifiSettingsProvider.notifier)
                        .setQuickSetupEnabled(v),
                  ),
                ],
              ),
            ),
          ),
          AppGap.lg(),
          // ── Quick Setup mode: Main + Guest cards ─────────────────
          if (quickSetupEnabled) ...[
            _buildQuickSetupNotice(context),
            AppGap.md(),
            _buildQuickSetupGrid(context, columnCount, fixedWidth, gutter),
          ]
          // ── Normal mode: per-band grid ───────────────────────────
          else
            _buildAdvancedGrid(context, state, columnCount, fixedWidth, gutter),
        ],
      ),
    );
  }

  Widget _buildQuickSetupGrid(
    BuildContext context,
    int columnCount,
    double fixedWidth,
    double gutter,
  ) {
    final items = [false, true]; // Main then Guest

    final rows = <TableRow>[];
    for (var i = 0; i < items.length; i += columnCount) {
      final chunk = items.skip(i).take(columnCount).toList();
      final cells = <Widget>[];
      for (var j = 0; j < columnCount; j++) {
        if (j < chunk.length) {
          cells.add(WifiQuickSetupCard(
            isGuest: chunk[j],
            lastInRow: j == columnCount - 1,
          ));
        } else {
          cells.add(const SizedBox.shrink());
        }
      }
      rows.add(TableRow(children: cells));
    }

    return Table(
      defaultVerticalAlignment: TableCellVerticalAlignment.intrinsicHeight,
      columnWidths: _columnWidths(columnCount, fixedWidth, gutter),
      children: rows,
    );
  }

  Widget _buildQuickSetupNotice(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return AppSurface(
      variant: SurfaceVariant.tonal,
      borderRadius: AppRadius.md,
      showBorder: false,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppIcon.font(
            AppFontIcons.infoCircle,
            color: colorScheme.onSurfaceVariant,
            size: 18,
          ),
          AppGap.sm(),
          Expanded(
            child: AppText.bodySmall(
              loc(context).quickSetupNotice,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedGrid(
    BuildContext context,
    UspWifiSettingsState state,
    int columnCount,
    double fixedWidth,
    double gutter,
  ) {
    const bandOrder = ['2.4GHz', '5GHz', '6GHz'];
    int bandRank(String band) {
      final idx = bandOrder.indexOf(band);
      return idx < 0 ? 99 : idx;
    }

    final networks = state.settings.current.networks;
    final mainNets = networks.where((n) => !n.isGuest).toList()
      ..sort((a, b) => bandRank(a.band).compareTo(bandRank(b.band)));
    final guestNets = networks.where((n) => n.isGuest).toList()
      ..sort((a, b) => bandRank(a.band).compareTo(bandRank(b.band)));

    // Build a map from band to guest network for pairing
    final guestByBand = {for (final g in guestNets) g.band: g};

    // Build columns: each band is a column with Main on top, Guest below
    // Use Expanded so all columns share equal width regardless of count
    final columns = <Widget>[];

    for (var i = 0; i < mainNets.length; i++) {
      final main = mainNets[i];
      final guest = guestByBand[main.band];
      final lastInRow = i == mainNets.length - 1;

      final columnChildren = <Widget>[
        WifiNetworkCard(
          ssidInstancePath: main.ssidInstancePath,
          lastInRow: true,
        ),
      ];

      if (guest != null) {
        columnChildren.add(WifiNetworkCard(
          ssidInstancePath: guest.ssidInstancePath,
          lastInRow: true,
        ));
      }

      columns.add(Expanded(
        child: Padding(
          padding: EdgeInsets.only(right: lastInRow ? 0 : gutter),
          child: Column(children: columnChildren),
        ),
      ));
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: columns,
    );
  }

  Map<int, TableColumnWidth> _columnWidths(
      int count, double fixedWidth, double gutter) {
    return Map.fromEntries(
      List.generate(count, (i) => i).map(
        (e) => e == count - 1
            ? MapEntry(e, FixedColumnWidth(fixedWidth))
            : MapEntry(e, FixedColumnWidth(fixedWidth + gutter)),
      ),
    );
  }
}
