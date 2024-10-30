import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/core/jnap/models/single_port_forwarding_rule.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ports/_ports.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ports/views/widgets/_widgets.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/page/components/styled/consts.dart';

import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';
import 'package:privacygui_widgets/widgets/card/setting_card.dart';
import 'package:privacygui_widgets/widgets/container/responsive_layout.dart';
import 'package:privacygui_widgets/widgets/dropdown/dropdown_button.dart';
import 'package:privacygui_widgets/widgets/gap/const/spacing.dart';
import 'package:privacygui_widgets/widgets/input_field/ip_form_field.dart';
import 'package:privacygui_widgets/widgets/page/layout/basic_layout.dart';
import 'package:privacygui_widgets/widgets/table/editable_table_settings_view.dart';

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

  late final TextEditingController applicationTextController;
  bool _isEditingValid = true;

  @override
  void initState() {
    _notifier = ref.read(singlePortForwardingListProvider.notifier);
    applicationTextController = TextEditingController();
    doSomethingWithSpinner(
      context,
      _notifier.fetch(),
    );

    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(singlePortForwardingListProvider);
    final submaskToken = ref
        .read(singlePortForwardingRuleProvider.notifier)
        .subnetMask
        .split('.');
    final prefixIP =
        ref.read(singlePortForwardingRuleProvider.notifier).ipAddress;
    return StyledAppPageView(
      title: loc(context).singlePortForwarding,
      scrollable: true,
      useMainPadding: false,
      appBarStyle: AppBarStyle.none,
      padding: EdgeInsets.zero,
      child: AppBasicLayout(
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppGap.large2(),
            AppText.bodyLarge(loc(context).singlePortForwardingDescription),
            if (!_notifier.isExceedMax()) ...[
              const AppGap.large2(),
              AddRuleCard(
                onTap: () {
                  context.pushNamed<bool?>(RouteNamed.singlePortForwardingRule,
                      extra: {'rules': state.rules}).then((value) {
                    if (value ?? false) {
                      _notifier.fetch();
                    }
                  });
                },
              ),
            ],
            const AppGap.large2(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.labelLarge(loc(context).rules),
                const AppGap.medium(),
                if (state.rules.isNotEmpty)
                  ...state.rules
                      .map(
                    (e) => RuleItemCard(
                      title: e.description,
                      isEnabled: e.isEnabled,
                      onTap: () {
                        context.pushNamed<bool?>(
                            RouteNamed.singlePortForwardingRule,
                            extra: {
                              'rules': state.rules,
                              'edit': e
                            }).then((value) {
                          if (value ?? false) {
                            _notifier.fetch();
                          }
                        });
                      },
                    ),
                  )
                      .expand((element) sync* {
                    yield element;
                    yield const AppGap.small2();
                  }),
                if (state.rules.isEmpty) const EmptyRuleCard(),
              ],
            ),
            const AppGap.medium(),
            AppEditableTableSettingsView<SinglePortForwardingRule>(
              title: loc(context).singlePortForwarding,
              headers: [
                'Application Name',
                loc(context).externalPort,
                loc(context).internalPort,
                'Protocol',
                'Device IP#',
              ],
              actionHeader: loc(context).action,
              columnWidths: ResponsiveLayout.isOverLargeLayout(context)
                  ? const {
                      0: FractionColumnWidth(.25),
                      1: FractionColumnWidth(.08),
                      2: FractionColumnWidth(.08),
                      3: FractionColumnWidth(.18),
                      4: FractionColumnWidth(.27),
                    }
                  : const {
                      0: FractionColumnWidth(.2),
                      1: FractionColumnWidth(.08),
                      2: FractionColumnWidth(.08),
                      3: FractionColumnWidth(.2),
                      4: FractionColumnWidth(.3),
                    },
              dataList: [...state.rules],
              editRowIndex: 0,
              cellBuilder: (context, index, rule) {
                return switch (index) {
                  0 => AppText.bodyLarge(rule.description),
                  1 => AppText.bodyLarge('${rule.externalPort}'),
                  2 => AppText.bodyLarge('${rule.internalPort}'),
                  3 =>
                    AppText.bodyLarge(getProtocolTitle(context, rule.protocol)),
                  4 => AppText.bodyLarge(rule.internalServerIPAddress),
                  _ => AppText.bodyLarge(''),
                };
              },
              editCellBuilder: (context, index, rule) {
                return switch (index) {
                  0 => AppTextField.outline(
                      controller: applicationTextController,
                      onChanged: (value) {
                        setState(() {
                          _isEditingValid = value.isNotEmpty;
                        });
                      },
                    ),
                  1 => AppTextField.minMaxNumber(
                      min: 0,
                      max: 65535,
                      border: OutlineInputBorder(),
                      controller: TextEditingController()
                        ..text = '${rule.externalPort}'),
                  2 => AppTextField.minMaxNumber(
                      min: 0,
                      max: 65535,
                      border: OutlineInputBorder(),
                      controller: TextEditingController()
                        ..text = '${rule.internalPort}'),
                  3 => AppDropdownButton(
                      initial: rule.protocol,
                      items: const ['TCP', 'UDP', 'Both'],
                      label: (e) => getProtocolTitle(context, e),
                      onChanged: (value) {},
                    ),
                  4 => AppIPFormField(
                      controller: TextEditingController()
                        ..text = rule.internalServerIPAddress,
                      border: const OutlineInputBorder(),
                      octet1ReadOnly: submaskToken[0] == '255',
                      octet2ReadOnly: submaskToken[1] == '255',
                      octet3ReadOnly: submaskToken[2] == '255',
                      octet4ReadOnly: submaskToken[3] == '255',
                    ),
                  _ => AppText.bodyLarge(''),
                };
              },
              createNewItem: () => SinglePortForwardingRule(
                  isEnabled: true,
                  externalPort: 0,
                  protocol: 'Both',
                  internalServerIPAddress: prefixIP,
                  internalPort: 0,
                  description: ''),
              isEditingDataValid: _isEditingValid,
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
                            description: '${rule.internalPort}',
                          )
                        ],
                      ),
                      TableRow(
                        children: [
                          AppSettingCard.noBorder(
                            padding: EdgeInsets.only(bottom: Spacing.medium),
                            title: loc(context).protocol,
                            description:
                                getProtocolTitle(context, rule.protocol),
                          ),
                          AppSettingCard.noBorder(
                            padding: EdgeInsets.only(bottom: Spacing.medium),
                            title: loc(context).ipAddress,
                            description: rule.internalServerIPAddress,
                          )
                        ],
                      ),
                    ],
                  )),
              editItemCardBuilder: (context, rule) {
                return AppCard(
                    child: Column(
                  children: [
                    AppTextField.outline(
                      controller: applicationTextController,
                    ),
                    AppDropdownButton(
                      initial: rule.protocol,
                      items: const ['TCP', 'UDP', 'Both'],
                      label: (e) => getProtocolTitle(context, e),
                      onChanged: (value) {},
                    ),
                    AppIPFormField(
                      controller: TextEditingController()
                        ..text = rule.internalServerIPAddress,
                      border: const OutlineInputBorder(),
                      octet1ReadOnly: submaskToken[0] == '255',
                      octet2ReadOnly: submaskToken[1] == '255',
                      octet3ReadOnly: submaskToken[2] == '255',
                      octet4ReadOnly: submaskToken[3] == '255',
                    ),
                  ],
                ));
              },
            )
          ],
        ),
      ),
    );
  }
}
