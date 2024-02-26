import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:linksys_app/core/jnap/providers/device_manager_provider.dart';
import 'package:linksys_app/page/components/shortcuts/snack_bar.dart';
import 'package:linksys_app/page/components/styled/styled_page_view.dart';
import 'package:linksys_app/page/components/views/arguments_view.dart';
import 'package:linksys_app/page/devices/_devices.dart';
import 'package:linksys_app/route/constants.dart';
import 'package:linksys_app/util/extensions.dart';
import 'package:linksys_widgets/hook/icon_hooks.dart';
import 'package:linksys_widgets/theme/_theme.dart';
import 'package:linksys_widgets/theme/const/spacing.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/card/general_card.dart';
import 'package:linksys_widgets/widgets/container/responsive_layout.dart';

import 'package:linksys_widgets/widgets/page/layout/basic_layout.dart';
import 'package:linksys_widgets/widgets/panel/custom_animated_box.dart';
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
            padding: const EdgeInsets.only(),
            child: AppBasicLayout(
              header: _buildHeader(offlineDeviceList),
              content: ResponsiveLayout.isDesktop(context)
                  ? _buildDeviceGridView(offlineDeviceList)
                  : _buildDeviceListView(offlineDeviceList),
              footer: _isEdit ? _buildFooter(offlineDeviceList) : null,
            ),
          );
  }

  Widget _buildDeviceGridView(List<DeviceListItem> offlineDeviceList) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: (3 / 2),
      ),
      itemCount: offlineDeviceList.length,
      itemBuilder: (context, index) {
        return CustomAnimatedBox(
            value: _removeIDs.contains(offlineDeviceList[index].deviceId),
            selectable: _isEdit,
            onChanged: (value) {
              if (_isEdit) {
                _checkedItem(offlineDeviceList[index].deviceId, value);
              }
            },
            child: _buildDeviceGridCell(offlineDeviceList[index]));
      },
    );
  }

  Widget _buildDeviceGridCell(DeviceListItem item) {
    return AppCard(
      image: CustomTheme.of(context).images.devices.getByName(item.icon),
      title: item.name,
    );
  }

  Widget _buildDeviceListView(List<DeviceListItem> offlineDeviceList) {
    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: offlineDeviceList.length,
      itemBuilder: (context, index) {
        return _buildDeviceListCell(offlineDeviceList[index]);
      },
      separatorBuilder: (BuildContext context, int index) {
        return const Divider(
          height: 8,
        );
      },
    );
  }

  Widget _buildDeviceListCell(DeviceListItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.regular),
      child: AppDevicePanel.offline(
        headerChecked: _removeIDs.contains(item.deviceId),
        onHeaderChecked: _isEdit
            ? (value) {
                _checkedItem(item.deviceId, value);
              }
            : null,
        title: item.name,
        deviceImage:
            CustomTheme.of(context).images.devices.getByName(item.icon),
        onTap: !item.isOnline
            ? null
            : () {
                ref.read(deviceDetailIdProvider.notifier).state = item.deviceId;
                context.pushNamed(RouteNamed.deviceDetails);
              },
      ),
    );
  }

  Widget _buildHeader(List<DeviceListItem> offlineDeviceList) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(Spacing.regular),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppText.headlineMedium('Offline'),
              AppTextButton.noPadding(
                _isEdit ? 'Cancel' : 'Edit',
                onTap: () {
                  setState(() {
                    if (_isEdit) {
                      _removeIDs.clear();
                    }
                    _isEdit = !_isEdit;
                  });
                },
              )
            ],
          ),
        ),
        Padding(
            padding: const EdgeInsets.all(Spacing.regular),
            child: AppText.labelLarge('Offline (${offlineDeviceList.length})')),
        const Divider(
          height: 8,
        ),
      ],
    );
  }

  Widget _buildFooter(List<DeviceListItem> offlineDeviceList) {
    return Padding(
      padding: const EdgeInsets.all(Spacing.regular),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          AppCheckbox(
            text: 'Select all',
            value: _removeIDs.length == offlineDeviceList.length,
            onChanged: (value) {
              setState(() {
                if (value == true) {
                  _removeIDs
                    ..addAll(offlineDeviceList.map((e) => e.deviceId).toList())
                    ..unique((x) => x);
                } else {
                  _removeIDs.clear();
                }
              });
            },
          ),
          AppFilledButton(
            'Remove(${_removeIDs.length})',
            onTap: _removeIDs.isEmpty
                ? null
                : () {
                    _showConfirmDialog();
                  },
          ),
        ],
      ),
    );
  }

  void _checkedItem(String deviceId, bool? value) {
    setState(() {
      if (value == true) {
        _removeIDs
          ..add(deviceId)
          ..unique((x) => x);
      } else {
        _removeIDs.remove(deviceId);
      }
    });
  }

  void _showConfirmDialog() {
    showAdaptiveDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: AppText.bodyLarge('Remove all offline devices'),
        content: AppText.bodyLarge(
            'These devices will reappear if they reconnect to your WiFi network.'),
        actions: [
          AppTextButton('Cancel', onTap: () {
            context.pop();
          }),
          AppTextButton(
            'Clear',
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
        .deleteDevices(deviceIds: _removeIDs)
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
