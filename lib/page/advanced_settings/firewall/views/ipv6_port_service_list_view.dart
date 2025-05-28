import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/core/jnap/models/ipv6_firewall_rule.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/advanced_settings/_advanced_settings.dart';
import 'package:privacy_gui/page/components/settings_view/editable_card_list_settings_view.dart';
import 'package:privacy_gui/page/components/settings_view/editable_table_settings_view.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:privacy_gui/page/instant_device/providers/device_list_state.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/setting_card.dart';
import 'package:privacygui_widgets/widgets/container/responsive_layout.dart';
import 'package:privacygui_widgets/widgets/dropdown/dropdown_button.dart';
import 'package:privacygui_widgets/widgets/gap/const/spacing.dart';
import 'package:privacygui_widgets/widgets/input_field/ip_form_field_display_type.dart';
import 'package:privacygui_widgets/widgets/input_field/ipv6_form_field.dart';
import 'package:privacygui_widgets/widgets/page/layout/basic_layout.dart';

import '../../apps_and_gaming/ports/views/widgets/_widgets.dart';

class Ipv6PortServiceListView extends ArgumentsConsumerStatefulView {
  const Ipv6PortServiceListView({super.key, super.args});

  @override
  ConsumerState<Ipv6PortServiceListView> createState() =>
      _Ipv6PortServiceListViewState();
}

