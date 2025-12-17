import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/advanced_settings/static_routing/models/static_route_entry_ui_model.dart';
import 'package:privacy_gui/page/advanced_settings/static_routing/models/static_routing_rule_ui_model.dart';
import 'package:privacy_gui/page/advanced_settings/static_routing/providers/static_routing_provider.dart';
import 'package:privacy_gui/page/advanced_settings/static_routing/providers/static_routing_rule_provider.dart';
import 'package:privacy_gui/page/advanced_settings/static_routing/providers/static_routing_state.dart';
import 'package:privacy_gui/page/components/mixin/page_snackbar_mixin.dart';
import 'package:privacy_gui/page/components/settings_view/editable_card_list_settings_view.dart';
import 'package:privacy_gui/page/components/settings_view/editable_table_settings_view.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/utils.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/setting_card.dart';
import 'package:privacygui_widgets/widgets/container/responsive_layout.dart';
import 'package:privacygui_widgets/widgets/dropdown/dropdown_button.dart';
import 'package:privacygui_widgets/widgets/gap/const/spacing.dart';
import 'package:privacygui_widgets/widgets/input_field/ip_form_field.dart';
import 'package:privacygui_widgets/widgets/input_field/ip_form_field_display_type.dart';
import 'package:privacygui_widgets/widgets/radios/radio_list.dart';

class StaticRoutingView extends ArgumentsConsumerStatefulView {
  const StaticRoutingView({
    Key? key,
    super.args,
  }) : super(key: key);

  @override
  ConsumerState<StaticRoutingView> createState() => _StaticRoutingViewState();
}

