import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/core/jnap/models/lan_settings.dart';
import 'package:privacy_gui/core/utils/extension.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/shortcuts/snack_bar.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:privacy_gui/page/devices/providers/device_list_state.dart';
import 'package:privacy_gui/page/advanced_settings/local_network_settings/providers/local_network_settings_provider.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';
import 'package:privacygui_widgets/widgets/card/list_card.dart';
import 'package:privacygui_widgets/widgets/card/setting_card.dart';
import 'package:privacygui_widgets/widgets/page/layout/basic_layout.dart';
import 'package:privacygui_widgets/widgets/progress_bar/full_screen_spinner.dart';

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
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dhcpReservedList = ref.watch(localNetworkSettingProvider
        .select((value) => value.dhcpReservationList));
    return _isLoading
        ? const AppFullScreenSpinner()
        : StyledAppPageView(
            scrollable: true,
            title: loc(context).dhcpReservations.capitalizeWords(),
            child: AppBasicLayout(
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText.bodyLarge(loc(context).dhcpReservationDescption),
                  const AppGap.large1(),
                  Row(
                    children: [
                      Expanded(
                        child: AppSettingCard(
                          title: loc(context).selectFromMyDHCPList,
                          trailing: const Icon(LinksysIcons.add),
                          onTap: () async {
                            final result = await context
                                .pushNamed<List<DeviceListItem>?>(
                                    RouteNamed.devicePicker,
                                    extra: {
                                  'type': 'ipv4AndMac',
                                  'selectMode': 'multiple',
                                });

                            if (result != null) {
                              final addedList = result.map((e) {
                                return DHCPReservation(
                                  description:
                                      e.name.replaceAll(RegExp(r' '), ''),
                                  ipAddress: e.ipv4Address,
                                  macAddress: e.macAddress,
                                );
                              }).toList();
                              ref
                                  .read(localNetworkSettingProvider.notifier)
                                  .updateDHCPReservationList(addedList);
                            }
                          },
                        ),
                      ),
                      Expanded(
                        child: AppSettingCard(
                          title: loc(context).manuallyAddReservation,
                          trailing: const Icon(LinksysIcons.add),
                          onTap: () async {
                            final result = await context
                                .pushNamed<DHCPReservation?>(
                                    RouteNamed.dhcpReservationEdit,
                                    extra: {
                                  'viewType': 'add',
                                });
                            if (result != null) {
                              final isReservationOverlap = ref
                                  .read(localNetworkSettingProvider.notifier)
                                  .isReservationOverlap(item: result);
                              if (!isReservationOverlap) {
                                ref
                                    .read(localNetworkSettingProvider.notifier)
                                    .updateDHCPReservationList([result]);
                              } else {
                                showFailedSnackBar(
                                  context,
                                  loc(context).ipOrMacAddressOverlap,
                                );
                              }
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const AppGap.large2(),
                  AppText.labelLarge(
                      loc(context).reservedAddresses.capitalizeWords()),
                  const AppGap.medium(),
                  ...reservedAddresses(dhcpReservedList),
                ],
              ),
            ),
          );
  }

  List<Widget> reservedAddresses(List<DHCPReservation> reserved) {
    if (reserved.isEmpty) {
      return [
        AppCard(
          child: SizedBox(
            height: 180,
            child: Center(
              child: AppText.bodyMedium(loc(context).youHaveNoDHCPReservations),
            ),
          ),
        ),
      ];
    } else {
      return [
        SizedBox(
          height: reserved.length * 100,
          child: ListView.builder(
            itemCount: reserved.length,
            itemBuilder: (context, index) {
              final item = reserved[index];
              return AppListCard(
                title: AppText.labelMedium(item.description),
                description: AppText.bodyMedium(
                    "IP: ${item.ipAddress}\nMAC: ${item.macAddress}"),
                trailing: AppIconButton(
                  icon: LinksysIcons.edit,
                  onTap: () {
                    goDHCPReservationEdit(item, index);
                  },
                ),
                onTap: () {
                  goDHCPReservationEdit(item, index);
                },
              );
            },
          ),
        ),
      ];
    }
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
}