class _Ipv6PortServiceListViewState
    extends ConsumerState<Ipv6PortServiceListView> {
  late final Ipv6PortServiceListNotifier _notifier;
  // Ipv6PortServiceListState? preservedState;
  // Fro Edit table settings
  final TextEditingController applicationTextController =
      TextEditingController();
  final TextEditingController firstPortTextController = TextEditingController();
  final TextEditingController lastPortTextController = TextEditingController();
  final TextEditingController ipAddressTextController = TextEditingController();
  bool _isEditRuleValid = false;

  @override
  void initState() {
    _notifier = ref.read(ipv6PortServiceListProvider.notifier);
    // doSomethingWithSpinner(
    //   context,
    //   _notifier.fetch(),
    // ).then((state) {
    //   setState(() {
    //     preservedState = state;
    //   });
    // });
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(ipv6PortServiceListProvider);
    return StyledAppPageView.innerPage(
      child: (context, constraints) => AppBasicLayout(
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppGap.large2(),
            ResponsiveLayout(
                desktop: _desktopSettingsView(state),
                mobile: _mobildSettingsView(state)),
          ],
        ),
      ),
    );
  }

  Widget _mobildSettingsView(Ipv6PortServiceListState state) {
    // return Center();
    return EditableCardListsettingsView<IPv6FirewallRule>(
        title: loc(context).ipv6PortServices,
        emptyMessage: loc(context).noIPv6PortService,
        addEnabled: !_notifier.isExceedMax(),
        addLabel: loc(context).add,
        itemCardBuilder: (context, rule) => EditableListItem(
              title: rule.description,
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Table(
                    children: [
                      TableRow(
                        children: [
                          AppSettingCard.noBorder(
                            padding: EdgeInsets.only(bottom: Spacing.medium),
                            title: loc(context).startPort,
                            description: getProtocolTitle(
                                context,
                                rule.portRanges.firstOrNull?.protocol ??
                                    'Both'),
                          ),
                          AppSettingCard.noBorder(
                            padding: EdgeInsets.only(bottom: Spacing.medium),
                            title: loc(context).endPort,
                            description:
                                '${rule.portRanges.firstOrNull?.firstPort ?? 0} ${loc(context).to} ${rule.portRanges.firstOrNull?.lastPort ?? 0}',
                          )
                        ],
                      ),
                    ],
                  ),
                  Table(
                    children: [
                      TableRow(
                        children: [
                          AppSettingCard.noBorder(
                            padding: EdgeInsets.only(bottom: Spacing.medium),
                            title: loc(context).ipAddress,
                            description: rule.ipv6Address,
                          )
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
        editRoute: RouteNamed.ipv6PortServiceRule,
        dataList: state.rules,
        onSave: (index, rule) {
          if (index >= 0) {
            _notifier.editRule(index, rule);
          } else {
            _notifier.addRule(rule);
          }
        },
        onDelete: (index, rule) {
          _notifier.deleteRule(rule);
        });
  }

  Widget _desktopSettingsView(Ipv6PortServiceListState state) {
    return AppEditableTableSettingsView<IPv6FirewallRule>(
      title: loc(context).ipv6PortServices,
      addEnabled: !_notifier.isExceedMax(),
      emptyMessage: loc(context).noIPv6PortService,
      onStartEdit: (index, rule) {
        ref
            .read(ipv6PortServiceRuleProvider.notifier)
            .init(state.rules, rule, index);
        // Edit
        applicationTextController.text = rule?.description ?? '';
        firstPortTextController.text =
            '${rule?.portRanges.firstOrNull?.firstPort ?? 0}';
        lastPortTextController.text =
            '${rule?.portRanges.firstOrNull?.lastPort ?? 0}';
        ipAddressTextController.text = rule?.ipv6Address ?? '';
        setState(() {
          _isEditRuleValid =
              ref.read(ipv6PortServiceRuleProvider.notifier).isRuleValid();
        });
      },
      headers: [
        loc(context).applicationName,
        loc(context).protocol,
        loc(context).deviceIP,
        loc(context).startEndPorts,
      ],
      columnWidths: ResponsiveLayout.isOverLargeLayout(context)
          ? const {
              0: FractionColumnWidth(.2),
              1: FractionColumnWidth(.2),
              2: FractionColumnWidth(.35),
              3: FractionColumnWidth(.15),
            }
          : const {
              0: FractionColumnWidth(.2),
              1: FractionColumnWidth(.2),
              2: FractionColumnWidth(.35),
              3: FractionColumnWidth(.15),
            },
      dataList: [...state.rules],
      editRowIndex: 0,
      cellBuilder: (context, ref, index, rule) {
        return switch (index) {
          0 => AppText.bodySmall(rule.description),
          1 => AppText.bodySmall(getProtocolTitle(
              context, rule.portRanges.firstOrNull?.protocol ?? 'Both')),
          2 => AppText.bodySmall(rule.ipv6Address),
          3 => AppText.bodySmall(
              '${rule.portRanges.firstOrNull?.firstPort ?? 0} ${loc(context).to} ${rule.portRanges.firstOrNull?.lastPort ?? 0}'),
          _ => AppText.bodySmall(''),
        };
      },
      editCellBuilder: (context, ref, index, rule, error) {
        final stateRule = ref.watch(ipv6PortServiceRuleProvider).rule;

        return switch (index) {
          0 => AppTextField.outline(
              controller: applicationTextController,
              onChanged: (value) {
                ref
                    .read(ipv6PortServiceRuleProvider.notifier)
                    .updateRule(stateRule?.copyWith(description: value));
                setState(() {
                  _isEditRuleValid = ref
                      .read(ipv6PortServiceRuleProvider.notifier)
                      .isRuleValid();
                });
              },
            ),
          1 => AppDropdownButton(
              initial: stateRule?.portRanges.firstOrNull?.protocol ?? 'Both',
              items: const ['TCP', 'UDP', 'Both'],
              label: (e) => getProtocolTitle(context, e),
              onChanged: (value) {
                final portRanges = stateRule?.portRanges ?? [];
                final portRange = portRanges.firstOrNull;
                ref.read(ipv6PortServiceRuleProvider.notifier).updateRule(
                      stateRule?.copyWith(
                        portRanges: portRange == null
                            ? null
                            : [portRange.copyWith(protocol: value)],
                      ),
                    );
                setState(() {
                  _isEditRuleValid = ref
                      .read(ipv6PortServiceRuleProvider.notifier)
                      .isRuleValid();
                });
              },
            ),
          2 => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppIPv6FormField(
                  displayType: AppIpFormFieldDisplayType.tight,
                  controller: ipAddressTextController,
                  border: const OutlineInputBorder(),
                  onChanged: (value) {
                    ref
                        .read(ipv6PortServiceRuleProvider.notifier)
                        .updateRule(stateRule?.copyWith(ipv6Address: value));
                    setState(() {
                      _isEditRuleValid = ref
                          .read(ipv6PortServiceRuleProvider.notifier)
                          .isRuleValid();
                    });
                  },
                ),
                const AppGap.small3(),
                AppTextButton.noPadding(
                  loc(context).selectDevices,
                  onTap: () async {
                    final result =
                        await context.pushNamed<List<DeviceListItem>?>(
                      RouteNamed.devicePicker,
                      extra: {'type': 'ipv6', 'selectMode': 'single'},
                    );
                    if (result != null) {
                      final device = result.first;
                      ipAddressTextController.text = device.ipv6Address;
                    }
                  },
                )
              ],
            ),
          3 => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Expanded(
                      child: AppTextField.minMaxNumber(
                        min: 0,
                        max: 65535,
                        border: OutlineInputBorder(),
                        controller: firstPortTextController,
                        onChanged: (value) {
                          final portRanges = stateRule?.portRanges ?? [];
                          final portRange = portRanges.firstOrNull;
                          ref
                              .read(ipv6PortServiceRuleProvider.notifier)
                              .updateRule(
                                stateRule?.copyWith(
                                  portRanges: portRange == null
                                      ? null
                                      : [
                                          portRange.copyWith(
                                              firstPort:
                                                  int.tryParse(value) ?? 0)
                                        ],
                                ),
                              );
                          setState(() {
                            _isEditRuleValid = ref
                                .read(ipv6PortServiceRuleProvider.notifier)
                                .isRuleValid();
                          });
                        },
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(
                          left: Spacing.small1, right: Spacing.small1),
                      child: AppText.bodySmall(loc(context).to),
                    ),
                    Expanded(
                      child: AppTextField.minMaxNumber(
                        min: 0,
                        max: 65535,
                        border: OutlineInputBorder(),
                        controller: lastPortTextController,
                        onChanged: (value) {
                          final portRanges = stateRule?.portRanges ?? [];
                          final portRange = portRanges.firstOrNull;
                          ref
                              .read(ipv6PortServiceRuleProvider.notifier)
                              .updateRule(
                                stateRule?.copyWith(
                                  portRanges: portRange == null
                                      ? null
                                      : [
                                          portRange.copyWith(
                                              lastPort:
                                                  int.tryParse(value) ?? 0)
                                        ],
                                ),
                              );
                          setState(() {
                            _isEditRuleValid = ref
                                .read(ipv6PortServiceRuleProvider.notifier)
                                .isRuleValid();
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          _ => AppText.bodyLarge(''),
        };
      },
      onValidate: (index) {
        final notifier = ref.read(ipv6PortServiceRuleProvider.notifier);
        final ruleState = ref.watch(ipv6PortServiceRuleProvider);
        return switch (index) {
          0 => notifier.isRuleNameValidate(applicationTextController.text)
              ? null
              : loc(context).theNameMustNotBeEmpty,
          2 => notifier.isDeviceIpValidate(ipAddressTextController.text)
              ? null
              : loc(context).invalidIpAddress,
          3 => notifier.isPortRangeValid(
                  int.tryParse(firstPortTextController.text) ?? 0,
                  int.tryParse(lastPortTextController.text) ?? 0)
              ? !notifier.isPortConflict(
                      int.tryParse(firstPortTextController.text) ?? 0,
                      int.tryParse(lastPortTextController.text) ?? 0,
                      ruleState.rule?.portRanges.firstOrNull?.protocol ??
                          'Both')
                  ? null
                  : loc(context).rulesOverlapError
              : loc(context).portRangeError,
          _ => null,
        };
      },
      createNewItem: () => const IPv6FirewallRule(
          isEnabled: true,
          description: '',
          ipv6Address: '',
          portRanges: [PortRange(protocol: 'Both', firstPort: 0, lastPort: 0)]),
      onSaved: (index, rule) {
        final stateRule = ref.read(ipv6PortServiceRuleProvider).rule;
        if (stateRule == null) {
          return;
        }
        if (index == null) {
          // add
          ref.read(ipv6PortServiceListProvider.notifier).addRule(stateRule);
        } else {
          // edit
          ref
              .read(ipv6PortServiceListProvider.notifier)
              .editRule(index, stateRule);
        }
      },
      onDeleted: (index, rule) {
        ref.read(ipv6PortServiceListProvider.notifier).deleteRule(rule);
      },
      isEditingDataValid: _isEditRuleValid,
    );
  }
}
