import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/devices/providers/device_filter_provider.dart';
import 'package:privacy_gui/page/devices/providers/device_filter_state.dart';
import 'package:privacy_gui/page/_shared/components/wifi_ui.dart';
import 'package:ui_kit_library/ui_kit.dart';

const _kNotApplicableEthernet = 'Not applicable for Ethernet devices';
const _kAllLabel = 'All';

/// Sentinel value used in String-typed dropdowns to represent "All". Avoids
/// passing `null` as the value, which `AppDropdown` renders at 50% opacity
/// (its placeholder style). The `onChanged` handlers convert this back to
/// `null` before updating filter state.
const _kAllSentinel = '__ALL__';

String _connectionLabel(DeviceConnectionFilter v) {
  switch (v) {
    case DeviceConnectionFilter.all:
      return _kAllLabel;
    case DeviceConnectionFilter.wifi:
      return 'WiFi';
    case DeviceConnectionFilter.ethernet:
      return 'Ethernet';
  }
}

/// Signal labels reuse `NodeSignalLevelExt.resolveLabel` so the strings are
/// localized and consistent with the node/topology pages. `all` and `unknown`
/// have no matching NodeSignalLevel and fall back to literal strings.
String _signalLabel(BuildContext context, DeviceSignalFilter v) {
  if (v == DeviceSignalFilter.all) return _kAllLabel;
  if (v == DeviceSignalFilter.unknown) return '--';
  final level = nodeLevelOf(v);
  return level?.resolveLabel(context) ?? _kAllLabel;
}

String _statusLabel(DeviceStatusFilter v) {
  switch (v) {
    case DeviceStatusFilter.all:
      return _kAllLabel;
    case DeviceStatusFilter.online:
      return 'Online';
    case DeviceStatusFilter.offline:
      return 'Offline';
  }
}

List<DeviceSignalFilter> _signalOptions(DeviceFilterOptions options) {
  return [
    DeviceSignalFilter.all,
    DeviceSignalFilter.excellent,
    DeviceSignalFilter.good,
    DeviceSignalFilter.fair,
    DeviceSignalFilter.poor,
    if (options.hasUnknownSignalDevices) DeviceSignalFilter.unknown,
  ];
}

// ═══════════════════════════════════════════════════════════════════════════
// Status segmented control — shared by desktop and mobile/tablet layouts
// ═══════════════════════════════════════════════════════════════════════════

