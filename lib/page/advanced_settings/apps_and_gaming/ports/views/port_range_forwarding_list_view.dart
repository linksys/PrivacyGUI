import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/setting_card.dart';
import 'package:privacygui_widgets/widgets/container/responsive_layout.dart';
import 'package:privacygui_widgets/widgets/dropdown/dropdown_button.dart';
import 'package:privacygui_widgets/widgets/gap/const/spacing.dart';
import 'package:privacygui_widgets/widgets/input_field/ip_form_field.dart';

import 'package:privacy_gui/core/jnap/models/port_range_forwarding_rule.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ports/_ports.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ports/views/widgets/_widgets.dart';
import 'package:privacy_gui/page/components/settings_view/editable_card_list_settings_view.dart';
import 'package:privacy_gui/page/components/settings_view/editable_table_settings_view.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:privacy_gui/route/constants.dart';

class PortRangeForwardingListView extends ArgumentsConsumerStatelessView {
  const PortRangeForwardingListView({super.key, super.args});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PortRangeForwardingListContentView(
      args: super.args,
    );
  }
}

class PortRangeForwardingListContentView extends ArgumentsConsumerStatefulView {
  const PortRangeForwardingListContentView({super.key, super.args});

  @override
  ConsumerState<PortRangeForwardingListContentView> createState() =>
      _PortRangeForwardingContentViewState();
}

