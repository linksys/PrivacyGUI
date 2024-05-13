import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:linksys_app/core/jnap/models/lan_settings.dart';
import 'package:linksys_app/core/utils/extension.dart';
import 'package:linksys_app/localization/localization_hook.dart';
import 'package:linksys_app/page/components/styled/styled_page_view.dart';
import 'package:linksys_app/page/components/views/arguments_view.dart';
import 'package:linksys_app/page/devices/providers/device_list_state.dart';
import 'package:linksys_app/page/troubleshooting/_troubleshooting.dart';
import 'package:linksys_app/page/advanced_settings/local_network_settings/providers/local_network_settings_provider.dart';
import 'package:linksys_app/page/advanced_settings/local_network_settings/providers/local_network_settings_state.dart';
import 'package:linksys_app/route/constants.dart';
import 'package:linksys_app/util/extensions.dart';
import 'package:linksys_widgets/icons/linksys_icons.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/card/card.dart';
import 'package:linksys_widgets/widgets/card/list_card.dart';
import 'package:linksys_widgets/widgets/card/setting_card.dart';
import 'package:linksys_widgets/widgets/page/layout/basic_layout.dart';
import 'package:linksys_widgets/widgets/progress_bar/full_screen_spinner.dart';

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
  final List<DhcpClientModel> _checked = [];
  List<DHCPReservation> _tempReserved = [];

  late LocalNetworkSettingsState _currentSettings;

  @override
  void initState() {
    super.initState();
    _currentSettings =
        ref.read(localNetworkSettingProvider.notifier).currentSettings();
    _isLoading = true;
    Future.doWhile(() => !mounted)
        .then((_) async =>
            await ref.read(troubleshootingProvider.notifier).fetch())
        .then((_) async =>
            await ref.read(localNetworkSettingProvider.notifier).fetch())
        .then((_) {
      _init();
      setState(() {
        _isLoading = false;
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // final dhcpClientList = ref.watch(troubleshootingProvider).dhcpClientList;
    final dhcpReservedList =
        ref.watch(localNetworkSettingProvider).dhcpReservationList;

    return _isLoading
        ? const AppFullScreenSpinner()
        : StyledAppPageView(
            scrollable: true,
            title: loc(context).dhcpReservations.capitalizeWords(),
            bottomBar: PageBottomBar(
              isPositiveEnabled: !listEquals(_tempReserved, dhcpReservedList),
              onPositiveTap: () {
                setState(() {
                  _isLoading = true;
                });
                ref
                    .read(localNetworkSettingProvider.notifier)
                    .saveSettings(_currentSettings.copyWith(
                        dhcpReservationList: _tempReserved))
                    .then((_) {
                  setState(() {
                    _init();
                    _isLoading = false;
                  });
                });
              },
            ),
            actions: [
              AppTextButton.noPadding(
                'Save',
                onTap: !listEquals(_tempReserved, dhcpReservedList)
                    ? () {
                        setState(() {
                          _isLoading = true;
                        });
                        ref
                            .read(localNetworkSettingProvider.notifier)
                            .saveSettings(_currentSettings.copyWith(
                                dhcpReservationList: _tempReserved))
                            .then((_) {
                          setState(() {
                            _init();
                            _isLoading = false;
                          });
                        });
                      }
                    : null,
              ),
            ],
            child: AppBasicLayout(
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText.bodyLarge(loc(context).dhcpReservationDescption),
                  const AppGap.semiBig(),
                  AppSettingCard(
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
                        result.map((e) {
                          final item = DHCPReservation(
                            description: e.name,
                            ipAddress: e.ipv4Address,
                            macAddress: e.macAddress,
                          );
                          if (!_tempReserved.contains(item)) {
                            setState(() {
                              _tempReserved.add(item);
                            });
                          }
                        });
                      }
                    },
                  ),
                  AppSettingCard(
                    title: loc(context).manuallyAddReservation,
                    trailing: const Icon(LinksysIcons.add),
                    onTap: () async {
                      final result = await context.pushNamed<DHCPReservation?>(
                          RouteNamed.dhcpReservationEdit,
                          extra: {
                            'viewType': 'add',
                          });
                      if (result != null) {
                        if (!_tempReserved.contains(result)) {
                          setState(() {
                            _tempReserved.add(result);
                          });
                        }
                      }
                    },
                  ),
                  const AppGap.big(),
                  AppText.labelLarge(
                      loc(context).reservedAddresses.capitalizeWords()),
                  const AppGap.regular(),
                  ...reservedAddresses(_tempReserved),
                ],
              ),
            ),
          );
  }

  void _init() {
    final dhcpReservedList =
        ref.read(localNetworkSettingProvider).dhcpReservationList;
    final dhcpClientList = ref.read(troubleshootingProvider).dhcpClientList;
    _checked.addAll(dhcpClientList.where((element) =>
        dhcpReservedList.map((e) => e.macAddress).contains(element.mac)));
    _tempReserved = [
      ...dhcpReservedList,
      ..._checked
          .map((e) => DHCPReservation(
              macAddress: e.mac, ipAddress: e.ipAddress, description: e.name))
          .toList()
    ].unique((e) => e.macAddress);
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
                  onTap: () async {
                    final result = await context.pushNamed<DHCPReservation?>(
                        RouteNamed.dhcpReservationEdit,
                        extra: {
                          'viewType': 'edit',
                          'item': item,
                        });
                    if (result != null) {
                      if (result.ipAddress == 'DELETE') {
                        setState(() {
                          _tempReserved.remove(item);
                        });
                      } else if (!_tempReserved.contains(result)) {
                        setState(() {
                          _tempReserved[index] = result;
                        });
                      }
                    }
                  },
                ),
              );
            },
          ),
        ),
      ];
    }
  }
}