class _StaticRoutingViewState extends ConsumerState<StaticRoutingView>
    with PageSnackbarMixin {
  late final StaticRoutingNotifier _notifier;

  // Fro Edit table settings
  final TextEditingController routerNameTextController =
      TextEditingController();
  final TextEditingController destinationIPTextController =
      TextEditingController();
  final TextEditingController subnetMaskTextController =
      TextEditingController();
  final TextEditingController gatewayTextController = TextEditingController();
  bool _isEditRuleValid = false;
  int? currentFocus;

  @override
  void initState() {
    super.initState();

    _notifier = ref.read(staticRoutingProvider.notifier);

    doSomethingWithSpinner(
      context,
      _notifier.fetch(),
    );
  }

  @override
  void dispose() {
    routerNameTextController.dispose();
    destinationIPTextController.dispose();
    subnetMaskTextController.dispose();
    gatewayTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(staticRoutingProvider);
    final submaskToken = state.status.subnetMask.split('.');
    final prefixIP = state.status.routerIp;
    return Theme(
      data: Theme.of(context).copyWith(
          inputDecorationTheme: Theme.of(context)
              .inputDecorationTheme
              .copyWith(contentPadding: EdgeInsets.all(Spacing.small1))),
      child: StyledAppPageView.withSliver(
        title: loc(context).advancedRouting,
        scrollable: true,
        bottomBar: PageBottomBar(
            isPositiveEnabled: state.isDirty,
            onPositiveTap: () {
              doSomethingWithSpinner(context, _notifier.save()).then((_) {
                showChangesSavedSnackBar();
              }).onError((error, stackTrace) {
                showErrorMessageSnackBar(error);
              });
            }),
        child: (context, constraints) => SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppRadioList(
                key: const Key('settingNetwork'),
                selected: state.current.isNATEnabled
                    ? RoutingSettingNetwork.nat
                    : RoutingSettingNetwork.dynamicRouting,
                itemHeight: 56,
                items: [
                  AppRadioListItem(
                    title: loc(context).nat,
                    value: RoutingSettingNetwork.nat,
                  ),
                  AppRadioListItem(
                    title: loc(context).dynamicRouting,
                    value: RoutingSettingNetwork.dynamicRouting,
                  ),
                ],
                onChanged: (index, value) {
                  if (value != null) {
                    _notifier.updateSettingNetwork(value);
                  }
                },
              ),
              const AppGap.large2(),
              ResponsiveLayout(
                  desktop: _desktopSettingsView(state, submaskToken, prefixIP),
                  mobile: _mobildSettingsView(state, submaskToken, prefixIP))
            ],
          ),
        ),
      ),
    );
  }

  Widget _mobildSettingsView(
      StaticRoutingState state, List<String> submaskToken, String prefixIP) {
    // return Center();
    return EditableCardListsettingsView<StaticRoutingRuleUIModel>(
        title: loc(context).staticRouting,
        emptyMessage: loc(context).noAdvancedRouting,
        addLabel: loc(context).add,
        addEnabled: !_notifier.isExceedMax(),
        itemCardBuilder: (context, rule) {
          // Convert from StaticRoutingRuleUIModel (CIDR) to display format
          final displaySubnetMask =
              NetworkUtils.prefixLengthToSubnetMask(rule.networkPrefixLength);
          return EditableListItem(
            title: rule.name,
            content: Table(
              children: [
                TableRow(
                  children: [
                    AppSettingCard.noBorder(
                      padding: EdgeInsets.only(bottom: Spacing.medium),
                      title: loc(context).destinationIPAddress,
                      description: rule.destinationIP,
                    ),
                    AppSettingCard.noBorder(
                      padding: EdgeInsets.only(bottom: Spacing.medium),
                      title: loc(context).subnetMask,
                      description: displaySubnetMask,
                    )
                  ],
                ),
                TableRow(
                  children: [
                    AppSettingCard.noBorder(
                      padding: EdgeInsets.only(bottom: Spacing.medium),
                      title: loc(context).gateway,
                      description: rule.gateway?.isEmpty ?? true
                          ? '--'
                          : rule.gateway ?? '--',
                    ),
                    AppSettingCard.noBorder(
                      padding: EdgeInsets.only(bottom: Spacing.medium),
                      title: loc(context).labelInterface,
                      description: getInterfaceTitle(rule.interface),
                    )
                  ],
                ),
              ],
            ),
          );
        },
        editRoute: RouteNamed.settingsStaticRoutingRule,
        // Convert entries to StaticRoutingRuleUIModel for editor
        dataList: state.current.entries
            .map((e) => StaticRoutingRuleUIModel(
                  name: e.name,
                  destinationIP: e.destinationIP,
                  networkPrefixLength:
                      NetworkUtils.subnetMaskToPrefixLength(e.subnetMask),
                  gateway: e.gateway.isEmpty ? null : e.gateway,
                  interface: e.interface,
                ))
            .toList(),
        onSave: (index, rule) {
          // Convert from StaticRoutingRuleUIModel back to StaticRouteEntryUIModel
          final uiEntry = StaticRouteEntryUIModel(
            name: rule.name,
            destinationIP: rule.destinationIP,
            subnetMask:
                NetworkUtils.prefixLengthToSubnetMask(rule.networkPrefixLength),
            gateway: rule.gateway ?? '',
            interface: rule.interface,
          );
          if (index >= 0) {
            _notifier.editRule(index, uiEntry);
          } else {
            _notifier.addRule(uiEntry);
          }
        },
        onDelete: (index, rule) {
          // Convert for deletion
          final uiEntry = StaticRouteEntryUIModel(
            name: rule.name,
            destinationIP: rule.destinationIP,
            subnetMask:
                NetworkUtils.prefixLengthToSubnetMask(rule.networkPrefixLength),
            gateway: rule.gateway ?? '',
            interface: rule.interface,
          );
          _notifier.deleteRule(uiEntry);
        });
  }

  Widget _desktopSettingsView(
      StaticRoutingState state, List<String> submaskToken, String prefixIP) {
    return AppEditableTableSettingsView<StaticRouteEntryUIModel>(
      title: loc(context).staticRouting,
      emptyMessage: loc(context).noStaticRoutes,
      addEnabled: !_notifier.isExceedMax(),
      pivotalIndex: 4, // Changes on the interface may make other values invalid
      onStartEdit: (index, rule) {
        currentFocus = null;
        // Entries are already UI models, no conversion needed
        final uiEntries = state.current.entries;

        // Create UI rule for editor (with CIDR notation prefix length)
        final uiRule = rule != null
            ? StaticRoutingRuleUIModel(
                name: rule.name,
                destinationIP: rule.destinationIP,
                networkPrefixLength:
                    NetworkUtils.subnetMaskToPrefixLength(rule.subnetMask),
                gateway: rule.gateway.isEmpty ? null : rule.gateway,
                interface: 'LAN',
              )
            : null;

        ref.read(staticRoutingRuleProvider.notifier).init(
            uiEntries
                .map((e) => StaticRoutingRuleUIModel(
                      name: e.name,
                      destinationIP: e.destinationIP,
                      networkPrefixLength:
                          NetworkUtils.subnetMaskToPrefixLength(e.subnetMask),
                      gateway: e.gateway.isEmpty ? null : e.gateway,
                      interface: 'LAN',
                    ))
                .toList(),
            uiRule,
            index,
            state.status.routerIp,
            state.status.subnetMask);
        // Edit
        routerNameTextController.text = rule?.name ?? '';
        destinationIPTextController.text = rule?.destinationIP ?? '';
        subnetMaskTextController.text = rule?.subnetMask ?? '';
        gatewayTextController.text = rule?.gateway ?? '';
        setState(() {
          _isEditRuleValid =
              ref.read(staticRoutingRuleProvider.notifier).isRuleValid();
        });
      },
      headers: [
        loc(context).routeName,
        loc(context).destinationIPAddress,
        loc(context).subnetMask,
        loc(context).gateway,
        loc(context).labelInterface,
      ],
      columnWidths: ResponsiveLayout.isOverLargeLayout(context)
          ? const {
              0: FractionColumnWidth(.15),
              1: FractionColumnWidth(.2),
              2: FractionColumnWidth(.2),
              3: FractionColumnWidth(.2),
              4: FractionColumnWidth(.15),
            }
          : const {
              0: FractionColumnWidth(.15),
              1: FractionColumnWidth(.2),
              2: FractionColumnWidth(.2),
              3: FractionColumnWidth(.2),
              4: FractionColumnWidth(.15),
            },
      dataList: [...state.current.entries],
      editRowIndex: 0,
      cellBuilder: (context, ref, index, rule) {
        return switch (index) {
          0 => AppText.bodySmall(rule.name),
          1 => AppText.bodySmall(rule.destinationIP),
          2 => AppText.bodySmall(rule.subnetMask),
          3 => AppText.bodySmall(rule.gateway.isEmpty ? '--' : rule.gateway),
          4 => AppText.bodySmall(getInterfaceTitle(rule.interface)),
          _ => AppText.bodySmall(''),
        };
      },
      editCellBuilder: (context, index, controller) {
        final stateRule = ref.watch(staticRoutingRuleProvider).rule;
        return switch (index) {
          0 => AppTextField.outline(
              key: const Key('ruleName'),
              controller: routerNameTextController,
              onChanged: (value) {
                ref
                    .read(staticRoutingRuleProvider.notifier)
                    .updateRule(stateRule?.copyWith(name: value));
                setState(() {
                  _isEditRuleValid = ref
                      .read(staticRoutingRuleProvider.notifier)
                      .isRuleValid();
                });
              },
            ),
          1 => AppIPFormField(
              key: const Key('destinationIP'),
              displayType: AppIpFormFieldDisplayType.tight,
              controller: destinationIPTextController,
              border: const OutlineInputBorder(),
              onChanged: (value) {
                ref.read(staticRoutingRuleProvider.notifier).updateRule(
                      stateRule?.copyWith(
                        destinationIP: value,
                      ),
                    );
                setState(() {
                  _isEditRuleValid = ref
                      .read(staticRoutingRuleProvider.notifier)
                      .isRuleValid();
                });
              },
            ),
          2 => AppIPFormField(
              key: const Key('subnetMask'),
              displayType: AppIpFormFieldDisplayType.tight,
              controller: subnetMaskTextController,
              border: const OutlineInputBorder(),
              onChanged: (value) {
                ref.read(staticRoutingRuleProvider.notifier).updateRule(
                      stateRule?.copyWith(
                        networkPrefixLength:
                            NetworkUtils.subnetMaskToPrefixLength(value),
                      ),
                    );
                setState(() {
                  _isEditRuleValid = ref
                      .read(staticRoutingRuleProvider.notifier)
                      .isRuleValid();
                });
              },
            ),
          3 => AppIPFormField(
              key: const Key('gateway'),
              displayType: AppIpFormFieldDisplayType.tight,
              controller: gatewayTextController,
              border: const OutlineInputBorder(),
              onChanged: (value) {
                ref.read(staticRoutingRuleProvider.notifier).updateRule(
                      stateRule?.copyWith(
                        gateway: value,
                      ),
                    );
                setState(() {
                  _isEditRuleValid = ref
                      .read(staticRoutingRuleProvider.notifier)
                      .isRuleValid();
                });
              },
            ),
          4 => AppDropdownButton<RoutingSettingInterface>(
              key: const Key('interface'),
              title: loc(context).labelInterface,
              items: const [
                RoutingSettingInterface.lan,
                RoutingSettingInterface.internet,
              ],
              initial: RoutingSettingInterface.resolve(
                  stateRule?.interface ?? 'LAN'),
              label: (item) => getInterfaceTitle(item.value),
              onChanged: (value) {
                ref.read(staticRoutingRuleProvider.notifier).updateRule(
                      stateRule?.copyWith(
                        interface: value.value,
                      ),
                    );
                setState(() {
                  _isEditRuleValid = ref
                      .read(staticRoutingRuleProvider.notifier)
                      .isRuleValid();
                });
              },
            ),
          _ => AppText.bodyLarge(''),
        };
      },
      onValidate: (index) {
        final stateRule = ref.watch(staticRoutingRuleProvider).rule;
        return switch (index) {
          0 => ref
                  .read(staticRoutingRuleProvider.notifier)
                  .isNameValid(routerNameTextController.text)
              ? null
              : loc(context).theNameMustNotBeEmpty,
          1 => ref
                  .read(staticRoutingRuleProvider.notifier)
                  .isValidIpAddress(destinationIPTextController.text)
              ? null
              : loc(context).invalidIpAddress,
          2 => ref.read(staticRoutingRuleProvider.notifier).isValidSubnetMask(
                  NetworkUtils.subnetMaskToPrefixLength(
                      subnetMaskTextController.text))
              ? null
              : loc(context).invalidSubnetMask,
          3 => ref.read(staticRoutingRuleProvider.notifier).isValidIpAddress(
                  gatewayTextController.text,
                  (stateRule?.interface ?? 'LAN') == 'LAN')
              ? null
              : loc(context).invalidGatewayIpAddress,
          _ => null,
        };
      },
      createNewItem: () => const StaticRouteEntryUIModel(
        name: '',
        destinationIP: '',
        subnetMask: '255.255.255.0',
        gateway: '',
        interface: 'LAN',
      ),
      onSaved: (index, rule) {
        final stateRule = ref.read(staticRoutingRuleProvider).rule;
        if (stateRule == null) {
          return;
        }
        // Convert StaticRoutingRuleUIModel to StaticRouteEntryUIModel
        final uiEntry = StaticRouteEntryUIModel(
          name: stateRule.name,
          destinationIP: stateRule.destinationIP,
          subnetMask: NetworkUtils.prefixLengthToSubnetMask(
              stateRule.networkPrefixLength),
          gateway: stateRule.gateway ?? '',
          interface: stateRule.interface,
        );
        if (index == null) {
          // add
          ref.read(staticRoutingProvider.notifier).addRule(uiEntry);
        } else {
          // edit
          ref.read(staticRoutingProvider.notifier).editRule(index, uiEntry);
        }
      },
      onDeleted: (index, rule) {
        ref.read(staticRoutingProvider.notifier).deleteRule(rule);
      },
      isEditingDataValid: _isEditRuleValid,
    );
  }

  String getInterfaceTitle(String interface) {
    final resolved = RoutingSettingInterface.resolve(interface);
    return switch (resolved) {
      RoutingSettingInterface.lan => loc(context).lanWireless,
      RoutingSettingInterface.internet =>
        RoutingSettingInterface.internet.value,
    };
  }
}
