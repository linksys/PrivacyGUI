import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/devices/providers/devices_data_provider.dart';
import 'package:privacy_gui/page/local_network/providers/ethernet_data_provider.dart';
import 'package:privacy_gui/page/port_forwarding/providers/port_forwarding_data_provider.dart';
import 'package:privacy_gui/page/port_forwarding/providers/port_triggering_data_provider.dart';
import 'package:privacy_gui/page/_shared/components/layout_blocks/stat_blocks.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_data_provider.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// A row of summary stat cards displayed at the top of the dashboard.
///
/// Each tile resolves against its own domain provider independently: a tile
/// whose provider is still loading shows a skeleton, one whose provider has
/// failed shows an error affordance (its title stays mounted and tapping it
/// re-invalidates just that provider), and one with data shows its value.
/// A single domain failure therefore degrades only its own tile(s) — the
/// other tiles keep rendering their data (#1367).
class UspStatsPanel extends ConsumerWidget {
  const UspStatsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devicesAsync = ref.watch(devicesDataProvider);
    final wifiAsync = ref.watch(wifiDataProvider);
    final ethernetAsync = ref.watch(ethernetDataProvider);
    final pfAsync = ref.watch(portForwardingDataProvider);
    final ptAsync = ref.watch(portTriggeringDataProvider);

    // Router / Devices both derive from the devices domain, so they share its
    // async status. Port Rules combines two providers — treat it as loading if
    // either is loading and errored if either errored.
    final forwardStatus = _combine(pfAsync, ptAsync);

    return Row(
      children: [
        Expanded(
          child: _StatCell(
            icon: Icons.router,
            label: loc(context).router,
            status: _statusOf(devicesAsync),
            value: () => '${devicesAsync.requireValue.nodes.length}',
            onRetry: () => ref.invalidate(devicesDataProvider),
          ),
        ),
        AppGap.sm(),
        Expanded(
          child: _StatCell(
            icon: Icons.devices,
            label: loc(context).devices,
            status: _statusOf(devicesAsync),
            value: () =>
                '${devicesAsync.requireValue.clientDevices.where((d) => d.isActive).length}',
            onRetry: () => ref.invalidate(devicesDataProvider),
          ),
        ),
        AppGap.sm(),
        Expanded(
          child: _StatCell(
            icon: Icons.lan,
            label: loc(context).lanPorts,
            status: _statusOf(ethernetAsync),
            value: () {
              final lanPorts = ethernetAsync.requireValue.ethernetPortModels
                  .where((p) => !p.isWan);
              final lanConnected = lanPorts.where((p) => p.isUp).length;
              return '$lanConnected/${lanPorts.length}';
            },
            onRetry: () => ref.invalidate(ethernetDataProvider),
          ),
        ),
        AppGap.sm(),
        Expanded(
          child: _StatCell(
            icon: Icons.wifi,
            label: loc(context).radios,
            status: _statusOf(wifiAsync),
            value: () {
              final radios = wifiAsync.requireValue.radioModels;
              final enabled = radios.where((r) => r.enable).length;
              return '$enabled/${radios.length}';
            },
            onRetry: () => ref.invalidate(wifiDataProvider),
          ),
        ),
        AppGap.sm(),
        Expanded(
          child: _StatCell(
            icon: Icons.shortcut,
            label: loc(context).portRules,
            status: forwardStatus,
            value: () {
              final pfCount = pfAsync.requireValue.ruleModels.length;
              final ptCount = ptAsync.requireValue.ruleModels.length;
              return '${pfCount + ptCount}';
            },
            onRetry: () {
              ref.invalidate(portForwardingDataProvider);
              ref.invalidate(portTriggeringDataProvider);
            },
          ),
        ),
      ],
    );
  }

  /// Collapses an [AsyncValue] to the tile's own three-way status: a value is
  /// shown, a spinner is shown, or an error affordance is shown. Unlike
  /// `valueOrNull`, this keeps error distinct from loading so a failed provider
  /// no longer looks like it is still loading (#1367).
  _CellStatus _statusOf(AsyncValue<Object?> async) {
    if (async.hasError) return _CellStatus.error;
    if (async.hasValue) return _CellStatus.data;
    return _CellStatus.loading;
  }

  /// Combined status for a tile backed by two providers (Port Rules). Error
  /// wins over loading, which wins over data.
  _CellStatus _combine(AsyncValue<Object?> a, AsyncValue<Object?> b) {
    if (a.hasError || b.hasError) return _CellStatus.error;
    if (a.hasValue && b.hasValue) return _CellStatus.data;
    return _CellStatus.loading;
  }
}

enum _CellStatus { loading, data, error }

/// A single stat tile that renders its value, a loading skeleton, or an error
/// affordance, depending on its backing provider's [_CellStatus].
///
/// [value] is a thunk rather than a plain string because it dereferences the
/// provider's resolved data (`requireValue`), which is only safe to read in the
/// [_CellStatus.data] branch.
class _StatCell extends StatelessWidget {
  final IconData icon;
  final String label;
  final _CellStatus status;
  final String Function() value;
  final VoidCallback onRetry;

  const _StatCell({
    required this.icon,
    required this.label,
    required this.status,
    required this.value,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return switch (status) {
      _CellStatus.data => StatTile(icon: icon, value: value(), label: label),
      _CellStatus.loading => const _StatCellSkeleton(),
      // Keep the title mounted and turn the value into a tappable error glyph
      // that re-invalidates just this tile's provider — so the user can tell
      // which widget failed and recover it without a full page reload.
      _CellStatus.error => Semantics(
          button: true,
          label: '$label, ${loc(context).retry}',
          child: StatTile(
            icon: icon,
            value: '—',
            label: label,
            onTap: onRetry,
          ),
        ),
    };
  }
}

/// Loading placeholder for one stat tile — the single-tile equivalent of the
/// `CardSkeleton.stats()` row, so a per-tile loading state occupies the same
/// space its resolved [StatTile] will.
class _StatCellSkeleton extends StatelessWidget {
  const _StatCellSkeleton();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppSkeleton(
              width: 24, height: 24, borderRadius: BorderRadius.circular(4)),
          AppGap.sm(),
          AppSkeleton.text(width: 40, height: 18),
          AppGap.xs(),
          AppSkeleton.text(width: 48),
        ],
      ),
    );
  }
}