/// Status segmented control for switching between All/Online/Offline views.
/// Used above the device list in all layouts.
class UspDeviceStatusSegmented extends ConsumerWidget {
  const UspDeviceStatusSegmented({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(
      deviceFilterConfigProvider.select((f) => f.status),
    );
    const values = DeviceStatusFilter.values;
    final selectedIndex = values.indexOf(status);

    return AppTabs(
      tabs: values
          .map((v) => TabItem(label: _statusLabel(v)))
          .toList(growable: false),
      initialIndex: selectedIndex,
      displayMode: TabDisplayMode.segmented,
      showBorder: false,
      onTabChanged: (i) =>
          ref.read(deviceFilterConfigProvider.notifier).setStatus(values[i]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Desktop filter panel
// ═══════════════════════════════════════════════════════════════════════════

/// Desktop filter panel — vertical sidebar sized to 3 grid columns.
/// Status filter is NOT included here — it lives above the device list.
class UspDeviceFilterPanel extends ConsumerWidget {
  const UspDeviceFilterPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(deviceFilterConfigProvider);
    final options = ref.watch(deviceFilterOptionsProvider);

    final isOffline = filter.status == DeviceStatusFilter.offline;
    final isEthernet = filter.connection == DeviceConnectionFilter.ethernet;
    final hasMultipleNodes = options.nodes.length > 1;

    // When Offline is chosen, other filters are meaningless — offline devices
    // have no live SSID / band / RSSI / node. Show explanatory note only.
    if (isOffline) {
      return SizedBox(
        width: context.colWidth(3),
        child: AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _FilterHeader(
                activeCount: filter.activeCountExcludingStatus,
                onClear: () =>
                    ref.read(deviceFilterConfigProvider.notifier).clearAll(),
              ),
              AppGap.lg(),
              _InfoNote(
                text: 'Additional filters are only available for '
                    'online devices.',
              ),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      width: context.colWidth(3),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _FilterHeader(
              activeCount: filter.activeCountExcludingStatus,
              onClear: () =>
                  ref.read(deviceFilterConfigProvider.notifier).clearAll(),
            ),
            AppGap.lg(),

            // ── CONNECTION ────────────────────────────────────────────────
            _SectionHeader(title: 'Connection'),
            AppGap.sm(),
            _DropdownRow<DeviceConnectionFilter>(
              label: 'Type',
              value: filter.connection,
              items: DeviceConnectionFilter.values,
              labelOf: _connectionLabel,
              onChanged: (v) => ref
                  .read(deviceFilterConfigProvider.notifier)
                  .setConnection(v ?? DeviceConnectionFilter.all),
            ),
            AppGap.sm(),
            _DropdownRow<DeviceSignalFilter>(
              label: 'Signal',
              value: filter.signal,
              items: _signalOptions(options),
              labelOf: (v) => _signalLabel(context, v),
              disabled: isEthernet,
              disabledTooltip: _kNotApplicableEthernet,
              onChanged: (v) => ref
                  .read(deviceFilterConfigProvider.notifier)
                  .setSignal(v ?? DeviceSignalFilter.all),
            ),
            AppGap.lg(),

            // ── WI-FI ─────────────────────────────────────────────────────
            // Hide the whole WiFi section when there is no data to offer;
            // grey it out when the user has scoped to Ethernet.
            if (options.ssids.isNotEmpty || options.bands.isNotEmpty) ...[
              _SectionHeader(title: 'Wi-Fi'),
              AppGap.sm(),
              if (options.ssids.isNotEmpty)
                _DropdownRow<String>(
                  label: 'SSID',
                  value: filter.ssidName ?? _kAllSentinel,
                  items: [_kAllSentinel, ...options.ssids],
                  labelOf: (v) => v == _kAllSentinel ? _kAllLabel : v,
                  disabled: isEthernet,
                  disabledTooltip: _kNotApplicableEthernet,
                  onChanged: (v) => ref
                      .read(deviceFilterConfigProvider.notifier)
                      .setSsidName(v == _kAllSentinel ? null : v),
                ),
              if (options.ssids.isNotEmpty && options.bands.isNotEmpty)
                AppGap.sm(),
              if (options.bands.isNotEmpty)
                _DropdownRow<String>(
                  label: 'Band',
                  value: filter.band ?? _kAllSentinel,
                  items: [_kAllSentinel, ...options.bands],
                  labelOf: (v) => v == _kAllSentinel ? _kAllLabel : v,
                  disabled: isEthernet,
                  disabledTooltip: _kNotApplicableEthernet,
                  onChanged: (v) => ref
                      .read(deviceFilterConfigProvider.notifier)
                      .setBand(v == _kAllSentinel ? null : v),
                ),
              AppGap.lg(),
            ],

            // ── LOCATION ──────────────────────────────────────────────────
            if (hasMultipleNodes) ...[
              _SectionHeader(title: 'Location'),
              AppGap.sm(),
              _DropdownRow<String>(
                label: 'Connected via',
                value: filter.nodeId ?? _kAllSentinel,
                items: [
                  _kAllSentinel,
                  ...options.nodes.map((n) => n.deviceId),
                ],
                labelOf: (id) {
                  if (id == _kAllSentinel) return _kAllLabel;
                  final node =
                      options.nodes.where((n) => n.deviceId == id).firstOrNull;
                  return node?.model ?? id;
                },
                onChanged: (v) => ref
                    .read(deviceFilterConfigProvider.notifier)
                    .setNodeId(v == _kAllSentinel ? null : v),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FilterHeader extends StatelessWidget {
  const _FilterHeader({required this.activeCount, required this.onClear});

  final int activeCount;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AppText.titleMedium('Filters'),
        const Spacer(),
        if (activeCount > 0) ...[
          AppBadge(label: '$activeCount'),
          AppGap.xs(),
          AppButton.text(
            label: 'Clear',
            onTap: onClear,
          ),
        ],
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return AppText.labelSmall(
      title.toUpperCase(),
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
  }
}

class _InfoNote extends StatelessWidget {
  const _InfoNote({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.info_outline, size: 16, color: color),
        AppGap.xs(),
        Expanded(
          child: AppText.bodySmall(text, color: color),
        ),
      ],
    );
  }
}

class _DropdownRow<T> extends StatelessWidget {
  const _DropdownRow({
    required this.label,
    required this.value,
    required this.items,
    required this.labelOf,
    required this.onChanged,
    this.disabled = false,
    this.disabledTooltip,
  });

  final String label;
  final T value;
  final List<T> items;
  final String Function(T) labelOf;
  final ValueChanged<T?> onChanged;
  final bool disabled;
  final String? disabledTooltip;

  @override
  Widget build(BuildContext context) {
    // AppDropdown's `_displayString(null)` returns the hint, so we pass the
    // "All …" label as hint to get a readable placeholder when value is null.
    final displayWhenNull = value == null ? labelOf(value) : null;

    Widget dropdown = AppDropdown<T>(
      items: items,
      value: value,
      itemAsString: labelOf,
      hint: displayWhenNull,
      onChanged: onChanged,
    );

    // `AppDropdown` treats `onChanged: null` as disabled visually, but its
    // internal `AppInteractionSensor.onTap` still opens the menu. Wrap with
    // IgnorePointer to actually block interaction when disabled.
    if (disabled) {
      dropdown = IgnorePointer(child: dropdown);
    }

    final child = Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 80,
          child: AppText.labelMedium(
            label,
            color: disabled
                ? Theme.of(context).disabledColor
                : Theme.of(context).colorScheme.onSurface,
          ),
        ),
        AppGap.sm(),
        Expanded(child: dropdown),
        if (disabled && disabledTooltip != null) ...[
          AppGap.xs(),
          AppTooltip(
            message: disabledTooltip!,
            child: Icon(
              Icons.info_outline,
              size: 16,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );

    return disabled ? Opacity(opacity: 0.5, child: child) : child;
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Mobile/Tablet chip bar
// ═══════════════════════════════════════════════════════════════════════════

/// Mobile/tablet filter bar — horizontal chip row for quick filtering.
/// Status filter is NOT included here — it lives above the device list.
/// Dependency rules: Offline hides all chips, Ethernet greys out WiFi-scoped chips.
class UspDeviceFilterChipBar extends ConsumerWidget {
  const UspDeviceFilterChipBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(deviceFilterConfigProvider);
    final options = ref.watch(deviceFilterOptionsProvider);
    final notifier = ref.read(deviceFilterConfigProvider.notifier);

    final isOffline = filter.status == DeviceStatusFilter.offline;
    final isEthernet = filter.connection == DeviceConnectionFilter.ethernet;

    // When Offline, no additional filters are meaningful
    if (isOffline) {
      return const SizedBox.shrink();
    }

    final chips = <Widget>[
      _Chip(
        label: filter.connection == DeviceConnectionFilter.all
            ? 'Connection'
            : _connectionLabel(filter.connection),
        isActive: filter.connection != DeviceConnectionFilter.all,
        onTap: () => _showPicker<DeviceConnectionFilter>(
          context,
          title: 'Connection',
          items: DeviceConnectionFilter.values,
          selected: filter.connection,
          labelOf: _connectionLabel,
          onSelected: notifier.setConnection,
        ),
      ),
      _Chip(
        label: filter.signal == DeviceSignalFilter.all
            ? 'Signal'
            : _signalLabel(context, filter.signal),
        isActive: filter.signal != DeviceSignalFilter.all,
        disabled: isEthernet,
        onTap: () => _showPicker<DeviceSignalFilter>(
          context,
          title: 'Signal',
          items: _signalOptions(options),
          selected: filter.signal,
          labelOf: (v) => _signalLabel(context, v),
          onSelected: notifier.setSignal,
        ),
      ),
      if (options.ssids.isNotEmpty)
        _Chip(
          label: filter.ssidName ?? 'SSID',
          isActive: filter.ssidName != null,
          disabled: isEthernet,
          onTap: () => _showPicker<String?>(
            context,
            title: 'SSID',
            items: [null, ...options.ssids],
            selected: filter.ssidName,
            labelOf: (v) => v ?? 'All',
            onSelected: notifier.setSsidName,
          ),
        ),
      if (options.bands.isNotEmpty)
        _Chip(
          label: filter.band ?? 'Band',
          isActive: filter.band != null,
          disabled: isEthernet,
          onTap: () => _showPicker<String?>(
            context,
            title: 'Band',
            items: [null, ...options.bands],
            selected: filter.band,
            labelOf: (v) => v ?? 'All',
            onSelected: notifier.setBand,
          ),
        ),
      if (options.nodes.length > 1)
        _Chip(
          label: filter.nodeId != null
              ? (options.nodes
                      .where((n) => n.deviceId == filter.nodeId)
                      .firstOrNull
                      ?.model ??
                  filter.nodeId!)
              : 'Node',
          isActive: filter.nodeId != null,
          onTap: () => _showPicker<String?>(
            context,
            title: 'Node',
            items: [null, ...options.nodes.map((n) => n.deviceId)],
            selected: filter.nodeId,
            labelOf: (id) {
              if (id == null) return 'All';
              return options.nodes
                      .where((n) => n.deviceId == id)
                      .firstOrNull
                      ?.model ??
                  id;
            },
            onSelected: notifier.setNodeId,
          ),
        ),
    ];

    if (filter.activeCountExcludingStatus > 0) {
      chips.add(_Chip(
        label: 'Clear',
        isActive: false,
        onTap: notifier.clearAll,
      ));
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < chips.length; i++) ...[
            if (i > 0) AppGap.sm(),
            chips[i],
          ],
        ],
      ),
    );
  }

  void _showPicker<T>(
    BuildContext context, {
    required String title,
    required List<T> items,
    required T selected,
    required String Function(T) labelOf,
    required void Function(T) onSelected,
  }) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: AppText.titleMedium(title),
            ),
            ...items.map((item) => ListTile(
                  title: Text(labelOf(item)),
                  selected: item == selected,
                  onTap: () {
                    onSelected(item);
                    Navigator.pop(ctx);
                  },
                )),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.isActive,
    required this.onTap,
    this.disabled = false,
  });

  final String label;
  final bool isActive;
  final bool disabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final chip = FilterChip(
      label: Text(label),
      selected: isActive,
      onSelected: disabled ? null : (_) => onTap(),
    );
    return disabled ? Opacity(opacity: 0.5, child: chip) : chip;
  }
}
