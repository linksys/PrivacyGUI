import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/jnap/models/get_routing_settings.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
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
      child: StyledAppPageView(
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
        onBackTap: null,
        child: (context, constraints) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppRadioList(
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
    );
  }

  Widget _mobildSettingsView(
      StaticRoutingState state, List<String> submaskToken, String prefixIP) {
    // return Center();
    return EditableCardListsettingsView<NamedStaticRouteEntry>(
        title: loc(context).staticRouting,
        emptyMessage: loc(context).noAdvancedRouting,
        addLabel: loc(context).add,
        addEnabled: !_notifier.isExceedMax(),
        itemCardBuilder: (context, rule) => EditableListItem(
              title: rule.name,
              content: Table(
                children: [
                  TableRow(
                    children: [
                      AppSettingCard.noBorder(
                        padding: EdgeInsets.only(bottom: Spacing.medium),
                        title: loc(context).destinationIPAddress,
                        description: rule.settings.destinationLAN,
                      ),
                      AppSettingCard.noBorder(
                        padding: EdgeInsets.only(bottom: Spacing.medium),
                        title: loc(context).subnetMask,
                        description: NetworkUtils.prefixLengthToSubnetMask(
                            rule.settings.networkPrefixLength),
                      )
                    ],
                  ),
                  TableRow(
                    children: [
                      AppSettingCard.noBorder(
                        padding: EdgeInsets.only(bottom: Spacing.medium),
                        title: loc(context).gateway,
                        description: rule.settings.gateway ?? '--',
                      ),
                      AppSettingCard.noBorder(
                        padding: EdgeInsets.only(bottom: Spacing.medium),
                        title: loc(context).labelInterface,
                        description: getInterfaceTitle(rule.settings.interface),
                      )
                    ],
                  ),
                ],
              ),
            ),
        editRoute: RouteNamed.settingsStaticRoutingRule,
        dataList: state.current.entries.entries,
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

  Widget _desktopSettingsView(
      StaticRoutingState state, List<String> submaskToken, String prefixIP) {
    return AppEditableTableSettingsView<NamedStaticRouteEntry>(
      title: loc(context).staticRouting,
      emptyMessage: loc(context).noStaticRoutes,
      addEnabled: !_notifier.isExceedMax(),
      pivotalIndex: 4, // Changes on the interface may make other values invalid
      onStartEdit: (index, rule) {
        currentFocus = null;
        ref.read(staticRoutingRuleProvider.notifier).init(
            state.current.entries.entries,
            rule,
            index,
            state.status.routerIp,
            state.status.subnetMask);
        // Edit
        routerNameTextController.text = rule?.name ?? '';
        destinationIPTextController.text =
            '${rule?.settings.destinationLAN ?? 0}';
        subnetMaskTextController.text = NetworkUtils.prefixLengthToSubnetMask(
            rule?.settings.networkPrefixLength ?? 0);
        gatewayTextController.text = rule?.settings.gateway ?? '';
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
      dataList: [...state.current.entries.entries],
      editRowIndex: 0,
      cellBuilder: (context, ref, index, rule) {
        return switch (index) {
          0 => AppText.bodySmall(rule.name),
          1 => AppText.bodySmall(rule.settings.destinationLAN),
          2 => AppText.bodySmall(NetworkUtils.prefixLengthToSubnetMask(
              rule.settings.networkPrefixLength)),
          3 => AppText.bodySmall(rule.settings.gateway ?? '--'),
          4 => AppText.bodySmall(getInterfaceTitle(rule.settings.interface)),
          _ => AppText.bodySmall(''),
        };
      },
      editCellBuilder: (context, index, controller) {
        final stateRule = ref.watch(staticRoutingRuleProvider).rule;
        return switch (index) {
          0 => AppTextField.outline(
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
              displayType: AppIpFormFieldDisplayType.tight,
              controller: destinationIPTextController,
              border: const OutlineInputBorder(),
              onChanged: (value) {
                ref.read(staticRoutingRuleProvider.notifier).updateRule(
                      stateRule?.copyWith(
                        settings:
                            stateRule.settings.copyWith(destinationLAN: value),
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
              displayType: AppIpFormFieldDisplayType.tight,
              controller: subnetMaskTextController,
              border: const OutlineInputBorder(),
              onChanged: (value) {
                ref.read(staticRoutingRuleProvider.notifier).updateRule(
                      stateRule?.copyWith(
                        settings: stateRule.settings.copyWith(
                          networkPrefixLength:
                              NetworkUtils.subnetMaskToPrefixLength(value),
                        ),
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
              displayType: AppIpFormFieldDisplayType.tight,
              controller: gatewayTextController,
              border: const OutlineInputBorder(),
              onChanged: (value) {
                ref.read(staticRoutingRuleProvider.notifier).updateRule(
                      stateRule?.copyWith(
                        settings:
                            stateRule.settings.copyWith(gateway: () => value),
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
              title: loc(context).labelInterface,
              items: const [
                RoutingSettingInterface.lan,
                RoutingSettingInterface.internet,
              ],
              initial: RoutingSettingInterface.resolve(
                  stateRule?.settings.interface ?? 'LAN'),
              label: (item) => getInterfaceTitle(item.value),
              onChanged: (value) {
                ref.read(staticRoutingRuleProvider.notifier).updateRule(
                      stateRule?.copyWith(
                        settings:
                            stateRule.settings.copyWith(interface: value.value),
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
                  (stateRule?.settings.interface ?? 'LAN') == 'LAN')
              ? null
              : loc(context).invalidGatewayIpAddress,
          _ => null,
        };
      },
      createNewItem: () => NamedStaticRouteEntry(
        name: '',
        settings: StaticRouteEntry(
          destinationLAN: '',
          interface: 'LAN',
          networkPrefixLength: 24,
        ),
      ),
      onSaved: (index, rule) {
        final stateRule = ref.read(staticRoutingRuleProvider).rule;
        if (stateRule == null) {
          return;
        }
        if (index == null) {
          // add
          ref.read(staticRoutingProvider.notifier).addRule(stateRule);
        } else {
          // edit
          ref.read(staticRoutingProvider.notifier).editRule(index, stateRule);
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
