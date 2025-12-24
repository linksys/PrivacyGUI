import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_provider.dart';
import 'package:privacy_gui/core/jnap/providers/polling_provider.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/customs/animated_refresh_container.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/page/components/shortcuts/snack_bar.dart';
import 'package:privacy_gui/page/components/ui_kit_page_view.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:privacy_gui/page/instant_device/_instant_device.dart';
import 'package:privacy_gui/page/instant_device/views/device_list_widget.dart';
import 'package:privacy_gui/page/instant_device/views/devices_filter_widget.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:ui_kit_library/ui_kit.dart';

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
    MediaQuery.of(context);

    final filteredDeviceList = ref.watch(filteredDeviceListProvider);
    final isOnlineFilter = ref.watch(
        deviceFilterConfigProvider.select((value) => value.connectionFilter));
    if (isOnlineFilter) {
      setState(() {
        _selectedList.clear();
      });
    }

    return UiKitPageView.withSliver(
      title: loc(context).instantDevices,
      bottomBar: isOnlineFilter
          ? null
          : UiKitBottomBarConfig(
              isPositiveEnabled: _selectedList.isNotEmpty,
              positiveLabel: loc(context).delete,
              onPositiveTap: () => _showConfirmDeleteDialog(_selectedList),
            ),
      actions: [
        AnimatedRefreshContainer(
          builder: (controller) {
            return AppButton.text(
              label: loc(context).refresh,
              icon: AppIcon.font(AppFontIcons.refresh),
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
      child: (context, constraints) => AppResponsiveLayout(
        desktop: (ctx) =>
            _desktopLayout(ctx, isOnlineFilter, filteredDeviceList),
        mobile: (ctx) => _mobileLayout(ctx, isOnlineFilter, filteredDeviceList),
      ),
    );
  }

  Widget _desktopLayout(BuildContext context, bool isOnlineFilter,
      List<DeviceListItem> filteredDeviceList) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: context.colWidth(4),
          child: AppCard(
            padding: EdgeInsets.all(AppSpacing.sm),
            child: const DevicesFilterWidget(),
          ),
        ),
        AppGap.gutter(),
        SizedBox(
          width: context.colWidth(8),
          child: _deviceListView(context, isOnlineFilter, filteredDeviceList),
        ),
      ],
    );
  }

  Widget _mobileLayout(BuildContext context, bool isOnlineFilter,
      List<DeviceListItem> filteredDeviceList) {
    return _deviceListView(context, isOnlineFilter, filteredDeviceList);
  }

  Widget _deviceListView(BuildContext context, bool isOnlineFilter,
      List<DeviceListItem> filteredDeviceList) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: AppSpacing.lg),
          child: AppResponsiveLayout(
            desktop: (ctx) => Column(
              children: [
                Row(
                  children: [
                    AppText.labelLarge(
                      loc(context).nDevices(filteredDeviceList.length),
                    ),
                    const Spacer(),
                    _editButton(context, isOnlineFilter, filteredDeviceList),
                  ],
                ),
              ],
            ),
            mobile: (ctx) => Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.labelLarge(
                  loc(context).nDevices(filteredDeviceList.length),
                ),
                AppGap.lg(),
                Row(
                  children: [
                    _editButton(context, isOnlineFilter, filteredDeviceList),
                    const Spacer(),
                    AppButton.text(
                      label: loc(context).filters,
                      icon: AppIcon.font(AppFontIcons.filter),
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          useRootNavigator: true,
                          showDragHandle: true,
                          builder: (context) => Container(
                            padding: EdgeInsets.all(AppSpacing.xxl),
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
        DeviceListWidget(
          physics: NeverScrollableScrollPhysics(),
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
      ],
    );
  }

  Widget _editButton(BuildContext context, bool isOnlineFilter,
      List<DeviceListItem> filteredDeviceList) {
    return AppButton.text(
      label: loc(context).selectAll,
      icon: AppIcon.font(filteredDeviceList.length == _selectedList.length
          ? AppFontIcons.checkBox
          : AppFontIcons.checkBoxOutlineBlank),
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
        AppButton.text(
          label: loc(context).cancel,
          onTap: () {
            context.pop();
          },
        ),
        AppButton.text(
          label: loc(context).delete,
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
        if (mounted) {
          showSimpleSnackBar(context, loc(context).deviceDeleted);
        }
      }).onError((error, stackTrace) {
        if (mounted) {
          showFailedSnackBar(context, loc(context).generalError);
        }
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
        AppButton.text(
          label: loc(context).cancel,
          onTap: () {
            context.pop();
          },
        ),
        AppButton.text(
          label: loc(context).disconnect,
          onTap: () {
            context.pop();
            doSomethingWithSpinner(
              context,
              ref
                  .read(deviceManagerProvider.notifier)
                  .deauthClient(macAddress: macAddress)
                  .then((_) {
                if (mounted) {
                  showSimpleSnackBar(context, loc(context).successExclamation);
                }
              }).onError((error, stackTrace) {
                if (mounted) {
                  showFailedSnackBar(context, loc(context).generalError);
                }
              }),
            );
          },
        ),
      ],
    );
  }
}
