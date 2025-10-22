import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/jnap/models/single_port_forwarding_rule.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ports/_ports.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ports/views/widgets/_widgets.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/providers/apps_and_gaming_provider.dart';
import 'package:privacy_gui/page/components/settings_view/editable_card_list_settings_view.dart';
import 'package:privacy_gui/page/components/settings_view/editable_table_settings_view.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/page/components/styled/consts.dart';

import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/setting_card.dart';
import 'package:privacygui_widgets/widgets/container/responsive_layout.dart';
import 'package:privacygui_widgets/widgets/dropdown/dropdown_button.dart';
import 'package:privacygui_widgets/widgets/gap/const/spacing.dart';
import 'package:privacygui_widgets/widgets/input_field/ip_form_field.dart';
import 'package:privacygui_widgets/widgets/page/layout/basic_layout.dart';

class SinglePortForwardingListView extends ArgumentsConsumerStatelessView {
  const SinglePortForwardingListView({super.key, super.args});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SinglePortForwardingListContentView(
      args: super.args,
    );
  }
}

class SinglePortForwardingListContentView
    extends ArgumentsConsumerStatefulView {
  const SinglePortForwardingListContentView({super.key, super.args});

  @override
  ConsumerState<SinglePortForwardingListContentView> createState() =>
      _SinglePortForwardingContentViewState();
}

