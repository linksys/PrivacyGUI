import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/core/jnap/models/get_routing_settings.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/advanced_settings/static_routing/providers/static_routing_provider.dart';
import 'package:privacy_gui/page/advanced_settings/static_routing/providers/static_routing_rule_provider.dart';
import 'package:privacy_gui/page/advanced_settings/static_routing/providers/static_routing_state.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:privacy_gui/utils.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';
import 'package:privacygui_widgets/widgets/dropdown/dropdown_button.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/gap/const/spacing.dart';
import 'package:privacygui_widgets/widgets/input_field/ip_form_field.dart';

class StaticRoutingRuleView extends ArgumentsConsumerStatefulView {
  const StaticRoutingRuleView({
    super.key,
    super.args,
  });

  @override
  ConsumerState<StaticRoutingRuleView> createState() =>
      _StaticRoutingDetailViewState();
}

class _StaticRoutingDetailViewState
    extends ConsumerState<StaticRoutingRuleView> {
  late final StaticRoutingRuleNotifier _notifier;

  final _routeNameController = TextEditingController();
  final _subnetController = TextEditingController();
  final _gatewayController = TextEditingController();
  final _destinationIpController = TextEditingController();

  String? _destinationIpError;
  String? _subnetMaskError;
  String? _gatewayIpError;
  bool _isEdit = false;

  @override
  void initState() {
    _notifier = ref.read(staticRoutingRuleProvider.notifier);
    final state = ref.read(staticRoutingProvider);
    final routerIp = state.routerIp;
    final subnetMask = state.subnetMask;
    final rules = widget.args['items'] as List<NamedStaticRouteEntry>? ?? [];
    var rule = widget.args['edit'] as NamedStaticRouteEntry?;
    int? index;

    if (rule != null) {
      _isEdit = true;
      _routeNameController.text = rule!.name;
      _subnetController.text = NetworkUtils.prefixLengthToSubnetMask(
          rule.settings.networkPrefixLength);
      _gatewayController.text = rule.settings.gateway ?? '';
      _destinationIpController.text = rule.settings.destinationLAN;
      index = rules.indexOf(rule);
    } else {
      _isEdit = false;
      rule = NamedStaticRouteEntry(
        name: '',
        settings: StaticRouteEntry(
            destinationLAN: '', interface: 'LAN', networkPrefixLength: 24),
      );
      _subnetController.text = NetworkUtils.prefixLengthToSubnetMask(
          rule.settings.networkPrefixLength);
    }
    doSomethingWithSpinner(context, Future.doWhile(() => !mounted)).then((_) {
      _notifier.init(rules, rule, index, routerIp, subnetMask);
    });
    super.initState();
  }

  @override
  void dispose() {
    _routeNameController.dispose();
    _subnetController.dispose();
    _gatewayController.dispose();
    _destinationIpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(staticRoutingRuleProvider);
    return StyledAppPageView(
      scrollable: true,
      title: _isEdit ? loc(context).addStaticRoute : loc(context).edit,
      bottomBar: PageBottomBar(
        isPositiveEnabled: _notifier.isRuleValid(),
        positiveLabel: loc(context).save,
        onPositiveTap: () {
          final rule = ref.read(staticRoutingRuleProvider).rule;
          context.pop(rule);
        },
      ),
      child: AppCard(
        padding: EdgeInsets.symmetric(
            horizontal: Spacing.large2, vertical: Spacing.large2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppTextField.outline(
              headerText: loc(context).routeName,
              controller: _routeNameController,
              onChanged: (text) {
                _notifier.updateRule(
                  state.rule?.copyWith(
                    name: text,
                  ),
                );
              },
            ),
            const AppGap.large2(),
            AppIPFormField(
              semanticLabel: 'destination IP Address',
              header: AppText.bodyLarge(
                loc(context).destinationIPAddress,
              ),
              controller: _destinationIpController,
              border: const OutlineInputBorder(),
              onChanged: (text) {
                _notifier.updateRule(
                  state.rule?.copyWith(
                    settings:
                        state.rule?.settings.copyWith(destinationLAN: text),
                  ),
                );
              },
              onFocusChanged: (focused) {
                final text = _destinationIpController.text;
                if (!focused && text.isNotEmpty) {
                  setState(() {
                    _notifier.isValidIpAddress(text)
                        ? null
                        : loc(context).invalidIpAddress;
                  });
                }
              },
            ),
            if (_destinationIpError != null)
              Padding(
                padding: const EdgeInsets.only(top: Spacing.small2),
                child: AppText.bodyMedium(
                  _destinationIpError!,
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            const AppGap.large2(),
            AppIPFormField(
              semanticLabel: 'subnet Mask',
              header: AppText.bodyLarge(
                loc(context).subnetMask,
              ),
              controller: _subnetController,
              border: const OutlineInputBorder(),
              onChanged: (text) {
                _notifier.updateRule(
                  state.rule?.copyWith(
                    settings: state.rule?.settings.copyWith(
                      networkPrefixLength:
                          NetworkUtils.subnetMaskToPrefixLength(text),
                    ),
                  ),
                );
              },
              onFocusChanged: (focused) {
                final text = _subnetController.text;
                if (!focused && text.isNotEmpty) {
                  try {
                    setState(() {
                      _subnetMaskError = _notifier.isValidSubnetMask(
                              NetworkUtils.subnetMaskToPrefixLength(text))
                          ? null
                          : loc(context).invalidSubnetMask;
                    });
                  } on FormatException catch (e) {
                    setState(() {
                      _subnetMaskError = e.message;
                    });
                  }
                }
              },
            ),
            if (_subnetMaskError != null)
              Padding(
                padding: const EdgeInsets.only(top: Spacing.small2),
                child: AppText.bodyMedium(
                  _subnetMaskError!,
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            const AppGap.large2(),
            AppIPFormField(
              semanticLabel: 'gateway',
              header: AppText.bodyLarge(
                loc(context).gateway,
              ),
              controller: _gatewayController,
              border: const OutlineInputBorder(),
              onChanged: (text) {
                _notifier.updateRule(
                  state.rule?.copyWith(
                    settings: state.rule?.settings.copyWith(
                      gateway: () => text,
                    ),
                  ),
                );
              },
              onFocusChanged: (focused) {
                final text = _gatewayController.text;
                if (!focused) {
                  setState(() {
                    _gatewayIpError = _notifier.isValidIpAddress(
                            text, state.rule?.settings.interface == 'LAN')
                        ? null
                        : loc(context).invalidGatewayIpAddress;
                  });
                }
              },
            ),
            if (_gatewayIpError != null)
              Padding(
                padding: const EdgeInsets.only(top: Spacing.small2),
                child: AppText.bodyMedium(
                  _gatewayIpError!,
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            const AppGap.large2(),
            AppDropdownButton<RoutingSettingInterface>(
              title: loc(context).labelInterface,
              items: const [
                RoutingSettingInterface.lan,
                RoutingSettingInterface.internet,
              ],
              initial: RoutingSettingInterface.resolve(
                  state.rule?.settings.interface ?? 'LAN'),
              label: (item) => getInterfaceTitle(item.value),
              onChanged: (value) {
                _notifier.updateRule(
                  state.rule?.copyWith(
                    settings:
                        state.rule?.settings.copyWith(interface: value.value),
                  ),
                );
              },
            ),
          ],
        ),
      ),
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

  // void _save() {
  //   // Make a copy of the current routing list
  //   final settingList = List<NamedStaticRouteEntry>.from(
  //     ref.read(staticRoutingProvider).setting.entries,
  //   );
  //   // Create a new routing item
  //   final newSetting = NamedStaticRouteEntry(
  //     name: _routeNameController.text,
  //     settings: StaticRouteEntry(
  //       destinationLAN: _destinationIpController.text,
  //       gateway: _gatewayController.text,
  //       interface: selectedInterface.value,
  //       networkPrefixLength: NetworkUtils.subnetMaskToPrefixLength(
  //         _subnetController.text,
  //       ),
  //     ),
  //   );
  //   // If it is editing a current item, remove it
  //   if (_currentSetting != null) {
  //     settingList.removeWhere((element) => element == _currentSetting);
  //   }
  //   // Add the new one into the list
  //   settingList.add(newSetting);
  //   // Send the request
  //   doSomethingWithSpinner(
  //     context,
  //     ref
  //         .read(staticRoutingProvider.notifier)
  //         .saveRoutingSettingList(settingList)
  //         .then((value) {
  //       // Succeeded, update the list to the state
  //       ref.read(staticRoutingProvider).setting.copyWith(entries: settingList);
  //       showSuccessSnackBar(context, loc(context).saved);
  //       context.pop();
  //     }).onError((error, stackTrace) {
  //       // Failed, show the error message
  //       var jnapError = loc(context).unknownError;
  //       if (error is JNAPError) {
  //         jnapError = errorCodeHelper(context, error.result) ??
  //             loc(context).unknownError;
  //       }
  //       showFailedSnackBar(context, jnapError);
  //     }),
  //   );
  // }
}
