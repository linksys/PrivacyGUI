import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_state.dart';
import 'package:privacy_gui/page/advanced_settings/local_network_settings/providers/dhcp_reservations_provider.dart';
import 'package:privacy_gui/page/advanced_settings/local_network_settings/providers/dhcp_reservations_state.dart';
import 'package:privacy_gui/page/components/mixin/page_snackbar_mixin.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/theme/_theme.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';
import 'package:privacygui_widgets/widgets/card/list_card.dart';
import 'package:privacygui_widgets/widgets/container/responsive_layout.dart';
import 'package:privacygui_widgets/widgets/gap/const/spacing.dart';
import 'package:privacygui_widgets/widgets/input_field/ip_form_field.dart';
import 'package:privacygui_widgets/widgets/page/layout/basic_layout.dart';

import 'package:privacy_gui/core/jnap/models/lan_settings.dart';
import 'package:privacy_gui/core/utils/extension.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/advanced_settings/local_network_settings/providers/local_network_settings_provider.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:privacy_gui/page/instant_device/_instant_device.dart';
import 'package:privacy_gui/page/instant_device/views/devices_filter_widget.dart';
import 'package:privacy_gui/validator_rules/input_validators.dart';
import 'package:privacy_gui/validator_rules/rules.dart';

class DHCPReservationsView extends ArgumentsConsumerStatelessView {
  const DHCPReservationsView({super.key, super.args});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DHCPReservationsContentView(
      args: super.args,
    );
  }
}

class DHCPReservationsContentView extends ArgumentsConsumerStatefulView {
  const DHCPReservationsContentView({super.key, super.args});

  @override
  ConsumerState<DHCPReservationsContentView> createState() =>
      _DHCPReservationsContentViewState();
}

