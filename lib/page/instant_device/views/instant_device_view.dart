import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_provider.dart';
import 'package:privacy_gui/core/jnap/providers/polling_provider.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/customs/animated_refresh_container.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/page/components/shortcuts/snack_bar.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:privacy_gui/page/instant_device/_instant_device.dart';
import 'package:privacy_gui/page/instant_device/views/device_list_widget.dart';
import 'package:privacy_gui/page/instant_device/views/devices_filter_widget.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/theme/_theme.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';
import 'package:privacygui_widgets/widgets/container/responsive_layout.dart';
import 'package:privacygui_widgets/widgets/gap/const/spacing.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';

import 'package:privacygui_widgets/widgets/page/layout/basic_layout.dart';

class InstantDeviceView extends ArgumentsConsumerStatefulView {
  const InstantDeviceView({
    Key? key,
    super.args,
  }) : super(key: key);

  @override
  ConsumerState<InstantDeviceView> createState() => _InstantDeviceViewState();
}

class _InstantDeviceViewState extends ConsumerState<InstantDeviceView> {
  List<String> _selectedList = [];

  @override
  void initState() {
    super.initState();
    Future.doWhile(() => !mounted).then((value) {
      return ref.read(deviceFilterConfigProvider.notifier).initFilter();
    });
  }

  @override
  Widget build(BuildContext context) {
    final filteredDeviceList = ref.watch(filteredDeviceListProvider);
    final isOnlineFilter = ref.watch(
        deviceFilterConfigProvider.select((value) => value.connectionFilter));
    if (isOnlineFilter) {
      setState(() {
        _selectedList.clear();
      });
    }

    return StyledAppPageView(
      padding: const EdgeInsets.only(),
      title: loc(context).instantDevices,
      bottomBar: isOnlineFilter
          ? null
          : InversePageBottomBar(
              isPositiveEnabled: _selectedList.isNotEmpty,
              positiveLabel: loc(context).delete,
              onPositiveTap: () {
                _showConfirmDeleteDialog(_selectedList);
              },
            ),
      actions: [
        AnimatedRefreshContainer(
          builder: (controller) {
            return AppTextButton.noPadding(
              loc(context).refresh,
              icon: LinksysIcons.refresh,
              onTap: () {
                controller.repeat();
                ref.read(pollingProvider.notifier).forcePolling().then((value) {
                  controller.stop();
                });
              },
            );
          },
        ),
      ],
      child: ResponsiveLayout(
        desktop: _desktopLayout(isOnlineFilter, filteredDeviceList),
        mobile: _mobileLayout(isOnlineFilter, filteredDeviceList),
      ),
    );
  }

