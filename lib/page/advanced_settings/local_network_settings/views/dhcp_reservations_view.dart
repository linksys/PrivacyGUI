import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/page/advanced_settings/local_network_settings/providers/dhcp_reservations_provider.dart';
import 'package:privacy_gui/page/advanced_settings/local_network_settings/providers/dhcp_reservations_state.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/theme/_theme.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';
import 'package:privacygui_widgets/widgets/card/list_card.dart';
import 'package:privacygui_widgets/widgets/gap/const/spacing.dart';
import 'package:privacygui_widgets/widgets/input_field/ip_form_field.dart';
import 'package:privacygui_widgets/widgets/page/layout/basic_layout.dart';

import 'package:privacy_gui/core/jnap/models/lan_settings.dart';
import 'package:privacy_gui/core/utils/extension.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/advanced_settings/local_network_settings/providers/local_network_settings_provider.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/page/components/shortcuts/snack_bar.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:privacy_gui/page/instant_device/_instant_device.dart';
import 'package:privacy_gui/page/instant_device/providers/device_list_state.dart';
import 'package:privacy_gui/page/instant_device/views/devices_filter_widget.dart';
import 'package:privacy_gui/route/constants.dart';
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
    });
    ;
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dhcpReservedList = ref.watch(localNetworkSettingProvider
        .select((value) => value.dhcpReservationList));
    final deviceList = ref.watch(filteredDeviceListProvider);

    return StyledAppPageView(
      scrollable: true,
      title: loc(context).dhcpReservations.capitalizeWords(),
      bottomBar: PageBottomBar(
          isPositiveEnabled: dhcpReservedList != _preservedState,
          onPositiveTap: () {
            // doSomethingWithSpinner(
            //         context,
            //         ref
            //             .read(localNetworkSettingProvider.notifier)
            //             .saveReservations())
            //     .then((state) {
            //   setState(() {
            //     _preservedState = state;
            //   });
            // });
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
                SizedBox(
                    width: 4.col, child: AppCard(child: DevicesFilterWidget())),
                const AppGap.gutter(),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // AppSettingCard(
                      //   title: loc(context).selectFromMyDHCPList,
                      //   trailing: const Icon(
                      //     LinksysIcons.add,
                      //     semanticLabel: 'add',
                      //   ),
                      //   onTap: () async {
                      //     final result = await context
                      //         .pushNamed<List<DeviceListItem>?>(
                      //             RouteNamed.devicePicker,
                      //             extra: {
                      //           'type': 'ipv4AndMac',
                      //           'selectMode': 'multiple',
                      //         });

                      //     if (result != null) {
                      //       final addedList = result.map((e) {
                      //         return DHCPReservation(
                      //           description:
                      //               e.name.replaceAll(RegExp(r' '), ''),
                      //           ipAddress: e.ipv4Address,
                      //           macAddress: e.macAddress,
                      //         );
                      //       }).toList();
                      //       ref
                      //           .read(localNetworkSettingProvider.notifier)
                      //           .updateDHCPReservationList(addedList);
                      //     }
                      //   },
                      // ),
                      // const AppGap.small2(),
                      // AppSettingCard(
                      //   title: loc(context).manuallyAddReservation,
                      //   trailing: const Icon(
                      //     LinksysIcons.add,
                      //     semanticLabel: 'add',
                      //   ),
                      //   onTap: () async {
                      //     final result = await context
                      //         .pushNamed<DHCPReservation?>(
                      //             RouteNamed.dhcpReservationEdit,
                      //             extra: {
                      //           'viewType': 'add',
                      //         });
                      //     if (result != null) {
                      //       final isReservationOverlap = ref
                      //           .read(localNetworkSettingProvider.notifier)
                      //           .isReservationOverlap(item: result);
                      //       if (!isReservationOverlap) {
                      //         ref
                      //             .read(localNetworkSettingProvider.notifier)
                      //             .updateDHCPReservationList([result]);
                      //       } else {
                      //         showFailedSnackBar(
                      //           context,
                      //           loc(context).ipOrMacAddressOverlap,
                      //         );
                      //       }
                      //     }
                      //   },
                      // ),
                      // const AppGap.large3(),
                      AppText.labelLarge(loc(context)
                          .nReservedAddresses(dhcpReservedList.length)
                          .capitalizeWords()),
                      const AppGap.medium(),
                      reservedAddresses(dhcpReservedList, deviceList),
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

  Widget reservedAddresses(
      List<DHCPReservation> reserved, List<DeviceListItem> deviceList) {
    // final filteredDeviceList = deviceList
    //     .where((e) => !reserved.any((r) => r.macAddress == e.macAddress))
    //     .map(
    //       (e) => ReservedListItem(
    //         reserved: false,
    //         data: DHCPReservation(
    //             macAddress: e.macAddress,
    //             ipAddress: e.ipv4Address,
    //             description: e.name),
    //       ),
    //     )
    //     .toList();
    final state = ref.watch(dhcpReservationProvider);
    final list = [
      // ...reserved.map((e) => ReservedListItem(reserved: true, data: e)),
      // ...filteredDeviceList
      ...state.reservations, ...state.devices,
    ];
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
                  description: AppText.bodyMedium(
                      "IP: ${item.data.ipAddress}\nMAC: ${item.data.macAddress}"),
                  // trailing: AppIconButton(
                  //   icon: LinksysIcons.edit,
                  //   semanticLabel: 'edit',
                  //   onTap: () {
                  //     // goDHCPReservationEdit(item, index);
                  //   },
                  // ),
                  onTap: () {
                    // if (item.reserved) {
                    //   ref
                    //       .read(localNetworkSettingProvider.notifier)
                    //       .updateDHCPReservationOfIndex(
                    //           item.data.copyWith(ipAddress: 'DELETE'), index);
                    // } else {
                    //   ref
                    //       .read(localNetworkSettingProvider.notifier)
                    //       .updateDHCPReservationList([item.data]);
                    // }
                    ref
                        .read(dhcpReservationProvider.notifier)
                        .updateReservations(item);
                  },
                );
              },
              separatorBuilder: (BuildContext context, int index) {
                return index == (reserved.length - 1)
                    ? const Divider(
                        height: Spacing.large2,
                      )
                    : const AppGap.medium();
              },
            ),
          );
  }

  void goDHCPReservationEdit(DHCPReservation item, int index) async {
    final result = await context
        .pushNamed<DHCPReservation?>(RouteNamed.dhcpReservationEdit, extra: {
      'viewType': 'edit',
      'item': item,
    });
    if (result != null) {
      final succeed = ref
          .read(localNetworkSettingProvider.notifier)
          .updateDHCPReservationOfIndex(result, index);
      if (!succeed) {
        showFailedSnackBar(
          context,
          loc(context).ipOrMacAddressOverlap,
        );
      }
    }
  }

  Future _showManualAddReservationModal([DHCPReservation? item, int? index]) {
    final deviceNameController = TextEditingController();
    final ipController = TextEditingController();
    final macController = TextEditingController();

    bool enableSave = false;

    bool updateEnableSave() {
      final name = deviceNameController.text;
      final ip = ipController.text;
      final mac = macController.text;
      bool allFilled = name.isNotEmpty && ip.isNotEmpty && mac.isNotEmpty;
      bool edited = name != item?.description ||
          ip != item?.ipAddress ||
          mac != item?.macAddress;
      final InputValidator macValidator = InputValidator([MACAddressRule()]);

      bool isMacValid = macValidator.validate(mac);
      return allFilled && edited && isMacValid;
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
                onChanged: (value) {
                  setState(() {
                    enableSave = updateEnableSave();
                  });
                },
              ),
            ],
          );
        },
        event: () async {},
        checkPositiveEnabled: () => enableSave);
  }
}
