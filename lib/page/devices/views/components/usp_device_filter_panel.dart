import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/_shared/components/layout_blocks.dart';
import 'package:privacy_gui/page/_shared/models/client_device.dart';
import 'package:privacy_gui/page/_shared/utils/device_classifier.dart';
import 'package:privacy_gui/page/devices/providers/device_filter_provider.dart';
import 'package:privacy_gui/page/devices/providers/device_filter_state.dart';
import 'package:privacy_gui/page/devices/views/components/usp_signal_strength_indicator.dart';
import 'package:privacy_gui/page/_shared/components/wifi_ui.dart';
import 'package:ui_kit_library/ui_kit.dart' hide ConnectionType;

String _signalLabel(BuildContext context, DeviceSignalLevel level) {
  final nodeLevel = nodeLevelOf(level);
  return nodeLevel?.resolveLabel(context) ?? '';
}

String _statusLabel(BuildContext context, DeviceStatusFilter v) {
  switch (v) {
    case DeviceStatusFilter.all:
      return loc(context).all;
    case DeviceStatusFilter.online:
      return loc(context).online;
    case DeviceStatusFilter.offline:
      return loc(context).offline;
  }
}

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
          .map((v) => TabItem(label: _statusLabel(context, v)))
          .toList(growable: false),
      initialIndex: selectedIndex,
      displayMode: TabDisplayMode.segmented,
      showBorder: false,
      onTabChanged: (i) =>
          ref.read(deviceFilterConfigProvider.notifier).setStatus(values[i]),
    );
  }
}

class UspDeviceFilterPanel extends ConsumerWidget {
  const UspDeviceFilterPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(deviceFilterConfigProvider);
    final options = ref.watch(deviceFilterOptionsProvider);

    final isOffline = filter.status == DeviceStatusFilter.offline;
    final isEthernetOnly = filter.isEthernetOnly;

    if (isOffline) {
      return SizedBox(
        width: context.colWidth(3),
        child: AppCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _FilterHeader(
                activeCount: filter.activeCountExcludingStatus,
                onClear: () =>
                    ref.read(deviceFilterConfigProvider.notifier).clearAll(),
              ),
              AppGap.md(),
              LayoutBlock(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: _InfoNote(
                  text: loc(context).additionalFiltersOnlineOnly,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      width: context.colWidth(3),
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _FilterHeader(
              activeCount: filter.activeCountExcludingStatus,
              onClear: () =>
                  ref.read(deviceFilterConfigProvider.notifier).clearAll(),
            ),
            AppGap.md(),

            // CONNECTION
            LayoutBlock(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionHeader(title: loc(context).connection),
                  AppGap.sm(),
                  _ChipGroupRow(
                    label: loc(context).type,
                    chips: [
                      ChipItem(label: loc(context).wifi),
                      ChipItem(label: loc(context).ethernet),
                    ],
                    selectedIndices: _connectionToIndices(filter.connections),
                    onSelectionChanged: (indices) => ref
                        .read(deviceFilterConfigProvider.notifier)
                        .setConnections(_indicesToConnections(indices)),
                  ),
                  if (options.nodes.isNotEmpty) ...[
                    AppGap.sm(),
                    _ChipGroupRow(
                      label: loc(context).node,
                      chips: options.nodes
                          .map((n) => ChipItem(label: n.model))
                          .toList(),
                      selectedIndices: _nodeIdsToIndices(
                        filter.nodeIds,
                        options.nodes.map((n) => n.deviceId).toList(),
                      ),
                      onSelectionChanged: (indices) => ref
                          .read(deviceFilterConfigProvider.notifier)
                          .setNodeIds(_indicesToNodeIds(
                            indices,
                            options.nodes.map((n) => n.deviceId).toList(),
                          )),
                    ),
                  ],
                ],
              ),
            ),

            // DEVICE
            AppGap.sm(),
            LayoutBlock(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionHeader(title: loc(context).devices),
                  AppGap.sm(),
                  _ChipGroupRow(
                    label: loc(context).type,
                    chips: DeviceCategory.values
                        .map((c) => ChipItem(
                              label: '',
                              iconWidget: Icon(c.icon, size: 16),
                            ))
                        .toList(),
                    selectedIndices: _categoriesToIndices(
                      filter.deviceCategories,
                      DeviceCategory.values,
                    ),
                    onSelectionChanged: (indices) => ref
                        .read(deviceFilterConfigProvider.notifier)
                        .setDeviceCategories(_indicesToCategories(
                          indices,
                          DeviceCategory.values,
                        )),
                  ),
                  AppGap.sm(),
                  _ChipGroupRow(
                    label: 'MAC',
                    chips: [
                      ChipItem(label: loc(context).privateMac),
                      ChipItem(label: loc(context).publicMac),
                    ],
                    selectedIndices: _privateMacToIndices(filter.privateMac),
                    onSelectionChanged: (indices) => ref
                        .read(deviceFilterConfigProvider.notifier)
                        .setPrivateMac(_indicesToPrivateMac(indices)),
                  ),
                ],
              ),
            ),

