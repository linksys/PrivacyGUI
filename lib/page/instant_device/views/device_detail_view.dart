import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/core/data/providers/device_manager_provider.dart';
import 'package:privacy_gui/core/data/providers/device_manager_state.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/utils/extension.dart';
import 'package:privacy_gui/core/utils/icon_device_category.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/core/utils/wifi.dart';
import 'package:privacy_gui/page/advanced_settings/local_network_settings/models/dhcp_reservation_ui_model.dart';
import 'package:privacy_gui/page/advanced_settings/local_network_settings/providers/local_network_settings_provider.dart';
import 'package:privacy_gui/page/components/shared_widgets.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/page/components/shortcuts/snack_bar.dart';
import 'package:privacy_gui/page/components/ui_kit_page_view.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/dashboard/_dashboard.dart';
import 'package:privacy_gui/page/instant_device/_instant_device.dart';
import 'package:privacy_gui/page/instant_device/extensions/icon_device_category_ext.dart';
import 'package:privacy_gui/utils.dart';
import 'package:privacy_gui/validator_rules/rules.dart';
import 'package:privacy_gui/page/components/composed/app_loadable_widget.dart';
import 'package:ui_kit_library/ui_kit.dart';

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
        .select((value) => value.status.dhcpReservationList));

    setState(() {
      isReservedIp = dhcpReservationList.any((e) =>
          e.ipAddress == state.item.ipv4Address ||
          e.macAddress == state.item.macAddress);
    });
    return LayoutBuilder(
      builder: (context, constraint) {
        return UiKitPageView.withSliver(
          title: state.item.name,
          child: (context, constraints) => AppResponsiveLayout(
            desktop: (ctx) => _desktopLayout(ctx, state),
            mobile: (ctx) => _mobileLayout(ctx, state),
          ),
        );
      },
    );
  }

  Widget _desktopLayout(BuildContext context, ExternalDeviceDetailState state) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: context.colWidth(4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _avatarCard(context, state),
            ],
          ),
        ),
        AppGap.gutter(),
        SizedBox(
          width: context.colWidth(8),
          child: _detailSection(context, state),
        ),
      ],
    );
  }

  Widget _mobileLayout(BuildContext context, ExternalDeviceDetailState state) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _avatarCard(context, state),
        AppGap.sm(),
        _detailSection(context, state),
      ],
    );
  }

  Widget _avatarCard(BuildContext context, ExternalDeviceDetailState state) {
    return SelectionArea(
      child: AppCard(
        padding: EdgeInsets.all(AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: double.infinity,
              height: 120,
              child: AppIcon.font(
                IconDeviceCategoryExt.resolveByName(state.item.icon),
                size: 40,
              ),
            ),
            // Device name with edit button
            _buildSettingRow(
              context,
              title: state.item.name,
              trailing: AppIconButton(
                icon: AppIcon.font(AppFontIcons.edit),
                onTap: _showEdidDeviceModal,
              ),
            ),
            _buildSettingRow(
              context,
              title: loc(context).manufacturer,
              description: _formatEmptyValue(state.item.manufacturer),
            ),
            _buildSettingRow(
              context,
              title: loc(context).device,
              description: _formatEmptyValue(state.item.model),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailSection(BuildContext context, ExternalDeviceDetailState state) {
    final isBridge = ref.watch(dashboardHomeProvider).isBridgeMode;

    return SelectionArea(
      child: Column(
        children: [
          _buildDetailCard(
            context,
            title: loc(context).connectTo,
            description: state.item.upstreamDevice.isEmpty
                ? loc(context).unknown
                : state.item.upstreamDevice,
          ),
          if (state.item.isOnline && !state.item.isWired) ...[
            AppGap.sm(),
            _buildSsidCard(context, state),
            AppGap.sm(),
            _buildSignalStrengthCard(context, state),
          ],
          AppGap.sm(),
          _buildIpAddressCard(context, state, isBridge),
          AppGap.sm(),
          _buildDetailCard(
            context,
            title: loc(context).macAddress,
            description: _formatEmptyValue(state.item.macAddress),
          ),
          AppGap.sm(),
          _buildDetailCard(
            context,
            title: loc(context).ipv6Address,
            description: _formatEmptyValue(state.item.ipv6Address),
          ),
        ],
      ),
    );
  }

  /// Composed SettingRow to replace AppSettingCard.noBorder
  Widget _buildSettingRow(
    BuildContext context, {
    required String title,
    String? description,
    Widget? trailing,
  }) {
    return Padding(
      padding: EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Tooltip(
                  message: title,
                  child: AppText.bodyLarge(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (description != null) ...[
                  AppGap.xs(),
                  AppText.bodyMedium(description),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  /// Composed DetailCard to replace AppSettingCard
  Widget _buildDetailCard(
    BuildContext context, {
    required String title,
    required String description,
    Widget? trailing,
  }) {
    return AppCard(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.xxl,
        vertical: AppSpacing.lg,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.bodyMedium(title),
                AppGap.xs(),
                AppText.labelLarge(description),
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _buildSsidCard(BuildContext context, ExternalDeviceDetailState state) {
    return AppCard(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.xxl,
        vertical: AppSpacing.lg,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.bodyMedium(loc(context).ssid),
                AppGap.xs(),
                AppText.labelLarge(
                  _formatEmptyValue('${state.item.ssid} • ${state.item.band}'),
                ),
                if (state.item.isMLO) ...[
                  AppGap.sm(),
                  AppButton.text(
                    label: loc(context).mloCapable,
                    onTap: () {
                      showMLOCapableModal(context);
                    },
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignalStrengthCard(
      BuildContext context, ExternalDeviceDetailState state) {
    return AppCard(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.xxl,
        vertical: AppSpacing.lg,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.bodyMedium(loc(context).signalStrength),
                AppGap.xs(),
                Row(children: [
                  AppText.labelLarge(
                    getWifiSignalLevel(state.item.signalStrength)
                        .resolveLabel(context),
                    color: getWifiSignalLevel(state.item.signalStrength)
                        .resolveColor(context),
                  ),
                  AppText.labelLarge(' • '),
                  AppText.labelLarge(
                    state.item.isWired
                        ? ''
                        : _formatEmptyValue('${state.item.signalStrength} dBm'),
                  ),
                ]),
              ],
            ),
          ),
          SharedWidgets.resolveSignalStrengthIcon(
              context, state.item.signalStrength),
        ],
      ),
    );
  }

  Widget _buildIpAddressCard(
      BuildContext context, ExternalDeviceDetailState state, bool isBridge) {
    final showReserveButton = !isBridge &&
        state.item.isOnline &&
        state.item.ipv4Address.isNotEmpty &&
        state.item.type != WifiConnectionType.guest &&
        isReservedIp != null;

    return AppCard(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.xxl,
        vertical: AppSpacing.lg,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.bodyMedium(loc(context).ipAddress),
                AppGap.xs(),
                AppText.labelLarge(_formatEmptyValue(state.item.ipv4Address)),
              ],
            ),
          ),
          if (showReserveButton)
            AppLoadableWidget.textButton(
              title: isReservedIp == true
                  ? loc(context).releaseReservedIp
                  : loc(context).reserveIp,
              spinnerSize: Size(36, 36),
              onTap: (controller) async {
                await handleReserveDhcp(state.item, isReservedIp!);
              },
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
              AppGap.xxl(),
              AppTextFormField(
                controller: _deviceNameController,
                label: loc(context).deviceName,
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
              ),
              if (_errorMessage != null)
                Padding(
                  padding: EdgeInsets.only(top: 8.0),
                  child: AppText.bodySmall(
                    _errorMessage!,
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              AppGap.xxxl(),
              AppText.labelLarge(loc(context).selectIcon.capitalizeWords()),
              AppGap.xxxl(),
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
                    child: AppIcon.font(
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

  Future<dynamic> handleReserveDhcp(
      DeviceListItem item, bool isReservedIp) async {
    final notifier = ref.read(localNetworkSettingProvider.notifier);
    final dhcpReservationItem = DHCPReservationUIModel(
      description: item.name.replaceAll(HostNameRule().rule, ''),
      ipAddress: item.ipv4Address,
      macAddress: item.macAddress,
    );
    if (isReservedIp) {
      // Show dialog to release
      final delete = await _showResevedIpDialog(isReservedIp);
      if (delete) {
        final dhcpReservationList =
            ref.read(localNetworkSettingProvider).status.dhcpReservationList;
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
      // Show dialog to reserve
      final reserve = await _showResevedIpDialog(isReservedIp);
      if (reserve) {
        final isOverlap =
            notifier.isReservationOverlap(item: dhcpReservationItem);
        if (isOverlap) {
          if (!mounted) return;
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
        AppButton.text(
          label: loc(context).cancel,
          onTap: () {
            context.pop(false);
          },
        ),
        AppButton.text(
          label: isReservedIp ? loc(context).okay : loc(context).reserveIp,
          onTap: () {
            context.pop(true);
          },
        ),
      ],
    );
  }

  // !TODO
  Future _saveDhcpResevervationSetting() async {
    final state = ref.read(localNetworkSettingProvider);
    await ref
        .read(localNetworkSettingProvider.notifier)
        .saveReservations(state.status.dhcpReservationList)
        .then((_) {
      if (!mounted) return;
      // show succeed
      showSuccessSnackBar(
        context,
        loc(context).changesSaved,
      );
    }).catchError((error) {
      // show error
      final err = error as JNAPError;
      if (!mounted) return;
      showFailedSnackBar(
        context,
        err.result,
      );
    }, test: (error) => error is JNAPError);
  }
}
