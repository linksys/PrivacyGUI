import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/wifi_settings/providers/usp_wifi_settings_provider.dart';
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
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Error or empty state
    if (state.status.errorMessage != null ||
        state.settings.current.networks.isEmpty) {
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
                state.status.errorMessage ??
                    'No WiFi networks found. Check router connection.',
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      );
    }

    final quickSetupEnabled = state.settings.current.quickSetupEnabled;
    final canSave = state.canSave;
    final isSaving = state.status.isSaving;

    // Responsive column count
    final columnCount = context.isDesktopLargeLayout
        ? 4
        : context.isDesktopLayout
            ? 3
            : 2;

    final span = context.currentMaxColumns ~/ columnCount;
    final fixedWidth = context.colWidth(span);
    final gutter = context.layoutGutter;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Quick Setup toggle card ──────────────────────────────
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
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
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
                AppGap.lg(),
                // ── Quick Setup mode: Main + Guest cards ─────────────────
                if (quickSetupEnabled)
                  _buildQuickSetupGrid(context, columnCount, fixedWidth, gutter)
                // ── Normal mode: per-band grid ───────────────────────────
                else
                  _buildAdvancedGrid(
                      context, state, columnCount, fixedWidth, gutter),
              ],
            ),
          ),
        ),
        // ── Page-level Save button ───────────────────────────────────────
        if (quickSetupEnabled || state.isDirty || isSaving)
          _buildSaveBar(context, ref, canSave, isSaving),
      ],
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

  Widget _buildAdvancedGrid(
    BuildContext context,
    dynamic state,
    int columnCount,
    double fixedWidth,
    double gutter,
  ) {
    const bandOrder = ['2.4GHz', '5GHz', '6GHz'];
    int bandRank(String band) {
      final idx = bandOrder.indexOf(band);
      return idx < 0 ? 99 : idx;
    }

    final sorted = [...state.settings.current.networks]..sort((a, b) {
        if (a.isGuest != b.isGuest) return a.isGuest ? 1 : -1;
        return bandRank(a.band).compareTo(bandRank(b.band));
      });

    final rows = <TableRow>[];
    for (var i = 0; i < sorted.length; i += columnCount) {
      final chunk = sorted.skip(i).take(columnCount).toList();
      final cells = <Widget>[];
      for (var j = 0; j < columnCount; j++) {
        if (j < chunk.length) {
          cells.add(WifiNetworkCard(
            ssidInstancePath: chunk[j].ssidInstancePath,
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

  Widget _buildSaveBar(
    BuildContext context,
    WidgetRef ref,
    bool canSave,
    bool isSaving,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.layoutMargin,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        child: AppButton.primary(
          label: 'Save',
          isLoading: isSaving,
          onTap: (canSave && !isSaving)
              ? () async {
                  try {
                    await ref.read(uspWifiSettingsProvider.notifier).save();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Settings saved'),
                        ),
                      );
                    }
                  } catch (_) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Failed to save settings'),
                        ),
                      );
                    }
                  }
                }
              : null,
        ),
      ),
    );
  }
}