class _SinglePortForwardingContentViewState
    extends ConsumerState<SinglePortForwardingListContentView> {
  late final SinglePortForwardingListNotifier _notifier;
  SinglePortForwardingListState? preservedState;
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
    _notifier = ref.read(singlePortForwardingListProvider.notifier);

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
    applicationTextController.dispose();
    internalPortTextController.dispose();
    externalPortTextController.dispose();
    ipAddressTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(singlePortForwardingListProvider);
    final submaskToken = state.status.subnetMask.split('.');
    final prefixIP = state.status.routerIp;
    // ref.listen(singlePortForwardingListProvider, (previous, next) {
    //   ref
    //       .read(appsAndGamingProvider.notifier)
    //       .setChanged(next != preservedState);
    // });
    return StyledAppPageView(
      hideTopbar: true,
      title: loc(context).singlePortForwarding,
      scrollable: true,
      useMainPadding: true,
      appBarStyle: AppBarStyle.none,
      padding: EdgeInsets.zero,
      // bottomBar: PageBottomBar(
      //     isPositiveEnabled: state != preservedState,
      //     onPositiveTap: () {
      //       doSomethingWithSpinner(context, _notifier.save()).then((state) {
      //         setState(() {
      //           preservedState = state;
      //         });
      //         // ref.read(appsAndGamingProvider.notifier).setChanged(false);
      //       });
      //     }),
      child: (context, constraints) => AppBasicLayout(
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppGap.large2(),
            ResponsiveLayout(
                desktop: _desktopSettingsView(state, submaskToken, prefixIP),
                mobile: _mobildSettingsView(state, submaskToken, prefixIP))
          ],
        ),
      ),
    );
  }

  Widget _mobildSettingsView(SinglePortForwardingListState state,
      List<String> submaskToken, String prefixIP) {
    // return Center();
    return EditableCardListsettingsView<SinglePortForwardingRule>(
        title: loc(context).singlePortForwarding,
        emptyMessage: loc(context).noSinglePortForwarding,
        addLabel: loc(context).add,
        addEnabled: !_notifier.isExceedMax(),
        itemCardBuilder: (context, rule) => EditableListItem(
              title: rule.description,
              content: Table(
                children: [
                  TableRow(
                    children: [
                      AppSettingCard.noBorder(
                        padding: EdgeInsets.only(bottom: Spacing.medium),
                        title: loc(context).internalPort,
                        description: '${rule.internalPort}',
                      ),
                      AppSettingCard.noBorder(
                        padding: EdgeInsets.only(bottom: Spacing.medium),
                        title: loc(context).externalPort,
                        description: '${rule.externalPort}',
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
        editRoute: RouteNamed.singlePortForwardingRule,
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

  Widget _desktopSettingsView(SinglePortForwardingListState state,
      List<String> submaskToken, String prefixIP) {
    return AppEditableTableSettingsView<SinglePortForwardingRule>(
      title: loc(context).singlePortForwarding,
      emptyMessage: loc(context).noSinglePortForwarding,
      addEnabled: !_notifier.isExceedMax(),
      onStartEdit: (index, rule) {
        ref
            .read(singlePortForwardingRuleProvider.notifier)
            .init(state.current.rules, rule, index, state.status.routerIp, state.status.subnetMask);
        // Edit
        applicationTextController.text = rule?.description ?? '';
        internalPortTextController.text = '${rule?.internalPort ?? 0}';
        externalPortTextController.text = '${rule?.externalPort ?? 0}';
        ipAddressTextController.text = rule?.internalServerIPAddress ?? '';
        setState(() {
          _isEditRuleValid =
              ref.read(singlePortForwardingRuleProvider.notifier).isRuleValid();
        });
      },
      headers: [
        loc(context).applicationName,
        loc(context).internalPort,
        loc(context).externalPort,
        loc(context).protocol,
        loc(context).deviceIP,
      ],
      columnWidths: ResponsiveLayout.isOverLargeLayout(context)
          ? const {
              0: FractionColumnWidth(.2),
              1: FractionColumnWidth(.1),
              2: FractionColumnWidth(.1),
              3: FractionColumnWidth(.2),
              4: FractionColumnWidth(.22),
            }
          : const {
              0: FractionColumnWidth(.2),
              1: FractionColumnWidth(.12),
              2: FractionColumnWidth(.12),
              3: FractionColumnWidth(.2),
              4: FractionColumnWidth(.22),
            },
      dataList: [...state.current.rules],
      editRowIndex: 0,
      cellBuilder: (context, ref, index, rule) {
        return switch (index) {
          0 => AppText.bodySmall(rule.description),
          1 => AppText.bodySmall('${rule.internalPort}'),
          2 => AppText.bodySmall('${rule.externalPort}'),
          3 => AppText.bodySmall(getProtocolTitle(context, rule.protocol)),
          4 => AppText.bodySmall(rule.internalServerIPAddress),
          _ => AppText.bodySmall(''),
        };
      },
      editCellBuilder: (context, index, controller) {
        final stateRule = ref.watch(singlePortForwardingRuleProvider).rule;

        return switch (index) {
          0 => AppTextField.outline(
              controller: applicationTextController,
              onChanged: (value) {
                ref
                    .read(singlePortForwardingRuleProvider.notifier)
                    .updateRule(stateRule?.copyWith(description: value));
                setState(() {
                  _isEditRuleValid = ref
                      .read(singlePortForwardingRuleProvider.notifier)
                      .isRuleValid();
                });
              },
            ),
          1 => AppTextField.minMaxNumber(
              min: 0,
              max: 65535,
              border: OutlineInputBorder(),
              controller: internalPortTextController,
              onChanged: (value) {
                ref.read(singlePortForwardingRuleProvider.notifier).updateRule(
                    stateRule?.copyWith(
                        internalPort: int.tryParse(value) ?? 0));
                setState(() {
                  _isEditRuleValid = ref
                      .read(singlePortForwardingRuleProvider.notifier)
                      .isRuleValid();
                });
              },
            ),
          2 => AppTextField.minMaxNumber(
              min: 0,
              max: 65535,
              border: OutlineInputBorder(),
              controller: externalPortTextController,
              onChanged: (value) {
                ref.read(singlePortForwardingRuleProvider.notifier).updateRule(
                    stateRule?.copyWith(
                        externalPort: int.tryParse(value) ?? 0));
                setState(() {
                  _isEditRuleValid = ref
                      .read(singlePortForwardingRuleProvider.notifier)
                      .isRuleValid();
                });
              },
            ),
          3 => AppDropdownButton(
              initial: stateRule?.protocol,
              items: const ['TCP', 'UDP', 'Both'],
              label: (e) => getProtocolTitle(context, e),
              onChanged: (value) {
                ref
                    .read(singlePortForwardingRuleProvider.notifier)
                    .updateRule(stateRule?.copyWith(protocol: value));
                setState(() {
                  _isEditRuleValid = ref
                      .read(singlePortForwardingRuleProvider.notifier)
                      .isRuleValid();
                });
              },
            ),
          4 => AppIPFormField(
              controller: ipAddressTextController,
              border: const OutlineInputBorder(),
              octet1ReadOnly: submaskToken[0] == '255',
              octet2ReadOnly: submaskToken[1] == '255',
              octet3ReadOnly: submaskToken[2] == '255',
              octet4ReadOnly: submaskToken[3] == '255',
              onChanged: (value) {
                ref.read(singlePortForwardingRuleProvider.notifier).updateRule(
                    stateRule?.copyWith(internalServerIPAddress: value));
                setState(() {
                  _isEditRuleValid = ref
                      .read(singlePortForwardingRuleProvider.notifier)
                      .isRuleValid();
                });
              },
            ),
          _ => AppText.bodyLarge(''),
        };
      },
      onValidate: (index) {
        final notifier = ref.read(singlePortForwardingRuleProvider.notifier);
        return switch (index) {
          0 => notifier.isNameValid(applicationTextController.text)
              ? null
              : loc(context).theNameMustNotBeEmpty,
          2 => notifier.isPortConflict(
                  int.tryParse(externalPortTextController.text) ?? 0,
                  ref.read(singlePortForwardingRuleProvider).rule?.protocol ??
                      'Both')
              ? loc(context).rulesOverlapError
              : null,
          4 => notifier.isDeviceIpValidate(ipAddressTextController.text)
              ? null
              : loc(context).invalidIpAddress,
          _ => null,
        };
      },
      createNewItem: () => SinglePortForwardingRule(
          isEnabled: true,
          externalPort: 0,
          protocol: 'Both',
          internalServerIPAddress: prefixIP,
          internalPort: 0,
          description: ''),
      onSaved: (index, rule) {
        final stateRule = ref.read(singlePortForwardingRuleProvider).rule;
        if (stateRule == null) {
          return;
        }
        if (index == null) {
          // add
          ref
              .read(singlePortForwardingListProvider.notifier)
              .addRule(stateRule);
        } else {
          // edit
          ref
              .read(singlePortForwardingListProvider.notifier)
              .editRule(index, stateRule);
        }
      },
      onDeleted: (index, rule) {
        ref.read(singlePortForwardingListProvider.notifier).deleteRule(rule);
      },
      isEditingDataValid: _isEditRuleValid,
    );
  }
}
