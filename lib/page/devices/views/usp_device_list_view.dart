import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/components/ui_kit_page_view.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/page/devices/providers/devices_data_provider.dart';
import 'package:privacy_gui/page/devices/providers/device_filter_provider.dart';
import 'package:privacy_gui/page/devices/providers/device_filter_state.dart';
import 'package:privacy_gui/page/devices/views/components/usp_device_filter_panel.dart';
import 'package:privacy_gui/page/devices/views/components/usp_device_list_tile.dart';
import 'package:privacy_gui/page/shell/usp_top_bar.dart';
import 'package:ui_kit_library/ui_kit.dart';

class UspDeviceListView extends ConsumerStatefulWidget {
  const UspDeviceListView({super.key});

  @override
  ConsumerState<UspDeviceListView> createState() => _UspDeviceListViewState();
}

class _UspDeviceListViewState extends ConsumerState<UspDeviceListView> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asyncDevices = ref.watch(devicesDataProvider);
    final devices = ref.watch(filteredDeviceListProvider);
    final filter = ref.watch(deviceFilterConfigProvider);
    final totalCount = asyncDevices.valueOrNull?.totalClientCount ?? 0;

    return UiKitPageView.withSliver(
      scrollable: true,
      title: 'Devices',
      topbar: const PreferredSize(
        preferredSize: Size.fromHeight(64),
        child: UspTopBar(),
      ),
      backFallback: RouteNamed.uspMenu,
      onRefresh: () => ref.refresh(devicesDataProvider.future),
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: (childContext, constraints) {
        return asyncDevices.when(
          loading: () => const Center(child: AppLoader()),
          error: (e, _) => Center(child: AppText.bodyMedium('Error: $e')),
          data: (state) {
            return AppResponsiveLayout(
              mobile: (_) =>
                  _buildMobileLayout(context, devices, filter, totalCount),
              tablet: (_) =>
                  _buildMobileLayout(context, devices, filter, totalCount),
              desktop: (_) =>
                  _buildDesktopLayout(context, devices, filter, totalCount),
            );
          },
        );
      },
    );
  }

  Widget _buildSearchBar() {
    return AppTextFormField(
      controller: _searchController,
      hintText: 'Search by name, MAC, or IP',
      prefixIcon: const Icon(Icons.search, size: 20),
      suffixIcon: _searchController.text.isNotEmpty
          ? IconButton(
              icon: const Icon(Icons.clear, size: 18),
              onPressed: () {
                _searchController.clear();
                ref
                    .read(deviceFilterConfigProvider.notifier)
                    .setSearchQuery('');
              },
            )
          : null,
      onChanged: (value) {
        ref.read(deviceFilterConfigProvider.notifier).setSearchQuery(value);
      },
    );
  }

  Widget _buildCountRow(List devices, int totalCount) {
    return Align(
      alignment: Alignment.centerRight,
      child: AppText.labelLarge(
        '${devices.length} / $totalCount',
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }

  Widget _buildDeviceList(List devices) {
    if (devices.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
        child: Center(
          child: AppText.bodyMedium('No devices match the current filters'),
        ),
      );
    }
    return Column(
      children: [
        for (final device in devices) ...[
          UspDeviceListTile(
            device: device,
            onTap: () => context.goNamed(
              RouteNamed.uspDeviceDetail,
              queryParameters: {'mac': device.mac},
            ),
          ),
          AppGap.sm(),
        ],
      ],
    );
  }

  Widget _buildDesktopLayout(BuildContext context, List devices,
      DeviceFilterConfig filter, int totalCount) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const UspDeviceFilterPanel(),
            AppGap.gutter(),
            Expanded(
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: _buildSearchBar()),
                      AppGap.md(),
                      const SizedBox(
                        width: 240,
                        child: UspDeviceStatusSegmented(),
                      ),
                    ],
                  ),
                  AppGap.sm(),
                  _buildCountRow(devices, totalCount),
                  AppGap.lg(),
                  _buildDeviceList(devices),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMobileLayout(BuildContext context, List devices,
      DeviceFilterConfig filter, int totalCount) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSearchBar(),
        AppGap.md(),
        const UspDeviceStatusSegmented(),
        AppGap.md(),
        const UspDeviceFilterChipBar(),
        AppGap.sm(),
        _buildCountRow(devices, totalCount),
        AppGap.lg(),
        _buildDeviceList(devices),
      ],
    );
  }
}
