import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/jnap/models/port_range_triggering_rule.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ports/_ports.dart';
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
import 'package:privacygui_widgets/widgets/gap/const/spacing.dart';
import 'package:privacygui_widgets/widgets/page/layout/basic_layout.dart';

class PortRangeTriggeringListView extends ArgumentsConsumerStatelessView {
  const PortRangeTriggeringListView({super.key, super.args});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PortRangeTriggeringListContentView(
      args: super.args,
    );
  }
}

class PortRangeTriggeringListContentView extends ArgumentsConsumerStatefulView {
  const PortRangeTriggeringListContentView({super.key, super.args});

  @override
  ConsumerState<PortRangeTriggeringListContentView> createState() =>
      _PortRangeTriggeringContentViewState();
}

class _PortRangeTriggeringContentViewState
    extends ConsumerState<PortRangeTriggeringListContentView> {
  late final PortRangeTriggeringListNotifier _notifier;
  PortRangeTriggeringListState? preservedState;

  // Fro Edit table settings
  final TextEditingController applicationTextController =
      TextEditingController();
  final TextEditingController firstTriggerPortController =
      TextEditingController();
  final TextEditingController lastTriggerPortController =
      TextEditingController();
  final TextEditingController firstForwardedPortController =
      TextEditingController();
  final TextEditingController lastForwardedPortController =
      TextEditingController();
  bool _isEditRuleValid = false;

  @override
  void initState() {
    super.initState();
    _notifier = ref.read(portRangeTriggeringListProvider.notifier);
    doSomethingWithSpinner(
      context,
      _notifier.fetch(),
    ).then((state) {
      setState(() {
        preservedState = state;
      });
    });
  }

  @override
  void dispose() {
    applicationTextController.dispose();
    firstTriggerPortController.dispose();
    lastTriggerPortController.dispose();
    firstForwardedPortController.dispose();
    lastForwardedPortController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(portRangeTriggeringListProvider);
    return StyledAppPageView(
      scrollable: true,
      useMainPadding: false,
      appBarStyle: AppBarStyle.none,
      padding: EdgeInsets.zero,
      title: loc(context).portRangeTriggering,
      bottomBar: PageBottomBar(
          isPositiveEnabled: state != preservedState,
          onPositiveTap: () {
            doSomethingWithSpinner(context, _notifier.save()).then((state) {
              setState(() {
                preservedState = state;
              });
            });
          }),
      child: AppBasicLayout(
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // const AppGap.large2(),
            // AppText.bodyLarge(loc(context).portRangeForwardingDescription),
            // if (!_notifier.isExceedMax()) ...[
            //   const AppGap.large2(),
            //   AddRuleCard(
            //     onTap: () {
            //       context.pushNamed<bool?>(RouteNamed.protRangeTriggeringRule,
            //           extra: {'rules': state.rules}).then((value) {
            //         if (value ?? false) {
            //           _notifier.fetch();
            //         }
            //       });
            //     },
            //   ),
            // ],
            const AppGap.large2(),
            ResponsiveLayout(
                desktop: _desktopSettingsView(state),
                mobile: _mobildSettingsView(state))
          ],
        ),
      ),
    );
  }

  Widget _mobildSettingsView(PortRangeTriggeringListState state) {
    // return Center();
    return EditableCardListsettingsView<PortRangeTriggeringRule>(
        title: loc(context).portRangeTriggering,
        addLabel: loc(context).add,
        addEnabled: _notifier.isExceedMax(),
        emptyMessage: loc(context).noPortRangeTriggering,
        itemCardBuilder: (context, rule) => EditableListItem(
              title: rule.description,
              content: Table(
                children: [
                  TableRow(
                    children: [
                      AppSettingCard.noBorder(
                        padding: EdgeInsets.only(bottom: Spacing.medium),
                        title: loc(context).triggeredRange,
                        description:
                            '${rule.firstTriggerPort} ${loc(context).to} ${rule.lastTriggerPort}',
                      ),
                    ],
                  ),
                  TableRow(
                    children: [
                      AppSettingCard.noBorder(
                        padding: EdgeInsets.only(bottom: Spacing.medium),
                        title: loc(context).forwardedRange,
                        description:
                            '${rule.firstForwardedPort} ${loc(context).to} ${rule.lastForwardedPort}',
                      ),
                    ],
                  ),
                ],
              ),
            ),
        editRoute: RouteNamed.portRangeTriggeringRule,
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

  Widget _desktopSettingsView(PortRangeTriggeringListState state) {
    return AppEditableTableSettingsView<PortRangeTriggeringRule>(
      title: loc(context).portRangeTriggering,
      emptyMessage: loc(context).noPortRangeTriggering,
      addEnabled: _notifier.isExceedMax(),
      onStartEdit: (index, rule) {
        ref
            .read(portRangeTriggeringRuleProvider.notifier)
            .init(state.rules, rule, index);
        // Edit
        applicationTextController.text = rule?.description ?? '';
        firstTriggerPortController.text = '${rule?.firstTriggerPort ?? 0}';
        lastTriggerPortController.text = '${rule?.lastTriggerPort ?? 0}';
        firstForwardedPortController.text = '${rule?.firstForwardedPort ?? 0}';
        lastForwardedPortController.text = '${rule?.lastForwardedPort ?? 0}';
        setState(() {
          _isEditRuleValid =
              ref.read(portRangeTriggeringRuleProvider.notifier).isRuleValid();
        });
      },
      headers: [
        loc(context).applicationName,
        loc(context).triggeredRange,
        loc(context).forwardedRange,
      ],
      columnWidths: ResponsiveLayout.isOverLargeLayout(context)
          ? const {
              0: FractionColumnWidth(.3),
              1: FractionColumnWidth(.25),
              2: FractionColumnWidth(.25),
            }
          : const {
              0: FractionColumnWidth(.3),
              1: FractionColumnWidth(.25),
              2: FractionColumnWidth(.25),
            },
      dataList: [...state.rules],
      editRowIndex: 0,
      cellBuilder: (context, ref, index, rule) {
        return switch (index) {
          0 => AppText.bodySmall(rule.description),
          1 => AppText.bodySmall(
              '${rule.firstTriggerPort} ${loc(context).to} ${rule.lastTriggerPort}'),
          2 => AppText.bodySmall(
              '${rule.firstForwardedPort} ${loc(context).to} ${rule.lastForwardedPort}'),
          _ => AppText.bodyLarge(''),
        };
      },
      editCellBuilder: (context, ref, index, rule) {
        final stateRule = ref.watch(portRangeTriggeringRuleProvider).rule;

        return switch (index) {
          0 => AppTextField.outline(
              controller: applicationTextController,
              onChanged: (value) {
                ref
                    .read(portRangeTriggeringRuleProvider.notifier)
                    .updateRule(stateRule?.copyWith(description: value));
                setState(() {
                  _isEditRuleValid = ref
                      .read(portRangeTriggeringRuleProvider.notifier)
                      .isRuleValid();
                });
              },
            ),
          1 => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(
                  child: AppTextField.minMaxNumber(
                    min: 0,
                    max: 65535,
                    border: OutlineInputBorder(),
                    controller: firstTriggerPortController,
                    onChanged: (value) {
                      ref
                          .read(portRangeTriggeringRuleProvider.notifier)
                          .updateRule(stateRule?.copyWith(
                              firstTriggerPort: int.tryParse(value) ?? 0));
                      setState(() {
                        _isEditRuleValid = ref
                            .read(portRangeTriggeringRuleProvider.notifier)
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
                    controller: lastTriggerPortController,
                    onChanged: (value) {
                      ref
                          .read(portRangeTriggeringRuleProvider.notifier)
                          .updateRule(stateRule?.copyWith(
                              lastTriggerPort: int.tryParse(value) ?? 0));
                      setState(() {
                        _isEditRuleValid = ref
                            .read(portRangeTriggeringRuleProvider.notifier)
                            .isRuleValid();
                      });
                    },
                  ),
                ),
              ],
            ),
          2 => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(
                  child: AppTextField.minMaxNumber(
                    min: 0,
                    max: 65535,
                    border: OutlineInputBorder(),
                    controller: firstForwardedPortController,
                    onChanged: (value) {
                      ref
                          .read(portRangeTriggeringRuleProvider.notifier)
                          .updateRule(stateRule?.copyWith(
                              firstForwardedPort: int.tryParse(value) ?? 0));
                      setState(() {
                        _isEditRuleValid = ref
                            .read(portRangeTriggeringRuleProvider.notifier)
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
                    controller: lastForwardedPortController,
                    onChanged: (value) {
                      ref
                          .read(portRangeTriggeringRuleProvider.notifier)
                          .updateRule(stateRule?.copyWith(
                              lastForwardedPort: int.tryParse(value) ?? 0));
                      setState(() {
                        _isEditRuleValid = ref
                            .read(portRangeTriggeringRuleProvider.notifier)
                            .isRuleValid();
                      });
                    },
                  ),
                ),
              ],
            ),
          _ => AppText.bodyLarge(''),
        };
      },
      createNewItem: () => const PortRangeTriggeringRule(
          isEnabled: true,
          description: '',
          firstTriggerPort: 0,
          lastTriggerPort: 0,
          firstForwardedPort: 0,
          lastForwardedPort: 0),
      onSaved: (index, rule) {
        final stateRule = ref.read(portRangeTriggeringRuleProvider).rule;
        if (stateRule == null) {
          return;
        }
        if (index == null) {
          // add
          ref.read(portRangeTriggeringListProvider.notifier).addRule(stateRule);
        } else {
          // edit
          ref
              .read(portRangeTriggeringListProvider.notifier)
              .editRule(index, stateRule);
        }
      },
      onDeleted: (index, rule) {
        ref.read(portRangeTriggeringListProvider.notifier).deleteRule(rule);
      },
      isEditingDataValid: _isEditRuleValid,
    );
  }
}