class _DHCPReservationsContentViewState
    extends ConsumerState<DHCPReservationsContentView> with PageSnackbarMixin {
  @override
  void initState() {
    super.initState();

    Future.doWhile(() => !mounted).then((value) {
      ref.read(deviceFilterConfigProvider.notifier).initFilter();
      final reservations = ref.read(localNetworkSettingProvider
          .select((state) => state.status.dhcpReservationList));
      ref
          .read(dhcpReservationProvider.notifier)
          .setInitialReservations(reservations);
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dhcpReservationProvider);
    final notifier = ref.read(dhcpReservationProvider.notifier);
    ref.listen(filteredDeviceListProvider, (prev, next) {
      ref.read(dhcpReservationProvider.notifier).updateDevices(next
          .where((e) =>
              e.ipv4Address.isNotEmpty && e.type != WifiConnectionType.guest)
          .toList());
    });

    return StyledAppPageView(
      scrollable: true,
      title: loc(context).dhcpReservations.capitalizeWords(),
      bottomBar: PageBottomBar(
          isPositiveEnabled: notifier.isDirty(),
          onPositiveTap: () {
            doSomethingWithSpinner(
                context,
                notifier.save().then((_) {
                  showChangesSavedSnackBar();
                })).then((_) {
              ref.read(dhcpReservationProvider.notifier).revert();
            });
          }),
      actions: [
        AppTextButton.noPadding(
          loc(context).add,
          key: Key('addReservationButton'),
          icon: LinksysIcons.add,
          onTap: () {
            _showManualAddReservationModal();
          },
        )
      ],
      child: (context, constraints) => AppBasicLayout(
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText.bodyLarge(loc(context).dhcpReservationDescption),
            const AppGap.large2(),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (ResponsiveLayout.isDesktopLayout(context))
                  SizedBox(
                    width: 4.col,
                    child: AppCard(
                      child: DevicesFilterWidget(
                        onlineOnly: true,
                      ),
                    ),
                  ),
                const AppGap.gutter(),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: AppText.labelLarge(
                              loc(context).nReservedAddresses(state
                                  .settings.current.reservations
                                  .where((e) => e.reserved)
                                  .length),
                            ),
                          ),
                          if (ResponsiveLayout.isMobileLayout(context))
                            AppIconButton(
                              icon: LinksysIcons.filter,
                              onTap: () {
                                showSimpleAppOkDialog(
                                  context,
                                  content: SingleChildScrollView(
                                    child: DevicesFilterWidget(
                                      onlineOnly: true,
                                    ),
                                  ),
                                );
                              },
                            )
                        ],
                      ),
                      const AppGap.medium(),
                      reservedAddresses(),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget reservedAddresses() {
    final state = ref.watch(dhcpReservationProvider);
    final list = [
      ...state.settings.current.reservations,
      ...state.status.devices.where((e) => !state.settings.current.reservations
          .any((r) => r.data.macAddress == e.data.macAddress)),
    ]..sort((a, b) => a.reserved
        ? -1
        : b.reserved
            ? 1
            : 0);
    return list.isEmpty
        ? SizedBox.shrink()
        : SizedBox(
            height: list.length * 108 + 16,
            // height: constraint.maxHeight,
            child: ListView.separated(
              itemCount: list.length,
              itemBuilder: (context, index) {
                final item = list[index];
                final isConflictItem =
                    ref.read(dhcpReservationProvider.notifier).isConflict(item);
                return Opacity(
                  opacity: !item.reserved && isConflictItem ? 0.5 : 1,
                  child: AppListCard(
                    color: item.reserved
                        ? Theme.of(context).colorScheme.secondaryContainer
                        : Theme.of(context).colorScheme.surface,
                    borderColor: item.reserved
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.outline,
                    title: AppText.labelMedium(item.data.description),
                    leading: AppCheckbox(value: item.reserved),
                    trailing: item.reserved
                        ? AppIconButton(
                            icon: LinksysIcons.edit,
                            onTap: () {
                              _showManualAddReservationModal(item);
                            },
                          )
                        : null,
                    description: AppText.bodyMedium(
                        "IP: ${item.data.ipAddress}\nMAC: ${item.data.macAddress}"),
                    onTap: (!item.reserved && isConflictItem)
                        ? null
                        : () {
                            ref
                                .read(dhcpReservationProvider.notifier)
                                .updateReservations(item);
                          },
                  ),
                );
              },
              separatorBuilder: (BuildContext context, int index) {
                return index ==
                        (state.settings.current.reservations
                                .where((e) => e.reserved)
                                .length -
                            1)
                    ? const Divider(
                        height: Spacing.large2,
                      )
                    : const AppGap.medium();
              },
            ),
          );
  }

  Future _showManualAddReservationModal([
    ReservedListItem? item,
  ]) {
    final reservationList =
        ref.watch(dhcpReservationProvider).settings.current.reservations;
    final routerIp =
        ref.watch(localNetworkSettingProvider).settings.current.ipAddress;
    final subnetMask =
        ref.watch(localNetworkSettingProvider).settings.current.subnetMask;
    final subnetToken = subnetMask.split('.');
    final deviceNameController = TextEditingController()
      ..text = item?.data.description ?? '';
    final ipController = TextEditingController()
      ..text = item?.data.ipAddress ?? routerIp;
    final macController = TextEditingController()
      ..text = item?.data.macAddress ?? '';

    bool enableSave = false;
    bool isNameValid(String name) => !HostNameRule().validate(name);
    bool isIpValid(String ip) =>
        IpAddressAsLocalIpValidator(routerIp, subnetMask).validate(ip) &&
        !reservationList.any(
            (e) => e == item ? false : (e.reserved && e.data.ipAddress == ip));
    bool isMacValid(String mac) =>
        MACAddressWithReservedRule().validate(mac) &&
        !reservationList.any((e) => e == item
            ? false
            : (e.reserved &&
                e.data.macAddress.toUpperCase() == mac.toUpperCase()));
    bool updateEnableSave() {
      final name = deviceNameController.text;
      final ip = ipController.text;
      final mac = macController.text;
      bool allFilled = name.isNotEmpty && ip.isNotEmpty && mac.isNotEmpty;
      bool edited = name != item?.data.description ||
          ip != item?.data.ipAddress ||
          mac != item?.data.macAddress;

      return allFilled &&
          edited &&
          isMacValid(mac) &&
          isNameValid(name) &&
          isIpValid(ip);
    }

    return showSubmitAppDialog(context,
        title: item == null
            ? loc(context).manuallyAddReservation
            : loc(context).edit,
        positiveLabel: item == null ? loc(context).save : loc(context).update,
        contentBuilder: (context, setState, onSubmit) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppTextField(
                key: Key('deviceNameTextField'),
                headerText: loc(context).deviceName,
                controller: deviceNameController,
                border: const OutlineInputBorder(),
                errorText: !(isNameValid(deviceNameController.text))
                    ? loc(context).invalidCharacters
                    : null,
                onChanged: (value) {
                  setState(() {
                    enableSave = updateEnableSave();
                  });
                },
              ),
              const AppGap.large3(),
              AppIPFormField(
                key: Key('ipAddressTextField'),
                header: AppText.bodySmall(loc(context).assignIpAddress),
                semanticLabel: 'assign ip address',
                controller: ipController,
                border: const OutlineInputBorder(),
                octet1ReadOnly: subnetToken[0] == '255',
                octet2ReadOnly: subnetToken[1] == '255',
                octet3ReadOnly: subnetToken[2] == '255',
                octet4ReadOnly: subnetToken[3] == '255',
                onChanged: (value) {
                  setState(() {
                    enableSave = updateEnableSave();
                  });
                },
                errorText: isIpValid(ipController.text)
                    ? null
                    : loc(context).invalidIpOrSameAsHostIp,
              ),
              const AppGap.large3(),
              AppTextField.macAddress(
                key: Key('macAddressTextField'),
                headerText: loc(context).macAddress,
                semanticLabel: 'mac address',
                controller: macController,
                border: const OutlineInputBorder(),
                errorText: !isMacValid(macController.text)
                    ? loc(context).invalidMACAddress
                    : null,
                onChanged: (value) {
                  setState(() {
                    enableSave = updateEnableSave();
                  });
                },
              ),
            ],
          );
        },
        event: () async {
          final name = deviceNameController.text;
          final ip = ipController.text;
          final mac = macController.text;
          item == null
              ? ref.read(dhcpReservationProvider.notifier).updateReservations(
                    ReservedListItem(
                      reserved: true,
                      data: DHCPReservation(
                          macAddress: mac, ipAddress: ip, description: name),
                    ),
                    true,
                  )
              : ref
                  .read(dhcpReservationProvider.notifier)
                  .updateReservationItem(item, name, ip, mac);
        },
        checkPositiveEnabled: () => enableSave);
  }
}
