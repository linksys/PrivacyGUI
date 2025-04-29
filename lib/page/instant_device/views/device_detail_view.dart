import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/core/jnap/models/lan_settings.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_provider.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_state.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/utils/extension.dart';
import 'package:privacy_gui/core/utils/icon_device_category.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/core/utils/wifi.dart';
import 'package:privacy_gui/page/advanced_settings/local_network_settings/providers/local_network_settings_provider.dart';
import 'package:privacy_gui/page/components/shared_widgets.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/page/components/shortcuts/snack_bar.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/dashboard/_dashboard.dart';
import 'package:privacy_gui/page/dashboard/providers/dashboard_home_provider.dart';
import 'package:privacy_gui/page/instant_device/_instant_device.dart';
import 'package:privacy_gui/page/instant_device/extensions/icon_device_category_ext.dart';
import 'package:privacy_gui/utils.dart';
import 'package:privacy_gui/validator_rules/rules.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/theme/_theme.dart';
import 'package:privacygui_widgets/widgets/card/list_card.dart';
import 'package:privacygui_widgets/widgets/gap/const/spacing.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';
import 'package:privacygui_widgets/widgets/card/setting_card.dart';
import 'package:privacygui_widgets/widgets/container/responsive_layout.dart';
import 'package:privacygui_widgets/widgets/loadable_widget/loadable_widget.dart';
import 'package:privacygui_widgets/widgets/page/layout/basic_layout.dart';

class DeviceDetailView extends ArgumentsConsumerStatefulView {
  const DeviceDetailView({
    Key? key,
    super.args,
  }) : super(key: key);

  @override
  ConsumerState<DeviceDetailView> createState() => _DeviceDetailViewState();
}

class _DeviceDetailViewState extends ConsumerState<DeviceDetailView> {
  final TextEditingController _deviceNameController = TextEditingController();
  late int _iconIndex;
  String? _errorMessage;
  bool? isReservedIp;

  @override
  void dispose() {
    super.dispose();
    _deviceNameController.dispose();
  }

  @override
  void initState() {
    super.initState();
    _iconIndex = _getCurrentIconIndex();

    // Fetch lan setting
    ref.read(localNetworkSettingProvider.notifier).fetch();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(externalDeviceDetailProvider);
    final dhcpReservationList = ref.watch(localNetworkSettingProvider
        .select((value) => value.dhcpReservationList));

    setState(() {
      isReservedIp = dhcpReservationList.any((e) =>
          e.ipAddress == state.item.ipv4Address ||
          e.macAddress == state.item.macAddress);
    });
    return LayoutBuilder(
      builder: (context, constraint) {
        return StyledAppPageView(
          padding: const EdgeInsets.only(),
          title: state.item.name,
          scrollable: true,
          child: AppBasicLayout(
            content: ResponsiveLayout(
              desktop: _desktopLayout(state),
              mobile: _mobileLayout(state),
            ),
          ),
        );
      },
    );
  }

