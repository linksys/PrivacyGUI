import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/core/jnap/providers/polling_provider.dart';
import 'package:privacy_gui/core/utils/extension.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/customs/animated_refresh_container.dart';
import 'package:privacy_gui/page/components/mixin/page_snackbar_mixin.dart';
import 'package:privacy_gui/page/components/mixin/preserved_state_mixin.dart';
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
import 'package:privacygui_widgets/widgets/card/setting_card.dart';
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

class _InstantPrivacyViewState extends ConsumerState<InstantPrivacyView>
    with
        PreservedStateMixin<InstantPrivacyState, InstantPrivacyView>,
        PageSnackbarMixin {
  late final InstantPrivacyNotifier _notifier;
  bool _isRefreshing = false;

  @override
  void initState() {
    _notifier = ref.read(instantPrivacyProvider.notifier);
    doSomethingWithSpinner(
      context,
      _notifier.fetch().then((value) {
        preservedState = value;
        _notifier.doPolling();
      }),
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
      markLabel: 'Beta',
      child: (context, constraints, scrollController) =>ResponsiveLayout(
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
          if (preservedState?.mode == MacFilterMode.deny) ...[
            _warningCard(),
            const AppGap.small2(),
          ],
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
          if (preservedState?.mode == MacFilterMode.deny) ...[
            _warningCard(),
            const AppGap.small2(),
          ],
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

  Widget _warningCard() {
    return AppSettingCard(
      title: loc(context).macFilteringDisableWarning,
      leading: Icon(
        LinksysIcons.infoCircle,
        color: Theme.of(context).colorScheme.error,
      ),
      borderColor: Theme.of(context).colorScheme.error,
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
        Row(
          children: [
            Expanded(
              child: Column(
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
                ],
              ),
            ),
            AnimatedRefreshContainer(builder: (controller) {
              return AppIconButton(
                icon: LinksysIcons.refresh,
                color: Theme.of(context).colorScheme.primary,
                onTap: () {
                  setState(() {
                    _isRefreshing = true;
                  });
                  controller.repeat();
                  ref
                      .read(pollingProvider.notifier)
                      .forcePolling()
                      .then((value) {
                    controller.stop();
                    setState(() {
                      _isRefreshing = false;
                    });
                  });
                },
              );
            }),
          ],
        ),
        const AppGap.medium(),
        SizedBox(
          height: deviceList.length * 110,
          child: ListView.separated(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
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
    final myMac =
        ref.watch(instantPrivacyProvider.select((state) => state.myMac));
    return AppCard(
      color:
          device.isOnline ? null : Theme.of(context).colorScheme.surfaceVariant,
      borderColor:
          device.isOnline ? null : Theme.of(context).colorScheme.outlineVariant,
      child: Row(
        children: [
          Icon(
            IconDeviceCategoryExt.resolveByName(device.icon),
            semanticLabel: 'device icon',
            size: 24,
          ),
          const AppGap.medium(),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                    final textPainter = TextPainter(
                      text: TextSpan(
                        text: device.name,
                        style: Theme.of(context)
                            .textTheme
                            .labelLarge, // Use your actual text style
                      ),
                      maxLines: 1, // Use your actual maxLines value
                      textDirection:
                          TextDirection.ltr, // Use your actual text direction
                    )..layout(minWidth: 0, maxWidth: double.infinity);
                    if (textPainter.size.width > constraints.maxWidth) {
                      return Tooltip(
                        message: device.name,
                        child: AppText.labelLarge(
                          device.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    } else {
                      return AppText.labelLarge(
                        device.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      );
                    }
                  },
                ),
                const AppGap.small1(),
                AppText.bodyMedium(device.isOnline
                    ? device.ipv4Address
                    : loc(context).offline),
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
                _showDeleteDialog(
                    device.macAddress, device.macAddress == myMac);
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
          semanticLabel: 'instant privacy',
          value: state.mode == MacFilterMode.allow,
          onChanged: _isRefreshing
              ? null
              : (value) {
                  _showEnableDialog(value);
                },
        )
      ],
    ));
  }

  void _showEnableDialog(bool enable) {
    showInstantPrivacyConfirmDialog(context, enable).then((value) {
      if (value != true) {
        return;
      }
      if (enable) {
        final macAddressList = ref
            .read(instantPrivacyDeviceListProvider)
            .map((e) => e.macAddress.toUpperCase())
            .toList();
        _notifier.setMacAddressList(macAddressList);
      }
      _notifier.setEnable(enable);
      doSomethingWithSpinner(
        context,
        _notifier.save(),
      ).then((state) {
        preservedState = state;
        showChangesSavedSnackBar();
      }).onError((error, stackTrace) {
        showErrorMessageSnackBar(error);
      });
    });
  }

  void _showDeleteDialog(String macAddress, bool self) {
    showSimpleAppDialog(
      context,
      dismissible: false,
      title: self ? loc(context).alertExclamation : loc(context).deleteDevice,
      content: AppText.bodyMedium(self
          ? loc(context).instantPrivacyNotAllowDeleteCurrent
          : loc(context).instantPrivacyDeleteDeviceDesc),
      actions: [
        if (self) ...[
          AppTextButton(
            loc(context).ok,
            onTap: () {
              context.pop();
            },
          ),
        ],
        if (!self) ...[
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
      ],
    );
  }
}
