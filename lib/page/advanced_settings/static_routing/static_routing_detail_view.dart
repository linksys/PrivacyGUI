import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/core/jnap/models/get_routing_settings.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/advanced_settings/static_routing/providers/static_routing_provider.dart';
import 'package:privacy_gui/page/advanced_settings/static_routing/providers/static_routing_state.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/page/components/shortcuts/snack_bar.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:privacy_gui/util/error_code_helper.dart';
import 'package:privacy_gui/utils.dart';
import 'package:privacygui_widgets/widgets/dropdown/dropdown_menu.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/gap/const/spacing.dart';
import 'package:privacygui_widgets/widgets/input_field/ip_form_field.dart';

class StaticRoutingDetailView extends ArgumentsConsumerStatefulView {
  const StaticRoutingDetailView({
    super.key,
    super.args,
  });

  @override
  ConsumerState<StaticRoutingDetailView> createState() =>
      _StaticRoutingDetailViewState();
}

class _StaticRoutingDetailViewState
    extends ConsumerState<StaticRoutingDetailView> {
  late final NamedStaticRouteEntry? _currentSetting;
  final _routeNameController = TextEditingController();
  final _subnetController = TextEditingController();
  final _gatewayController = TextEditingController();
  final _destinationIpController = TextEditingController();
  late RoutingSettingInterface selectedInterface;
  String? _destinationIpError;
  String? _subnetMaskError;
  String? _gatewayIpError;

  @override
  void initState() {
    _currentSetting = widget.args['currentSetting'] as NamedStaticRouteEntry?;
    if (_currentSetting != null) {
      _routeNameController.text = _currentSetting!.name;
      _subnetController.text = NetworkUtils.prefixLengthToSubnetMask(
        _currentSetting!.settings.networkPrefixLength,
      );
      _gatewayController.text = _currentSetting!.settings.gateway!;
      _destinationIpController.text = _currentSetting!.settings.destinationLAN;
    }
    selectedInterface = RoutingSettingInterface.resolve(
      _currentSetting?.settings.interface,
    );
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
    return StyledAppPageView(
      scrollable: true,
      title: _currentSetting == null
          ? loc(context).addStaticRoute
          : loc(context).edit,
      bottomBar: PageBottomBar(
        isPositiveEnabled: _isInputValid(),
        isNegitiveEnabled: _currentSetting != null ? true : null,
        positiveLabel: loc(context).save,
        negitiveLable: _currentSetting != null ? loc(context).delete : null,
        onPositiveTap: _save,
        onNegitiveTap: _delete,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppTextField.outline(
            hintText: loc(context).routeName,
            controller: _routeNameController,
            onChanged: (text) {
              setState(() {});
            },
          ),
          const AppGap.large2(),
          AppDropdownMenu<RoutingSettingInterface>(
            items: const [
              RoutingSettingInterface.lan,
              RoutingSettingInterface.internet,
            ],
            initial: selectedInterface,
            label: (item) => getInterfaceTitle(item.value),
            onChanged: (value) {
              setState(() {
                selectedInterface = value;
              });
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
              setState(() {});
            },
            onFocusChanged: (focused) {
              final text = _destinationIpController.text;
              if (!focused && text.isNotEmpty) {
                setState(() {
                  _destinationIpError = NetworkUtils.isValidIpAddress(text)
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
              setState(() {});
            },
            onFocusChanged: (focused) {
              final text = _subnetController.text;
              if (!focused && text.isNotEmpty) {
                try {
                  setState(() {
                    _subnetMaskError = NetworkUtils.isValidSubnetMask(text)
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
              setState(() {});
            },
            onFocusChanged: (focused) {
              final text = _gatewayController.text;
              if (!focused && text.isNotEmpty) {
                setState(() {
                  _gatewayIpError = NetworkUtils.isValidIpAddress(text)
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
        ],
      ),
    );
  }

  String getInterfaceTitle(String interface) {
    final resolved = RoutingSettingInterface.resolve(interface);
    return switch (resolved) {
      RoutingSettingInterface.lan => loc(context).lanWireless,
      RoutingSettingInterface.internet =>
        RoutingSettingInterface.internet.value,
      _ => loc(context).lanWireless,
    };
  }

  bool _isInputValid() {
    return _routeNameController.text.isNotEmpty &&
        _destinationIpController.text.isNotEmpty &&
        _destinationIpError == null &&
        _subnetController.text.isNotEmpty &&
        _subnetMaskError == null &&
        _gatewayController.text.isNotEmpty &&
        _gatewayIpError == null;
  }

  void _save() {
    // Make a copy of the current routing list
    final settingList = List<NamedStaticRouteEntry>.from(
      ref.read(staticRoutingProvider).setting.entries,
    );
    // Create a new routing item
    final newSetting = NamedStaticRouteEntry(
      name: _routeNameController.text,
      settings: StaticRouteEntry(
        destinationLAN: _destinationIpController.text,
        gateway: _gatewayController.text,
        interface: selectedInterface.value,
        networkPrefixLength: NetworkUtils.subnetMaskToPrefixLength(
          _subnetController.text,
        ),
      ),
    );
    // If it is editing a current item, remove it
    if (_currentSetting != null) {
      settingList.removeWhere((element) => element == _currentSetting);
    }
    // Add the new one into the list
    settingList.add(newSetting);
    // Send the request
    doSomethingWithSpinner(
      context,
      ref
          .read(staticRoutingProvider.notifier)
          .saveRoutingSettingList(settingList)
          .then((value) {
        // Succeeded, update the list to the state
        ref.read(staticRoutingProvider).setting.copyWith(entries: settingList);
        showSuccessSnackBar(context, loc(context).saved);
        context.pop();
      }).onError((error, stackTrace) {
        // Failed, show the error message
        var jnapError = loc(context).unknownError;
        if (error is JNAPError) {
          jnapError = errorCodeHelper(context, error.result) ??
              loc(context).unknownError;
        }
        showFailedSnackBar(context, jnapError);
      }),
    );
  }

  void _delete() {
    final settingList = ref.read(staticRoutingProvider).setting.entries;
    settingList.removeWhere((element) => element == _currentSetting);
    doSomethingWithSpinner(
      context,
      ref
          .read(staticRoutingProvider.notifier)
          .saveRoutingSettingList(settingList)
          .then((value) => context.pop()),
    );
  }
}
