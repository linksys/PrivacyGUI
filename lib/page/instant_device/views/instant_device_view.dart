import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_provider.dart';
import 'package:privacy_gui/core/jnap/providers/polling_provider.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/customs/animated_refresh_container.dart';
import 'package:privacy_gui/page/components/mixin/client_signal_watcher_mixin.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/page/components/shortcuts/snack_bar.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:privacy_gui/page/components/widgets/write_guard.dart';
import 'package:privacy_gui/page/instant_device/_instant_device.dart';
import 'package:privacy_gui/page/instant_device/views/device_list_widget.dart';
import 'package:privacy_gui/page/instant_device/views/devices_filter_widget.dart';
import 'package:privacy_gui/page/instant_device/views/restricted_devices_view.dart';
import 'package:privacy_gui/page/instant_device/providers/client_access_policy_provider.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/theme/_theme.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';
import 'package:privacygui_widgets/widgets/container/responsive_layout.dart';
import 'package:privacygui_widgets/widgets/gap/const/spacing.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';

import 'package:privacygui_widgets/widgets/page/layout/basic_layout.dart';
import 'package:privacy_gui/page/components/mixin/page_snackbar_mixin.dart';

class InstantDeviceView extends ArgumentsConsumerStatefulView {
  const InstantDeviceView({
    Key? key,
    super.args,
  }) : super(key: key);

  @override
  ConsumerState<InstantDeviceView> createState() => _InstantDeviceViewState();
}

class _InstantDeviceViewState extends ConsumerState<InstantDeviceView>
    with ClientSignalWatcherMixin, PageSnackbarMixin {
  List<String> _selectedList = [];
  bool _restrictedDevicesSelected = false;

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
    ref.listen(restrictedDevicesProvider, (_, next) {
      if (_restrictedDevicesSelected &&
          !next.isLoading &&
          !next.hasError &&
          (next.valueOrNull?.isEmpty ?? false)) {
        _showConnectionDevices();
        ref
            .read(deviceFilterConfigProvider.notifier)
            .updateConnectionFilter(false);
      }
    });

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
      scrollable: _restrictedDevicesSelected ||
          !ResponsiveLayout.isMobileLayout(context),
      title: loc(context).instantDevices,
      bottomBar: isOnlineFilter || _restrictedDevicesSelected
          ? null
          : InversePageBottomBar(
              isPositiveEnabled: _selectedList.isNotEmpty,
              positiveLabel: loc(context).delete,
              onPositiveTap: () {
                _showConfirmDeleteDialog(_selectedList);
              },
            ),
      actions: [
        if (isOnlineFilter || _restrictedDevicesSelected)
          AppTextButton.noPadding(
            loc(context).offlineDevices,
            onTap: () {
              _showConnectionDevices();
              ref
                  .read(deviceFilterConfigProvider.notifier)
                  .updateConnectionFilter(false);
            },
          ),
        AnimatedRefreshContainer(
          builder: (controller) {
            return AppTextButton.noPadding(
              loc(context).refresh,
              icon: LinksysIcons.refresh,
              onTap: () {
                ref.invalidate(clientAccessPolicyProvider);
                controller.repeat();
                ref
                    .read(pollingProvider.notifier)
                    .forcePollingWithClientSignals()
                    .then((value) {
                  controller.stop();
                });
              },
            );
          },
        ),
      ],
      child: (context, constraints) => AppBasicLayout(
        // height: constraints.maxHeight,
        content: ResponsiveLayout(
          desktop: _desktopLayout(isOnlineFilter, filteredDeviceList),
          mobile: _mobileLayout(isOnlineFilter, filteredDeviceList),
        ),
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
            child: _filters(),
          ),
        ),
        const AppGap.gutter(),
        SizedBox(
          width: 8.col,
          child: _listContent(isOnlineFilter, filteredDeviceList),
        ),
      ],
    );
  }

  Widget _mobileLayout(
      bool isOnlineFilter, List<DeviceListItem> filteredDeviceList) {
    return _listContent(isOnlineFilter, filteredDeviceList);
  }

  Widget _listContent(bool isOnline, List<DeviceListItem> devices) =>
      _restrictedDevicesSelected
          ? RestrictedDevicesView(onShowFilters: _showFilters)
          : _deviceListView(isOnline, devices);

  void _showConnectionDevices() => setState(() {
        _restrictedDevicesSelected = false;
        _selectedList.clear();
      });

  Widget _filters() => DevicesFilterWidget(
        restrictedDevicesSelected: _restrictedDevicesSelected,
        onConnectionSelected: () {
          _showConnectionDevices();
          if (ResponsiveLayout.isMobileLayout(context)) {
            Navigator.of(context, rootNavigator: true).pop();
          }
        },
        onRestrictedDevicesSelected: () {
          setState(() {
            _restrictedDevicesSelected = true;
            _selectedList.clear();
          });
          // Close the mobile filter sheet so the selected view is visible.
          if (ResponsiveLayout.isMobileLayout(context)) {
            Navigator.of(context, rootNavigator: true).pop();
          }
        },
      );

  void _showFilters() => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useRootNavigator: true,
        showDragHandle: true,
        builder: (_) => Padding(
          padding: const EdgeInsets.all(Spacing.large2),
          child: _filters(),
        ),
      );

  Widget _deviceListView(
      bool isOnlineFilter, List<DeviceListItem> filteredDeviceList) {
    return AppBasicLayout(
      header: Padding(
        padding: const EdgeInsets.only(bottom: Spacing.medium),
        child: ResponsiveLayout(
          desktop: Column(
            children: [
              Row(
                children: [
                  AppText.labelLarge(
                    loc(context).nDevices(filteredDeviceList.length),
                  ),
                  const Spacer(),
                  _editButton(isOnlineFilter, filteredDeviceList),
                ],
              ),
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
                    onTap: _showFilters,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      content: SizedBox(
        height: filteredDeviceList.length * 84,
        child: DeviceListWidget(
          devices: filteredDeviceList,
          isEdit: !isOnlineFilter,
          enableDelete: !isOnlineFilter,
          enableRemove: isOnlineFilter,
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
          onItemDelete: (item) {
            _showConfirmDeleteDialog([item.deviceId]);
          },
        ),
      ),
    );
  }

  Widget _editButton(
      bool isOnlineFilter, List<DeviceListItem> filteredDeviceList) {
    return AppTextButton.noPadding(
      loc(context).selectAll,
      icon: filteredDeviceList.length == _selectedList.length
          ? LinksysIcons.checkBox
          : LinksysIcons.checkBoxOutlineBlank,
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
    final deviceIds = List<String>.unmodifiable(selectedList);
    showSimpleAppDialog(
      context,
      dismissible: false,
      title: loc(context).nDevicesDeleteDevicesTitle(deviceIds.length),
      content: AppText.bodyLarge(
          loc(context).nDevicesDeleteDevicesDescription(deviceIds.length)),
      actions: [
        AppTextButton(
          loc(context).cancel,
          color: Theme.of(context).colorScheme.onSurface,
          onTap: () {
            context.pop();
          },
        ),
        WriteGuard(
          child: AppTextButton(
            loc(context).delete,
            color: Theme.of(context).colorScheme.error,
            onTap: () {
              context.pop();
              _removeDevices(deviceIds);
            },
          ),
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
        showErrorMessageSnackBar(error);
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
                showErrorMessageSnackBar(error);
              }),
            );
          },
        ),
      ],
    );
  }
}
