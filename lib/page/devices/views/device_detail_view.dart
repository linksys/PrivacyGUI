import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/core/jnap/models/lan_settings.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_provider.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/utils/icon_device_category.dart';
import 'package:privacy_gui/core/utils/wifi.dart';
import 'package:privacy_gui/page/advanced_settings/local_network_settings/providers/local_network_settings_provider.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/page/components/shortcuts/snack_bar.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/devices/_devices.dart';
import 'package:privacy_gui/page/devices/extensions/icon_device_category_ext.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/theme/_theme.dart';
import 'package:privacygui_widgets/widgets/gap/const/spacing.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';
import 'package:privacygui_widgets/widgets/card/setting_card.dart';
import 'package:privacygui_widgets/widgets/container/responsive_layout.dart';
import 'package:privacygui_widgets/widgets/loadable_widget/loadable_widget.dart';
import 'package:privacygui_widgets/widgets/page/layout/basic_layout.dart';
import 'package:privacygui_widgets/widgets/progress_bar/spinner.dart';

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
  bool _isLoading = false;

  @override
  void dispose() {
    super.dispose();
    _deviceNameController.dispose();
  }

  @override
  void initState() {
    super.initState();
    _iconIndex = _getCurrentIconIndex();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(externalDeviceDetailProvider);
    return LayoutBuilder(
      builder: (context, constraint) {
        return StyledAppPageView(
          padding: const EdgeInsets.only(),
          title: loc(context).devices,
          scrollable: true,
          child: AppBasicLayout(
            content: ResponsiveLayout(
                desktop: _desktopLayout(state), mobile: _mobileLayout(state)),
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
          width: 3.col,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _avatarCard(state),
              const AppGap.medium(),
              _extraInfoSection(state),
            ],
          ),
        ),
        const AppGap.gutter(),
        SizedBox(
          width: 9.col,
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
        _detailSection(state),
        _extraInfoSection(state),
      ],
    );
  }

  Widget _avatarCard(ExternalDeviceDetailState state) {
    return AppCard(
      padding: const EdgeInsets.all(Spacing.small2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: double.infinity,
            height: 120,
            child: Icon(
              IconDeviceCategoryExt.resolveByName(state.item.icon),
              size: 40,
            ),
          ),
          AppSettingCard.noBorder(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
            title: state.item.name,
            trailing: AppIconButton(
              icon: LinksysIcons.edit,
              onTap: _showEditingDialog,
            ),
          ),
          AppSettingCard.noBorder(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
            title: loc(context).connectTo,
            description: state.item.upstreamDevice,
          ),
          AppSettingCard.noBorder(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
            title: loc(context).signalStrength,
            description: _formatEmptyValue('${state.item.signalStrength} dBM'),
            trailing: Icon(getWifiSignalIconData(
              context,
              state.item.isWired ? null : state.item.signalStrength,
            )),
          ),
        ],
      ),
    );
  }

  Widget _detailSection(ExternalDeviceDetailState state) {
    return Column(
      children: [
        if (!state.item.isWired)
          AppSettingCard(
            padding: const EdgeInsets.symmetric(
              horizontal: Spacing.large2,
              vertical: Spacing.medium,
            ),
            title: loc(context).wifi,
            description:
                _formatEmptyValue('${state.item.ssid} (${state.item.band})'),
          ),
        const AppGap.medium(),
        AppSettingCard(
          padding: const EdgeInsets.fromLTRB(
            Spacing.large2,
            Spacing.medium,
            Spacing.small1,
            Spacing.medium,
          ),
          title: loc(context).ipAddress,
          description: _formatEmptyValue(state.item.ipv4Address),
          trailing: AppLoadableWidget.textButton(
            title: loc(context).reserveDHCP,
            onTap: () async {
              await handleReserveDhcp(state.item);
            },
          ),
        ),
        const AppGap.medium(),
        AppSettingCard(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.large2,
            vertical: Spacing.medium,
          ),
          title: loc(context).macAddress,
          description: _formatEmptyValue(state.item.macAddress),
        ),
        const AppGap.medium(),
        AppSettingCard(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.large2,
            vertical: Spacing.medium,
          ),
          title: loc(context).ipv6Address,
          description: _formatEmptyValue(state.item.ipv6Address),
        ),
      ],
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

  _showEditingDialog() {
    _deviceNameController.text =
        ref.read(externalDeviceDetailProvider).item.name;
    _iconIndex = _getCurrentIconIndex();

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (sfbContext, sfbSetState) {
            return AlertDialog(
              title: AppText.titleLarge(
                  loc(sfbContext).deviceDetailEditDialogTitle),
              actions: _isLoading
                  ? null
                  : [
                      AppTextButton(
                        loc(sfbContext).cancel,
                        color: Theme.of(sfbContext).colorScheme.onSurface,
                        onTap: () {
                          _errorMessage = null;
                          sfbContext.pop();
                        },
                      ),
                      AppTextButton(
                        loc(sfbContext).save,
                        onTap: () {
                          _saveDevice(sfbContext, sfbSetState);
                        },
                      ),
                    ],
              content: _isLoading
                  ? const AppSpinner(
                      size: Size(400, 200),
                    )
                  : _dialogContent(sfbContext, sfbSetState),
            );
          },
        );
      },
    );
  }

  Widget _dialogContent(
    BuildContext context,
    void Function(void Function()) setState,
  ) {
    return SizedBox(
      width: 400,
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
                _errorMessage = null;
              });
            },
          ),
          const AppGap.large3(),
          AppText.labelLarge(loc(context).selectIcon),
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
                  color: index == _iconIndex
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  void _saveDevice(
    BuildContext context,
    void Function(void Function()) setState,
  ) {
    final newName = _deviceNameController.text;
    if (newName.isEmpty) {
      setState(() {
        _errorMessage = loc(context).theNameMustNotBeEmpty;
      });
      return;
    }
    // Send the request
    setState(() {
      _isLoading = true;
    });
    final newIcon = IconDeviceCategory.values[_iconIndex];
    final deviceId = ref.read(externalDeviceDetailProvider).item.deviceId;
    ref
        .read(deviceManagerProvider.notifier)
        .updateDeviceNameAndIcon(
          targetId: deviceId,
          newName: newName,
          isLocation: false,
          icon: newIcon,
        )
        .then((value) {
      setState(() {
        _isLoading = false;
      });
      context.pop();
    }).onError((error, stackTrace) {
      setState(() {
        _isLoading = false;
      });
    });
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

  Future<dynamic> handleReserveDhcp(DeviceListItem item) async {
    final notifier = ref.read(localNetworkSettingProvider.notifier);
    // Fetch lan setting
    await notifier.fetch();
    final dhcpReservationList =
        ref.read(localNetworkSettingProvider).dhcpReservationList;
    final dhcpReservationItem = DHCPReservation(
      description: item.name.replaceAll(RegExp(r' '), ''),
      ipAddress: item.ipv4Address,
      macAddress: item.macAddress,
    );
    if (dhcpReservationList.contains(dhcpReservationItem)) {
      // Show alert to delete
      final delete = await _showDeleteAlert();
      if (delete) {
        final index = dhcpReservationList.indexOf(dhcpReservationItem);
        notifier.updateDHCPReservationOfIndex(
            dhcpReservationItem.copyWith(ipAddress: 'DELETE'), index);
        await _saveDhcpResevervationSetting();
      }
    } else {
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

  Future<bool> _showDeleteAlert() async {
    return await showSimpleAppDialog(
      context,
      title: loc(context).deleteReservation,
      content: AppText.bodyMedium(loc(context).thisActionCannotBeUndone),
      actions: [
        AppTextButton(
          loc(context).cancel,
          color: Theme.of(context).colorScheme.onSurface,
          onTap: () {
            context.pop(false);
          },
        ),
        AppTextButton(
          loc(context).delete,
          color: Theme.of(context).colorScheme.error,
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