class _PortRangeForwardingContentViewState
    extends ConsumerState<PortRangeForwardingListContentView> {
  late final PortRangeForwardingListNotifier _notifier;
  PortRangeForwardingListState? preservedState;
// Fro Edit table settings
  final TextEditingController applicationTextController =
      TextEditingController();
  final TextEditingController internalPortTextController =
      TextEditingController();
  final TextEditingController externalPortTextController =
      TextEditingController();
  final TextEditingController ipAddressTextController = TextEditingController();
  bool _isEditRuleValid = false;

  @override
  void initState() {
    _notifier = ref.read(portRangeForwardingListProvider.notifier);
    // doSomethingWithSpinner(
    //   context,
    //   _notifier.fetch(),
    // ).then((state) {
    //   setState(() {
    //     preservedState = state;
    //   });
    //   // ref.read(appsAndGamingProvider.notifier).setChanged(false);
    // });

    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(portRangeForwardingListProvider);
    final submaskToken = state.status.subnetMask.split('.');
    final prefixIP = state.status.routerIp;
    // ref.listen(portRangeForwardingListProvider, (previous, next) {
    //   ref
    //       .read(appsAndGamingProvider.notifier)
    //       .setChanged(next != preservedState);
    // });
    return SingleChildScrollView(
      child: Theme(
        data: Theme.of(context).copyWith(
            inputDecorationTheme: Theme.of(context)
                .inputDecorationTheme
                .copyWith(contentPadding: EdgeInsets.all(Spacing.small1))),
        child: ResponsiveLayout(
          desktop: _desktopSettingsView(state, submaskToken, prefixIP),
          mobile: _mobildSettingsView(state, submaskToken, prefixIP),
        ),
      ),
    );
  }

  Widget _mobildSettingsView(PortRangeForwardingListState state,
      List<String> submaskToken, String prefixIP) {
    // return Center();
    return EditableCardListsettingsView<PortRangeForwardingRule>(
        title: loc(context).portRangeForwarding,
        emptyMessage: loc(context).noPortRangeForwarding,
        addEnabled: !_notifier.isExceedMax(),
        addLabel: loc(context).add,
        itemCardBuilder: (context, rule) => EditableListItem(
              title: rule.description,
              content: Table(
                children: [
                  TableRow(
                    children: [
                      AppSettingCard.noBorder(
                        padding: EdgeInsets.only(bottom: Spacing.medium),
                        title: loc(context).startPort,
                        description: '${rule.firstExternalPort}',
                      ),
                      AppSettingCard.noBorder(
                        padding: EdgeInsets.only(bottom: Spacing.medium),
                        title: loc(context).endPort,
                        description: '${rule.lastExternalPort}',
                      )
                    ],
                  ),
                  TableRow(
                    children: [
                      AppSettingCard.noBorder(
                        padding: EdgeInsets.only(bottom: Spacing.medium),
                        title: loc(context).protocol,
                        description: getProtocolTitle(context, rule.protocol),
                      ),
                      AppSettingCard.noBorder(
                        padding: EdgeInsets.only(bottom: Spacing.medium),
                        title: loc(context).ipAddress,
                        description: rule.internalServerIPAddress,
                      )
                    ],
                  ),
                ],
              ),
            ),
        editRoute: RouteNamed.portRangeForwardingRule,
        dataList: state.current.rules,
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

  Widget _desktopSettingsView(PortRangeForwardingListState state,
      List<String> submaskToken, String prefixIP) {
    return AppEditableTableSettingsView<PortRangeForwardingRule>(
      title: loc(context).portRangeForwarding,
      addEnabled: !_notifier.isExceedMax(),
      emptyMessage: loc(context).noPortRangeForwarding,
      onStartEdit: (index, rule) {
        ref.read(portRangeForwardingRuleProvider.notifier).init(
            state.current.rules,
            rule,
            index,
            state.status.routerIp,
            state.status.subnetMask);
        // Edit
        applicationTextController.text = rule?.description ?? '';
        internalPortTextController.text = '${rule?.firstExternalPort ?? 0}';
        externalPortTextController.text = '${rule?.lastExternalPort ?? 0}';
        ipAddressTextController.text = rule?.internalServerIPAddress ?? '';
        setState(() {
          _isEditRuleValid =
              ref.read(portRangeForwardingRuleProvider.notifier).isRuleValid();
        });
      },
      headers: [
        loc(context).applicationName,
        loc(context).startEndPorts,
        loc(context).protocol,
        loc(context).deviceIP,
      ],
      columnWidths: ResponsiveLayout.isOverLargeLayout(context)
          ? const {
              0: FractionColumnWidth(.2),
              1: FractionColumnWidth(.2),
              2: FractionColumnWidth(.18),
              3: FractionColumnWidth(.27),
            }
          : const {
              0: FractionColumnWidth(.2),
              1: FractionColumnWidth(.2),
              2: FractionColumnWidth(.2),
              3: FractionColumnWidth(.3),
            },
      dataList: [...state.current.rules],
      editRowIndex: 0,
      cellBuilder: (context, ref, index, rule) {
        return switch (index) {
          0 => AppText.bodySmall(rule.description),
          1 => AppText.bodySmall(
              '${rule.firstExternalPort} ${loc(context).to} ${rule.lastExternalPort}'),
          2 => AppText.bodySmall(getProtocolTitle(context, rule.protocol)),
          3 => AppText.bodySmall(rule.internalServerIPAddress),
          _ => AppText.bodySmall(''),
        };
      },
      editCellBuilder: (context, index, controller) {
        final stateRule = ref.watch(portRangeForwardingRuleProvider).rule;

        return switch (index) {
          0 => AppTextField.outline(
              controller: applicationTextController,
              onChanged: (value) {
                ref
                    .read(portRangeForwardingRuleProvider.notifier)
                    .updateRule(stateRule?.copyWith(description: value));
                setState(() {
                  _isEditRuleValid = ref
                      .read(portRangeForwardingRuleProvider.notifier)
                      .isRuleValid();
                });
              },
            ),
          1 => Column(
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
                        controller: internalPortTextController,
                        onChanged: (value) {
                          ref
                              .read(portRangeForwardingRuleProvider.notifier)
                              .updateRule(stateRule?.copyWith(
                                  firstExternalPort: int.tryParse(value) ?? 0));
                          setState(() {
                            _isEditRuleValid = ref
                                .read(portRangeForwardingRuleProvider.notifier)
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
                        controller: externalPortTextController,
                        onChanged: (value) {
                          ref
                              .read(portRangeForwardingRuleProvider.notifier)
                              .updateRule(stateRule?.copyWith(
                                  lastExternalPort: int.tryParse(value) ?? 0));
                          setState(() {
                            _isEditRuleValid = ref
                                .read(portRangeForwardingRuleProvider.notifier)
                                .isRuleValid();
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          2 => AppDropdownButton(
              initial: stateRule?.protocol,
              items: const ['TCP', 'UDP', 'Both'],
              label: (e) => getProtocolTitle(context, e),
              onChanged: (value) {
                ref
                    .read(portRangeForwardingRuleProvider.notifier)
                    .updateRule(stateRule?.copyWith(protocol: value));
                setState(() {
                  _isEditRuleValid = ref
                      .read(portRangeForwardingRuleProvider.notifier)
                      .isRuleValid();
                });
              },
            ),
          3 => AppIPFormField(
              controller: ipAddressTextController,
              border: const OutlineInputBorder(),
              octet1ReadOnly: submaskToken[0] == '255',
              octet2ReadOnly: submaskToken[1] == '255',
              octet3ReadOnly: submaskToken[2] == '255',
              octet4ReadOnly: submaskToken[3] == '255',
              onChanged: (value) {
                ref.read(portRangeForwardingRuleProvider.notifier).updateRule(
                    stateRule?.copyWith(internalServerIPAddress: value));
                setState(() {
                  _isEditRuleValid = ref
                      .read(portRangeForwardingRuleProvider.notifier)
                      .isRuleValid();
                });
              },
            ),
          _ => AppText.bodyLarge(''),
        };
      },
      onValidate: (index) {
        final notifier = ref.read(portRangeForwardingRuleProvider.notifier);
        return switch (index) {
          0 => notifier.isNameValid(applicationTextController.text)
              ? null
              : loc(context).theNameMustNotBeEmpty,
          1 => notifier.isPortRangeValid(
                  int.tryParse(internalPortTextController.text) ?? 0,
                  int.tryParse(externalPortTextController.text) ?? 0)
              ? !notifier.isPortConflict(
                      int.tryParse(internalPortTextController.text) ?? 0,
                      int.tryParse(externalPortTextController.text) ?? 0,
                      ref
                              .read(portRangeForwardingRuleProvider)
                              .rule
                              ?.protocol ??
                          'Both')
                  ? null
                  : loc(context).rulesOverlapError
              : loc(context).portRangeError,
          3 => notifier.isDeviceIpValidate(ipAddressTextController.text)
              ? null
              : loc(context).invalidIpAddress,
          _ => null,
        };
      },
      createNewItem: () => PortRangeForwardingRule(
          isEnabled: true,
          firstExternalPort: 0,
          protocol: 'Both',
          internalServerIPAddress: prefixIP,
          lastExternalPort: 0,
          description: ''),
      onSaved: (index, rule) {
        final stateRule = ref.read(portRangeForwardingRuleProvider).rule;
        if (stateRule == null) {
          return;
        }
        if (index == null) {
          // add
          ref.read(portRangeForwardingListProvider.notifier).addRule(stateRule);
        } else {
          // edit
          ref
              .read(portRangeForwardingListProvider.notifier)
              .editRule(index, stateRule);
        }
      },
      onDeleted: (index, rule) {
        ref.read(portRangeForwardingListProvider.notifier).deleteRule(rule);
      },
      isEditingDataValid: _isEditRuleValid,
    );
  }
}
