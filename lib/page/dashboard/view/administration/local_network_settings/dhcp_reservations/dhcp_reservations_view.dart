import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:linksys_app/core/jnap/models/lan_settings.dart';
import 'package:linksys_app/localization/localization_hook.dart';
import 'package:linksys_app/page/components/styled/styled_page_view.dart';
import 'package:linksys_app/page/components/views/arguments_view.dart';
import 'package:linksys_app/provider/local_network_settings/local_network_settings_provider.dart';
import 'package:linksys_app/provider/local_network_settings/local_network_settings_state.dart';
import 'package:linksys_app/provider/troubleshooting/dhcp_client.dart';
import 'package:linksys_app/provider/troubleshooting/troubleshooting_provider.dart';
import 'package:linksys_app/util/extensions.dart';
import 'package:linksys_widgets/theme/const/spacing.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/input_field/ip_form_field.dart';
import 'package:linksys_widgets/widgets/page/layout/basic_layout.dart';
import 'package:linksys_widgets/widgets/panel/general_section.dart';
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
      _SinglePortForwardingContentViewState();
}

class _SinglePortForwardingContentViewState
    extends ConsumerState<DHCPReservationsContentView> {
  bool _isLoading = false;
  final List<DhcpClientModel> _checked = [];
  List<DHCPReservation> _tempReserved = [];

  late final TextEditingController _deviceNameController;
  late final TextEditingController _ipController;
  late final TextEditingController _macController;
  late LocalNetworkSettingsState _currentSettings;

  @override
  void initState() {
    super.initState();
    _currentSettings =
        ref.read(localNetworkSettingProvider.notifier).currentSettings();
    _deviceNameController = TextEditingController();
    _ipController = TextEditingController();
    _macController = TextEditingController();
    _isLoading = true;
    Future.doWhile(() => !mounted)
        .then((_) async =>
            await ref.read(troubleshootingProvider.notifier).fetch())
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
    _deviceNameController.dispose();
    _ipController.dispose();
    _macController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dhcpClientList = ref.watch(troubleshootingProvider).dhcpClientList;
    final dhcpReservedList =
        ref.watch(localNetworkSettingProvider).dhcpReservationList;

    return _isLoading
        ? const AppFullScreenSpinner()
        : StyledAppPageView(
            scrollable: true,
            title: getAppLocalizations(context).dhcp_reservations,
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
                  const AppGap.semiBig(),
                  AppSection.withLabel(
                      title: getAppLocalizations(context).reserved_addresses,
                      content: SizedBox(
                        width: double.infinity,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _createReservedTable(_tempReserved),
                            AppTextButton.noPadding(
                              getAppLocalizations(context)
                                  .add_device_reservations,
                              onTap: () {
                                _showAddBottomSheet();
                              },
                            ),
                          ],
                        ),
                      )),
                  const AppGap.semiBig(),
                  AppSection.withLabel(
                    title: getAppLocalizations(context).dhcp_list,
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _createDHCPClientTable(dhcpClientList),
                      ],
                    ),
                  ),
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

  Widget _createDHCPClientTable(List<DhcpClientModel> dhcpClientList) {
    return Table(
      border:
          TableBorder.all(color: Theme.of(context).colorScheme.onBackground),
      children: [
        TableRow(
          children: [
            _paddingTableCell(
              child: const AppText.labelMedium('Name'),
            ),
            _paddingTableCell(
              child: const AppText.labelMedium('Interface'),
            ),
            _paddingTableCell(
              child: const AppText.labelMedium('Ip Address'),
            ),
            _paddingTableCell(
              child: const AppText.labelMedium('MAC Address'),
            ),
            _paddingTableCell(
              child: const AppText.labelMedium('Select'),
            ),
          ],
        ),
        ...dhcpClientList.map(
          (e) => TableRow(
            children: [
              _paddingTableCell(child: AppText.bodyMedium(e.name)),
              _paddingTableCell(child: AppText.bodyMedium(e.interface)),
              _paddingTableCell(child: AppText.bodyMedium(e.ipAddress)),
              _paddingTableCell(child: AppText.bodyMedium(e.mac)),
              _paddingTableCell(
                  child: AppCheckbox(
                value: _checked
                        .firstWhereOrNull((element) => element.mac == e.mac) !=
                    null,
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }
                  setState(() {
                    if (value) {
                      _checked.add(e);
                      _tempReserved.add(DHCPReservation(
                          macAddress: e.mac,
                          ipAddress: e.ipAddress,
                          description: e.name));
                    } else {
                      _checked.remove(e);
                      _tempReserved.removeWhere(
                          (element) => element.macAddress == e.mac);
                    }
                  });
                },
              )),
            ],
          ),
        ),
      ],
    );
  }

  Widget _createReservedTable(List<DHCPReservation> dhcpReservedList) {
    return Table(
      border:
          TableBorder.all(color: Theme.of(context).colorScheme.onBackground),
      children: [
        TableRow(
          children: [
            _paddingTableCell(
              child: const AppText.labelMedium('Device Name'),
            ),
            _paddingTableCell(
              child: const AppText.labelMedium('Assign IP Address'),
            ),
            _paddingTableCell(
              child: const AppText.labelMedium('To: MAC Address'),
            ),
            _paddingTableCell(
              child: const AppText.labelMedium(''),
            ),
          ],
        ),
        ...dhcpReservedList.map(
          (e) => TableRow(
            children: [
              _paddingTableCell(child: AppText.bodyMedium(e.description)),
              _paddingTableCell(child: AppText.bodyMedium(e.ipAddress)),
              _paddingTableCell(child: AppText.bodyMedium(e.macAddress)),
              _paddingTableCell(
                  child: Row(
                children: [
                  AppTextButton.noPadding(
                    'Edit',
                    onTap: () {
                      _showAddBottomSheet(editItem: e);
                    },
                  ),
                  AppTextButton.noPadding(
                    'Delete',
                    onTap: () {
                      _tempReserved.remove(e);
                    },
                  )
                ],
              )),
            ],
          ),
        ),
      ],
    );
  }

  Widget _paddingTableCell({required Widget child}) {
    return Padding(
      padding: const EdgeInsets.all(Spacing.semiSmall),
      child: TableRowInkWell(child: child),
    );
  }

  void _showAddBottomSheet({DHCPReservation? editItem}) async {
    final result = await showModalBottomSheet<DHCPReservation>(
        context: context,
        useRootNavigator: true,
        useSafeArea: true,
        enableDrag: false,
        builder: (context) => Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  const AppGap.big(),
                  AppTextField(
                    hintText: 'Device Name',
                    controller: _deviceNameController
                      ..text = editItem?.description ?? '',
                  ),
                  AppIPFormField(
                    controller: _ipController..text = editItem?.ipAddress ?? '',
                  ),
                  AppTextField.macAddress(
                    hintText: 'To: MAC Address',
                    controller: _macController
                      ..text = editItem?.macAddress ?? '',
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      AppFilledButton(
                        editItem != null ? 'Update' : 'Add',
                        onTap: () {
                          context.pop(DHCPReservation(
                            macAddress: _macController.text,
                            ipAddress: _ipController.text,
                            description: _deviceNameController.text,
                          ));
                        },
                      ),
                      const AppGap.regular(),
                      AppFilledButton(
                        'Cancel',
                        onTap: () {
                          context.pop();
                        },
                      )
                    ],
                  )
                ],
              ),
            ));
    if (result != null) {
      final index = _tempReserved
          .indexWhere((element) => element.macAddress == result.macAddress);
      setState(() {
        if (index != -1) {
          _tempReserved.replaceRange(index, index + 1, [result]);
          _tempReserved = [..._tempReserved];
        } else {
          _tempReserved = [..._tempReserved, result];
        }
      });
    }
  }
}
