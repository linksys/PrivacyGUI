import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:linksys_app/core/jnap/providers/device_manager_provider.dart';
import 'package:linksys_app/page/components/styled/styled_page_view.dart';
import 'package:linksys_app/page/components/views/arguments_view.dart';
import 'package:linksys_app/provider/devices/device_detail_id_provider.dart';
import 'package:linksys_app/provider/devices/device_list_provider.dart';
import 'package:linksys_app/provider/devices/device_list_state.dart';
import 'package:linksys_app/route/constants.dart';
import 'package:linksys_app/util/extensions.dart';
import 'package:linksys_widgets/hook/icon_hooks.dart';
import 'package:linksys_widgets/theme/_theme.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/base/padding.dart';
import 'package:linksys_widgets/widgets/page/layout/basic_layout.dart';
import 'package:linksys_widgets/widgets/progress_bar/full_screen_spinner.dart';

class OfflineDevicesView extends ArgumentsConsumerStatefulView {
  const OfflineDevicesView({
    Key? key,
    super.args,
  }) : super(key: key);

  @override
  ConsumerState<OfflineDevicesView> createState() => _OfflineDevicesViewState();
}

class _OfflineDevicesViewState extends ConsumerState<OfflineDevicesView> {
  bool _isEdit = false;
  bool _isLoading = false;
  final List<String> _removeIDs = [];

  @override
  Widget build(BuildContext context) {
    final offlineDeviceList = ref.watch(offlineDeviceListProvider);
    return _isLoading
        ? AppFullScreenSpinner()
        : StyledAppPageView(
            padding: const AppEdgeInsets.zero(),
            child: AppBasicLayout(
              header: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppPadding.regular(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        AppText.headlineMedium('Offline'),
                        AppTertiaryButton.noPadding(
                          _isEdit ? 'Cancel' : 'Edit',
                          onTap: () {
                            setState(() {
                              _isEdit = !_isEdit;
                              if (_isEdit) {
                                _removeIDs.clear();
                              }
                            });
                          },
                        )
                      ],
                    ),
                  ),
                  AppPadding.regular(
                      child: AppText.labelLarge(
                          'Offline (${offlineDeviceList.length})')),
                  const Divider(
                    height: 8,
                  ),
                ],
              ),
              content: ListView.separated(
                padding: EdgeInsets.zero,
                itemCount: offlineDeviceList.length,
                itemBuilder: (context, index) {
                  return _buildDeviceCell(offlineDeviceList[index]);
                },
                separatorBuilder: (BuildContext context, int index) {
                  return const Divider(
                    height: 8,
                  );
                },
              ),
              footer: _isEdit
                  ? AppPadding.regular(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          AppCheckbox(
                            text: 'Select all',
                            value:
                                _removeIDs.length == offlineDeviceList.length,
                            onChanged: (value) {
                              setState(() {
                                if (value == true) {
                                  _removeIDs
                                    ..addAll(offlineDeviceList
                                        .map((e) => e.deviceId)
                                        .toList())
                                    ..unique((x) => x);
                                } else {
                                  _removeIDs.clear();
                                }
                              });
                            },
                          ),
                          AppPrimaryButton(
                            'Remove(${_removeIDs.length})',
                            onTap: _removeIDs.isEmpty
                                ? null
                                : () {
                                    showAdaptiveDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: AppText.bodyLarge(
                                            'Remove all offline devices'),
                                        content: AppText.bodyLarge(
                                            'These devices will reappear if they reconnect to your WiFi network.'),
                                        actions: [
                                          AppTertiaryButton('Cancel',
                                              onTap: () {
                                            context.pop();
                                          }),
                                          AppTertiaryButton(
                                            'Clear',
                                            onTap: () {
                                              setState(() {
                                                _isLoading = true;
                                              });
                                              ref
                                                  .read(deviceManagerProvider
                                                      .notifier)
                                                  .deleteDevices(
                                                      deviceIds: _removeIDs)
                                                  .then((value) {
                                                setState(() {
                                                  _isEdit = false;
                                                  _isLoading = false;
                                                });
                                              });
                                              context.pop();
                                            },
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                          ),
                        ],
                      ),
                    )
                  : null,
            ),
          );
  }

  Widget _buildDeviceCell(DeviceListItem item) {
    return AppPadding(
      padding: const AppEdgeInsets.symmetric(horizontal: AppGapSize.regular),
      child: AppDevicePanel.normal(
        headerChecked: _removeIDs.contains(item.deviceId),
        onHeaderChecked: _isEdit
            ? (value) {
                setState(() {
                  if (value == true) {
                    _removeIDs
                      ..add(item.deviceId)
                      ..unique((x) => x);
                  } else {
                    _removeIDs.remove(item.deviceId);
                  }
                });
              }
            : null,
        title: item.name,
        place: '',
        band: '',
        deviceImage: AppTheme.of(context).images.devices.getByName(item.icon),
        rssiIcon: null,
        onTap: !item.isOnline
            ? null
            : () {
                ref.read(deviceDetailIdProvider.notifier).state = item.deviceId;
                context.pushNamed(RouteNamed.deviceDetails);
              },
      ),
    );
  }
}
