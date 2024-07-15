import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/core/jnap/models/get_routing_settings.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/advanced_settings/static_routing/providers/static_routing_provider.dart';
import 'package:privacy_gui/page/advanced_settings/static_routing/providers/static_routing_state.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/page/components/shortcuts/snack_bar.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:privacy_gui/utils.dart';
import 'package:privacygui_widgets/widgets/dropdown/dropdown_menu.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
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
  String? errorMessage;

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
    selectedInterface = RoutingSettingInterface.resolve(
      _currentSetting?.settings.interface,
    );
    return StyledAppPageView(
      scrollable: true,
      title: _currentSetting == null
          ? loc(context).addStaticRoute
          : loc(context).edit,
      bottomBar: PageBottomBar(
        isPositiveEnabled: _isInputValid(),
        isNegitiveEnabled: _currentSetting != null,
        positiveLabel: loc(context).save,
        negitiveLable: loc(context).delete,
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
              setState(() => _isInputValid());
            },
          ),
          const AppGap.large2(),
          AppDropdownMenu<RoutingSettingInterface>(
            items: const [
              RoutingSettingInterface.lan,
              RoutingSettingInterface.internet,
            ],
            initial: selectedInterface,
            label: (item) => item.value,
            onChanged: (value) {
              selectedInterface = value;
            },
          ),
          const AppGap.large2(),
          AppIPFormField(
            header: AppText.bodyLarge(
              loc(context).destinationIPAddress,
            ),
            controller: _destinationIpController,
            border: const OutlineInputBorder(),
            onChanged: (text) {
              setState(() => _isInputValid());
            },
          ),
          const AppGap.large2(),
          AppIPFormField(
            header: AppText.bodyLarge(
              loc(context).subnetMask,
            ),
            controller: _subnetController,
            border: const OutlineInputBorder(),
            onChanged: (text) {
              setState(() => _isInputValid());
            },
          ),
          const AppGap.large2(),
          AppIPFormField(
            header: AppText.bodyLarge(
              loc(context).gateway,
            ),
            controller: _gatewayController,
            border: const OutlineInputBorder(),
            onChanged: (text) {
              setState(() => _isInputValid());
            },
          ),
        ],
      ),
    );
  }

  bool _isInputValid() {
    //TODO: Check the format validation
    return _routeNameController.text.isNotEmpty &&
        _subnetController.text.isNotEmpty &&
        _gatewayController.text.isNotEmpty &&
        _destinationIpController.text.isNotEmpty;
  }

  void _save() {
    final settingList = ref.read(staticRoutingProvider).setting.entries;
    if (_currentSetting != null) {
      var updated = settingList.removeAt(
        settingList.indexWhere((element) => element == _currentSetting),
      );
      updated = updated.copyWith(
        name: _routeNameController.text,
        settings: updated.settings.copyWith(
          destinationLAN: _destinationIpController.text,
          gateway: _gatewayController.text,
          interface: selectedInterface.value,
          networkPrefixLength: NetworkUtils.subnetMaskToPrefixLength(
            _subnetController.text,
          ),
        ),
      );
      settingList.add(updated);
    } else {
      settingList.add(
        NamedStaticRouteEntry(
          name: _routeNameController.text,
          settings: StaticRouteEntry(
            destinationLAN: _destinationIpController.text,
            gateway: _gatewayController.text,
            interface: selectedInterface.value,
            networkPrefixLength: NetworkUtils.subnetMaskToPrefixLength(
              _subnetController.text,
            ),
          ),
        ),
      );
    }

    doSomethingWithSpinner(
      context,
      ref
          .read(staticRoutingProvider.notifier)
          .saveRoutingSettingList(settingList)
          .then((value) {
        showSuccessSnackBar(context, loc(context).saved);
        context.pop();
      }).onError((error, stackTrace) =>
              showFailedSnackBar(context, loc(context).unknownError)),
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
