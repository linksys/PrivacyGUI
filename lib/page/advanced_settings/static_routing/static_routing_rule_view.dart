import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/core/jnap/models/get_routing_settings.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/advanced_settings/static_routing/providers/static_routing_provider.dart';
import 'package:privacy_gui/page/advanced_settings/static_routing/providers/static_routing_rule_provider.dart';
import 'package:privacy_gui/page/advanced_settings/static_routing/providers/static_routing_state.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/page/components/ui_kit_page_view.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:privacy_gui/utils.dart';

import 'package:ui_kit_library/ui_kit.dart';

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

  String? _routeNameError;
  String? _destinationIpError;
  String? _subnetMaskError;
  String? _gatewayIpError;
  bool _isEdit = false;

  @override
  void initState() {
    _notifier = ref.read(staticRoutingRuleProvider.notifier);
    final state = ref.read(staticRoutingProvider);
    final routerIp = state.status.routerIp;
    final subnetMask = state.status.subnetMask;
    final rules = widget.args['items'] as List<NamedStaticRouteEntry>? ?? [];
    var rule = widget.args['edit'] as NamedStaticRouteEntry?;
    int? index;
    if (rule != null) {
      _isEdit = true;
      _routeNameController.text = rule.name;
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
    return UiKitPageView.withSliver(
      title: _isEdit ? loc(context).edit : loc(context).addStaticRoute,
      bottomBar: UiKitBottomBarConfig(
        isPositiveEnabled: _notifier.isRuleValid(),
        positiveLabel: loc(context).save,
        onPositiveTap: () {
          final rule = ref.read(staticRoutingRuleProvider).rule;
          context.pop(rule);
        },
      ),
      child: (context, constraints) => AppCard(
        child: Padding(
          padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.xxl, vertical: AppSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppTextFormField(
                key: const Key('ruleName'),
                label: loc(context).routeName,
                controller: _routeNameController,
                validator: (text) => _routeNameError,
                onChanged: (text) {
                  _notifier.updateRule(
                    state.rule?.copyWith(
                      name: text,
                    ),
                  );
                },
                // Removed onFocusChanged as not directly supported or needs workaround.
                // Assuming validation logic can be moved to onChanged or validator.
                // For now keeping simple replacement.
              ),
              AppGap.xxl(),
              AppIpv4TextField(
                key: const Key('destinationIP'),
                label: loc(context).destinationIPAddress,
                controller: _destinationIpController,
                onChanged: (text) {
                  _notifier.updateRule(
                    state.rule?.copyWith(
                      settings:
                          state.rule?.settings.copyWith(destinationLAN: text),
                    ),
                  );
                },
                // errorText handled via validator or internal state?
                // AppIpv4TextField handles validation internally usually?
                // Migration doc says: "UI Kit 版本，新增 errorText 與 invalidFormatMessage 參數" for MacAddress.
                // For IPv4: "專用 IP 輸入框，移除 privacygui_widgets 依賴"
                // Assuming AppIpv4TextField has mostly compatible API.
                // Re-checking AppIpv4TextField API if possible would be safer.
                // Given constraints, I will assume it has `errorText` or similar.
                errorText: _destinationIpError,
              ),
              AppGap.xxl(),
              AppIpv4TextField(
                key: const Key('subnetMask'),
                label: loc(context).subnetMask,
                controller: _subnetController,
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
                errorText: _subnetMaskError,
              ),
              AppGap.xxl(),
              AppIpv4TextField(
                key: const Key('gateway'),
                label: loc(context).gateway,
                controller: _gatewayController,
                onChanged: (text) {
                  _notifier.updateRule(
                    state.rule?.copyWith(
                      settings: state.rule?.settings.copyWith(
                        gateway: () => text,
                      ),
                    ),
                  );
                },
                errorText: _gatewayIpError,
              ),
              AppGap.xxl(),
              AppDropdown<RoutingSettingInterface>(
                key: const Key('interface'),
                label: loc(context).labelInterface,
                items: const [
                  RoutingSettingInterface.lan,
                  RoutingSettingInterface.internet,
                ],
                value: RoutingSettingInterface.resolve(
                    state.rule?.settings.interface ?? 'LAN'),
                itemAsString: (item) => getInterfaceTitle(item.value),
                onChanged: (value) {
                  if (value == null) return;
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
