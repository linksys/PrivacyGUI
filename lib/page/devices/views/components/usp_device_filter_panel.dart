import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/devices/providers/device_filter_provider.dart';
import 'package:privacy_gui/page/devices/providers/device_filter_state.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Desktop filter panel — vertical sidebar sized to 3 grid columns.
class UspDeviceFilterPanel extends ConsumerWidget {
  const UspDeviceFilterPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(deviceFilterConfigProvider);
    final options = ref.watch(deviceFilterOptionsProvider);

    return SizedBox(
      width: context.colWidth(3),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            AppText.titleMedium('Filters'),
            AppGap.xl(),

            // Status
            AppText.labelLarge('Status'),
            AppGap.sm(),
            AppRadioList<DeviceStatusFilter>(
              items: const [
                AppRadioListItem(title: 'All', value: DeviceStatusFilter.all),
                AppRadioListItem(
                    title: 'Online', value: DeviceStatusFilter.online),
                AppRadioListItem(
                    title: 'Offline', value: DeviceStatusFilter.offline),
              ],
              selected: filter.status,
              onChanged: (_, value) {
                if (value == null) return;
                ref.read(deviceFilterConfigProvider.notifier).state =
                    filter.copyWith(status: value);
              },
            ),
            AppGap.lg(),

            // Node
            if (options.nodes.length > 1) ...[
              AppText.labelLarge('Node'),
              AppGap.sm(),
              AppDropdown<String?>(
                items: [null, ...options.nodes.map((n) => n.deviceId)],
                value: filter.nodeId,
                itemAsString: (id) {
                  if (id == null) return 'All';
                  final node =
                      options.nodes.where((n) => n.deviceId == id).firstOrNull;
                  return node?.model ?? id;
                },
                onChanged: (value) {
                  ref.read(deviceFilterConfigProvider.notifier).state =
                      filter.copyWith(nodeId: () => value);
                },
              ),
              AppGap.lg(),
            ],

            // SSID
            if (options.ssids.isNotEmpty) ...[
              AppText.labelLarge('SSID'),
              AppGap.sm(),
              AppDropdown<String?>(
                items: [null, ...options.ssids],
                value: filter.ssidName,
                itemAsString: (s) => s ?? 'All',
                onChanged: (value) {
                  ref.read(deviceFilterConfigProvider.notifier).state =
                      filter.copyWith(ssidName: () => value);
                },
              ),
              AppGap.lg(),
            ],

            // Band
            if (options.bands.isNotEmpty) ...[
              AppText.labelLarge('Band'),
              AppGap.sm(),
              AppDropdown<String?>(
                items: [null, ...options.bands],
                value: filter.band,
                itemAsString: (s) => s ?? 'All',
                onChanged: (value) {
                  ref.read(deviceFilterConfigProvider.notifier).state =
                      filter.copyWith(band: () => value);
                },
              ),
              AppGap.lg(),
            ],

            // Reset
            if (filter.isActive)
              AppButton.text(
                label: 'Reset Filters',
                onTap: () {
                  ref.read(deviceFilterConfigProvider.notifier).state =
                      const DeviceFilterConfig();
                },
              ),
          ],
        ),
      ),
    );
  }
}

/// Mobile filter bar — horizontal chip row for quick filtering.
class UspDeviceFilterChipBar extends ConsumerWidget {
  const UspDeviceFilterChipBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(deviceFilterConfigProvider);
    final options = ref.watch(deviceFilterOptionsProvider);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          // Status chips
          _buildChip(
            context,
            label: _statusLabel(filter.status),
            isActive: filter.status != DeviceStatusFilter.all,
            onTap: () => _showStatusPicker(context, ref, filter),
          ),
          AppGap.sm(),
          // Node chip
          if (options.nodes.length > 1) ...[
            _buildChip(
              context,
              label: filter.nodeId != null
                  ? (options.nodes
                          .where((n) => n.deviceId == filter.nodeId)
                          .firstOrNull
                          ?.model ??
                      filter.nodeId!)
                  : 'Node',
              isActive: filter.nodeId != null,
              onTap: () => _showNodePicker(context, ref, filter, options),
            ),
            AppGap.sm(),
          ],
          // SSID chip
          if (options.ssids.isNotEmpty) ...[
            _buildChip(
              context,
              label: filter.ssidName ?? 'SSID',
              isActive: filter.ssidName != null,
              onTap: () => _showSsidPicker(context, ref, filter, options),
            ),
            AppGap.sm(),
          ],
          // Band chip
          if (options.bands.isNotEmpty) ...[
            _buildChip(
              context,
              label: filter.band ?? 'Band',
              isActive: filter.band != null,
              onTap: () => _showBandPicker(context, ref, filter, options),
            ),
            AppGap.sm(),
          ],
          // Reset
          if (filter.isActive)
            _buildChip(
              context,
              label: 'Reset',
              isActive: false,
              onTap: () {
                ref.read(deviceFilterConfigProvider.notifier).state =
                    const DeviceFilterConfig();
              },
            ),
        ],
      ),
    );
  }

  Widget _buildChip(
    BuildContext context, {
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return FilterChip(
      label: Text(label),
      selected: isActive,
      onSelected: (_) => onTap(),
    );
  }

  String _statusLabel(DeviceStatusFilter status) {
    switch (status) {
      case DeviceStatusFilter.all:
        return 'Status';
      case DeviceStatusFilter.online:
        return 'Online';
      case DeviceStatusFilter.offline:
        return 'Offline';
    }
  }

  void _showStatusPicker(
      BuildContext context, WidgetRef ref, DeviceFilterConfig filter) {
    _showPickerSheet(
      context,
      title: 'Status',
      items: DeviceStatusFilter.values,
      selected: filter.status,
      labelOf: (s) => s.name[0].toUpperCase() + s.name.substring(1),
      onSelected: (value) {
        ref.read(deviceFilterConfigProvider.notifier).state =
            filter.copyWith(status: value);
      },
    );
  }

  void _showNodePicker(BuildContext context, WidgetRef ref,
      DeviceFilterConfig filter, DeviceFilterOptions options) {
    _showPickerSheet(
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
      onSelected: (value) {
        ref.read(deviceFilterConfigProvider.notifier).state =
            filter.copyWith(nodeId: () => value);
      },
    );
  }

  void _showSsidPicker(BuildContext context, WidgetRef ref,
      DeviceFilterConfig filter, DeviceFilterOptions options) {
    _showPickerSheet(
      context,
      title: 'SSID',
      items: [null, ...options.ssids],
      selected: filter.ssidName,
      labelOf: (s) => s ?? 'All',
      onSelected: (value) {
        ref.read(deviceFilterConfigProvider.notifier).state =
            filter.copyWith(ssidName: () => value);
      },
    );
  }

  void _showBandPicker(BuildContext context, WidgetRef ref,
      DeviceFilterConfig filter, DeviceFilterOptions options) {
    _showPickerSheet(
      context,
      title: 'Band',
      items: [null, ...options.bands],
      selected: filter.band,
      labelOf: (s) => s ?? 'All',
      onSelected: (value) {
        ref.read(deviceFilterConfigProvider.notifier).state =
            filter.copyWith(band: () => value);
      },
    );
  }

  void _showPickerSheet<T>(
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
