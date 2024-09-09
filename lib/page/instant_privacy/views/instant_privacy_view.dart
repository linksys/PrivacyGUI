import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/core/jnap/providers/polling_provider.dart';
import 'package:privacy_gui/core/utils/extension.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/shared_widgets.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:privacy_gui/page/instant_device/extensions/icon_device_category_ext.dart';
import 'package:privacy_gui/page/instant_device/providers/device_list_state.dart';
import 'package:privacy_gui/page/instant_privacy/providers/instant_privacy_device_list_provider.dart';
import 'package:privacy_gui/page/instant_privacy/providers/instant_privacy_provider.dart';
import 'package:privacy_gui/page/instant_privacy/providers/instant_privacy_state.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/theme/_theme.dart';

import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';
import 'package:privacygui_widgets/widgets/container/responsive_layout.dart';
import 'package:privacygui_widgets/widgets/page/layout/basic_layout.dart';

class InstantPrivacyView extends ArgumentsConsumerStatefulView {
  const InstantPrivacyView({
    super.key,
    super.args,
  });

  @override
  ConsumerState<InstantPrivacyView> createState() => _InstantPrivacyViewState();
}

class _InstantPrivacyViewState extends ConsumerState<InstantPrivacyView> {
  late final InstantPrivacyNotifier _notifier;
  @override
  void initState() {
    _notifier = ref.read(instantPrivacyProvider.notifier);
    doSomethingWithSpinner(
      context,
      _notifier
          .fetch()
          .then((value) => ref.read(pollingProvider.notifier).forcePolling()),
    );
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(instantPrivacyProvider);
    final displayDevices = ref.watch(instantPrivacyDeviceListProvider);
    return StyledAppPageView(
      scrollable: true,
      title: loc(context).instantPrivacy,
      child: ResponsiveLayout(
        desktop: _desktopLayout(state, displayDevices),
        mobile: _mobileLayout(state, displayDevices),
      ),
    );
  }

  Widget _desktopLayout(
      InstantPrivacyState state, List<DeviceListItem> deviceList) {
    return AppBasicLayout(
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          AppText.bodyLarge(loc(context).instantPrivacyDescription),
          const AppGap.large4(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _enableTile(state),
                    const AppGap.large2(),
                    _deviceListView(
                        state.mode == MacFilterMode.allow, deviceList),
                  ],
                ),
              ),
              const AppGap.gutter(),
              SizedBox(
                width: 3.col,
                child: _infoCard(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _mobileLayout(
      InstantPrivacyState state, List<DeviceListItem> deviceList) {
    return AppBasicLayout(
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          AppText.bodyLarge(loc(context).instantPrivacyDescription),
          const AppGap.medium(),
          _enableTile(state),
          const AppGap.small2(),
          _infoCard(),
          const AppGap.large2(),
          _deviceListView(state.mode == MacFilterMode.allow, deviceList),
          const AppGap.large2(),
        ],
      ),
    );
  }

  Widget _infoCard() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            LinksysIcons.infoCircle,
            semanticLabel: 'info icon',
            color: Theme.of(context).colorScheme.primary,
          ),
          const AppGap.medium(),
          AppText.bodySmall(
            loc(context).instantPrivacyInfo,
            maxLines: 30,
          ),
        ],
      ),
    );
  }

  Widget _deviceListView(bool isEnable, List<DeviceListItem> deviceList) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.titleSmall(
          loc(context).nDevices(deviceList.length).capitalizeWords(),
          maxLines: 5,
        ),
        const AppGap.small1(),
        AppText.bodyMedium(
          loc(context).theDevicesAllowedToConnect,
          maxLines: 5,
        ),
        const AppGap.medium(),
        SizedBox(
          height: deviceList.length * 110,
          child: ListView.separated(
            itemCount: deviceList.length,
            itemBuilder: (context, index) {
              return _deviceCard(isEnable, deviceList[index]);
            },
            separatorBuilder: (BuildContext context, int index) {
              return const AppGap.small2();
            },
          ),
        ),
      ],
    );
  }

  Widget _deviceCard(bool isEnable, DeviceListItem device) {
    return AppCard(
      child: Row(
        children: [
          Icon(
            IconDeviceCategoryExt.resolveByName(device.icon),
            size: 24,
          ),
          const AppGap.medium(),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.labelLarge(device.name),
                if (device.isOnline) ...[
                  const AppGap.small1(),
                  AppText.bodyMedium(device.ipv4Address),
                ],
                const AppGap.small1(),
                AppText.bodyMedium(device.macAddress),
              ],
            ),
          ),
          const AppGap.small1(),
          _connectionInfo(device),
          const AppGap.medium(),
          SharedWidgets.resolveSignalStrengthIcon(
            context,
            device.signalStrength,
            isOnline: device.isOnline,
            isWired: device.isWired,
          ),
          if (isEnable) ...[
            const AppGap.medium(),
            AppIconButton.noPadding(
              icon: LinksysIcons.delete,
              semanticLabel: 'delete',
              color: Theme.of(context).colorScheme.error,
              onTap: () {
                _showDeleteDialog(device.macAddress);
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _connectionInfo(DeviceListItem device) {
    return device.isOnline
        ? ResponsiveLayout(
            desktop: AppText.bodyMedium(device.isWired
                ? loc(context).ethernet
                : '${device.ssid}  •  ${device.band}'),
            mobile: device.isWired
                ? AppText.bodyMedium(loc(context).ethernet)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      AppText.bodyMedium(device.ssid),
                      const AppGap.small1(),
                      AppText.bodyMedium(device.band),
                    ],
                  ),
          )
        : Container();
  }

  Widget _enableTile(InstantPrivacyState state) {
    return AppCard(
        child: Row(
      children: [
        Expanded(child: AppText.labelLarge(loc(context).instantPrivacy)),
        AppSwitch(
          value: state.mode != MacFilterMode.disabled,
          onChanged: (value) {
            _showEnableDialog(value);
          },
        )
      ],
    ));
  }

  void _showEnableDialog(bool enable) {
    showSimpleAppDialog(
      context,
      dismissible: false,
      title: enable
          ? loc(context).turnOnInstantPrivacy
          : loc(context).turnOffInstantPrivacy,
      content: AppText.bodyMedium(enable
          ? loc(context).turnOnInstantPrivacyDesc
          : loc(context).turnOffInstantPrivacyDesc),
      actions: [
        AppTextButton(
          loc(context).cancel,
          color: Theme.of(context).colorScheme.onSurface,
          onTap: () {
            context.pop();
          },
        ),
        AppTextButton(
          enable ? loc(context).turnOn : loc(context).turnOff,
          color: Theme.of(context).colorScheme.primary,
          onTap: () {
            if (enable) {
              final macAddressList = ref
                  .read(instantPrivacyDeviceListProvider)
                  .map((e) => e.macAddress.toUpperCase())
                  .toList();
              _notifier.setMacAddressList(macAddressList);
            }
            _notifier.setEnable(enable);
            context.pop();
            doSomethingWithSpinner(
              context,
              _notifier.save(),
            );
          },
        ),
      ],
    );
  }

  void _showDeleteDialog(String macAddress) {
    showSimpleAppDialog(
      context,
      dismissible: false,
      title: loc(context).deleteDevice,
      content: AppText.bodyMedium(loc(context).instantPrivacyDeleteDeviceDesc),
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
            _notifier.removeSelection([macAddress]);
            context.pop();
            doSomethingWithSpinner(
              context,
              _notifier.save(),
            );
          },
        ),
      ],
    );
  }
}
