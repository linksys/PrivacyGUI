import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:linksys_app/core/jnap/providers/device_manager_provider.dart';
import 'package:linksys_app/core/utils/wifi.dart';
import 'package:linksys_app/localization/localization_hook.dart';
import 'package:linksys_app/page/components/shortcuts/snack_bar.dart';
import 'package:linksys_app/page/components/styled/styled_page_view.dart';
import 'package:linksys_app/page/components/views/arguments_view.dart';
import 'package:linksys_app/page/devices/_devices.dart';
import 'package:linksys_app/page/devices/extensions/icon_device_category_ext.dart';
import 'package:linksys_app/page/devices/views/device_list_widget.dart';
import 'package:linksys_app/page/devices/views/devices_filter_widget.dart';
import 'package:linksys_app/route/constants.dart';
import 'package:linksys_widgets/icons/linksys_icons.dart';
import 'package:linksys_widgets/theme/const/spacing.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/card/device_list_card.dart';
import 'package:linksys_widgets/widgets/container/responsive_layout.dart';

import 'package:linksys_widgets/widgets/page/layout/basic_layout.dart';
import 'package:linksys_widgets/widgets/progress_bar/full_screen_spinner.dart';

class DashboardDevices extends ArgumentsConsumerStatefulView {
  const DashboardDevices({
    Key? key,
    super.args,
  }) : super(key: key);

  @override
  ConsumerState<DashboardDevices> createState() => _DashboardDevicesState();
}

class _DashboardDevicesState extends ConsumerState<DashboardDevices> {
  bool _isEdit = false;
  bool _isLoading = false;
  List<String> _selectedList = [];

  @override
  void initState() {
    super.initState();
    Future.doWhile(() => !mounted).then((value) {
      return ref.read(deviceFilterConfigProvider.notifier).initFilter();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Future.doWhile(() => !mounted).then(
    //     (value) => ref.read(filteredDeviceListProvider.notifier).initFilter());
  }

  @override
  Widget build(BuildContext context) {
    final filteredDeviceList = ref.watch(filteredDeviceListProvider);
    final isOnlineFilter = ref.watch(
        deviceFilterConfigProvider.select((value) => value.connectionFilter));
    // final filteredChips =
    //     ref.watch(filteredDeviceListProvider.select((value) => value.$3));
    final count = filteredDeviceList.length;
    return _isLoading
        ? const AppFullScreenSpinner()
        : StyledAppPageView(
            padding: const EdgeInsets.only(),
            title: loc(context).devices,
            menuWidget: const DevicesFilterWidget(),
            child: AppBasicLayout(
              header: Padding(
                  padding: const EdgeInsets.only(
                      left: Spacing.semiSmall, bottom: Spacing.regular),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          AppText.labelLarge(loc(context).nDevices(count)),
                          if (!isOnlineFilter)
                            _buildEditWidget(filteredDeviceList),
                        ],
                      ),
                      // const AppGap.regular(),
                      // Wrap(
                      //   spacing: 16,
                      //   children: filteredChips
                      //       .map((e) => FilterChip(
                      //             label: AppText.bodySmall(e ?? ''),
                      //             selected: true,
                      //             onSelected: (bool value) {},
                      //           ))
                      //       .toList(),
                      // ),
                    ],
                  )),
              content: DeviceListWidget(
                devices: filteredDeviceList,
                isEdit: _isEdit,
                isItemSelected: (item) => _selectedList.contains(item.deviceId),
                // itemBuilder: (context, index) {
                //   return _buildCell(index, filteredDeviceList);
                // },
                onItemSelected: (value, item) {
                  setState(() {
                    if (value) {
                      _selectedList.add(item.deviceId);
                    } else {
                      _selectedList.remove(item.deviceId);
                    }
                  });
                },
                onItemClick: (item) {
                  ref.read(deviceDetailIdProvider.notifier).state =
                      item.deviceId;
                  context.pushNamed(RouteNamed.deviceDetails);
                },
              ),
            ),
          );
  }

  Widget _buildEditWidget(List<DeviceListItem> list) {
    bool isSelectedAll = list.length == _selectedList.length;
    final content = switch (_isEdit) {
      true => [
          AppTextButton(
            isSelectedAll ? loc(context).clearAll : loc(context).selectAll,
            icon: LinksysIcons.check,
            onTap: () {
              setState(() {
                _selectedList =
                    isSelectedAll ? [] : list.map((e) => e.deviceId).toList();
              });
            },
          ),
          AppTextButton(
            loc(context).deleteSelected,
            icon: LinksysIcons.delete,
            color: Theme.of(context).colorScheme.error,
            onTap: () {
              _showConfirmDialog();
            },
          ),
          AppTextButton(
            loc(context).cancel,
            color: Theme.of(context).colorScheme.onSurface,
            onTap: () {
              setState(() {
                _isEdit = !_isEdit;
              });
            },
          ),
        ],
      false => [
          AppTextButton.noPadding(
            loc(context).edit,
            icon: LinksysIcons.edit,
            onTap: () {
              setState(() {
                _isEdit = !_isEdit;
              });
            },
          ),
        ],
    };
    return Wrap(
      children: content,
    );
  }

  Widget _buildCell(int index, List<DeviceListItem> deviceList) {
    return _buildDeviceCell(deviceList[index]);
  }

  Widget _buildDeviceCell(DeviceListItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.zero),
      child: AppDeviceListCard(
        isSelected: _selectedList.contains(item.deviceId),
        title: '${item.name} [${item.signalStrength}]',
        description: ResponsiveLayout.isMobile(context) || !item.isOnline
            ? null
            : item.upstreamDevice,
        band: ResponsiveLayout.isMobile(context) ? null : item.band,
        leading: IconDeviceCategoryExt.resolveByName(item.icon),
        trailing: item.isOnline
            ? getWifiSignalIconData(
                context, item.isWired ? null : item.signalStrength)
            : null,
        onSelected: _isEdit
            ? (value) {
                setState(() {
                  if (value) {
                    _selectedList.add(item.deviceId);
                  } else {
                    _selectedList.remove(item.deviceId);
                  }
                });
              }
            : null,
        onTap: () {
          if (_isEdit) {
            return;
          } else {
            ref.read(deviceDetailIdProvider.notifier).state = item.deviceId;
            context.pushNamed(RouteNamed.deviceDetails);
          }
        },
      ),
    );
  }

  void _showConfirmDialog() {
    showAdaptiveDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: AppText.bodyLarge(
            loc(context).nDevicesDeleteDevicesTitle(_selectedList.length)),
        content: AppText.bodyLarge(loc(context)
            .nDevicesDeleteDevicesDescription(_selectedList.length)),
        actions: [
          AppTextButton(loc(context).cancel, onTap: () {
            context.pop();
          }),
          AppTextButton(
            loc(context).delete,
            color: Theme.of(context).colorScheme.error,
            onTap: () {
              _removeDevices();
              context.pop();
            },
          ),
        ],
      ),
    );
  }

  void _removeDevices() {
    setState(() {
      _isLoading = true;
    });
    ref
        .read(deviceManagerProvider.notifier)
        .deleteDevices(deviceIds: _selectedList)
        .then((value) {
      setState(() {
        _isEdit = false;
        _isLoading = false;
      });
      showSuccessSnackBar(context, 'Success!');
    }).onError((error, stackTrace) {
      setState(() {
        _isEdit = false;
        _isLoading = false;
      });
      showFailedSnackBar(context, 'Failed!');
    });
  }
}