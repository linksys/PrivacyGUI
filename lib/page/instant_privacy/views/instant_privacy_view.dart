import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/core/utils/extension.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/mixin/page_snackbar_mixin.dart';
import 'package:privacy_gui/page/components/shared_widgets.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/page/components/ui_kit_page_view.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:privacy_gui/page/components/views/remote_aware_switch.dart';
import 'package:privacy_gui/page/instant_device/extensions/icon_device_category_ext.dart';
import 'package:privacy_gui/page/instant_device/providers/device_list_state.dart';
import 'package:privacy_gui/page/instant_privacy/providers/instant_privacy_device_list_provider.dart';
import 'package:privacy_gui/page/instant_privacy/providers/instant_privacy_provider.dart';
import 'package:privacy_gui/page/instant_privacy/providers/instant_privacy_state.dart';
import 'package:ui_kit_library/ui_kit.dart';

class InstantPrivacyView extends ArgumentsConsumerStatefulView {
  const InstantPrivacyView({
    super.key,
    super.args,
  });

  @override
  ConsumerState<InstantPrivacyView> createState() => _InstantPrivacyViewState();
}

class _InstantPrivacyViewState extends ConsumerState<InstantPrivacyView>
    with PageSnackbarMixin {
  late final InstantPrivacyNotifier _notifier;

  @override
  void initState() {
    super.initState();
    _notifier = ref.read(instantPrivacyProvider.notifier);
    doSomethingWithSpinner(context, _notifier.fetch(forceRemote: true));
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(instantPrivacyProvider);
    final displayDevices = ref.watch(instantPrivacyDeviceListProvider);
    return UiKitPageView.withSliver(
      title: loc(context).instantPrivacy,
      markLabel: 'Beta',
      child: (context, constraints) => AppResponsiveLayout(
        desktop: (ctx) => _desktopLayout(ctx, state, displayDevices),
        mobile: (ctx) => _mobileLayout(ctx, state, displayDevices),
      ),
    );
  }

  Widget _desktopLayout(BuildContext context, InstantPrivacyState state,
      List<DeviceListItem> deviceList) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        AppText.bodyLarge(loc(context).instantPrivacyDescription),
        AppGap.xxxl(),
        if (state.settings.current.mode == MacFilterMode.deny) ...[
          _warningCard(context),
          AppGap.sm(),
        ],
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _enableTile(context, state),
                  AppGap.xxl(),
                  _deviceListView(
                      context,
                      state.settings.current.mode == MacFilterMode.allow,
                      deviceList),
                ],
              ),
            ),
            AppGap.gutter(),
            SizedBox(
              width: context.colWidth(3),
              child: _infoCard(context),
            ),
          ],
        ),
      ],
    );
  }

  Widget _mobileLayout(BuildContext context, InstantPrivacyState state,
      List<DeviceListItem> deviceList) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (state.settings.current.mode == MacFilterMode.deny) ...[
          _warningCard(context),
          AppGap.sm(),
        ],
        AppText.bodyLarge(loc(context).instantPrivacyDescription),
        AppGap.lg(),
        _enableTile(context, state),
        AppGap.sm(),
        _infoCard(context),
        AppGap.xxl(),
        _deviceListView(context,
            state.settings.current.mode == MacFilterMode.allow, deviceList),
        AppGap.xxl(),
      ],
    );
  }

  Widget _warningCard(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          AppIcon.font(
            AppFontIcons.infoCircle,
            color: Theme.of(context).colorScheme.error,
          ),
          AppGap.lg(),
          Expanded(
            child: AppText.bodyMedium(loc(context).macFilteringDisableWarning),
          ),
        ],
      ),
    );
  }

  Widget _infoCard(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppIcon.font(
            AppFontIcons.infoCircle,
            color: Theme.of(context).colorScheme.primary,
          ),
          AppGap.lg(),
          AppText.bodySmall(
            loc(context).instantPrivacyInfo,
          ),
        ],
      ),
    );
  }

  Widget _deviceListView(
      BuildContext context, bool isEnable, List<DeviceListItem> deviceList) {
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
                  ),
                  AppGap.xs(),
                  AppText.bodyMedium(
                    loc(context).theDevicesAllowedToConnect,
                  ),
                ],
              ),
            ),
            AppIconButton(
              icon: AppIcon.font(AppFontIcons.refresh),
              onTap: () {
                doSomethingWithSpinner(
                  context,
                  _notifier.fetch(forceRemote: true),
                );
              },
            ),
          ],
        ),
        AppGap.lg(),
        SizedBox(
          height: deviceList.length * 110,
          child: ListView.separated(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: deviceList.length,
            itemBuilder: (context, index) {
              return _deviceCard(context, isEnable, deviceList[index]);
            },
            separatorBuilder: (BuildContext context, int index) {
              return AppGap.sm();
            },
          ),
        ),
      ],
    );
  }

  Widget _deviceCard(
      BuildContext context, bool isEnable, DeviceListItem device) {
    final myMac = ref.watch(
        instantPrivacyProvider.select((state) => state.settings.current.myMac));
    return AppCard(
      child: Row(
        children: [
          AppIcon.font(
            IconDeviceCategoryExt.resolveByName(device.icon),
            size: 24,
          ),
          AppGap.lg(),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                    final textPainter = TextPainter(
                      text: TextSpan(
                        text: device.name,
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      maxLines: 1,
                      textDirection: TextDirection.ltr,
                    )..layout(minWidth: 0, maxWidth: double.infinity);
                    if (textPainter.size.width > constraints.maxWidth) {
                      return Tooltip(
                        message: device.name,
                        child: Text(
                          device.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                      );
                    } else {
                      return Text(
                        device.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelLarge,
                      );
                    }
                  },
                ),
                AppGap.xs(),
                AppText.bodyMedium(device.isOnline
                    ? device.ipv4Address
                    : loc(context).offline),
                AppGap.xs(),
                AppText.bodyMedium(device.macAddress),
              ],
            ),
          ),
          AppGap.xs(),
          _connectionInfo(context, device),
          AppGap.lg(),
          SharedWidgets.resolveSignalStrengthIcon(
            context,
            device.signalStrength,
            isOnline: device.isOnline,
            isWired: device.isWired,
          ),
          if (isEnable) ...[
            AppGap.lg(),
            AppIconButton(
              icon: AppIcon.font(
                AppFontIcons.delete,
                color: Theme.of(context).colorScheme.error,
              ),
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

  Widget _connectionInfo(BuildContext context, DeviceListItem device) {
    return device.isOnline
        ? AppResponsiveLayout(
            desktop: (ctx) => AppText.bodyMedium(device.isWired
                ? loc(context).ethernet
                : '${device.ssid}  •  ${device.band}'),
            mobile: (ctx) => device.isWired
                ? AppText.bodyMedium(loc(context).ethernet)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      AppText.bodyMedium(device.ssid),
                      AppGap.xs(),
                      AppText.bodyMedium(device.band),
                    ],
                  ),
          )
        : Container();
  }

  Widget _enableTile(BuildContext context, InstantPrivacyState state) {
    return AppCard(
        child: Row(
      children: [
        Expanded(child: AppText.labelLarge(loc(context).instantPrivacy)),
        RemoteAwareSwitch(
          value: state.settings.current.mode == MacFilterMode.allow,
          onChanged: (value) {
            _showEnableDialog(value);
          },
        )
      ],
    ));
  }

  void _showEnableDialog(bool enable) {
    showInstantPrivacyConfirmDialog(context, enable).then((value) {
      if (value != true || !mounted) {
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
          AppButton.text(
            label: loc(context).ok,
            onTap: () {
              context.pop();
            },
          ),
        ],
        if (!self) ...[
          AppButton.text(
            label: loc(context).cancel,
            onTap: () {
              context.pop();
            },
          ),
          AppButton.text(
            label: loc(context).delete,
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
