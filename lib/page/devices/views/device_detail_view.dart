import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_provider.dart';
import 'package:privacy_gui/core/utils/icon_device_category.dart';
import 'package:privacy_gui/core/utils/wifi.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/devices/_devices.dart';
import 'package:privacy_gui/page/devices/extensions/icon_device_category_ext.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/theme/const/spacing.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';
import 'package:privacygui_widgets/widgets/card/info_card.dart';
import 'package:privacygui_widgets/widgets/container/responsive_layout.dart';
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
          width: 280,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _avatarCard(state),
              const AppGap.small(),
              _extraInfoSection(state),
            ],
          ),
        ),
        const AppGap.regular(),
        Expanded(
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
      padding: const EdgeInsets.all(Spacing.semiSmall),
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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 8, 16),
            child: Row(
              children: [
                Expanded(
                  child: AppText.labelLarge(state.item.name),
                ),
                AppIconButton(
                  icon: LinksysIcons.edit,
                  onTap: _showEditingDialog,
                )
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.bodySmall(loc(context).connectTo),
                const AppGap.small(),
                AppText.labelLarge(state.item.upstreamDevice),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText.bodySmall(loc(context).signalStrength),
                    if (!state.item.isWired) ...[
                      const AppGap.small(),
                      AppText.labelLarge(
                        _formatEmptyValue('${state.item.signalStrength} dBM'),
                      ),
                    ],
                  ],
                ),
                const Spacer(),
                Icon(getWifiSignalIconData(
                  context,
                  state.item.isWired ? null : state.item.signalStrength,
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailSection(ExternalDeviceDetailState state) {
    return Column(
      children: [
        if (!state.item.isWired)
          AppInfoCard(
            padding: const EdgeInsets.symmetric(
              horizontal: Spacing.semiBig,
              vertical: Spacing.regular,
            ),
            title: loc(context).wifi,
            description:
                _formatEmptyValue('${state.item.ssid} (${state.item.band})'),
          ),
        AppInfoCard(
          padding: const EdgeInsets.fromLTRB(
            Spacing.semiBig,
            Spacing.regular,
            Spacing.small,
            Spacing.regular,
          ),
          title: loc(context).ipAddress,
          description: _formatEmptyValue(state.item.ipv4Address),
          trailing: AppTextButton(
            loc(context).reserveDHCP,
            onTap: () {
              //TODO: Show ReserveDHCP view
            },
          ),
        ),
        AppInfoCard(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.semiBig,
            vertical: Spacing.regular,
          ),
          title: loc(context).macAddress,
          description: _formatEmptyValue(state.item.macAddress),
        ),
        AppInfoCard(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.semiBig,
            vertical: Spacing.regular,
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
          AppInfoCard(
            showBorder: false,
            padding: const EdgeInsets.fromLTRB(
              Spacing.semiSmall,
              0,
              Spacing.semiSmall,
              Spacing.semiSmall,
            ),
            title: loc(context).manufacturer,
            description: _formatEmptyValue(state.item.manufacturer),
          ),
          const Divider(
            height: 8,
            thickness: 1,
          ),
          AppInfoCard(
            showBorder: false,
            padding: const EdgeInsets.fromLTRB(
              Spacing.semiSmall,
              Spacing.semiSmall,
              Spacing.semiSmall,
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
          const AppGap.semiBig(),
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
          const AppGap.big(),
          AppText.labelLarge(loc(context).selectIcon),
          const AppGap.big(),
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
        _errorMessage = 'The name must not be empty';
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
}