  Widget _desktopLayout(ExternalDeviceDetailState state) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 4.col,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _avatarCard(state),
            ],
          ),
        ),
        const AppGap.gutter(),
        SizedBox(
          width: 8.col,
          child: _detailSection(state),
        ),
      ],
    );
  }

  Widget _mobileLayout(ExternalDeviceDetailState state) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _avatarCard(state),
        const AppGap.small2(),
        _detailSection(state),
      ],
    );
  }

  Widget _avatarCard(ExternalDeviceDetailState state) {
    return SelectionArea(
      child: AppCard(
        padding: const EdgeInsets.all(Spacing.small2),
        color: Theme.of(context).colorScheme.background,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: double.infinity,
              height: 120,
              child: Icon(
                IconDeviceCategoryExt.resolveByName(state.item.icon),
                semanticLabel: state.item.icon,
                size: 40,
              ),
            ),
            AppSettingCard.noBorder(
              padding: const EdgeInsets.all(Spacing.medium),
              color: Theme.of(context).colorScheme.background,
              title: state.item.name,
              trailing: AppIconButton(
                icon: LinksysIcons.edit,
                semanticLabel: 'edit',
                onTap: _showEdidDeviceModal,
              ),
            ),
            AppSettingCard.noBorder(
              padding: const EdgeInsets.all(Spacing.medium),
              color: Theme.of(context).colorScheme.background,
              title: loc(context).manufacturer,
              description: _formatEmptyValue(state.item.manufacturer),
            ),
            AppSettingCard.noBorder(
              padding: const EdgeInsets.all(Spacing.medium),
              color: Theme.of(context).colorScheme.background,
              title: loc(context).device,
              description: _formatEmptyValue(state.item.model),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailSection(ExternalDeviceDetailState state) {
    final isBridge = ref.watch(dashboardHomeProvider).isBridgeMode;

    return SelectionArea(
      child: Column(
        children: [
          AppSettingCard(
            padding: const EdgeInsets.symmetric(
              horizontal: Spacing.large2,
              vertical: Spacing.medium,
            ),
            title: loc(context).connectTo,
            description: state.item.upstreamDevice.isEmpty
                ? loc(context).unknown
                : state.item.upstreamDevice,
          ),
          if (state.item.isOnline && !state.item.isWired) ...[
            const AppGap.small2(),
            AppListCard(
              padding: const EdgeInsets.symmetric(
                horizontal: Spacing.large2,
                vertical: Spacing.medium,
              ),
              title: AppText.bodyMedium(loc(context).ssid),
              description: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText.labelLarge(_formatEmptyValue(
                      '${state.item.ssid} • ${state.item.isMLO ? '6GHz, 5GHz' : state.item.band}')),
                  if (state.item.isMLO) ...[
                    const AppGap.small2(),
                    AppTextButton.noPadding(
                      loc(context).mloCapable,
                      onTap: () {
                        showMLOCapableModal(context);
                      },
                    ),
                  ],
                ],
              ),
            ),
            const AppGap.small2(),
            AppListCard(
              padding: const EdgeInsets.symmetric(
                horizontal: Spacing.large2,
                vertical: Spacing.medium,
              ),
              title: AppText.bodyMedium(loc(context).signalStrength),
              description: Row(children: [
                AppText.labelLarge(
                  getWifiSignalLevel(state.item.signalStrength)
                      .resolveLabel(context),
                  color: getWifiSignalLevel(state.item.signalStrength)
                      .resolveColor(context),
                ),
                const AppText.labelLarge(' • '),
                AppText.labelLarge(
                  state.item.isWired
                      ? ''
                      : _formatEmptyValue('${state.item.signalStrength} dBM'),
                ),
              ]),
              trailing: SharedWidgets.resolveSignalStrengthIcon(
                  context, state.item.signalStrength),
            ),
          ],
          const AppGap.small2(),
          AppSettingCard(
            padding: const EdgeInsets.symmetric(
                horizontal: Spacing.large2, vertical: Spacing.medium),
            title: loc(context).ipAddress,
            description: _formatEmptyValue(state.item.ipv4Address),
            trailing: !isBridge &&
                    state.item.isOnline &&
                    state.item.ipv4Address.isNotEmpty &&
                    state.item.type != WifiConnectionType.guest &&
                    isReservedIp != null
                ? AppLoadableWidget.textButton(
                    spinnerSize: Size(36, 36),
                    title: isReservedIp == true
                        ? loc(context).releaseReservedIp
                        : loc(context).reserveIp,
                    semanticsLabel: isReservedIp == true
                        ? 'release reserved ip'
                        : 'reserved ip',
                    padding: const EdgeInsets.only(),
                    showSpinnerWhenTap: false,
                    onTap: (AppLoadableWidgetController controller) async {
                      await handleReserveDhcp(
                          state.item, isReservedIp!, controller);
                    },
                  )
                : null,
          ),
          const AppGap.small2(),
          AppSettingCard(
            padding: const EdgeInsets.symmetric(
              horizontal: Spacing.large2,
              vertical: Spacing.medium,
            ),
            title: loc(context).macAddress,
            description: _formatEmptyValue(state.item.macAddress),
          ),
          const AppGap.small2(),
          AppSettingCard(
            padding: const EdgeInsets.symmetric(
              horizontal: Spacing.large2,
              vertical: Spacing.medium,
            ),
            title: loc(context).ipv6Address,
            description: _formatEmptyValue(state.item.ipv6Address),
          ),
        ],
      ),
    );
  }

  Widget _extraInfoSection(ExternalDeviceDetailState state) {
    return AppCard(
      child: Column(
        // crossAxisAlignment: CrossAxisAlignment.start,
        // mainAxisSize: MainAxisSize.min,
        children: [
          AppSettingCard(
            showBorder: false,
            padding: const EdgeInsets.fromLTRB(
              Spacing.small2,
              0,
              Spacing.small2,
              Spacing.small2,
            ),
            title: loc(context).manufacturer,
            description: _formatEmptyValue(state.item.manufacturer),
          ),
          const Divider(
            height: 8,
            thickness: 1,
          ),
          AppSettingCard(
            showBorder: false,
            padding: const EdgeInsets.fromLTRB(
              Spacing.small2,
              Spacing.small2,
              Spacing.small2,
              0,
            ),
            title: loc(context).device,
            description: state.item.model,
          ),
        ],
      ),
    );
  }

  _showEdidDeviceModal() {
    _deviceNameController.text =
        ref.read(externalDeviceDetailProvider).item.name;
    _iconIndex = _getCurrentIconIndex();
    _errorMessage = _deviceNameController.text.isEmpty ? 'empty' : null;
    return showSubmitAppDialog(context,
        title: loc(context).deviceNameAndIcon,
        contentBuilder: (context, setState, onSubmit) {
          return _dialogContent(context, setState, onSubmit);
        },
        event: _saveDevice,
        checkPositiveEnabled: () => _errorMessage == null);
  }

  Widget _dialogContent(
    BuildContext context,
    void Function(void Function()) setState,
    void Function() onSubmit,
  ) {
    return SingleChildScrollView(
      child: SizedBox(
        width: 400,
        child: Semantics(
          explicitChildNodes: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const AppGap.large2(),
              AppTextField.outline(
                controller: _deviceNameController,
                headerText: loc(context).deviceName,
                errorText: _errorMessage,
                onChanged: (text) {
                  setState(() {
                    final overMaxSize =
                        utf8.encoder.convert(text).length >= 256;
                    _errorMessage = text.isEmpty
                        ? loc(context).theNameMustNotBeEmpty
                        : overMaxSize
                            ? loc(context).deviceNameExceedMaxSize
                            : null;
                  });
                },
                onSubmitted: (_) {
                  if (_errorMessage != null) {
                    onSubmit();
                  }
                },
              ),
              const AppGap.large3(),
              AppText.labelLarge(loc(context).selectIcon.capitalizeWords()),
              const AppGap.large3(),
              GridView.builder(
                shrinkWrap: true,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 6,
                ),
                itemCount: IconDeviceCategory.values.length,
                itemBuilder: ((context, index) {
                  return InkWell(
                    onTap: () {
                      setState(() {
                        _iconIndex = index;
                      });
                    },
                    child: Icon(
                      IconDeviceCategoryExt.resolveByName(
                        IconDeviceCategory.values[index].name,
                      ),
                      semanticLabel: IconDeviceCategory.values[index].name,
                      color: index == _iconIndex
                          ? Theme.of(context).colorScheme.primary
                          : null,
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future _saveDevice() {
    final newName = _deviceNameController.text;

    final newIcon = IconDeviceCategory.values[_iconIndex];
    final deviceId = ref.read(externalDeviceDetailProvider).item.deviceId;
    return ref.read(deviceManagerProvider.notifier).updateDeviceNameAndIcon(
          targetId: deviceId,
          newName: newName,
          isLocation: false,
          icon: newIcon,
        );
  }

  int _getCurrentIconIndex() {
    final currentIconValue = ref.read(externalDeviceDetailProvider).item.icon;
    return IconDeviceCategory.values.indexWhere((element) {
      return element.name == currentIconValue;
    });
  }

  String _formatEmptyValue(String? value) {
    return (value == null || value.isEmpty) ? '--' : value;
  }

  Future<dynamic> handleReserveDhcp(DeviceListItem item, bool isReservedIp,
      AppLoadableWidgetController controller) async {
    final notifier = ref.read(localNetworkSettingProvider.notifier);
    final dhcpReservationItem = DHCPReservation(
      description: item.name.replaceAll(HostNameRule().rule, ''),
      ipAddress: item.ipv4Address,
      macAddress: item.macAddress,
    );
    if (isReservedIp) {
      // Show dialog to release
      final delete = await _showResevedIpDialog(isReservedIp);
      if (delete) {
        controller.showSpinner();
        final dhcpReservationList =
            ref.read(localNetworkSettingProvider).dhcpReservationList;
        final hit = dhcpReservationList.firstWhereOrNull((e) =>
            e.ipAddress == dhcpReservationItem.ipAddress ||
            e.macAddress == dhcpReservationItem.macAddress);
        if (hit == null) {
          logger.d('not found reserved item!');
          return;
        }
        final index = dhcpReservationList.indexOf(hit);
        notifier.updateDHCPReservationOfIndex(
            dhcpReservationItem.copyWith(ipAddress: 'DELETE'), index);
        await _saveDhcpResevervationSetting();
      }
    } else {
      // Show dialog to release
      final reserve = await _showResevedIpDialog(isReservedIp);
      if (reserve) {
        controller.showSpinner();
        final isOverlap =
            notifier.isReservationOverlap(item: dhcpReservationItem);
        if (isOverlap) {
          // Show overlap
          showFailedSnackBar(
            context,
            loc(context).ipOrMacAddressOverlap,
          );
        } else {
          // Save setting
          notifier.updateDHCPReservationList([dhcpReservationItem]);
          await _saveDhcpResevervationSetting();
        }
      }
    }
  }

  Future<bool> _showResevedIpDialog(bool isReservedIp) async {
    return await showSimpleAppDialog(
      context,
      title: isReservedIp
          ? loc(context).releaseReservedIp
          : loc(context).reserveIp,
      content: AppText.bodyMedium(isReservedIp
          ? loc(context).releaseReservedIpDescription
          : loc(context).reservedIpDescription),
      actions: [
        AppTextButton(
          loc(context).cancel,
          color: Theme.of(context).colorScheme.onSurface,
          onTap: () {
            context.pop(false);
          },
        ),
        AppTextButton(
          isReservedIp ? loc(context).okay : loc(context).reserveIp,
          onTap: () {
            context.pop(true);
          },
        ),
      ],
    );
  }

  Future _saveDhcpResevervationSetting() async {
    final state = ref.read(localNetworkSettingProvider);
    await ref
        .read(localNetworkSettingProvider.notifier)
        .saveSettings(state)
        .then((_) {
      // show succeed
      showSuccessSnackBar(
        context,
        loc(context).changesSaved,
      );
    }).catchError((error) {
      // show error
      final err = error as JNAPError;
      showFailedSnackBar(
        context,
        err.result,
      );
    }, test: (error) => error is JNAPError);
  }
}