            // WI-FI
            AppGap.sm(),
            LayoutBlock(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionHeader(title: loc(context).wifi),
                  AppGap.sm(),
                  _ChipGroupRow(
                    label: loc(context).signal,
                    chips: [
                      ChipItem(
                        label: '',
                        iconWidget: UspSignalStrengthIndicator.fixed(
                          level: 3,
                          color:
                              NodeSignalLevel.excellent.resolveColor(context) ??
                                  Colors.green,
                        ),
                      ),
                      ChipItem(
                        label: '',
                        iconWidget: UspSignalStrengthIndicator.fixed(
                          level: 2,
                          color: NodeSignalLevel.good.resolveColor(context) ??
                              Colors.green,
                        ),
                      ),
                      ChipItem(
                        label: '',
                        iconWidget: UspSignalStrengthIndicator.fixed(
                          level: 1,
                          color: NodeSignalLevel.fair.resolveColor(context) ??
                              Colors.orange,
                        ),
                      ),
                      ChipItem(
                        label: '',
                        iconWidget: UspSignalStrengthIndicator.fixed(
                          level: 0,
                          color: NodeSignalLevel.poor.resolveColor(context) ??
                              Colors.red,
                        ),
                      ),
                      if (options.hasUnknownSignalDevices)
                        ChipItem(label: '--'),
                    ],
                    selectedIndices: _signalToIndices(
                      filter.signals,
                      filter.includeUnknownSignal,
                      options.hasUnknownSignalDevices,
                    ),
                    disabled: isEthernetOnly,
                    disabledTooltip:
                        loc(context).notApplicableForEthernetDevices,
                    onSelectionChanged: (indices) {
                      final (signals, includeUnknown) = _indicesToSignals(
                        indices,
                        options.hasUnknownSignalDevices,
                      );
                      final notifier =
                          ref.read(deviceFilterConfigProvider.notifier);
                      notifier.setSignals(signals);
                      notifier.setIncludeUnknownSignal(includeUnknown);
                    },
                  ),
                  if (options.ssids.isNotEmpty) ...[
                    AppGap.sm(),
                    _ChipGroupRow(
                      label: loc(context).ssid,
                      chips:
                          options.ssids.map((s) => ChipItem(label: s)).toList(),
                      selectedIndices:
                          _stringsToIndices(filter.ssidNames, options.ssids),
                      disabled: isEthernetOnly,
                      disabledTooltip:
                          loc(context).notApplicableForEthernetDevices,
                      onSelectionChanged: (indices) => ref
                          .read(deviceFilterConfigProvider.notifier)
                          .setSsidNames(
                              _indicesToStrings(indices, options.ssids)),
                    ),
                  ],
                  if (options.bands.isNotEmpty) ...[
                    AppGap.sm(),
                    _ChipGroupRow(
                      label: loc(context).band,
                      chips:
                          options.bands.map((b) => ChipItem(label: b)).toList(),
                      selectedIndices:
                          _stringsToIndices(filter.bands, options.bands),
                      disabled: isEthernetOnly,
                      disabledTooltip:
                          loc(context).notApplicableForEthernetDevices,
                      onSelectionChanged: (indices) => ref
                          .read(deviceFilterConfigProvider.notifier)
                          .setBands(_indicesToStrings(indices, options.bands)),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Set<int> _connectionToIndices(Set<ConnectionType> types) {
  final indices = <int>{};
  if (types.contains(ConnectionType.wifi)) indices.add(0);
  if (types.contains(ConnectionType.wired)) indices.add(1);
  return indices;
}

Set<ConnectionType> _indicesToConnections(Set<int> indices) {
  final types = <ConnectionType>{};
  if (indices.contains(0)) types.add(ConnectionType.wifi);
  if (indices.contains(1)) types.add(ConnectionType.wired);
  return types;
}

Set<int> _signalToIndices(
  Set<DeviceSignalLevel> signals,
  bool includeUnknown,
  bool hasUnknownOption,
) {
  final indices = <int>{};
  if (signals.contains(DeviceSignalLevel.excellent)) indices.add(0);
  if (signals.contains(DeviceSignalLevel.good)) indices.add(1);
  if (signals.contains(DeviceSignalLevel.fair)) indices.add(2);
  if (signals.contains(DeviceSignalLevel.poor)) indices.add(3);
  if (hasUnknownOption && includeUnknown) indices.add(4);
  return indices;
}

(Set<DeviceSignalLevel>, bool) _indicesToSignals(
  Set<int> indices,
  bool hasUnknownOption,
) {
  final signals = <DeviceSignalLevel>{};
  if (indices.contains(0)) signals.add(DeviceSignalLevel.excellent);
  if (indices.contains(1)) signals.add(DeviceSignalLevel.good);
  if (indices.contains(2)) signals.add(DeviceSignalLevel.fair);
  if (indices.contains(3)) signals.add(DeviceSignalLevel.poor);
  final includeUnknown = hasUnknownOption && indices.contains(4);
  return (signals, includeUnknown);
}

Set<int> _stringsToIndices(Set<String> selected, List<String> options) {
  final indices = <int>{};
  for (var i = 0; i < options.length; i++) {
    if (selected.contains(options[i])) indices.add(i);
  }
  return indices;
}

Set<String> _indicesToStrings(Set<int> indices, List<String> options) {
  return indices
      .where((i) => i < options.length)
      .map((i) => options[i])
      .toSet();
}

Set<int> _nodeIdsToIndices(Set<String> nodeIds, List<String> allNodeIds) {
  final indices = <int>{};
  for (var i = 0; i < allNodeIds.length; i++) {
    if (nodeIds.contains(allNodeIds[i])) indices.add(i);
  }
  return indices;
}

Set<String> _indicesToNodeIds(Set<int> indices, List<String> allNodeIds) {
  return indices
      .where((i) => i < allNodeIds.length)
      .map((i) => allNodeIds[i])
      .toSet();
}

Set<int> _categoriesToIndices(
  Set<DeviceCategory> selected,
  List<DeviceCategory> options,
) {
  final indices = <int>{};
  for (var i = 0; i < options.length; i++) {
    if (selected.contains(options[i])) indices.add(i);
  }
  return indices;
}

Set<DeviceCategory> _indicesToCategories(
  Set<int> indices,
  List<DeviceCategory> options,
) {
  return indices
      .where((i) => i < options.length)
      .map((i) => options[i])
      .toSet();
}

Set<int> _privateMacToIndices(PrivateMacFilter filter) {
  return switch (filter) {
    PrivateMacFilter.all => const {},
    PrivateMacFilter.privateOnly => const {0},
    PrivateMacFilter.publicOnly => const {1},
  };
}

PrivateMacFilter _indicesToPrivateMac(Set<int> indices) {
  if (indices.contains(0) && !indices.contains(1)) {
    return PrivateMacFilter.privateOnly;
  }
  if (indices.contains(1) && !indices.contains(0)) {
    return PrivateMacFilter.publicOnly;
  }
  return PrivateMacFilter.all;
}

class _FilterHeader extends StatelessWidget {
  const _FilterHeader({required this.activeCount, required this.onClear});

  final int activeCount;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AppText.titleMedium(loc(context).filters),
        const Spacer(),
        if (activeCount > 0) ...[
          AppBadge(label: '$activeCount'),
          AppGap.xs(),
          AppButton.text(
            label: loc(context).clear,
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

class _ChipGroupRow extends StatelessWidget {
  const _ChipGroupRow({
    required this.label,
    required this.chips,
    required this.selectedIndices,
    required this.onSelectionChanged,
    this.disabled = false,
    this.disabledTooltip,
  });

  final String label;
  final List<ChipItem> chips;
  final Set<int> selectedIndices;
  final ValueChanged<Set<int>> onSelectionChanged;
  final bool disabled;
  final String? disabledTooltip;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            AppText.labelMedium(
              label,
              color: disabled
                  ? Theme.of(context).disabledColor
                  : Theme.of(context).colorScheme.onSurface,
            ),
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
        ),
        AppGap.xs(),
        IgnorePointer(
          ignoring: disabled,
          child: Opacity(
            opacity: disabled ? 0.5 : 1.0,
            child: AppChipGroup(
              chips: chips,
              selectedIndices: selectedIndices,
              selectionMode: ChipSelectionMode.multiple,
              onSelectionChanged: onSelectionChanged,
              wrap: true,
              spacing: AppSpacing.xs,
              size: ChipSize.compact,
            ),
          ),
        ),
      ],
    );
  }
}

// Mobile/Tablet chip bar
class UspDeviceFilterChipBar extends ConsumerWidget {
  const UspDeviceFilterChipBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(deviceFilterConfigProvider);
    final options = ref.watch(deviceFilterOptionsProvider);
    final notifier = ref.read(deviceFilterConfigProvider.notifier);

    final isOffline = filter.status == DeviceStatusFilter.offline;
    final isEthernetOnly = filter.isEthernetOnly;

    if (isOffline) {
      return const SizedBox.shrink();
    }

    final chips = <Widget>[
      _FilterChip(
        label: filter.connections.isEmpty
            ? loc(context).connection
            : filter.connections.length == 1
                ? (filter.connections.first == ConnectionType.wifi
                    ? loc(context).wifi
                    : loc(context).ethernet)
                : '${loc(context).connection} (${filter.connections.length})',
        isActive: filter.connections.isNotEmpty,
        onTap: () => _showMultiSelectPicker<ConnectionType>(
          context: context,
          title: loc(context).connection,
          items: ConnectionType.values,
          selected: filter.connections,
          labelOf: (v) => v == ConnectionType.wifi
              ? loc(context).wifi
              : loc(context).ethernet,
          onChanged: notifier.setConnections,
        ),
      ),
      _FilterChip(
        label: _buildSignalChipLabel(context, filter, options),
        isActive: filter.signals.isNotEmpty || filter.includeUnknownSignal,
        disabled: isEthernetOnly,
        onTap: () => _showSignalPicker(
          context: context,
          filter: filter,
          options: options,
          notifier: notifier,
        ),
      ),
      if (options.ssids.isNotEmpty)
        _FilterChip(
          label: filter.ssidNames.isEmpty
              ? loc(context).ssid
              : filter.ssidNames.length == 1
                  ? filter.ssidNames.first
                  : '${loc(context).ssid} (${filter.ssidNames.length})',
          isActive: filter.ssidNames.isNotEmpty,
          disabled: isEthernetOnly,
          onTap: () => _showMultiSelectPicker<String>(
            context: context,
            title: loc(context).ssid,
            items: options.ssids,
            selected: filter.ssidNames,
            labelOf: (v) => v,
            onChanged: notifier.setSsidNames,
          ),
        ),
      if (options.bands.isNotEmpty)
        _FilterChip(
          label: filter.bands.isEmpty
              ? loc(context).band
              : filter.bands.length == 1
                  ? filter.bands.first
                  : '${loc(context).band} (${filter.bands.length})',
          isActive: filter.bands.isNotEmpty,
          disabled: isEthernetOnly,
          onTap: () => _showMultiSelectPicker<String>(
            context: context,
            title: loc(context).band,
            items: options.bands,
            selected: filter.bands,
            labelOf: (v) => v,
            onChanged: notifier.setBands,
          ),
        ),
      if (options.nodes.length > 1)
        _FilterChip(
          label: filter.nodeIds.isEmpty
              ? loc(context).node
              : filter.nodeIds.length == 1
                  ? (options.nodes
                          .where((n) => n.deviceId == filter.nodeIds.first)
                          .firstOrNull
                          ?.model ??
                      filter.nodeIds.first)
                  : '${loc(context).node} (${filter.nodeIds.length})',
          isActive: filter.nodeIds.isNotEmpty,
          onTap: () => _showMultiSelectPicker<String>(
            context: context,
            title: loc(context).node,
            items: options.nodes.map((n) => n.deviceId).toList(),
            selected: filter.nodeIds,
            labelOf: (id) =>
                options.nodes
                    .where((n) => n.deviceId == id)
                    .firstOrNull
                    ?.model ??
                id,
            onChanged: notifier.setNodeIds,
          ),
        ),
    ];

    if (filter.activeCountExcludingStatus > 0) {
      chips.add(_FilterChip(
        label: loc(context).clear,
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

  String _buildSignalChipLabel(
    BuildContext context,
    DeviceFilterConfig filter,
    DeviceFilterOptions options,
  ) {
    final count = filter.signals.length + (filter.includeUnknownSignal ? 1 : 0);
    if (count == 0) return loc(context).signal;
    if (count == 1) {
      if (filter.includeUnknownSignal) return '--';
      return _signalLabel(context, filter.signals.first);
    }
    return '${loc(context).signal} ($count)';
  }

  void _showMultiSelectPicker<T>({
    required BuildContext context,
    required String title,
    required List<T> items,
    required Set<T> selected,
    required String Function(T) labelOf,
    required void Function(Set<T>) onChanged,
  }) {
    Set<T> tempSelected = Set.from(selected);

    showModalBottomSheet(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    AppText.titleMedium(title),
                    AppButton.text(
                      label: loc(context).done,
                      onTap: () {
                        onChanged(tempSelected);
                        Navigator.pop(ctx);
                      },
                    ),
                  ],
                ),
              ),
              ...items.map((item) => CheckboxListTile(
                    title: Text(labelOf(item)),
                    value: tempSelected.contains(item),
                    onChanged: (checked) {
                      setSheetState(() {
                        if (checked == true) {
                          tempSelected.add(item);
                        } else {
                          tempSelected.remove(item);
                        }
                      });
                    },
                  )),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }

  void _showSignalPicker({
    required BuildContext context,
    required DeviceFilterConfig filter,
    required DeviceFilterOptions options,
    required DeviceFilterNotifier notifier,
  }) {
    var tempSignals = Set<DeviceSignalLevel>.from(filter.signals);
    var tempIncludeUnknown = filter.includeUnknownSignal;

    showModalBottomSheet(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    AppText.titleMedium(loc(context).signal),
                    AppButton.text(
                      label: loc(context).done,
                      onTap: () {
                        notifier.setSignals(tempSignals);
                        notifier.setIncludeUnknownSignal(tempIncludeUnknown);
                        Navigator.pop(ctx);
                      },
                    ),
                  ],
                ),
              ),
              ...DeviceSignalLevel.values.map((level) => CheckboxListTile(
                    title: Text(_signalLabel(context, level)),
                    value: tempSignals.contains(level),
                    onChanged: (checked) {
                      setSheetState(() {
                        if (checked == true) {
                          tempSignals.add(level);
                        } else {
                          tempSignals.remove(level);
                        }
                      });
                    },
                  )),
              if (options.hasUnknownSignalDevices)
                CheckboxListTile(
                  title: const Text('--'),
                  value: tempIncludeUnknown,
                  onChanged: (checked) {
                    setSheetState(() {
                      tempIncludeUnknown = checked ?? false;
                    });
                  },
                ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
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