  Widget _desktopLayout(
      bool isOnlineFilter, List<DeviceListItem> filteredDeviceList) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 4.col,
          child: AppCard(
            padding: const EdgeInsets.all(Spacing.small2),
            margin: const EdgeInsets.only(bottom: Spacing.small3),
            color: Theme.of(context).colorScheme.background,
            child: const DevicesFilterWidget(),
          ),
        ),
        const AppGap.gutter(),
        SizedBox(
          width: 8.col,
          child: _deviceListView(isOnlineFilter, filteredDeviceList),
        ),
      ],
    );
  }

  Widget _mobileLayout(
      bool isOnlineFilter, List<DeviceListItem> filteredDeviceList) {
    return _deviceListView(isOnlineFilter, filteredDeviceList);
  }

  Widget _deviceListView(
      bool isOnlineFilter, List<DeviceListItem> filteredDeviceList) {
    return AppBasicLayout(
      header: Padding(
        padding: const EdgeInsets.only(bottom: Spacing.medium),
        child: ResponsiveLayout(
          desktop: Row(
            children: [
              AppText.labelLarge(
                loc(context).nDevices(filteredDeviceList.length),
              ),
              const Spacer(),
              _editButton(isOnlineFilter, filteredDeviceList),
            ],
          ),
          mobile: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText.labelLarge(
                loc(context).nDevices(filteredDeviceList.length),
              ),
              const AppGap.medium(),
              Row(
                children: [
                  _editButton(isOnlineFilter, filteredDeviceList),
                  const Spacer(),
                  AppTextButton.noPadding(
                    loc(context).filters,
                    icon: LinksysIcons.filter,
                    color: Theme.of(context).colorScheme.primary,
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        useRootNavigator: true,
                        builder: (context) => Container(
                          padding: const EdgeInsets.all(Spacing.large2),
                          width: double.infinity,
                          child: const DevicesFilterWidget(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      content: DeviceListWidget(
        devices: filteredDeviceList,
        isEdit: !isOnlineFilter,
        enableDeauth: isOnlineFilter,
        isItemSelected: (item) => _selectedList.contains(item.deviceId),
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
          ref.read(deviceDetailIdProvider.notifier).state = item.deviceId;
          context.pushNamed(RouteNamed.deviceDetails);
        },
        onItemDeauth: (item) {
          _showConfirmDeauthDialog(item.macAddress);
        },
      ),
    );
  }

  Widget _editButton(
      bool isOnlineFilter, List<DeviceListItem> filteredDeviceList) {
    return AppTextButton.noPadding(
      filteredDeviceList.length == _selectedList.length
          ? loc(context).deselectAll
          : loc(context).selectAll,
      icon: filteredDeviceList.length == _selectedList.length
          ? LinksysIcons.checkBoxOutlineBlank
          : LinksysIcons.checkBox,
      color: isOnlineFilter
          ? Theme.of(context).colorScheme.onSurface.withOpacity(0.12)
          : Theme.of(context).colorScheme.primary,
      onTap: isOnlineFilter
          ? null
          : () {
              setState(() {
                _selectedList =
                    filteredDeviceList.length == _selectedList.length
                        ? []
                        : filteredDeviceList.map((e) => e.deviceId).toList();
              });
            },
    );
  }

  void _showConfirmDeleteDialog(List<String> selectedList) {
    showSimpleAppDialog(
      context,
      dismissible: false,
      title: loc(context).nDevicesDeleteDevicesTitle(selectedList.length),
      content: AppText.bodyLarge(
          loc(context).nDevicesDeleteDevicesDescription(selectedList.length)),
      actions: [
        AppTextButton(
          loc(context).cancel,
          color: Theme.of(context).colorScheme.onSurface,
          onTap: () {
            context.pop();
          },
        ),
        AppTextButton(
          loc(context).delete,
          color: Theme.of(context).colorScheme.error,
          onTap: () {
            _removeDevices(selectedList);
            context.pop();
          },
        ),
      ],
    );
  }

  void _removeDevices(List<String> selectedList) {
    doSomethingWithSpinner(
      context,
      ref
          .read(deviceManagerProvider.notifier)
          .deleteDevices(deviceIds: selectedList)
          .then((_) {
            setState(() {
                _selectedList = [];
              });
        showSimpleSnackBar(context, loc(context).deviceDeleted);
      }).onError((error, stackTrace) {
        showFailedSnackBar(context, loc(context).generalError);
      }),
    );
  }

  void _showConfirmDeauthDialog(String macAddress) {
    showSimpleAppDialog(
      context,
      dismissible: false,
      title: loc(context).disconnectClient,
      content: AppText.bodyLarge(''),
      actions: [
        AppTextButton(
          loc(context).cancel,
          color: Theme.of(context).colorScheme.onSurface,
          onTap: () {
            context.pop();
          },
        ),
        AppTextButton(
          loc(context).disconnect,
          color: Theme.of(context).colorScheme.error,
          onTap: () {
            context.pop();
            doSomethingWithSpinner(
              context,
              ref
                  .read(deviceManagerProvider.notifier)
                  .deauthClient(macAddress: macAddress)
                  .then((_) {
                showSimpleSnackBar(context, loc(context).successExclamation);
              }).onError((error, stackTrace) {
                showFailedSnackBar(context, loc(context).generalError);
              }),
            );
          },
        ),
      ],
    );
  }
}
