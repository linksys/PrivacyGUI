import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/page/components/ui_kit_page_view.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/usp_page/dashboard/providers/usp_dashboard_notifier.dart';
import 'package:privacy_gui/usp_page/devices/providers/device_filter_provider.dart';
import 'package:privacy_gui/usp_page/devices/providers/device_filter_state.dart';
import 'package:privacy_gui/usp_page/devices/views/components/usp_device_filter_panel.dart';
import 'package:privacy_gui/usp_page/devices/views/components/usp_device_list_tile.dart';
import 'package:privacy_gui/usp_page/shell/usp_top_bar.dart';
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
    final asyncDashboard = ref.watch(uspDashboardProvider);
    final devices = ref.watch(filteredDeviceListProvider);
    final filter = ref.watch(deviceFilterConfigProvider);

    return UiKitPageView.withSliver(
      scrollable: true,
      appBarStyle: UiKitAppBarStyle.none,
      topbar: const PreferredSize(
        preferredSize: Size.fromHeight(64),
        child: UspTopBar(),
      ),
      backState: UiKitBackState.none,
      onRefresh: () => ref.refresh(uspDashboardProvider.future),
      padding:
          const EdgeInsets.only(top: AppSpacing.xxl, bottom: AppSpacing.md),
      child: (childContext, constraints) {
        return asyncDashboard.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: AppText.bodyMedium('Error: $e')),
          data: (state) {
            final totalCount = state.deviceModels.length;
            return AppResponsiveLayout(
              mobile: (_) => _buildMobileLayout(
                  context, devices, filter, totalCount),
              desktop: (_) => _buildDesktopLayout(
                  context, devices, filter, totalCount),
            );
          },
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, int filteredCount, int totalCount) {
    return Row(
      children: [
        AppIconButton(
          icon: AppIcon.font(Icons.arrow_back),
          onTap: () => context.canPop()
              ? context.pop()
              : context.goNamed(RouteNamed.uspDashboard),
        ),
        AppGap.md(),
        Expanded(child: AppText.headlineSmall('Devices')),
        AppText.labelLarge('$filteredCount / $totalCount'),
      ],
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
                ref.read(deviceFilterConfigProvider.notifier).state = ref
                    .read(deviceFilterConfigProvider)
                    .copyWith(searchQuery: '');
              },
            )
          : null,
      onChanged: (value) {
        ref.read(deviceFilterConfigProvider.notifier).state =
            ref.read(deviceFilterConfigProvider).copyWith(searchQuery: value);
      },
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
        _buildHeader(context, devices.length, totalCount),
        AppGap.xl(),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const UspDeviceFilterPanel(),
            AppGap.gutter(),
            Expanded(
              child: Column(
                children: [
                  _buildSearchBar(),
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
        _buildHeader(context, devices.length, totalCount),
        AppGap.lg(),
        _buildSearchBar(),
        AppGap.md(),
        const UspDeviceFilterChipBar(),
        AppGap.lg(),
        _buildDeviceList(devices),
      ],
    );
  }
}
