import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/advanced_settings/local_network_settings/providers/dhcp_reservations_provider.dart';
import 'package:privacy_gui/page/advanced_settings/local_network_settings/providers/dhcp_reservations_state.dart';
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
    extends ConsumerState<DHCPReservationsContentView> {
  DHCPReservationState? _preservedState;
  @override
  void initState() {
    super.initState();

    Future.doWhile(() => !mounted).then((value) {
      ref.read(deviceFilterConfigProvider.notifier).initFilter();
      final reservations = ref.read(localNetworkSettingProvider
          .select((state) => state.dhcpReservationList));
      _preservedState = ref
          .read(dhcpReservationProvider.notifier)
          .setReservations(reservations);
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dhcpReservationProvider);
    ref.listen(filteredDeviceListProvider, (prev, next) {
      ref.read(dhcpReservationProvider.notifier).updateDevices(next);
    });

    return StyledAppPageView(
      scrollable: true,
      title: loc(context).dhcpReservations.capitalizeWords(),
      bottomBar: PageBottomBar(
          isPositiveEnabled: !ListEquality()
              .equals(state.reservations, _preservedState?.reservations),
          onPositiveTap: () {
            final reservations = ref
                .read(dhcpReservationProvider)
                .reservations
                .where((e) => e.reserved)
                .map((e) => e.data)
                .toList();
            doSomethingWithSpinner(
                    context,
                    ref
                        .read(localNetworkSettingProvider.notifier)
                        .saveReservations(reservations))
                .then((state) {
              setState(() {
                _preservedState = ref
                    .read(dhcpReservationProvider.notifier)
                    .setReservations(state ?? []);
              });
            });
          }),
      actions: [
        AppTextButton.noPadding(
          loc(context).add,
          icon: LinksysIcons.add,
          onTap: () {
            _showManualAddReservationModal();
          },
        )
      ],
      child: AppBasicLayout(
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
                      ))),
                const AppGap.gutter(),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: AppText.labelLarge(loc(context)
                                .nReservedAddresses(state.reservations
                                    .where((e) => e.reserved)
                                    .length)
                                .capitalizeWords()),
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
      ...state.reservations,
      ...state.devices.where((e) => !state.reservations
          .any((r) => r.data.macAddress == e.data.macAddress)),
    ]..sort((a, b) => a.reserved
        ? -1
        : b.reserved
            ? 1
            : 0);
    return list.isEmpty
        ? SizedBox.shrink()
        : SizedBox(
            height: list.length * 100,
            // height: constraint.maxHeight,
            child: ListView.separated(
              itemCount: list.length,
              itemBuilder: (context, index) {
                final item = list[index];
                return AppListCard(
                  color: item.reserved
                      ? Theme.of(context).colorScheme.secondaryContainer
                      : Theme.of(context).colorScheme.surface,
                  borderColor: item.reserved
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.outline,
                  title: AppText.labelMedium(item.data.description),
                  leading: AppCheckbox(value: item.reserved),
                  description: AppText.bodyMedium(
                      "IP: ${item.data.ipAddress}\nMAC: ${item.data.macAddress}"),
                  onTap: () {
                    ref
                        .read(dhcpReservationProvider.notifier)
                        .updateReservations(item);
                  },
                );
              },
              separatorBuilder: (BuildContext context, int index) {
                return index ==
                        (state.reservations.where((e) => e.reserved).length - 1)
                    ? const Divider(
                        height: Spacing.large2,
                      )
                    : const AppGap.medium();
              },
            ),
          );
  }

  // void goDHCPReservationEdit(DHCPReservation item, int index) async {
  //   final routerIp = ref.watch(localNetworkSettingProvider).ipAddress;
  //   final subnetMask = ref.watch(localNetworkSettingProvider).subnetMask;
  //   final result = await context
  //       .pushNamed<DHCPReservation?>(RouteNamed.dhcpReservationEdit, extra: {
  //     'viewType': 'edit',
  //     'routerIp': routerIp,
  //     'subnetMask': subnetMask,
  //     'item': item,
  //   });
  //   if (result != null) {
  //     final succeed = ref
  //         .read(localNetworkSettingProvider.notifier)
  //         .updateDHCPReservationOfIndex(result, index);
  //     if (!succeed) {
  //       showFailedSnackBar(
  //         context,
  //         loc(context).ipOrMacAddressOverlap,
  //       );
  //     }
  //   }
  // }

  Future _showManualAddReservationModal([
    DHCPReservation? item,
  ]) {
    final routerIp = ref.watch(localNetworkSettingProvider).ipAddress;
    final subnetMask = ref.watch(localNetworkSettingProvider).subnetMask;
    final subnetToken = subnetMask.split('.');
    final deviceNameController = TextEditingController();
    final ipController = TextEditingController()..text = routerIp;
    final macController = TextEditingController();

    bool enableSave = false;
    bool isNameValid(String name) => !HostNameRule().validate(name);
    bool isMacValid(String mac) => MACAddressRule().validate(mac);
    bool updateEnableSave() {
      final name = deviceNameController.text;
      final ip = ipController.text;
      final mac = macController.text;
      bool allFilled = name.isNotEmpty && ip.isNotEmpty && mac.isNotEmpty;
      bool edited = name != item?.description ||
          ip != item?.ipAddress ||
          mac != item?.macAddress;

      return allFilled && edited && isMacValid(mac) && isNameValid(name);
    }

    return showSubmitAppDialog(context,
        title: loc(context).manuallyAddReservation,
        contentBuilder: (context, setState, onSubmit) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppTextField(
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
              ),
              const AppGap.large3(),
              AppTextField.macAddress(
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
          ref.read(dhcpReservationProvider.notifier).updateReservations(
                ReservedListItem(
                  reserved: true,
                  data: DHCPReservation(
                      macAddress: mac, ipAddress: ip, description: name),
                ),
              );
        },
        checkPositiveEnabled: () => enableSave);
  }
}
