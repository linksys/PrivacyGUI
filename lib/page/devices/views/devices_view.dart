import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_provider.dart';
import 'package:privacy_gui/core/utils/wifi.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/shortcuts/snack_bar.dart';
import 'package:privacy_gui/page/components/styled/consts.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:privacy_gui/page/devices/_devices.dart';
import 'package:privacy_gui/page/devices/extensions/icon_device_category_ext.dart';
import 'package:privacy_gui/page/devices/views/device_list_widget.dart';
import 'package:privacy_gui/page/devices/views/devices_filter_widget.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/util/semantic.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/widgets/gap/const/spacing.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/device_list_card.dart';
import 'package:privacygui_widgets/widgets/container/responsive_layout.dart';

import 'package:privacygui_widgets/widgets/page/layout/basic_layout.dart';
import 'package:privacygui_widgets/widgets/progress_bar/full_screen_spinner.dart';

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
  final String _tag = 'dashboard-device';

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
    final count = filteredDeviceList.length;
    return _isLoading
        ? const AppFullScreenSpinner()
        : StyledAppPageView(
            padding: const EdgeInsets.only(),
            title: _isEdit ? loc(context).editDevices : loc(context).devices,
            menuWidget: const DevicesFilterWidget(),
            largeMenu: true,
            bottomBar: _isEdit
                ? InversePageBottomBar(
                    isPositiveEnabled: _selectedList.isNotEmpty,
                    onPositiveTap: () {
                      _showConfirmDialog();
                    },
                    positiveLabel: loc(context).delete)
                : null,
            actions: _isEdit
                ? [
                    AppTextButton(
                      identifier: semanticIdentifier(
                        tag: _tag,
                        description:
                            filteredDeviceList.length == _selectedList.length
                                ? 'clearAll'
                                : 'selectAll',
                      ),
                      semanticLabel:
                          filteredDeviceList.length == _selectedList.length
                              ? 'clear All'
                              : 'select All',
                      filteredDeviceList.length == _selectedList.length
                          ? loc(context).clearAll
                          : loc(context).selectAll,
                      icon: filteredDeviceList.length == _selectedList.length
                          ? LinksysIcons.close
                          : LinksysIcons.check,
                      color: filteredDeviceList.length == _selectedList.length
                          ? Theme.of(context).colorScheme.error
                          : Theme.of(context).colorScheme.primary,
                      onTap: () {
                        setState(() {
                          _selectedList =
                              filteredDeviceList.length == _selectedList.length
                                  ? []
                                  : filteredDeviceList
                                      .map((e) => e.deviceId)
                                      .toList();
                        });
                      },
                    ),
                  ]
                : !isOnlineFilter
                    ? [
                        AppIconButton(
                          identifier: semanticIdentifier(
                              tag: _tag, description: 'edit'),
                          semanticLabel: 'edit',
                          icon: LinksysIcons.edit,
                          onTap: () {
                            setState(() {
                              _isEdit = !_isEdit;
                            });
                          },
                        ),
                      ]
                    : null,
            appBarStyle: _isEdit ? AppBarStyle.close : AppBarStyle.back,
            onBackTap: () {
              if (_isEdit) {
                setState(() {
                  _isEdit = !_isEdit;
                  _selectedList.clear();
                });
              } else {
                context.pop();
              }
            },
            child: AppBasicLayout(
              header: Padding(
                  padding: const EdgeInsets.only(bottom: Spacing.medium),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          AppText.labelLarge(
                            loc(context).nDevices(count),
                            identifier: semanticIdentifier(
                                tag: _tag, description: 'device-count'),
                            semanticLabel: 'device count',
                          ),
                          // if (!isOnlineFilter)
                          //   _buildEditWidget(filteredDeviceList),
                        ],
                      ),
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
        ],
      false => [
          AppTextButton(
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
        identifier: semanticIdentifier(tag: _tag, description: 'device-list'),
        semanticLabel: 'device list',
        isSelected: _selectedList.contains(item.deviceId),
        title: '${item.name} [${item.signalStrength}]',
        description: ResponsiveLayout.isMobileLayout(context) || !item.isOnline
            ? null
            : item.upstreamDevice,
        band: ResponsiveLayout.isMobileLayout(context) ? null : item.band,
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
          loc(context).nDevicesDeleteDevicesTitle(_selectedList.length),
          identifier: semanticIdentifier(
              tag: _tag, description: 'nDevicesDeleteDevicesTitle'),
        ),
        content: AppText.bodyLarge(
          loc(context).nDevicesDeleteDevicesDescription(_selectedList.length),
          identifier: semanticIdentifier(
              tag: _tag, description: 'nDevicesDeleteDevicesDescription'),
        ),
        actions: [
          AppTextButton(
            loc(context).cancel,
            identifier: semanticIdentifier(tag: _tag, description: 'cancel'),
            onTap: () {
              context.pop();
            },
          ),
          AppTextButton(
            loc(context).delete,
            identifier: semanticIdentifier(tag: _tag, description: 'delete'),
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
